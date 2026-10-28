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

  test "bleed runs the table edge to edge of the card and gives the padding back to the edge cells" do
    html =
      render(~H"""
      <.table id="t" rows={[%{n: 1}]} variant="bordered" bleed>
        <:col :let={row} label="N">{row.n}</:col>
      </.table>
      """)

    wrapper = classes(html, "div")
    assert "mx-[calc(var(--card-bleed-x,1rem)*-1)]" in wrapper
    assert "min-w-[calc(100%+var(--card-bleed-x,1rem)*2)]" in wrapper
    assert "[&_tr>:first-child]:pl-[var(--card-bleed-x,1rem)]" in wrapper
    assert "[&_tr>:last-child]:pr-[var(--card-bleed-x,1rem)]" in wrapper
    assert "first:mt-[calc(var(--card-bleed-t,0px)*-1)]" in wrapper
    assert "last:mb-[calc(var(--card-bleed-b,0px)*-1)]" in wrapper
    assert "first:rounded-t-[var(--card-bleed-rt,0px)]" in wrapper
    assert "rounded-none" in wrapper
    refute "rounded-lg" in wrapper
    refute "min-w-full" in wrapper
  end

  test "bleed also applies to a hand-written table" do
    html =
      render(~H"""
      <.table id="t" bleed>
        <.table_body id="b">
          <.table_row>
            <:cell>x</:cell>
          </.table_row>
        </.table_body>
      </.table>
      """)

    assert "mx-[calc(var(--card-bleed-x,1rem)*-1)]" in classes(html, "div")
  end

  test "without bleed the wrapper is untouched" do
    html = render_table(%{})
    assert "min-w-full" in classes(html, "div")
    refute "mx-[calc(var(--card-bleed-x,1rem)*-1)]" in classes(html, "div")
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

  test "labels name the scroll region, the sort buttons and each row's checkbox" do
    html =
      render(~H"""
      <.table
        id="t"
        rows={[%{id: "1", n: "#1"}, %{id: "2", n: "#2"}]}
        row_key={& &1.id}
        on_select="select"
        on_sort="sort"
        scroll_label="Orders list"
        sort_label="Sort by"
        row_label={&"Select order #{&1.n}"}
      >
        <:col :let={row} label="Order" sort_key="n">{row.n}</:col>
      </.table>
      """)

    assert ["region"] = html |> find("div[aria-label]") |> LazyHTML.attribute("role")
    assert ["0"] = html |> find("div[aria-label]") |> LazyHTML.attribute("tabindex")
    assert ["Sort by Order"] = html |> find("th button") |> LazyHTML.attribute("aria-label")

    assert ["Select order #1", "Select order #2"] =
             html |> find("tbody input") |> LazyHTML.attribute("aria-label")

    plain =
      render(~H"""
      <.table id="t" rows={[%{id: "1"}]} row_key={& &1.id} on_select="select">
        <:col :let={row}>{row.id}</:col>
      </.table>
      """)

    assert [] = plain |> find("div[tabindex]") |> Enum.to_list()
    assert ["Select row"] = plain |> find("tbody input") |> LazyHTML.attribute("aria-label")
  end

  test "a sort header is a pill with the arrow next to the label, and can be named" do
    html =
      render(~H"""
      <.table id="t" rows={[%{a: 1}]} on_sort="sort" sort_label="Sort by %{label}">
        <:col :let={row} label="A" sort_key="a">{row.a}</:col>
      </.table>
      <table>
        <.table_head on_sort="sort" sort_label="Sort by %{label}">
          <:col label="B" sort_key="b" />
        </.table_head>
      </table>
      """)

    assert ["Sort by A", "Sort by B"] =
             html |> find("th button") |> LazyHTML.attribute("aria-label")

    assert "h-7" in classes(html, "th button")
    assert "inline-flex" in classes(html, "th button")
    assert "hover:bg-slate-300/40" in classes(html, "th button")
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

  test "compact tightens the cells" do
    html =
      render(~H"""
      <.table id="t" rows={[1]} compact>
        <:col :let={row} label="N">{row}</:col>
      </.table>
      """)

    assert ["px-3", "py-2", "lg:px-3"] -- classes(html, "td") == []
    assert ["px-3", "py-2", "lg:px-3"] -- classes(html, "th") == []
    refute "py-3" in classes(html, "td")
  end

  test "headless renders no thead" do
    html =
      render(~H"""
      <.table id="t" rows={[1]} headless>
        <:col :let={row} label="N">{row}</:col>
      </.table>
      """)

    assert [] = find(html, "thead") |> Enum.to_list()
    assert [_] = find(html, "tbody td") |> Enum.to_list()
  end

  test "borderless drops the row rules and the cell borders" do
    html =
      render(~H"""
      <.table id="a" rows={[1]} borderless>
        <:col :let={row}>{row}</:col>
      </.table>
      <.table id="b" rows={[1]} variant="bordered" borderless>
        <:col :let={row}>{row}</:col>
      </.table>
      <.table id="c" rows={[1]}>
        <:col :let={row}>{row}</:col>
      </.table>
      """)

    assert "border-0" in classes(html, "#a tbody tr")
    assert "border-0" in classes(html, "#b td")
    refute "border-0" in classes(html, "#c tbody tr")
  end

  test "col align aligns header and cells" do
    html =
      render(~H"""
      <.table id="t" rows={[1]}>
        <:col :let={row} label="A" align="right">{row}</:col>
        <:col :let={row} label="B" align="center">{row}</:col>
        <:col :let={row} label="C">{row}</:col>
      </.table>
      """)

    assert "text-right" in classes(html, "th:nth-child(1)")
    assert "text-right" in classes(html, "td:nth-child(1)")
    assert "text-center" in classes(html, "td:nth-child(2)")
    refute Enum.any?(classes(html, "td:nth-child(3)"), &String.starts_with?(&1, "text-"))
  end

  test "row_class and row_attrs reach each row's tr" do
    html =
      render(~H"""
      <.table
        id="t"
        rows={[%{id: 1, late: true}, %{id: 2, late: false}]}
        row_id={&"r-#{&1.id}"}
        row_class={&(&1.late && "text-error")}
        row_attrs={&%{"phx-click" => "open", "phx-value-id" => &1.id}}
      >
        <:col :let={row}>{row.id}</:col>
      </.table>
      """)

    assert "text-error" in classes(html, "#r-1")
    refute "text-error" in classes(html, "#r-2")
    assert ["open", "open"] = html |> find("tbody tr") |> LazyHTML.attribute("phx-click")
    assert ["1", "2"] = html |> find("tbody tr") |> LazyHTML.attribute("phx-value-id")
  end

  test "the foot slot renders a totals row" do
    html =
      render(~H"""
      <.table id="t" rows={[%{n: 1}]}>
        <:col :let={row}>{row.n}</:col>
        <:col :let={row}>{row.n}</:col>
        <:foot>Total</:foot>
        <:foot align="right" class="text-primary" colspan="1">R$ 1</:foot>
      </.table>
      """)

    assert ["Total", "R$ 1"] =
             html |> find("tfoot td") |> Enum.map(&String.trim(LazyHTML.text(&1)))

    assert "font-semibold" in classes(html, "tfoot td")
    assert "text-right" in classes(html, "tfoot td:last-child")
    assert "text-primary" in classes(html, "tfoot td:last-child")

    html = render(~H|<.table id="t" rows={[]}>
  <:col>x</:col>
</.table>|)
    assert [] = html |> find("tfoot") |> Enum.to_list()
  end

  test "the foot slot also closes an expandable table" do
    html =
      render(~H"""
      <.table id="t" rows={[%{n: 1}]} row_class={fn _ -> "italic" end}>
        <:col :let={row}>{row.n}</:col>
        <:expand :let={%{row: row}}>{row.n}</:expand>
        <:foot>Sum</:foot>
      </.table>
      """)

    assert "Sum" = html |> find("tfoot td") |> LazyHTML.text() |> String.trim()
    assert "italic" in classes(html, "tbody tr:first-child")
  end

  test "sticky_header pins the header cells" do
    html = render(~H|<.table id="t" rows={[]} sticky_header><:col label="A" /></.table>|)
    assert "sticky" in classes(html, "th")
    assert "bg-white" in classes(html, "th")

    html =
      render(
        ~H|<.table id="t" rows={[]} sticky_header variant="zebra"><:col label="A" /></.table>|
      )

    assert "sticky" in classes(html, "th")
    assert "bg-slate-200" in classes(html, "th")
  end

  test "a stream renders the empty row hidden until the body is empty" do
    assigns = %{
      __changed__: nil,
      stream: Phoenix.LiveView.LiveStream.new(:people, make_ref(), [], [])
    }

    html =
      rendered_to_string(~H"""
      <.table id="t" rows={@stream}>
        <:col :let={{_id, row}}>{row.name}</:col>
        <:empty>None</:empty>
      </.table>
      """)

    assert "only:table-row" in classes(html, "#t-empty")
    assert "hidden" in classes(html, "#t-empty")
  end
end
