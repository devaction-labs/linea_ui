defmodule LineaUI.Test.CommandPaletteLive do
  @moduledoc false
  use Phoenix.LiveView
  use LineaUI

  @items [
    %{
      group: "Go to",
      scope: "pages",
      label: "Orders",
      sub: "Sales",
      value: "orders",
      keys: ["G", "O"]
    },
    %{group: "Actions", scope: "actions", label: "New order", value: "new-order"}
  ]

  def mount(_params, _session, socket),
    do: {:ok, assign(socket, items: @items, last: nil, open: false)}

  def render(assigns) do
    ~H"""
    <.command_palette
      id="palette"
      open={@open}
      items={@items}
      scopes={[{"All", "all"}, {"Pages", "pages"}]}
      assistant={%{label: "Ask: %{query}"}}
      on_select="selected"
      on_assistant="asked"
      on_search="search"
      on_close="closed"
    />
    <button id="open" phx-click="open">Open</button>
    <p id="last">{inspect(@last)}</p>
    """
  end

  def handle_event("open", _params, socket), do: {:noreply, LineaUI.open(socket, "palette")}

  def handle_event("selected", params, socket),
    do: {:noreply, assign(socket, last: {:selected, params})}

  def handle_event("asked", params, socket),
    do: {:noreply, assign(socket, last: {:asked, params})}

  def handle_event("closed", params, socket),
    do: {:noreply, assign(socket, last: {:closed, params})}

  def handle_event("search", %{"query" => query}, socket) do
    found =
      Enum.filter(@items, &String.contains?(String.downcase(&1.label), String.downcase(query)))

    {:noreply, assign(socket, items: found, last: {:search, query})}
  end
end
