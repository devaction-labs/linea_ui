if Code.ensure_loaded?(Igniter) do
  defmodule LineaUI.Installer.Hugeicons do
    @moduledoc """
    The step of `mix linea_ui.install --hugeicons` that draws the components' glyphs with
    [Hugeicons](https://hugeicons.com) instead of LineOne's own: the `hugeicons` dependency (its SVGs
    are vendored, not compiled) and `config :linea_ui, :icons, :hugeicons`. The Tailwind plugin
    that turns `huge-*` classes into masks is added to `app.css` by `LineaUI.Installer.Assets.css/2`.
    """

    @dep {:hugeicons,
          github: "hugeicons/hugeicons",
          ref: "3365154e0ae2461fbfb6249b89649127207a4f9e",
          sparse: "icons",
          app: false,
          compile: false,
          depth: 1}

    @doc "Adds the dependency and the icon-set config."
    @spec install(Igniter.t()) :: Igniter.t()
    def install(igniter) do
      igniter
      |> Igniter.Project.Deps.add_dep(@dep, on_exists: :skip)
      |> Igniter.Project.Config.configure("config.exs", :linea_ui, [:icons], :hugeicons)
    end
  end
end
