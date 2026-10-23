defmodule LineaUI.Components.ElementsLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule ElementsLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, _session, socket),
      do: {:ok, assign(socket, events: [], alert_open: true, tip_open: false)}

    def handle_event("show_tip", _params, socket),
      do: {:noreply, socket |> assign(tip_open: true) |> LineaUI.open("tip")}

    def handle_event("show_alert", _params, socket),
      do: {:noreply, assign(socket, alert_open: true)}

    def handle_event(event, params, socket),
      do: {:noreply, update(socket, :events, &[{event, params} | &1])}

    def render(assigns) do
      ~H"""
      <.alert id="notice" open={@alert_open} dismissible on_dismiss="dismissed">Saved</.alert>
      <.badge id="filter" on_remove="removed">Elixir</.badge>
      <.tooltip id="tip" text="Hint" open={@tip_open} on_open="tip_opened" on_close="tip_closed">
        <button id="tip-trigger">?</button>
      </.tooltip>
      <button id="show-tip" phx-click="show_tip">Show</button>
      <ul id="events">
        <li :for={{event, params} <- @events}>{event}:{params["id"]}</li>
      </ul>
      """
    end
  end

  test "the alert's close button tells the server which alert closed", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, ElementsLive)
    html = view |> element("#notice button[aria-label=Close]") |> render_click()
    assert html =~ "dismissed:notice"
  end

  test "the badge's remove button sends its id", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, ElementsLive)
    html = view |> element("#filter button") |> render_click()
    assert html =~ "removed:filter"
  end

  test "the tooltip carries its server state and callbacks for the hook", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, ElementsLive)
    [tip] = find(html, "#tip") |> Enum.to_list()
    assert LazyHTML.attribute(tip, "phx-hook") == ["LineaUI.Tooltip"]
    assert LazyHTML.attribute(tip, "data-open") == ["false"]
    assert tip |> LazyHTML.attribute("data-on-open") |> hd() =~ "tip_opened"

    view |> element("#show-tip") |> render_click()
    assert_push_event(view, "linea:open", %{id: "#tip"})
    assert view |> element("#tip") |> render() =~ ~s(data-open="true")
  end

  test "the hook's callback events reach the server", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, ElementsLive)
    assert render_hook(view, "tip_closed", %{"id" => "tip"}) =~ "tip_closed:tip"
  end
end
