defmodule LineaUI.Components.CalendarLiveTest do
  use LineaUI.LiveCase, async: true

  alias LineaUI.Components.Calendar

  defmodule AgendaLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, session, socket) do
      {:ok, assign(socket, date: ~D[2026-10-24], view: "month", test: session["test"])}
    end

    def handle_event("navigate", %{"date" => date, "view" => view}, socket),
      do: {:noreply, assign(socket, date: Date.from_iso8601!(date), view: view)}

    def handle_event("view", %{"date" => date, "view" => view}, socket),
      do: {:noreply, assign(socket, date: Date.from_iso8601!(date), view: view)}

    def handle_event("select", params, socket) do
      send(socket.assigns.test, {:select, params})
      {:noreply, socket}
    end

    def handle_event("event", params, socket) do
      send(socket.assigns.test, {:event, params})
      {:noreply, socket}
    end

    def events(date, view) do
      {first, last} = Calendar.calendar_range(date, view)

      for n <- 0..Date.diff(last, first), n in [4, 20] do
        %{id: n, title: "Event #{n}", date: Date.add(first, n)}
      end
    end

    def render(assigns) do
      assigns = assign(assigns, :events, events(assigns.date, assigns.view))

      ~H"""
      <.calendar
        id="agenda"
        view={@view}
        date={@date}
        today={~D[2026-10-24]}
        events={@events}
        on_navigate="navigate"
        on_view="view"
        on_select="select"
        on_event="event"
      />
      """
    end
  end

  defp title(view),
    do: view |> render() |> find("#agenda-title") |> LazyHTML.text() |> String.trim()

  test "the arrows ask for the next and the previous period and the server re-renders it", %{
    conn: conn
  } do
    {:ok, view, _html} = live_isolated(conn, AgendaLive, session: %{"test" => self()})
    assert title(view) == "October 2026"

    view |> element("[data-nav=next]") |> render_click()
    assert title(view) == "November 2026"

    view |> element("[data-nav=prev]") |> render_click()
    view |> element("[data-nav=prev]") |> render_click()
    assert title(view) == "September 2026"
  end

  test "Today returns to the day marked as today", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, AgendaLive, session: %{"test" => self()})

    view |> element("[data-nav=next]") |> render_click()
    assert title(view) == "November 2026"

    view |> element("[data-nav=today]") |> render_click()
    assert title(view) == "October 2026"
  end

  test "the view switch changes to the week grid and back", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, AgendaLive, session: %{"test" => self()})

    html = view |> element("[data-view-button=week]") |> render_click()
    assert find(html, "#agenda") |> LazyHTML.attribute("data-view") == ["week"]
    assert find(html, "[data-view-button=week]") |> LazyHTML.attribute("aria-pressed") == ["true"]
    assert title(view) == "18 – 24 Oct 2026"

    html = view |> element("[data-view-button=month]") |> render_click()
    assert find(html, "#agenda") |> LazyHTML.attribute("data-view") == ["month"]
  end

  test "choosing a day pushes its date", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, AgendaLive, session: %{"test" => self()})

    view |> element("[data-date='2026-10-12']") |> render_click()

    assert_received {:select, %{"id" => "agenda", "date" => "2026-10-12"}}
  end

  test "clicking an event pushes its id and day, and not the day's select", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, AgendaLive, session: %{"test" => self()})

    view |> element("[data-date='2026-10-01'] button", "Event 4") |> render_click()

    assert_received {:event, %{"id" => "agenda", "event" => 4, "date" => "2026-10-01"}}
    refute_received {:select, _params}
  end
end
