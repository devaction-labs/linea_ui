defmodule LineaUI.Components.TableTest do
  use LineaUI.ComponentCase, async: true

  @rows [%{id: 1, name: "Cy"}, %{id: 2, name: "Hart"}]

  defp render_table(assigns) do
    assigns =
      Map.merge(%{__changed__: nil, rows: @rows, variant: "basic", rounded: "row"}, assigns)

    rendered_to_string(~H"""
    <.table id="t" rows={@rows} variant={@variant} rounded={@rounded}>
      <:col :let={row} label="Name">{row.name}</:col>
      <:col :let={row} label="Id">{row.id}</:col>
    </.table>
    """)
  end

  test "renders a column per slot and a row per item" do
    html = render_table(%{})

    assert ["Name", "Id"] =
             html |> find("th") |> Enum.map(&LazyHTML.text/1) |> Enum.map(&String.trim/1)

    assert 2 = html |> find("tbody tr") |> Enum.count()
    assert "w-full" in classes(html, "table")
    assert "border-b-slate-200" in classes(html, "thead tr")
    assert "px-3" in classes(html, "th")
  end

  test "bordered draws cell borders inside a bordered wrapper" do
    html = render_table(%{variant: "bordered"})
    assert "rounded-lg" in classes(html, "div")
    assert "first:border-l-0" in classes(html, "td")
    assert "[&:last-child>td]:border-b-0" in classes(html, "tbody tr")
  end

  test "hoverable and zebra fill the header and mark the table" do
    html = render_table(%{variant: "hoverable"})
    assert "is-hoverable" in classes(html, "table")
    assert "bg-slate-200" in classes(html, "th")
    assert "first:rounded-l-lg" in classes(html, "th")

    html = render_table(%{variant: "zebra", rounded: "none"})
    assert "is-zebra" in classes(html, "table")
    refute "first:rounded-l-lg" in classes(html, "th")

    html = render_table(%{variant: "hoverable", rounded: "top"})
    assert "first:rounded-tl-lg" in classes(html, "th")
  end

  test "grid variant uses the gridjs look" do
    html = render_table(%{variant: "grid"})
    assert "lg:px-4" in classes(html, "th")
    assert "is-hoverable" in classes(html, "table")
  end

  test "hoverable overrides the variant" do
    html =
      render(~H"""
      <.table id="t" rows={[%{a: 1}]} hoverable>
        <:col :let={row}>{row.a}</:col>
      </.table>
      """)

    assert "is-hoverable" in classes(html, "table")
  end

  test "sortable headers send the column and the next direction" do
    html =
      render(~H"""
      <.table id="t" rows={[%{a: 1}]} on_sort="sort" sort_by="a" sort_dir="asc" target="#c">
        <:col :let={row} label="A" sort_key="a">{row.a}</:col>
        <:col :let={row} label="B" sort_key="b">{row.a}</:col>
      </.table>
      """)

    assert ["ascending", "none"] = html |> find("th") |> LazyHTML.attribute("aria-sort")

    assert ["desc", "asc"] =
             html |> find("th button") |> LazyHTML.attribute("phx-value-direction")

    assert ["a", "b"] = html |> find("th button") |> LazyHTML.attribute("phx-value-column")
    assert ["#c", "#c"] = html |> find("th button") |> LazyHTML.attribute("phx-target")
    assert ["asc", "none"] = html |> find(".table-sort-icon") |> LazyHTML.attribute("data-sort")
  end

  test "selection adds checkboxes with their keys" do
    html =
      render(~H"""
      <.table
        id="t"
        rows={[%{id: "1"}, %{id: "2"}]}
        row_key={& &1.id}
        selected={["1"]}
        on_select="select"
        on_select_all="all"
      >
        <:col :let={row}>{row.id}</:col>
      </.table>
      """)

    assert [_, _] = html |> find("tbody input[type=checkbox]") |> Enum.to_list()
    assert ["1", "2"] = html |> find("tbody input") |> LazyHTML.attribute("phx-value-id")

    assert ["false", "true"] =
             html |> find("tbody input") |> LazyHTML.attribute("phx-value-selected")

    assert [_] = html |> find("tbody input[checked]") |> Enum.to_list()

    assert ["LineaUI.TableSelectAll"] =
             html |> find("thead input") |> LazyHTML.attribute("phx-hook")

    assert ["true"] = html |> find("thead input") |> LazyHTML.attribute("data-indeterminate")
    assert ["true"] = html |> find("thead input") |> LazyHTML.attribute("phx-value-selected")
  end

  test "expandable rows render a detail panel and a toggle" do
    html =
      render(~H"""
      <.table id="t" rows={[%{id: 1}]} expand_label="More">
        <:col :let={row}>{row.id}</:col>
        <:expand :let={detail}>Detail {detail.row.id}</:expand>
      </.table>
      """)

    assert [_] = html |> find("tbody#t-row-0") |> Enum.to_list()

    assert ["t-row-0-detail"] =
             html |> find("button[aria-controls]") |> LazyHTML.attribute("aria-controls")

    assert "hidden" in classes(html, "#t-row-0-detail")
    assert html |> find("#t-row-0-detail") |> LazyHTML.text() =~ "Detail 1"
    assert html |> find("thead th:last-child") |> LazyHTML.text() =~ "More"
  end

  test "empty slot shows when there are no rows" do
    html =
      render(~H"""
      <.table id="t" rows={[]}>
        <:col :let={row}>{row}</:col>
        <:empty>Nothing here</:empty>
      </.table>
      """)

    assert html |> find("#t-empty") |> LazyHTML.text() =~ "Nothing here"
  end

  test "action slot and row_click" do
    html =
      render(~H"""
      <.table
        id="t"
        rows={[%{id: 1}]}
        row_click={fn row -> Phoenix.LiveView.JS.push("open", value: %{id: row.id}) end}
      >
        <:col :let={row}>{row.id}</:col>
        <:action>Edit</:action>
      </.table>
      """)

    assert [_, _] = html |> find("tbody td") |> Enum.to_list()
    assert [_] = html |> find("td[phx-click]") |> Enum.to_list()
    assert "cursor-pointer" in classes(html, "td")
  end
end
