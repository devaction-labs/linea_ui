defmodule LineaUI.Components.SegmentedLiveTest do
  use LineaUI.LiveCase, async: true

  alias LineaUI.Test.SegmentedLive

  test "the hidden input of a form field is what phx-change submits", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, SegmentedLive)

    assert [_] =
             html
             |> find(~s(input[type=hidden][name="filter[view]"][value=list]))
             |> Enum.to_list()

    view |> element("#filter") |> render_change(%{"filter" => %{"view" => "kanban"}})

    html = render(view)
    assert html |> find("#filter_view") |> LazyHTML.attribute("data-value") == ["kanban"]

    assert html
           |> find("#filter_view button[aria-pressed=true]")
           |> LazyHTML.attribute("data-value") == ["kanban"]

    assert view |> element("#last") |> render() =~ "kanban"
  end

  test "the hook's on_change reaches the LiveView", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, SegmentedLive)

    view
    |> element("#status")
    |> render_hook("set-status", %{"id" => "status", "value" => "draft"})

    assert view |> element("#last") |> render() =~ "status"
    html = render(view)
    assert html |> find("#status") |> LazyHTML.attribute("data-value") == ["draft"]
  end

  test "the server changes the chosen segment through value", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, SegmentedLive)
    assert html |> find("#status") |> LazyHTML.attribute("data-value") == ["all"]

    html = view |> element("#server-pick") |> render_click()

    assert html |> find("#status") |> LazyHTML.attribute("data-value") == ["draft"]

    assert html |> find("#status button[aria-pressed=true]") |> LazyHTML.attribute("data-value") ==
             ["draft"]
  end
end
