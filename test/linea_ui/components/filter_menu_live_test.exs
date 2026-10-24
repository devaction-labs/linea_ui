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
end
