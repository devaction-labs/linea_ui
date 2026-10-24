defmodule LineaUI.Components.CommandPaletteLiveTest do
  use LineaUI.LiveCase, async: true

  alias LineaUI.Test.CommandPaletteLive

  test "the server opens the palette", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, CommandPaletteLive)

    view |> element("#open") |> render_click()

    assert_push_event(view, "linea:open", %{id: "#palette"})
  end

  test "choosing an item reaches the LiveView with its value", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, CommandPaletteLive)

    view
    |> element("#palette-palette")
    |> render_hook("selected", %{"id" => "palette", "value" => "orders", "new_tab" => true})

    assert view |> element("#last") |> render() =~ "new_tab"
    assert view |> element("#last") |> render() =~ "orders"
  end

  test "the assistant row reaches the LiveView with the query", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, CommandPaletteLive)

    view
    |> element("#palette-palette")
    |> render_hook("asked", %{"id" => "palette", "query" => "late customers"})

    assert view |> element("#last") |> render() =~ "late customers"
  end

  test "a search pushed by the hook makes the server render other items", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, CommandPaletteLive)
    assert find(html, "[data-item]") |> Enum.count() == 2

    view
    |> element("#palette-palette")
    |> render_hook("search", %{"id" => "palette", "query" => "customers", "scope" => "all"})

    html = render(view)
    assert find(html, "[data-item]") |> Enum.count() == 0
    assert view |> element("#last") |> render() =~ "customers"
  end

  test "closing the dialog runs on_close", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, CommandPaletteLive)

    view |> element("#palette") |> render_hook("closed", %{"id" => "palette"})

    assert view |> element("#last") |> render() =~ "closed"
  end
end
