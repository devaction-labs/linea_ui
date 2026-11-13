defmodule LineaUI.Components.FilterMenuLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule OrdersLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, session, socket) do
      {:ok,
       assign(socket,
         filter: %{"status" => ["approved"], "sort" => "recent"},
         mode: session["mode"],
         test: session["test"]
       )}
    end

    def handle_event("apply", %{"filter" => params}, socket) do
      send(socket.assigns.test, {:apply, params})
      {:noreply, assign(socket, filter: Map.merge(%{"status" => []}, params))}
    end

    def handle_event("change", %{"filter" => params}, socket) do
      send(socket.assigns.test, {:change, params})
      {:noreply, assign(socket, filter: Map.merge(%{"status" => []}, params))}
    end

    def render(assigns) do
      ~H"""
      <form id="orders" phx-submit="apply" phx-change="change">
        <.filter_menu
          id="orders-filter"
          mode={@mode}
          groups={[
            %{
              name: "filter[status]",
              label: "Status",
              value: @filter["status"],
              options: [{"Invoiced", "invoiced", 3}, {"Approved", "approved", 2}, {"Draft", "draft", 2}]
            },
            %{
              name: "filter[sort]",
              label: "Sort by",
              display: :section,
              type: :single,
              value: @filter["sort"],
              options: [{"Recent", "recent"}, {"Value", "value"}]
            }
          ]}
        />
      </form>
      """
    end
  end

  defmodule PeriodLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, session, socket),
      do: {:ok, assign(socket, period: "7d", test: session["test"])}

    def handle_event("apply", %{"filter" => %{"period" => period} = params}, socket) do
      send(socket.assigns.test, {:apply, params})
      {:noreply, assign(socket, period: period)}
    end

    def render(assigns) do
      ~H"""
      <form id="period" phx-submit="apply">
        <.filter_menu
          id="period-filter"
          locale="pt_BR"
          groups={[
            %{
              name: "filter[period]",
              label: "Período",
              display: :section,
              type: :single,
              custom: true,
              value: @period,
              options: [{"Hoje", "today"}, {"7 dias", "7d"}]
            }
          ]}
        />
      </form>
      """
    end
  end

  defp checked(html, role),
    do:
      html
      |> find("[role=#{role}][aria-checked=true]")
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> hd()))

  defp mount_orders(conn, mode),
    do: live_isolated(conn, OrdersLive, session: %{"test" => self(), "mode" => mode})

  test "the first paint carries the applied values, their count and the pending results", %{
    conn: conn
  } do
    {:ok, _view, html} = mount_orders(conn, "apply")

    assert checked(html, "menuitemcheckbox") == ["Approved"]
    assert checked(html, "menuitemradio") == ["Recent"]
    assert find(html, "[data-filter-applied]") |> LazyHTML.text() |> String.trim() == "1"

    assert find(html, "[data-menu-action=apply]") |> LazyHTML.text() |> String.trim() ==
             "Apply (2)"
  end

  test "Apply submits the staged inputs and the server's new values come back", %{conn: conn} do
    {:ok, view, _html} = mount_orders(conn, "apply")

    view
    |> form("#orders", %{"filter" => %{"status" => ["invoiced", "draft"], "sort" => "value"}})
    |> render_submit()

    assert_received {:apply, %{"status" => ["invoiced", "draft"], "sort" => "value"}}

    html = render(view)
    assert checked(html, "menuitemcheckbox") == ["Invoiced", "Draft"]
    assert checked(html, "menuitemradio") == ["Value"]
    assert find(html, "[data-filter-applied]") |> LazyHTML.text() |> String.trim() == "2"
    assert find(html, "[data-submenu-count]") |> LazyHTML.text() |> String.trim() == "2"

    assert find(html, "[data-menu-action=apply]") |> LazyHTML.text() |> String.trim() ==
             "Apply (5)"
  end

  test "in live mode the form's phx-change hears the ticks and there is no Apply", %{conn: conn} do
    {:ok, view, html} = mount_orders(conn, "live")

    assert find(html, "[data-menu-action=apply]") |> Enum.to_list() == []

    view |> form("#orders", %{"filter" => %{"status" => ["draft"]}}) |> render_change()

    assert_received {:change, %{"status" => ["draft"], "sort" => "recent"}}
    assert checked(render(view), "menuitemcheckbox") == ["Draft"]
  end

  test "a custom period the server applies is the row's text and the checked radio", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, PeriodLive, session: %{"test" => self()})

    assert checked(html, "menuitemradio") == ["7"]
    assert find(html, "[data-filter-custom]") |> LazyHTML.attribute("data-selected") == []

    view
    |> element("#period")
    |> render_submit(%{"filter" => %{"period" => "custom:2026-11-03..2026-11-10"}})

    assert_received {:apply, %{"period" => "custom:2026-11-03..2026-11-10"}}

    html = render(view)
    assert checked(html, "menuitemradio") == []
    assert find(html, "[data-filter-custom]") |> LazyHTML.attribute("data-selected") == ["true"]

    assert find(html, "[data-filter-custom] > [data-submenu-trigger]")
           |> LazyHTML.text()
           |> String.trim() ==
             "03/11/2026 – 10/11/2026"

    assert find(html, "input[data-custom-input]") |> LazyHTML.attribute("value") == [
             "custom:2026-11-03..2026-11-10"
           ]

    view |> element("#period") |> render_submit(%{"filter" => %{"period" => "today"}})
    html = render(view)
    assert checked(html, "menuitemradio") == ["Hoje"]
    assert find(html, "[data-filter-custom]") |> LazyHTML.attribute("data-selected") == []

    assert find(html, "[data-filter-custom] > [data-submenu-trigger]")
           |> LazyHTML.text()
           |> String.trim() ==
             "Personalizado…"
  end
end
