defmodule LineaUI.LiveCaseTest do
  use LineaUI.LiveCase, async: true

  defmodule CounterLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, _session, socket), do: {:ok, assign(socket, count: 0)}
    def handle_event("inc", _params, socket), do: {:noreply, update(socket, :count, &(&1 + 1))}

    def render(assigns) do
      ~H"""
      <.button id="inc" phx-click="inc">{@count}</.button>
      """
    end
  end

  test "a component's event reaches the LiveView", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, CounterLive)
    assert view |> element("#inc") |> render_click() =~ "1"
  end
end
