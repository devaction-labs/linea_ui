if Code.ensure_loaded?(Igniter) do
  defmodule LineaUI.Installer.Web do
    @moduledoc """
    The steps of `mix linea_ui.install` that edit the Phoenix app's Elixir code: the endpoint,
    which serves LineaUI's fonts, and the web module, which imports the components.

    Each step is idempotent and, when it cannot find the place to edit, adds a warning to the
    `Igniter` and leaves the code alone.
    """

    alias Igniter.Code.{Common, Function}
    alias Igniter.Libs.Phoenix, as: PhoenixApp
    alias Igniter.Project.Module
    alias Sourceror.Zipper

    @static """
    plug Plug.Static, at: "/linea_ui", from: {:linea_ui, "priv/static"}
    """

    @use_linea "use LineaUI, avoid_conflicts: true"

    @doc """
    Adds `plug Plug.Static, at: "/linea_ui", from: {:linea_ui, "priv/static"}` after the
    endpoint's own `Plug.Static`.
    """
    @spec endpoint(Igniter.t()) :: Igniter.t()
    def endpoint(igniter) do
      module = PhoenixApp.web_module_name(igniter, "Endpoint")

      igniter
      |> Module.find_and_update_module(module, &add_static/1)
      |> or_warn(missing_endpoint(module))
    end

    defp add_static(zipper) do
      case find_static(zipper, &linea_static?/1) do
        {:ok, _} -> {:ok, zipper}
        :error -> add_after_static(zipper)
      end
    end

    defp add_after_static(zipper) do
      case find_static(zipper, &plug_static?/1) do
        {:ok, static} -> {:ok, Common.add_code(static, @static, placement: :after)}
        :error -> {:warning, missing_static()}
      end
    end

    defp find_static(zipper, predicate) do
      Function.move_to_function_call_in_current_scope(zipper, :plug, [1, 2], predicate)
    end

    defp plug_static?(call), do: Function.argument_equals?(call, 0, Plug.Static)

    defp linea_static?(call) do
      plug_static?(call) and
        Function.argument_matches_predicate?(call, 1, &(source(&1) =~ "linea_ui"))
    end

    @doc """
    Adds `use LineaUI, avoid_conflicts: true` to `html_helpers/0` of the web module, after the
    `CoreComponents` import.
    """
    @spec html_helpers(Igniter.t()) :: Igniter.t()
    def html_helpers(igniter) do
      module = PhoenixApp.web_module(igniter)

      igniter
      |> Module.find_and_update_module(module, &add_use/1)
      |> or_warn(missing_web(module))
    end

    defp add_use(zipper) do
      with {:ok, helpers} <- Function.move_to_defp(zipper, :html_helpers, 0),
           {:ok, body} <- Common.move_to_do_block(helpers) do
        add_use_to(zipper, body)
      else
        _ -> {:warning, missing_helpers()}
      end
    end

    defp add_use_to(zipper, body) do
      case Function.move_to_function_call_in_current_scope(body, :use, [1, 2], &linea?/1) do
        {:ok, _} -> {:ok, zipper}
        :error -> add_use_after_import(body)
      end
    end

    defp add_use_after_import(body) do
      case find_import(body) do
        {:ok, anchor} -> {:ok, Common.add_code(anchor, @use_linea, placement: :after)}
        :error -> {:warning, missing_helpers()}
      end
    end

    defp linea?(call), do: Function.argument_equals?(call, 0, LineaUI)

    defp find_import(quoted) do
      with :error <-
             Function.move_to_function_call_in_current_scope(
               quoted,
               :import,
               [1, 2],
               &core_components?/1
             ) do
        Function.move_to_function_call_in_current_scope(quoted, :import, [1, 2], &phoenix_html?/1)
      end
    end

    defp core_components?(call) do
      Function.argument_matches_predicate?(call, 0, &(source(&1) =~ "CoreComponents"))
    end

    defp phoenix_html?(call), do: Function.argument_equals?(call, 0, Elixir.Phoenix.HTML)

    defp source(zipper), do: zipper |> Zipper.node() |> Sourceror.to_string()

    defp or_warn({:ok, igniter}, _message), do: igniter
    defp or_warn({:error, igniter}, message), do: Igniter.add_warning(igniter, message)

    defp missing_endpoint(module) do
      "LineaUI: the endpoint #{inspect(module)} was not found. " <>
        ~s|Add `plug Plug.Static, at: "/linea_ui", from: {:linea_ui, "priv/static"}` to yours, which serves the fonts.|
    end

    defp missing_static do
      ~s|LineaUI: the endpoint has no `plug Plug.Static`. Add `plug Plug.Static, at: "/linea_ui", from: {:linea_ui, "priv/static"}` to it, which serves the fonts.|
    end

    defp missing_web(module) do
      "LineaUI: the web module #{inspect(module)} was not found. " <>
        "Add `use LineaUI, avoid_conflicts: true` where your app imports its components."
    end

    defp missing_helpers do
      "LineaUI: could not find `html_helpers/0` with an `import` in the web module. " <>
        "Add `use LineaUI, avoid_conflicts: true` where your app imports its components."
    end
  end
end
