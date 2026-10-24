defmodule LineaUI.Installer.Js do
  @moduledoc """
  The edit `mix linea_ui.install` makes to the app's `assets/js/app.js`, as a pure function from
  the file's contents to its new contents.

  It imports LineaUI's hooks and spreads them into the `hooks` option of the `LiveSocket`, whether
  that option is an object (`hooks: {...colocatedHooks}`), a variable (`hooks: Hooks`) or missing.
  """

  @import_line ~s|import {Hooks as LineaHooks} from "linea_ui"|
  @spread "...LineaHooks"

  @import_anchors [
    ~r/^import\s[^\n]*["']phoenix-colocated\/[^\n]*$/m,
    ~r/^import\s[^\n]*["']phoenix_live_view["'][^\n]*$/m,
    ~r/^import\s[^\n]*["']phoenix["'][^\n]*$/m
  ]

  @object_hooks ~r/(hooks:\s*\{)([^{}]*)(\})/
  @variable_hooks ~r/hooks:\s*([A-Za-z_$][\w$.]*)(?=\s*[,}\n])/
  @hooks_key ~r/\bhooks\s*:/
  @live_socket_options ~r/(new\s+LiveSocket\((?:[^()]*?,){2}\s*\{)(\n[ \t]*)?/

  @doc "Whether the file builds a `LiveSocket`, which the hooks are registered on."
  @spec live_socket?(String.t()) :: boolean()
  def live_socket?(js), do: Regex.match?(@live_socket_options, js)

  @doc """
  Returns `{:ok, js}` with the hooks imported and registered, `:unchanged` when LineaUI's hooks are
  already registered, or `:error` when the file has no `LiveSocket` options or import to anchor on.
  """
  @spec register_hooks(String.t()) :: {:ok, String.t()} | :unchanged | :error
  def register_hooks(js) do
    registered?(js)
    |> register(js)
  end

  defp registered?(js), do: js =~ @spread and js =~ ~s|from "linea_ui"|

  defp register(true, _js), do: :unchanged

  defp register(false, js) do
    with true <- live_socket?(js),
         {:ok, spread} <- spread_hooks(js) do
      import_hooks(spread)
    else
      _ -> :error
    end
  end

  defp spread_hooks(js) do
    cond do
      Regex.match?(@object_hooks, js) ->
        {:ok, Regex.replace(@object_hooks, js, &object/4, global: false)}

      Regex.match?(@variable_hooks, js) ->
        {:ok, Regex.replace(@variable_hooks, js, "hooks: {...\\1, #{@spread}}", global: false)}

      Regex.match?(@hooks_key, js) ->
        :error

      true ->
        {:ok, add_option(js)}
    end
  end

  defp object(_all, open, inner, close), do: open <> append_spread(inner) <> close

  defp append_spread(inner) do
    case String.trim(inner) do
      "" -> @spread
      trimmed -> String.trim_trailing(trimmed, ",") <> ", " <> @spread
    end
  end

  defp add_option(js) do
    Regex.replace(@live_socket_options, js, &option/3, global: false)
  end

  defp option(_all, open, ""), do: open <> "hooks: {#{@spread}}, "
  defp option(_all, open, newline), do: open <> newline <> "hooks: {#{@spread}}," <> newline

  defp import_hooks(js) do
    @import_anchors
    |> Enum.find_value(&Regex.run(&1, js, return: :index))
    |> place_import(js)
  end

  defp place_import(nil, _js), do: :error

  defp place_import([{start, length} | _], js) do
    head = binary_part(js, 0, start + length)
    tail = binary_part(js, start + length, byte_size(js) - start - length)
    {:ok, head <> "\n" <> @import_line <> tail}
  end
end
