defmodule LineaUI.Components.TableComposableTest do
  use LineaUI.ComponentCase, async: true

  alias Phoenix.LiveView.JS

  test "a table without rows renders its inner block with the look as data attributes" do
    html =
      render(~H"""
      <.table id="t" variant="hoverable" rounded="top" compact sticky_header class="min-w-[760px]">
        <.table_head>
          <:col>Number</:col>
          <:col label="Total" align="right" class="w-32" />
        </.table_head>
        <.table_body id="t-body">
          <.table_row id="r1" class="font-medium" phx-value-id="1" data-kind="order">
            <:cell>A-1</:cell>
            <:cell align="right" colspan="2">10</:cell>
          </.table_row>
        </.table_body>
      </.table>
      """)

    assert "linea-table" in classes(html, "table")
    assert "is-hoverable" in classes(html, "table")
    assert "min-w-[760px]" in classes(html, "table")
    assert "overflow-x-auto" in classes(html, "div")
    assert ["hoverable"] = html |> find("table") |> LazyHTML.attribute("data-variant")
    assert ["top"] = html |> find("table") |> LazyHTML.attribute("data-rounded")
    assert [_] = html |> find("table[data-compact][data-sticky]") |> Enum.to_list()

    assert ["Number", "Total"] =
             html |> find("th") |> Enum.map(&String.trim(LazyHTML.text(&1)))

    assert "text-right" in classes(html, "th:last-child")
    assert "w-32" in classes(html, "th:last-child")
    assert ["t-body"] = html |> find("tbody") |> LazyHTML.attribute("id")
    assert ["1"] = html |> find("tr#r1") |> LazyHTML.attribute("phx-value-id")
    assert ["order"] = html |> find("tr#r1") |> LazyHTML.attribute("data-kind")
    assert "font-medium" in classes(html, "tr#r1")
    assert ["2"] = html |> find("#r1 td:last-child") |> LazyHTML.attribute("colspan")
    assert "text-right" in classes(html, "#r1 td:last-child")
  end

  test "a stream body passes phx-update and the row ids through" do
    html =
      render(~H"""
      <.table id="t">
        <.table_body id="t-body" phx-update="stream">
          <.table_row :for={{id, row} <- [{"rows-1", %{n: 1}}]} id={id}>
            <:cell>{row.n}</:cell>
          </.table_row>
          <.table_empty id="t-empty">Nothing here.</.table_empty>
        </.table_body>
      </.table>
      """)

    assert ["stream"] = html |> find("tbody") |> LazyHTML.attribute("phx-update")
    assert [_] = html |> find("tr#rows-1") |> Enum.to_list()
    assert ["100"] = html |> find("#t-empty td") |> LazyHTML.attribute("colspan")
    assert "only:table-row" in classes(html, "#t-empty")
    assert "hidden" in classes(html, "#t-empty")
    assert html =~ "Nothing here."
  end

  test "row clicks put phx-click and the pointer on the row" do
    html =
      render(~H"""
      <.table id="t">
        <.table_body>
          <.table_row id="r" on_click="open" target="#c" phx-value-id="7">
            <:cell>x</:cell>
          </.table_row>
          <.table_row id="j" on_click={JS.navigate("/x")}>
            <:cell>y</:cell>
          </.table_row>
        </.table_body>
      </.table>
      """)

    assert ["open"] = html |> find("tr#r") |> LazyHTML.attribute("phx-click")
    assert ["#c"] = html |> find("tr#r") |> LazyHTML.attribute("phx-target")
    assert "cursor-pointer" in classes(html, "tr#r")
    assert [js] = html |> find("tr#j") |> LazyHTML.attribute("phx-click")
    assert js =~ "navigate"
  end

  test "selection adds checkbox cells, marks the row and draws the indeterminate header" do
    html =
      render(~H"""
      <.table id="t">
        <.table_head on_select_all="select_all" some_selected select_all_id="all">
          <:col>Name</:col>
        </.table_head>
        <.table_body>
          <.table_row id="a" selected on_select="select" select_value="1">
            <:cell>A</:cell>
          </.table_row>
          <.table_row id="b" selected={false} on_select="select" select_value="2">
            <:cell>B</:cell>
          </.table_row>
        </.table_body>
      </.table>
      """)

    assert ["LineaUI.TableSelectAll"] = html |> find("#all") |> LazyHTML.attribute("phx-hook")
    assert ["true"] = html |> find("#all") |> LazyHTML.attribute("data-indeterminate")
    assert ["true"] = html |> find("#all") |> LazyHTML.attribute("phx-value-selected")
    assert ["select_all"] = html |> find("#all") |> LazyHTML.attribute("phx-click")

    assert ["true"] = html |> find("tr#a") |> LazyHTML.attribute("data-selected")
    assert ["false"] = html |> find("tr#b") |> LazyHTML.attribute("data-selected")
    assert [_] = html |> find("#a input[checked]") |> Enum.to_list()
    assert [] = html |> find("#b input[checked]") |> Enum.to_list()
    assert ["1"] = html |> find("#a input") |> LazyHTML.attribute("phx-value-id")
    assert ["false"] = html |> find("#a input") |> LazyHTML.attribute("phx-value-selected")
    assert ["true"] = html |> find("#b input") |> LazyHTML.attribute("phx-value-selected")
  end

  test "a row without selected stays unmarked" do
    html = render(~H'<table>
  <tbody>
    <.table_row id="r">
      <:cell>x</:cell>
    </.table_row>
  </tbody>
</table>')
    assert [] = html |> find("tr[data-selected]") |> Enum.to_list()
  end

  test "sortable headers carry aria-sort and the next direction" do
    html =
      render(~H"""
      <.table id="t">
        <.table_head on_sort="sort" sort_by="name" sort_dir="asc" target="#c">
          <:col sort_key="name">Name</:col>
          <:col sort_key="total">Total</:col>
          <:col>Plain</:col>
        </.table_head>
      </.table>
      """)

    assert ["ascending", "none"] =
             html |> find("th[aria-sort]") |> LazyHTML.attribute("aria-sort")

    assert ["desc", "asc"] =
             html |> find("th button") |> LazyHTML.attribute("phx-value-direction")

    assert ["name", "total"] = html |> find("th button") |> LazyHTML.attribute("phx-value-column")
    assert ["#c", "#c"] = html |> find("th button") |> LazyHTML.attribute("phx-target")
    assert ["asc", "none"] = html |> find(".table-sort-icon") |> LazyHTML.attribute("data-sort")
    assert "Plain" = html |> find("th:last-child") |> LazyHTML.text() |> String.trim()
  end

  test "cells, the totals footer and free rows" do
    html =
      render(~H"""
      <.table id="t">
        <.table_body>
          <tr id="free">
            <.table_cell header>Row</.table_cell>
            <.table_cell colspan="2" rowspan="1" align="center" class="w-4">x</.table_cell>
          </tr>
        </.table_body>
        <.table_foot class="bg-slate-50">
          <:cell colspan="2">Total</:cell>
          <:cell align="right">R$ 10,00</:cell>
          <tr id="extra">
            <td>more</td>
          </tr>
        </.table_foot>
      </.table>
      """)

    assert ["row"] = html |> find("#free th") |> LazyHTML.attribute("scope")
    assert ["2"] = html |> find("#free td") |> LazyHTML.attribute("colspan")
    assert "text-center" in classes(html, "#free td")
    assert "bg-slate-50" in classes(html, "tfoot tr")

    assert ["2"] =
             html |> find("tfoot tr:first-child td:first-child") |> LazyHTML.attribute("colspan")

    assert "text-right" in classes(html, "tfoot tr:first-child td:last-child")
    assert [_] = html |> find("tfoot #extra") |> Enum.to_list()
  end

  test "an empty foot renders no row" do
    html = render(~H'<table>
  <.table_foot>
    <tr id="x">
      <td>1</td>
    </tr>
  </.table_foot>
</table>')
    assert 1 = html |> find("tfoot tr") |> Enum.count()
  end

  test "expandable rows pair a toggle with a hidden detail row" do
    html =
      render(~H"""
      <.table id="t">
        <.table_body>
          <.table_row id="o1">
            <:cell>A</:cell>
            <:cell><.table_expand_toggle row_id="o1" /></:cell>
          </.table_row>
          <.table_detail_row row_id="o1" class="bg-slate-50">Notes</.table_detail_row>
          <.table_row id="o2">
            <:cell><.table_expand_toggle row_id="o2" open /></:cell>
          </.table_row>
          <.table_detail_row row_id="o2" open>Open</.table_detail_row>
        </.table_body>
      </.table>
      """)

    assert ["o1-detail"] = html |> find("#o1 button") |> LazyHTML.attribute("aria-controls")
    assert ["false"] = html |> find("#o1 button") |> LazyHTML.attribute("aria-expanded")
    assert [toggle] = html |> find("#o1 button") |> LazyHTML.attribute("phx-click")
    assert toggle =~ "#o1-detail"
    assert ["100"] = html |> find("#o1-detail-row td") |> LazyHTML.attribute("colspan")
    assert "hidden" in classes(html, "#o1-detail")
    assert "bg-slate-50" in classes(html, "#o1-detail")
    refute "hidden" in classes(html, "#o2-detail")
    assert ["true"] = html |> find("#o2 button") |> LazyHTML.attribute("aria-expanded")
    assert "rotate-180" in classes(html, "#o2 svg")
  end

  test "table_checkbox sends its values and only hooks when it has an id" do
    html =
      render(~H"""
      <.table_checkbox label="Pick" checked on_click="pick" values={%{"id" => 3}} class="ml-1" />
      """)

    assert ["Pick"] = html |> find("input") |> LazyHTML.attribute("aria-label")
    assert ["3"] = html |> find("input") |> LazyHTML.attribute("phx-value-id")
    assert [] = html |> find("input[phx-hook]") |> Enum.to_list()
    assert [_] = html |> find("input[checked]") |> Enum.to_list()
    assert "ml-1" in classes(html, "input")
  end

  test "table_skeleton shapes: a disc with a bar, a pill and a number at the right" do
    html =
      render(~H"""
      <.table_skeleton
        id="s"
        variant="data"
        rows={2}
        columns={["Order", "Client", "Status", "Total"]}
        shapes={["text", "avatar", "pill", "number"]}
      />
      """)

    assert 2 = html |> find("tbody td:nth-child(2) .rounded-full") |> Enum.count()
    assert 2 = html |> find("tbody td:nth-child(3) .w-\\[70px\\]") |> Enum.count()
    assert 2 = html |> find("tbody td:nth-child(4) .ml-auto") |> Enum.count()
    assert "text-right" in classes(html, "th:nth-child(4)")
    assert "linea-dt" in classes(html, "table")
  end

  test "table_skeleton draws placeholder rows in the table look" do
    html =
      render(~H"""
      <.table_skeleton id="s" columns={["Number", "Total"]} rows={3} variant="hoverable" compact />
      """)

    assert ["true"] = html |> find("table") |> LazyHTML.attribute("aria-busy")
    assert ["Loading"] = html |> find("table") |> LazyHTML.attribute("aria-label")
    assert ["hoverable"] = html |> find("table") |> LazyHTML.attribute("data-variant")
    assert ["Number", "Total"] = html |> find("th") |> Enum.map(&String.trim(LazyHTML.text(&1)))
    assert 3 = html |> find("tbody tr") |> Enum.count()
    assert 6 = html |> find("tbody td .skeleton") |> Enum.count()

    html = render(~H'<.table_skeleton id="s" cols={3} rows={1} />')
    assert 3 = html |> find("th .skeleton") |> Enum.count()

    html = render(~H'<.table_skeleton id="s" headless rows={2} />')
    assert [] = html |> find("thead") |> Enum.to_list()
  end

  test "table_head :col, table_row :cell and table_foot :cell forward the attributes they do not use" do
    html =
      render(~H"""
      <.table id="t">
        <.table_head on_sort="sort" sort_by="number">
          <:col sort_key="number" data-col="number" id="th-number">Number</:col>
          <:col label="Total" align="right" data-col="total" title="Order total" />
        </.table_head>
        <.table_body id="t-body">
          <.table_row id="r1">
            <:cell data-field="number" id="r1-number" phx-click="open">A-1</:cell>
            <:cell align="right" colspan="2" aria-label="Total">10</:cell>
          </.table_row>
        </.table_body>
        <.table_foot>
          <:cell colspan="2" data-field="label">Total</:cell>
        </.table_foot>
      </.table>
      """)

    assert [_] =
             find(html, "th#th-number[data-col=number][aria-sort=ascending]") |> Enum.to_list()

    assert [_] =
             find(html, "th.text-right[data-col=total][title='Order total']") |> Enum.to_list()

    assert [_] = find(html, "td#r1-number[data-field=number][phx-click=open]") |> Enum.to_list()
    assert [_] = find(html, "td.text-right[colspan='2'][aria-label=Total]") |> Enum.to_list()
    assert [_] = find(html, "tfoot td[colspan='2'][data-field=label]") |> Enum.to_list()
    refute html =~ "sort_key"
    refute html =~ "inner_block"
    refute html =~ ~s(align=)
  end

  test "table_skeleton forwards its attributes to the table" do
    html = render(~H|<.table_skeleton id="loading" data-role="orders-loading" phx-mounted="x" />|)

    assert [_] =
             find(html, "table#loading[data-role=orders-loading][phx-mounted=x][aria-busy=true]")
             |> Enum.to_list()
  end
end
