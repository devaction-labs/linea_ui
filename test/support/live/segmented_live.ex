defmodule LineaUI.Test.SegmentedLive do
  @moduledoc false
  use Phoenix.LiveView
  use LineaUI

  def mount(_params, _session, socket) do
    form = to_form(%{"view" => "list", "period" => "month"}, as: :filter)
    {:ok, assign(socket, form: form, status: "all", last: nil)}
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} id="filter" phx-change="change">
      <.segmented field={@form[:view]} options={[{"List", "list"}, {"Kanban", "kanban"}]} />
    </.form>
    <.segmented
      id="status"
      value={@status}
      on_change="set-status"
      options={[%{label: "All", value: "all", count: 4}, %{label: "Draft", value: "draft"}]}
    />
    <button id="server-pick" phx-click="server-pick">Draft from the server</button>
    <p id="last">{inspect(@last)}</p>
    """
  end

  def handle_event("change", %{"filter" => params}, socket),
    do: {:noreply, assign(socket, form: to_form(params, as: :filter), last: params)}

  def handle_event("set-status", %{"id" => "status", "value" => value}, socket),
    do: {:noreply, assign(socket, status: value, last: {:status, value})}

  def handle_event("server-pick", _params, socket),
    do: {:noreply, assign(socket, status: "draft")}
end
