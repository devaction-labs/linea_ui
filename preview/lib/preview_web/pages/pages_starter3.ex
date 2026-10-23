defmodule PreviewWeb.Pages.PagesStarter3 do
  use PreviewWeb.Page, title: "Centered Links", category: :layout, lineone: "pages-starter-3"

  alias PreviewWeb.StarterShell

  def mount(socket), do: StarterShell.mount(socket, "/pages-starter3")

  def handle_event(event, params, socket), do: StarterShell.handle_event(event, params, socket)

  def render(assigns) do
    ~H"""
    <StarterShell.starter layout="sidebar" centered sidebar_open={@sidebar_open} current={@current} />
    """
  end
end
