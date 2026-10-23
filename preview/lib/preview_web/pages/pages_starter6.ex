defmodule PreviewWeb.Pages.PagesStarter6 do
  use PreviewWeb.Page, title: "Sideblock", category: :layout, lineone: "pages-starter-6"

  alias PreviewWeb.StarterShell

  def mount(socket), do: StarterShell.mount(socket, "/pages-starter6")

  def handle_event(event, params, socket), do: StarterShell.handle_event(event, params, socket)

  def render(assigns) do
    ~H"""
    <StarterShell.starter layout="sideblock" sidebar_open={@sidebar_open} current={@current} />
    """
  end
end
