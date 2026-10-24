defmodule LineaUI.Components.TabsLiveTest do
  use LineaUI.LiveCase, async: true

  alias LineaUI.Test.TabsLive

  test "the hook's on_change reaches the LiveView", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, TabsLive)

    view
    |> element("#t")
    |> render_hook("pick", %{"id" => "t", "value" => "profile", "tab" => "profile"})

    assert view |> element("#picked") |> render() =~ "profile"
  end

  test "the server changes the selection through selected", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, TabsLive)
    assert html =~ ~s(data-selected="home")
    html = view |> element("#server-pick") |> render_click()
    assert html |> find("#t[data-selected=profile]") |> Enum.count() == 1
    assert html |> find("#t-tab-profile[aria-selected=true]") |> Enum.count() == 1
    assert html |> find("#t-panel-home[hidden]") |> Enum.count() == 1
  end

  defmodule NavTabsLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, _session, socket), do: {:ok, assign(socket, tab: "show")}

    def render(assigns) do
      ~H"""
      <.tabs id="nav" selected={@tab}>
        <:tab name="show" patch="/customers/1">Details</:tab>
        <:tab name="orders" patch="/customers/1/orders">Orders</:tab>
      </.tabs>
      <button id="go-orders" phx-click="go">Orders</button>
      """
    end

    def handle_event("go", _params, socket), do: {:noreply, assign(socket, tab: "orders")}
  end

  test "navigation tabs follow the server's selected with aria-current", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, NavTabsLive)
    assert html |> find("a#nav-tab-show[aria-current=page]") |> Enum.count() == 1
    html = view |> element("#go-orders") |> render_click()

    assert html |> find("a#nav-tab-orders[aria-current=page][aria-selected=true]") |> Enum.count() ==
             1

    assert html |> find("#nav-tab-show[aria-current]") |> Enum.count() == 0
    assert html |> find("[aria-controls]") |> Enum.count() == 0
  end
end
