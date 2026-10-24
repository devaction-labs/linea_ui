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
end
