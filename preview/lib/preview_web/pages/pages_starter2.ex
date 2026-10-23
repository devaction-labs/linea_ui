defmodule PreviewWeb.Pages.PagesStarter2 do
  use PreviewWeb.Page, title: "Unblurred Header", category: :layout, lineone: "pages-starter-2"

  alias PreviewWeb.StarterShell

  def mount(socket), do: StarterShell.mount(socket, "/pages-starter2")

  def handle_event(event, params, socket), do: StarterShell.handle_event(event, params, socket)

  def render(assigns) do
    ~H"""
    <StarterShell.starter
      layout="sidebar"
      header_blur={false}
      sidebar_open={@sidebar_open}
      current={@current}
    />
    """
  end
end
