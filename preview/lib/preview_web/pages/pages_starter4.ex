defmodule PreviewWeb.Pages.PagesStarter4 do
  use PreviewWeb.Page, title: "Minimal Sidebar", category: :layout, lineone: "pages-starter-4"

  alias PreviewWeb.StarterShell

  def mount(socket), do: StarterShell.mount(socket, "/pages-starter4")

  def handle_event(event, params, socket), do: StarterShell.handle_event(event, params, socket)

  def render(assigns) do
    ~H"""
    <StarterShell.starter layout="minimal" sidebar_open={@sidebar_open} current={@current} />
    """
  end
end
