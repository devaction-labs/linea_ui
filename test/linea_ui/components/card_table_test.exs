defmodule LineaUI.Components.CardTableTest do
  use LineaUI.ComponentCase, async: true

  @rows [
    %{
      id: 1,
      number: "PED-1",
      client: "Secretaria de Saúde",
      issuer: "Matriz",
      total: "R$ 95,60",
      state: :success
    },
    %{
      id: 2,
      number: "PED-2",
      client: "Prefeitura",
      issuer: "Filial",
      total: "R$ 10,00",
      state: :error
    }
  ]

  defp orders(extra \\ %{}) do
    assigns =
      Map.merge(%{rows: @rows, selected: [], status: & &1.state, on_select: nil}, extra)

    rendered_to_string(~H"""
    <.card_table
      id="orders"
      rows={@rows}
      selected={@selected}
      status={@status}
      on_select={@on_select}
      row_id={&"order-#{&1.id}"}
      row_key={& &1.id}
    >
      <:col :let={o} label="Order" role="head">{o.number}</:col>
      <:col :let={o} label="Client" role="title" width="minmax(120px,1fr)">{o.client}</:col>
      <:col :let={o} label="Issuer" priority={2}>{o.issuer}</:col>
      <:col :let={o} label="Value" role="value" align="end" priority={1}>{o.total}</:col>
      <:action :let={o}>
        <button type="button" aria-label={"Actions #{o.number}"}>...</button>
      </:action>
    </.card_table>
    """)
  end

  test "one row per record, a header cell per column" do
    html = orders()

    assert find(html, "li.linea-ctable-row") |> Enum.count() == 2
    assert find(html, ".linea-ctable-head .linea-ctable-h") |> Enum.count() == 4
    assert LazyHTML.text(find(html, "#order-1")) =~ "Secretaria de Saúde"
  end

  test "the tracks of each width leave out the columns that left" do
    style = html_attr(orders(), ".linea-ctable", "style")

    assert style =~ "--ct-c0:max-content minmax(120px,1fr) max-content max-content 2.75rem"
    assert style =~ "--ct-c1:max-content minmax(120px,1fr) max-content 2.75rem"
    assert style =~ "--ct-c2:max-content minmax(120px,1fr) 2.75rem"
    assert style =~ "--ct-c3:max-content minmax(120px,1fr) 2.75rem"
  end

  test "the panel lists the columns that can leave, with their values" do
    pop = find(orders(), "#order-1 .linea-ctable-pop")

    assert LazyHTML.text(pop) =~ "Issuer"
    assert LazyHTML.text(pop) =~ "Matriz"
    assert LazyHTML.text(pop) =~ "R$ 95,60"
    refute LazyHTML.text(pop) =~ "Secretaria"
  end

  test "no panel when every column stays" do
    html =
      render(~H"""
      <.card_table id="t" rows={[%{a: 1}]}>
        <:col :let={r} label="A">{r.a}</:col>
      </.card_table>
      """)

    assert find(html, ".linea-ctable-pop") |> Enum.count() == 0
  end

  test "the status color is the bar of the row; an unknown one is ignored" do
    html = orders(%{status: &if(&1.id == 1, do: :success, else: :nope)})

    assert html_attr(html, "#order-1", "data-status") == "success"
    assert find(html, "#order-2[data-status]") |> Enum.count() == 0
  end

  test "a row without a status still draws the bar, in the neutral color" do
    css = File.read!("assets/css/parts/data.css")

    assert css =~ ~r/\.linea-ctable-row::before \{/
    assert css =~ "--ct-st: var(--color-slate-300)"
    assert css =~ "--ct-st: var(--color-navy-400)"
  end

  test "on_select adds a checkbox column and marks the selected rows" do
    html = orders(%{on_select: "select", selected: [1]})

    assert find(html, "#order-1 input[type=checkbox]") |> Enum.count() == 1
    assert html_attr(html, "#order-1", "data-selected") == "true"
    assert html_attr(html, "#order-2", "data-selected") == "false"
    assert html_attr(html, ".linea-ctable", "style") =~ "--ct-sel:2.75rem"
  end

  test "a sortable header is a button that sends the next direction" do
    html =
      render(~H"""
      <.card_table id="t" rows={[%{a: 1}]} on_sort="sort" sort_by="a" sort_dir="asc">
        <:col :let={r} label="A" sort_key="a">{r.a}</:col>
      </.card_table>
      """)

    assert html_attr(html, ".linea-ctable-sort", "phx-value-direction") == "desc"
    assert html_attr(html, ".linea-ctable-h", "aria-sort") == "ascending"
  end

  test "the empty slot shows for an empty list" do
    html =
      render(~H"""
      <.card_table id="t" rows={[]}>
        <:col :let={r} label="A">{r.a}</:col>
        <:empty>Nothing here</:empty>
      </.card_table>
      """)

    assert LazyHTML.text(find(html, "#t-empty")) =~ "Nothing here"
  end

  defp html_attr(html, selector, name),
    do: html |> find(selector) |> LazyHTML.attribute(name) |> hd()
end
