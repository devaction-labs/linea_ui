if Code.ensure_loaded?(Igniter) do
  defmodule LineaUI.Installer.Assets do
    @moduledoc """
    The steps of `mix linea_ui.install` that edit the app's own assets: `assets/css/app.css` and
    `assets/js/app.js`.

    Each step is idempotent and, when it cannot find the place to edit, adds a warning to the
    `Igniter` and leaves the file alone.
    """

    alias LineaUI.Installer.{Css, Js}

    @css "assets/css/app.css"
    @js "assets/js/app.js"

    @doc """
    Imports LineaUI's fonts and styles in `assets/css/app.css`.

    Options: `:replace_daisyui` removes the daisyUI and heroicons plugins, `:hugeicons` adds the
    Hugeicons plugin. daisyUI left in place gets a warning, as the two stylesheets can conflict.
    """
    @spec css(Igniter.t(), keyword()) :: Igniter.t()
    def css(igniter, opts) do
      edit(igniter, @css, fn igniter, css -> edit_css(igniter, css, opts) end)
    end

    defp edit_css(igniter, css, opts) do
      edit_css(igniter, css, opts, Css.tailwind?(css))
    end

    defp edit_css(igniter, css, _opts, false) do
      {Igniter.add_warning(igniter, missing_tailwind()), css}
    end

    defp edit_css(igniter, css, opts, true) do
      edited =
        [
          {opts[:replace_daisyui], &Css.replace_daisyui/1},
          {true, &Css.import_styles/1},
          {Css.source_none?(css), &Css.add_source/1},
          {opts[:hugeicons], &Css.add_hugeicons/1}
        ]
        |> Enum.filter(&elem(&1, 0))
        |> Enum.reduce(css, fn {_enabled, step}, acc -> step.(acc) end)

      {warn_daisyui(igniter, Css.daisyui?(edited)), edited}
    end

    defp warn_daisyui(igniter, false), do: igniter
    defp warn_daisyui(igniter, true), do: Igniter.add_warning(igniter, daisyui_conflict())

    @doc """
    Imports `LineaHooks` in `assets/js/app.js` and spreads them into the `LiveSocket` hooks.
    """
    @spec js(Igniter.t()) :: Igniter.t()
    def js(igniter) do
      edit(igniter, @js, &edit_js/2)
    end

    defp edit_js(igniter, js) do
      case Js.register_hooks(js) do
        {:ok, edited} -> {igniter, edited}
        :unchanged -> {igniter, js}
        :error -> {Igniter.add_warning(igniter, missing_live_socket()), js}
      end
    end

    defp edit(igniter, path, editor) do
      igniter = Igniter.include_existing_file(igniter, path)

      case Rewrite.source(igniter.rewrite, path) do
        {:ok, source} -> apply_edit(igniter, path, source, editor)
        {:error, _} -> Igniter.add_warning(igniter, missing_file(path))
      end
    end

    defp apply_edit(igniter, path, source, editor) do
      content = Rewrite.Source.get(source, :content)
      {igniter, edited} = editor.(igniter, content)
      write(igniter, path, content, edited)
    end

    defp write(igniter, _path, content, content), do: igniter

    defp write(igniter, path, _content, edited) do
      Igniter.update_file(igniter, path, &Rewrite.Source.update(&1, :content, edited))
    end

    defp missing_file(path) do
      "LineaUI: #{path} was not found, so it was not edited. See the README, section Installation, for the lines it needs."
    end

    defp missing_tailwind do
      ~s|LineaUI: #{@css} has no `@import "tailwindcss"`, so the LineaUI imports were not added. See the README, section Installation.|
    end

    defp missing_live_socket do
      "LineaUI: could not find where #{@js} sets the LiveSocket hooks, so LineaHooks was not registered. " <>
        ~s|Add `import {Hooks as LineaHooks} from "linea_ui"` and spread `...LineaHooks` into the `hooks` option.|
    end

    defp daisyui_conflict do
      "LineaUI: #{@css} still loads daisyUI, whose styles can conflict with LineaUI's. " <>
        "Run `mix linea_ui.install --replace-daisyui` to remove its plugins (and the heroicons one), " <>
        "or remove them by hand."
    end
  end
end
