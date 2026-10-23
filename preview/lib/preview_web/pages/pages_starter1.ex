defmodule PreviewWeb.Pages.PagesStarter1 do
  use PreviewWeb.Page, title: "Blurred Header", category: :layout, lineone: "pages-starter-1"

  alias PreviewWeb.StarterShell

  def mount(socket), do: StarterShell.mount(socket, "/pages-starter1")

  def handle_event(event, params, socket), do: StarterShell.handle_event(event, params, socket)

  def render(assigns) do
    ~H"""
    <StarterShell.starter layout="sidebar" sidebar_open={@sidebar_open} current={@current} />
    """
  end
end
