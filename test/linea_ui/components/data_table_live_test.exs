defmodule LineaUI.Components.DataTableLiveTest do
  use LineaUI.LiveCase, async: true

  alias LineaUI.Test.DataTableLive

  test "search sends the query and the LiveView filters", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, DataTableLive)

    html = view |> element("#people form") |> render_change(%{"search" => "Name 1"})

    assert html =~ ~s(&quot;search&quot;, %{&quot;search&quot; =&gt; &quot;Name 1&quot;})
    assert html =~ "Name 10"
    refute html =~ "Name 2<"
    assert html =~ "of <b>4</b> results"
  end

  test "sorting sends the column and the next direction", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, DataTableLive)

    view |> element("#people th button") |> render_click()
    html = view |> element("#people th button") |> render_click()

    assert html =~
             ~s(%{&quot;column&quot; =&gt; &quot;name&quot;, &quot;direction&quot; =&gt; &quot;asc&quot;})

    assert html =~
             ~s(%{&quot;column&quot; =&gt; &quot;name&quot;, &quot;direction&quot; =&gt; &quot;desc&quot;})

    assert [_] = html |> find("#people th[aria-sort=descending]") |> Enum.to_list()

    assert ["Name 9"] =
             html
             |> find("#people tbody td:last-child")
             |> Enum.take(1)
             |> Enum.map(&String.trim(LazyHTML.text(&1)))
  end

  test "pagination moves to the page and disables the edges", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, DataTableLive)

    assert [_] = html |> find("#people button[aria-label=Previous][disabled]") |> Enum.to_list()

    html = view |> element("#people button[aria-label='Page 3']") |> render_click()

    assert html =~ ~s(%{&quot;page&quot; =&gt; &quot;3&quot;})
    assert html =~ "Showing <b>11</b> to <b>12</b> of <b>12</b> results"
    assert [_] = html |> find("#people button[aria-label=Next][disabled]") |> Enum.to_list()

    assert ["page"] =
             html
             |> find("#people button[aria-label='Page 3']")
             |> LazyHTML.attribute("aria-current")
  end

  test "selection toggles rows and the header checkbox", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, DataTableLive)

    html = view |> element("#people tbody tr:first-child input") |> render_click()

    assert html =~
             ~s(%{&quot;id&quot; =&gt; &quot;1&quot;, &quot;selected&quot; =&gt; &quot;true&quot;})

    assert ["true"] =
             html |> find("#people-table-select-all") |> LazyHTML.attribute("data-indeterminate")

    html = view |> element("#people-table-select-all") |> render_click()
    assert [_, _, _, _, _] = html |> find("#people tbody input[checked]") |> Enum.to_list()

    assert ["false"] =
             html |> find("#people-table-select-all") |> LazyHTML.attribute("data-indeterminate")

    html = view |> element("#people-table-select-all") |> render_click()
    assert [] = html |> find("#people tbody input[checked]") |> Enum.to_list()
  end

  test "a table renders a stream and takes inserts", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, DataTableLive)

    assert ["stream"] = html |> find("#streamed tbody") |> LazyHTML.attribute("phx-update")
    assert [_, _, _] = html |> find("#streamed tbody tr") |> Enum.to_list()

    html = view |> element("#add") |> render_click()
    assert [_] = html |> find("#streamed tbody tr#people-99") |> Enum.to_list()
  end
end
