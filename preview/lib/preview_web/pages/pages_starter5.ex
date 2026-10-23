defmodule PreviewWeb.Pages.PagesStarter5 do
  use PreviewWeb.Page,
    title: "Horizontal Navigation",
    category: :layout,
    lineone: "pages-starter-5"

  alias PreviewWeb.StarterShell

  def mount(socket), do: StarterShell.mount(socket, "/pages-starter5")

  def handle_event(event, params, socket), do: StarterShell.handle_event(event, params, socket)

  def render(assigns) do
    ~H"""
    <StarterShell.starter layout="horizontal" sidebar_open={@sidebar_open} current={@current} />
    """
  end
end
