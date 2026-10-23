defmodule LineaUI.Test.TimelineLive do
  @moduledoc false
  use Phoenix.LiveView
  use LineaUI

  def mount(_params, _session, socket) do
    {:ok, stream(socket, :events, [%{id: 1, title: "Created"}, %{id: 2, title: "Shipped"}])}
  end

  def render(assigns) do
    ~H"""
    <.timeline id="events" rows={@streams.events}>
      <:item :let={{id, event}}>
        <.timeline_item id={id} title={event.title} color="primary" />
      </:item>
    </.timeline>
    <button id="add" phx-click="add">Add</button>
    <button id="drop" phx-click="drop">Drop</button>
    """
  end

  def handle_event("add", _params, socket),
    do: {:noreply, stream_insert(socket, :events, %{id: 3, title: "Delivered"})}

  def handle_event("drop", _params, socket),
    do: {:noreply, stream_delete(socket, :events, %{id: 1, title: "Created"})}
end
