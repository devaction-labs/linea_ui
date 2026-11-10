defmodule LineaUI.Components.DataTableTest do
  use LineaUI.ComponentCase, async: true

  test "the footer follows the pager events and footer={false} removes it" do
    html =
      render(~H"""
      <.data_table id="a" rows={[%{n: 1}]} on_page="page" on_search="search">
        <:col :let={row} label="N">{row.n}</:col>
      </.data_table>
      <.data_table id="b" rows={[%{n: 1}]} on_page="page" on_search="search" footer={false}>
        <:col :let={row} label="N">{row.n}</:col>
      </.data_table>
      <.data_table id="c" variant="grid" rows={[%{n: 1}]} on_page="page" footer={false}>
        <:col :let={row} label="N">{row.n}</:col>
      </.data_table>
      """)

    assert [_] = find(html, "#a ol.pagination") |> Enum.to_list()
    assert [] = find(html, "#b ol.pagination") |> Enum.to_list()
    assert [_] = find(html, "#b form#b-search-form") |> Enum.to_list()
    assert [] = find(html, "#c [role=status]") |> Enum.to_list()
  end

  test "advanced and grid draw the lean data look" do
    html =
      render(~H"""
      <.data_table
        id="a"
        rows={[%{n: 1}]}
        row_id={&"r#{&1.n}"}
        on_select="select"
        selected={[]}
        on_page="page"
      >
        <:col :let={row} label="N" sort_key="n">{row.n}</:col>
      </.data_table>
      <.data_table id="g" variant="grid" rows={[%{n: 1}]} compact sticky_header wrapper_class="max-h-60">
        <:col :let={row} label="N">{row.n}</:col>
      </.data_table>
      """)

    assert "linea-dt" in classes(html, "#a-table")
    assert "is-dt-hover" in classes(html, "#a-table")
    assert "h-10" in classes(html, "#a-table th")
    assert "text-[13px]" in classes(html, "#a-table th")
    assert "h-12" in classes(html, "#a-table td")
    assert "size-4" in classes(html, "#a-table td input")
    assert "flush" in classes(html, "#a .sg-card")

    assert "linea-dt" in classes(html, "#g-table")
    assert "rounded-[10px]" in classes(html, "#g > div")
    assert "max-h-60" in classes(html, "#g > div")
    assert "h-[34px]" in classes(html, "#g-table th")
    assert "h-[38px]" in classes(html, "#g-table td")
    assert "sticky" in classes(html, "#g-table th")
    assert "border-slate-150" in classes(html, "#g-table td")
  end

  test "density options reach the table" do
    html =
      render(~H"""
      <.data_table id="a" rows={[%{n: 1}]} compact headless borderless>
        <:col :let={row} label="N" align="right">{row.n}</:col>
      </.data_table>
      """)

    assert [] = find(html, "thead") |> Enum.to_list()
    assert "h-[38px]" in classes(html, "td")
    assert "text-right" in classes(html, "td")
    assert "border-0" in classes(html, "tbody tr")
  end

  test "table_search works on its own" do
    html =
      render(~H"""
      <.table_search id="users" value="" on_search="search" placeholder="Find" />
      <.table_search id="open" value="ann" on_search="search" target="#c" />
      """)

    assert [_] =
             find(html, "form#users-search-form[phx-change=search][phx-submit=search]")
             |> Enum.to_list()

    assert [_] = find(html, "input#users-search[name=search][placeholder=Find]") |> Enum.to_list()
    assert "w-0" in classes(html, "#users-search")
    assert "w-32" in classes(html, "#open-search")
    assert [_] = find(html, "#open-search-form[phx-target='#c']") |> Enum.to_list()

    assert [_] =
             find(html, "#users-search-form button[aria-controls=users-search]") |> Enum.to_list()
  end

  test "the labels of the pagers, summaries and checkboxes can be set" do
    html =
      render(~H"""
      <.data_table
        id="g"
        variant="grid"
        rows={[%{n: 1}]}
        total={25}
        page={2}
        on_page="page"
        on_select="select"
        on_select_all="all"
        on_sort="sort"
        row_key={& &1.n}
        page_label="Página %{page}"
        summary_label="De %{from} a %{to} (%{total} <resultados>)"
        select_all_label="Selecionar todos"
        select_label="Selecionar linha"
        sort_label="Ordenar por %{label}"
      >
        <:col :let={row} label="N" sort_key="n">{row.n}</:col>
      </.data_table>
      <.data_table
        id="a"
        rows={[%{n: 1}]}
        total={25}
        page={2}
        on_page="page"
        summary_label="%{from}-%{to}/%{total}"
      >
        <:col :let={row} label="N">{row.n}</:col>
      </.data_table>
      """)

    assert find(html, "#g button[aria-label='Página 2'][aria-current=page]") |> Enum.count() == 1
    assert html =~ "De <b>11</b> a <b>20</b> (<b>25</b> &lt;resultados&gt;)"
    assert find(html, "#g input[aria-label='Selecionar todos']") |> Enum.count() == 1
    assert find(html, "#g input[aria-label='Selecionar linha']") |> Enum.count() == 1
    assert find(html, "#g th button[aria-label='Ordenar por N']") |> Enum.count() == 1
    assert find(html, "#a [role=status]") |> LazyHTML.text() =~ "11-20/25"
  end

  test "the labels keep their English defaults" do
    html =
      render(~H"""
      <.data_table
        id="g"
        variant="grid"
        rows={[%{n: 1}]}
        total={25}
        on_page="page"
        on_select="select"
        on_sort="sort"
        row_key={& &1.n}
      >
        <:col :let={row} label="N" sort_key="n">{row.n}</:col>
      </.data_table>
      """)

    assert find(html, "#g button[aria-label='Page 1']") |> Enum.count() == 1
    assert html =~ "Showing <b>1</b> to <b>10</b> of <b>25</b> results"
    assert find(html, "#g input[aria-label='Select all rows']") |> Enum.count() == 1
    assert find(html, "#g input[aria-label='Select row']") |> Enum.count() == 1
    assert find(html, "#g th button[aria-label]") |> Enum.count() == 0
  end

  test "the grid search has a magnifier in a 36px box" do
    html =
      render(~H"""
      <.data_table id="g" variant="grid" rows={[%{n: 1}]} on_search="search">
        <:col :let={row} label="N">{row.n}</:col>
      </.data_table>
      """)

    assert find(
             html,
             "#g-search-form label.h-9 [class*='huge-search'], #g-search-form label.h-9 svg"
           )
           |> Enum.count() == 1

    assert find(html, "#g-search-form label.h-9 input[type=search]") |> Enum.count() == 1
  end

  test "the pagers leave a gap where pages are left out, the same window as pagination" do
    html =
      render(~H"""
      <.data_table id="a" rows={[%{n: 1}]} total={100} page_size={10} page={5} on_page="page">
        <:col :let={row} label="N">{row.n}</:col>
      </.data_table>
      <.data_table
        id="b"
        variant="grid"
        rows={[%{n: 1}]}
        total={100}
        page_size={10}
        page={1}
        on_page="page"
      >
        <:col :let={row} label="N">{row.n}</:col>
      </.data_table>
      """)

    assert ["...", "..."] =
             html |> find("#a ol.pagination span[aria-hidden=true]") |> Enum.map(&LazyHTML.text/1)

    assert ["4", "5", "6"] --
             (html
              |> find("#a ol.pagination li")
              |> Enum.map(&LazyHTML.text/1)
              |> Enum.map(&String.trim/1)) == []

    assert ["..."] = html |> find("#b span[aria-hidden=true]") |> Enum.map(&LazyHTML.text/1)
  end

  test "the title bar shows only with something in it; loading draws skeleton rows; the canvas pager" do
    bare =
      render(~H"""
      <.data_table id="t" rows={[%{n: 1}]}>
        <:col :let={r} label="N">{r.n}</:col>
      </.data_table>
      """)

    loading =
      render(~H"""
      <.data_table id="l" rows={[]} loading>
        <:col label="Pedido"></:col>
        <:col label="Total" align="right"></:col>
      </.data_table>
      """)

    canvas =
      render(~H"""
      <.data_table
        id="c"
        rows={[%{n: 1}]}
        total={30}
        page_size={3}
        on_page="page"
        pager="canvas"
        summary_label="%{from}–%{to} de %{total}"
      >
        <:col :let={r} label="N">{r.n}</:col>
      </.data_table>
      """)

    assert [] = find(bare, "#t > div.flex.items-center.justify-between") |> Enum.to_list()
    refute "mt-3" in classes(bare, "#t > .sg-card")
    assert LazyHTML.attribute(find(loading, "#l"), "aria-busy") == ["true"]
    assert [_, _, _, _, _, _] = find(loading, "#l tbody .sg-skel") |> Enum.to_list()
    assert [_] = find(canvas, "#c .sg-pager") |> Enum.to_list()
    assert find(canvas, "#c .sg-pager") |> LazyHTML.text() =~ "1–3 de 30"
  end

  describe "change tracking" do
    defmodule Page do
      use Phoenix.Component
      import LineaUI.Components.DataTable

      def page(assigns) do
        ~H"""
        <.data_table
          id="t"
          rows={@rows}
          class={@cls}
          variant={@variant}
          total={@total}
          on_page="pg"
          page_size={50}
        >
          <:col :let={r} label="Name">{r.name}</:col>
          <:col :let={r} label="Email">{r.email}</:col>
        </.data_table>
        """
      end
    end

    # the diff of a second render where only `changed` differs from the first
    defp second_diff(variant, changed) do
      rows = for i <- 1..50, do: %{name: "Row-#{i}", email: "row#{i}@example.com"}
      base = %{rows: rows, cls: "a", variant: variant, total: 120}
      alias Phoenix.LiveView.Diff

      {_diff, prints, comps} =
        Diff.render(
          %Phoenix.LiveView.Socket{},
          Page.page(Map.put(base, :__changed__, nil)),
          Diff.new_fingerprints(),
          Diff.new_components()
        )

      assigns =
        base
        |> Map.merge(changed)
        |> Map.put(:__changed__, Map.new(changed, &{elem(&1, 0), true}))

      {diff, _, _} = Diff.render(%Phoenix.LiveView.Socket{}, Page.page(assigns), prints, comps)
      Jason.encode!(diff)
    end

    for variant <- ["advanced", "grid"] do
      test "an unrelated change does not send the rows of the #{variant} table" do
        for changed <- [%{cls: "b"}, %{total: 130}] do
          json = second_diff(unquote(variant), changed)
          refute json =~ "Row-"
          assert byte_size(json) < 1_000
        end
      end
    end
  end
end
