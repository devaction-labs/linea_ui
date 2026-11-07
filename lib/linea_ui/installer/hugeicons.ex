if Code.ensure_loaded?(Igniter) do
  defmodule LineaUI.Installer.Hugeicons do
    @moduledoc """
    The step of `mix linea_ui.install --hugeicons` that draws the components' glyphs with
    [Hugeicons](https://hugeicons.com) instead of LineOne's own: `config :linea_ui, :icons, :hugeicons`
    and a notice to run `mix linea_ui.icons sync`, which vendors the SVGs into `assets/vendor/hugeicons`
    (no git dependency). The Tailwind plugin
    that turns `huge-*` classes into masks is added to `app.css` by `LineaUI.Installer.Assets.css/2`.
    """

    @doc "Sets the icon-set config and says how to fetch the SVGs."
    @spec install(Igniter.t()) :: Igniter.t()
    def install(igniter) do
      igniter
      |> Igniter.Project.Config.configure("config.exs", :linea_ui, [:icons], :hugeicons)
      |> Igniter.add_notice("""
      Hugeicons: run `mix linea_ui.icons sync` to download the icons your sources use into
      assets/vendor/hugeicons (`mix linea_ui.icons get NAME` adds one, `search TERM` finds names).
      """)
    end
  end
end
