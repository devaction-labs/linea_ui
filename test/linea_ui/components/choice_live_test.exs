defmodule LineaUI.Components.ChoiceLiveTest do
  use LineaUI.LiveCase, async: true

  alias LineaUI.Test.ChoiceLive

  test "chips, cards, picked tags and a two-field range reach phx-change", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, ChoiceLive)

    assert [_] =
             html
             |> find(~s(input[type=radio][name="filter[status]"][value=all][checked]))
             |> Enum.to_list()

    assert [_] =
             html |> find(~s(input[type=hidden][name="filter[from]"][value=""])) |> Enum.to_list()

    assert [_] = html |> find(~s(input[type=hidden][name="filter[to]"])) |> Enum.to_list()

    view
    |> element("#filter")
    |> render_change(%{
      "filter" => %{
        "status" => "draft",
        "channels" => ["", "email"],
        "tag_ids" => ["", "t3", "t1"],
        "from" => "2026-10-01",
        "to" => "2026-10-31"
      }
    })

    html = render(view)

    assert [_] =
             html
             |> find(~s(input[name="filter[status]"][value=draft][checked]))
             |> Enum.to_list()

    assert [_] =
             html
             |> find(~s(input[name="filter[channels][]"][value=email][checked]))
             |> Enum.to_list()

    assert html |> find("#filter_tag_ids") |> LazyHTML.attribute("data-value") == [
             ~s(["t3","t1"])
           ]

    assert html |> find("#filter_from_range") |> LazyHTML.attribute("data-value") == [
             ~s(["2026-10-01","2026-10-31"])
           ]
  end

  test "the tag search goes to the server, and the chosen label survives the new options", %{
    conn: conn
  } do
    {:ok, view, html} = live_isolated(conn, ChoiceLive)
    assert html |> find("#filter_tag_ids [data-ts-item]") |> LazyHTML.text() =~ "Retail"

    html =
      view
      |> element("#filter_tag_ids")
      |> render_hook("search_tags", %{"id" => "filter_tag_ids", "query" => "urg"})

    assert html |> find("#filter_tag_ids .option") |> LazyHTML.attribute("data-label") == [
             "Urgent"
           ]

    assert html |> find("#filter_tag_ids template[data-value=t3]") |> Enum.count() == 1
    assert html |> find("#last") |> LazyHTML.text() =~ ~s({:search, "urg"})
  end
end
