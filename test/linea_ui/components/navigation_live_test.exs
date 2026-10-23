defmodule LineaUI.Components.NavigationLiveTest do
  use LineaUI.LiveCase, async: true

  alias LineaUI.Test.{PaginationLive, TimelineLive}

  test "pagination pushes the page to the LiveView", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, PaginationLive)
    html = view |> element("#pages button", "2") |> render_click()
    assert html |> find("#pages [aria-current=page]") |> Enum.map(&LazyHTML.text/1) == ["2"]

    html = view |> element("#pages button[aria-label='Next page']") |> render_click()
    assert html |> find("#pages [aria-current=page]") |> Enum.map(&LazyHTML.text/1) == ["3"]
  end

  test "pagination with target reaches the LiveComponent", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, PaginationLive)
    html = view |> element("#inner-pages button", "3") |> render_click()
    assert html |> find("#inner-pages [aria-current=page]") |> Enum.map(&LazyHTML.text/1) == ["3"]
    assert html |> find("#pages [aria-current=page]") |> Enum.map(&LazyHTML.text/1) == ["1"]
  end

  test "the timeline renders a stream", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, TimelineLive)
    assert html |> find("ol#events[phx-update=stream] > li#events-1") |> Enum.count() == 1

    html = view |> element("#add") |> render_click()
    assert html |> find("ol#events > li#events-3") |> Enum.count() == 1
    assert html =~ "Delivered"

    html = view |> element("#drop") |> render_click()
    assert html |> find("li#events-1") |> Enum.count() == 0
  end
end
