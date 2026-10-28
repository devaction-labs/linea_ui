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

  test "density options reach the table" do
    html =
      render(~H"""
      <.data_table id="a" rows={[%{n: 1}]} compact headless borderless>
        <:col :let={row} label="N" align="right">{row.n}</:col>
      </.data_table>
      """)

    assert [] = find(html, "thead") |> Enum.to_list()
    assert "py-2" in classes(html, "td")
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

    assert ["…", "…"] =
             html |> find("#a ol.pagination span[aria-hidden=true]") |> Enum.map(&LazyHTML.text/1)

    assert ["4", "5", "6"] --
             (html
              |> find("#a ol.pagination li")
              |> Enum.map(&LazyHTML.text/1)
              |> Enum.map(&String.trim/1)) == []

    assert ["…"] = html |> find("#b span[aria-hidden=true]") |> Enum.map(&LazyHTML.text/1)
  end
end
