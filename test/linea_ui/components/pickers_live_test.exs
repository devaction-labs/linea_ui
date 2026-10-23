defmodule LineaUI.Components.PickersLiveTest do
  use LineaUI.LiveCase, async: true

  alias LineaUI.Test.PickersLive

  test "the hidden inputs carry the field names and phx-change gets their values", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, PickersLive)

    assert [_] =
             html
             |> find(~s(select[name="trip[state]"] option[value=AL][selected]))
             |> Enum.to_list()

    assert [_] =
             html
             |> find(~s(select[name="trip[tags][]"] option[value=a][selected]))
             |> Enum.to_list()

    assert [_] = html |> find(~s(input[type=hidden][name="trip[day]"])) |> Enum.to_list()
    assert [_] = html |> find(~s(input[type=hidden][name="trip[body]"])) |> Enum.to_list()

    view
    |> element("#trip")
    |> render_change(%{
      "trip" => %{
        "state" => "AK",
        "tags" => ["", "a", "b"],
        "day" => "2026-10-23",
        "at" => "13:13",
        "body" => "<p>Hi</p>"
      }
    })

    html = render(view)
    assert html |> find("#state") |> LazyHTML.text() == "AK"
    assert html |> find("#trip_state") |> LazyHTML.attribute("data-value") == [~s(["AK"])]
    assert html |> find("#trip_tags") |> LazyHTML.attribute("data-value") == [~s(["a","b"])]
    assert html |> find("#trip_day") |> LazyHTML.attribute("data-value") == [~s(["2026-10-23"])]
    assert html |> find("#trip_body") |> LazyHTML.attribute("data-value") == ["<p>Hi</p>"]
  end

  test "a value set by the server reaches the components", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, PickersLive)
    html = view |> element("#server-set") |> render_click()
    assert html |> find("#trip_state") |> LazyHTML.attribute("data-value") == [~s(["AK"])]
    assert html |> find("#trip_day") |> LazyHTML.attribute("data-value") == [~s(["2026-01-02"])]
  end

  test "on_search pushes the query and the server answers with new options", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, PickersLive)
    assert html |> find("#authors .option") |> Enum.count() == 2

    html =
      view |> element("#authors") |> render_hook("search", %{"id" => "authors", "query" => "emi"})

    assert html |> find("#authors .option") |> LazyHTML.attribute("data-label") == [
             "Emilie Watson"
           ]

    assert html |> find("#last") |> LazyHTML.text() =~ ~s({:search, "emi"})
  end

  test "on_change of the time picker and the editor reach the LiveView", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, PickersLive)

    view
    |> element("#trip_at")
    |> render_hook("time_changed", %{"id" => "trip_at", "value" => "09:30"})

    assert view |> element("#last") |> render() =~ "09:30"

    view
    |> element("#trip_body")
    |> render_hook("body_changed", %{"id" => "trip_body", "value" => "<b>x</b>"})

    assert view |> element("#last") |> render() =~ "body_changed"
  end
end
