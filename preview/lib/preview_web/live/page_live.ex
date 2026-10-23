defmodule PreviewWeb.PageLive do
  use PreviewWeb, :live_view

  alias PreviewWeb.Registry

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Registry.fetch(slug) do
      {:ok, page} ->
        {:ok, socket |> assign(page: page, page_title: page.title) |> page.module.mount()}

      :error ->
        {:ok, push_navigate(socket, to: "/")}
    end
  end

  @impl true
  def handle_event(event, params, socket),
    do: socket.assigns.page.module.handle_event(event, params, socket)

  @impl true
  def handle_info(message, socket), do: socket.assigns.page.module.handle_info(message, socket)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.preview flash={@flash} page={@page}>
      {@page.module.render(assigns)}
    </Layouts.preview>
    """
  end
end
