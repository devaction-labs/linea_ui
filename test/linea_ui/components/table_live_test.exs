defmodule LineaUI.Components.TableLiveTest do
  use LineaUI.LiveCase, async: true

  alias LineaUI.Test.TableLive

  test "a hand-written stream table renders its rows", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, TableLive)

    assert ["stream"] = html |> find("#people-body") |> LazyHTML.attribute("phx-update")
    assert 4 = html |> find("#people-body tr") |> Enum.count()
    assert [_] = html |> find("#people-body tr#people-1") |> Enum.to_list()
  end

  test "sorting sends the column and the next direction", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, TableLive)

    html = view |> element("#people th button") |> render_click()

    assert html =~ "name:desc"
    assert [_] = html |> find("#people th[aria-sort=descending]") |> Enum.to_list()
  end

  test "clicking a row sends its phx-value", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, TableLive)

    html = view |> element("tr#people-2") |> render_click()

    assert html =~ "opened=2"
  end

  test "selection is held by the server and drives the header box", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, TableLive)

    html = view |> element("#people-1 input") |> render_click()

    assert ["true"] = html |> find("tr#people-1") |> LazyHTML.attribute("data-selected")
    assert ["true"] = html |> find("#people-all") |> LazyHTML.attribute("data-indeterminate")

    html = view |> element("#people-all") |> render_click()

    assert 3 = html |> find("#people-body tr[data-selected=true]") |> Enum.count()
    assert [_] = html |> find("#people-all[checked]") |> Enum.to_list()
    assert ["false"] = html |> find("#people-all") |> LazyHTML.attribute("data-indeterminate")

    html = view |> element("#people-all") |> render_click()
    assert [] = html |> find("#people-body tr[data-selected=true]") |> Enum.to_list()

    view |> element("#people-1 input") |> render_click()
    html = view |> element("#people-1 input") |> render_click()
    assert ["false"] = html |> find("tr#people-1") |> LazyHTML.attribute("data-selected")
  end

  test "the pager moves pages and changes the page size", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, TableLive)

    assert html =~ "Showing 1–15 of 40"

    html = view |> element("#pager button[phx-value-page='3']") |> render_click()
    assert html =~ "Showing 31–40 of 40"

    html = view |> element("#pager-page-size") |> render_change(%{"page_size" => "30"})
    assert html =~ "page=1 per_page=30"
    assert html =~ "Showing 1–30 of 40"
    assert [] = html |> find("#pager button[phx-value-page='3']") |> Enum.to_list()
  end
end
