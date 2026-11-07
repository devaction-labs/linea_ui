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

  test "the panel is a plain list, not interactive, with no hook and no per-line copy" do
    html = orders()

    assert [_] = find(html, "#order-1 dl.linea-ctable-pop") |> Enum.to_list()
    assert find(html, "#order-1 .linea-ctable-pop > div > dt") |> Enum.count() == 2
    assert find(html, "#order-1 .linea-ctable-pop > div > dd") |> Enum.count() == 2
    assert find(html, "#order-1 .linea-ctable-pop button") |> Enum.count() == 0
    refute html =~ "LineaUI.CardTable"
    refute html =~ "aria-expanded"
    refute html =~ "data-copy-line"
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
    assert css =~ "--ct-st: var(--line-strong)"
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

  test "detail slots make the panel list exactly them, and a copy column gets a button and a tooltip" do
    assigns = %{rows: @rows}

    html =
      rendered_to_string(~H"""
      <.card_table id="orders" rows={@rows} row_id={&"order-#{&1.id}"}>
        <:col
          :let={o}
          label="Order"
          role="head"
          copy={& &1.number}
          copy_label="Copy order"
          copied_label="Order copied"
        >
          {o.number}
        </:col>
        <:col :let={o} label="Issuer" priority={2}>{o.issuer}</:col>
        <:detail :let={o} label="Due">{o.client}</:detail>
      </.card_table>
      """)

    pop = find(html, "#order-1 .linea-ctable-pop")
    assert pop |> LazyHTML.attribute("data-detail") == [""]
    assert LazyHTML.text(pop) =~ "Due"
    assert LazyHTML.text(pop) =~ "Secretaria de Saúde"
    # details first, then the columns that can leave, each with its priority
    assert LazyHTML.text(pop) =~ "Issuer"

    assert [{"data-d", ""}] =
             find(html, "#order-1 .linea-ctable-pop > div:first-child")
             |> LazyHTML.attributes()
             |> hd()
             |> Enum.take(1)

    assert find(html, "#order-1 .linea-ctable-pop > div[data-p=\"2\"]") |> LazyHTML.text() =~
             "Matriz"

    assert find(html, "#order-1-copy") |> LazyHTML.attribute("data-value") == ["PED-1"]
    assert find(html, "#order-1-copy") |> LazyHTML.attribute("aria-label") == ["Copy order"]
    assert find(html, "#order-1 .linea-ctable-ctip .l1") |> LazyHTML.text() == "PED-1"
    assert find(html, "#order-1 .linea-ctable-ctip .l2") |> LazyHTML.text() == "Order copied"
  end

  defp html_attr(html, selector, name),
    do: html |> find(selector) |> LazyHTML.attribute(name) |> hd()

  describe "heading" do
    test "title, description and actions are drawn above the table" do
      assigns = %{rows: @rows}

      html =
        rendered_to_string(~H"""
        <.card_table id="h" rows={@rows} title="Portal access" description="Who can see it.">
          <:actions><button>Invite</button></:actions>
          <:col :let={o} label="Order">{o.number}</:col>
        </.card_table>
        """)

      assert html =~ "linea-ctable-top"
      assert html =~ "Portal access"
      assert html =~ "Who can see it."
      assert html =~ "Invite"
    end

    test "no heading without title, description or actions" do
      refute orders() =~ "linea-ctable-top"
    end
  end

  test "flat is a plain table in a card, with the title, the actions or a top slot" do
    html =
      render(~H"""
      <.card_table id="t" variant="flat" title="Últimos pedidos" rows={[%{n: "#1", t: "R$ 1"}]}>
        <:actions><a href="#">Ver todos</a></:actions>
        <:col :let={o} label="Pedido">{o.n}</:col>
        <:col :let={o} label="Total" align="end">{o.t}</:col>
      </.card_table>
      """)

    top =
      render(~H"""
      <.card_table id="u" variant="flat" rows={[]}>
        <:top>
          <nav id="tabs">Abas</nav>
        </:top>
        <:col :let={o} label="Pedido">{o}</:col>
      </.card_table>
      """)

    assert [_] = find(html, "#t-box.sg-card.flush table.sg-table") |> Enum.to_list()
    assert find(html, "#t-box .sg-card-h h3") |> LazyHTML.text() == "Últimos pedidos"
    assert [_] = find(html, "#t-box .sg-card-h .meta a") |> Enum.to_list()
    assert [_] = find(html, "#t-box th.r") |> Enum.to_list()
    assert find(html, "#t tr td.r") |> LazyHTML.text() =~ "R$ 1"
    assert [_] = find(top, "#u-box .linea-ctable-flat-top #tabs") |> Enum.to_list()
    assert [] = find(top, "#u-box .sg-card-h") |> Enum.to_list()
  end

  describe "options" do
    defp opt_attr(html, sel, name), do: html |> find(sel) |> LazyHTML.attribute(name) |> hd()

    test "default breakpoints emit no style; custom ones emit a scoped style and c4 tracks" do
      refute orders() =~ "<style"

      assigns = %{rows: @rows}

      html =
        rendered_to_string(~H"""
        <.card_table id="bp" rows={@rows} breakpoints={[1180, 980, 760, 640, 560]}>
          <:col :let={o} label="A" role="head">{o.number}</:col>
          <:col :let={o} label="B" priority={4}>{o.issuer}</:col>
          <:col :let={o} label="C" priority={1}>{o.client}</:col>
        </.card_table>
        """)

      css = html |> find("style") |> LazyHTML.text()
      assert css =~ ~s([id="bp-box"].linea-ctable { container-name: ctable ct-bp; })
      assert css =~ ~s(.linea-ctable-cell [data-p="4"].linea-ctable-sub)
      assert css =~ ~s(.linea-ctable-cell [data-p="1"].linea-ctable-sub)
      # the default queries ask for ctable-d, which a custom table does not have
      refute css =~ "ctable-d"
      assert css =~ "@container ct-bp (max-width: 1179.98px)"
      assert css =~ "@container ct-bp (max-width: 979.98px)"
      assert css =~ "@container ct-bp (max-width: 759.98px)"
      assert css =~ "@container ct-bp (max-width: 639.98px)"
      assert css =~ "@container ct-bp (max-width: 559.98px)"
      assert css =~ ~s([data-p="4"].linea-ctable-cell)
      style = opt_attr(html, ".linea-ctable", "style")
      assert style =~ "--ct-c4:max-content"
      assert style =~ "--ct-c3:max-content max-content"
    end

    test "default container rules use ctable-d; the default CSS names both containers" do
      css = File.read!("assets/css/parts/data.css")
      assert css =~ "container-name: ctable ctable-d;"
      refute css =~ "@container ctable ("
      assert css =~ "@container ctable-d (max-width: 1179.98px)"
      assert css =~ ~s(.linea-ctable-cell [data-p="2"].linea-ctable-sub { display: none; })
    end

    test "copy_show inline marks the content; the default does not" do
      assigns = %{rows: @rows}

      html =
        rendered_to_string(~H"""
        <.card_table id="cs" rows={@rows}>
          <:col :let={o} label="A" copy={& &1.number} copy_show="inline">{o.number}</:col>
          <:col :let={o} label="B" copy={& &1.number}>{o.number}</:col>
        </.card_table>
        """)

      assert html |> find(~s(.linea-ctable-nn[data-show="inline"])) |> Enum.count() ==
               length(@rows)

      assert html |> find(".linea-ctable-nn") |> Enum.count() == 2 * length(@rows)
      refute orders() =~ "data-show"
    end

    test "ctable_sub renders a sub line with its priority, none when always shown" do
      assigns = %{rows: @rows}

      html =
        rendered_to_string(~H"""
        <.card_table id="sb" rows={@rows}>
          <:col :let={o} label="A">
            {o.client}
            <.ctable_sub priority={2}>emissor {o.issuer}</.ctable_sub><.ctable_sub>fixo</.ctable_sub>
          </:col>
        </.card_table>
        """)

      assert html |> find(~s(.linea-ctable-cell .linea-ctable-sub[data-p="2"])) |> Enum.count() ==
               length(@rows)

      assert html |> find(".linea-ctable-sub:not([data-p])") |> Enum.count() == length(@rows)
    end

    test "invalid breakpoints raise" do
      assigns = %{rows: @rows}

      for bad <- [[720, 960, 520], [1180], [1180, 1180, 520], [1180, 960.5, 520], [0, -1]] do
        assigns = Map.put(assigns, :bad, bad)

        assert_raise ArgumentError, ~r/breakpoints/, fn ->
          rendered_to_string(~H"""
          <.card_table id="bp" rows={@rows} breakpoints={@bad}>
            <:col :let={o} label="A">{o.number}</:col>
          </.card_table>
          """)
        end
      end
    end

    test "copy_tip value_label shows the value in bold and the label, before and after the copy" do
      assigns = %{rows: @rows}

      html =
        rendered_to_string(~H"""
        <.card_table id="orders" rows={@rows} row_id={&"order-#{&1.id}"}>
          <:col
            :let={o}
            label="Order"
            role="head"
            copy={& &1.number}
            copy_tip="value_label"
            copy_label="Copiar número"
            copied_label="Número copiado"
          >
            {o.number}
          </:col>
        </.card_table>
        """)

      assert opt_attr(html, "#order-1 .linea-ctable-ctip", "data-tip") == "value_label"
      assert find(html, "#order-1 .linea-ctable-ctip .l1 b") |> LazyHTML.text() == "PED-1"
      assert find(html, "#order-1 .linea-ctable-ctip .l1") |> LazyHTML.text() =~ "· Copiar número"
      assert find(html, "#order-1 .linea-ctable-ctip .l2 b") |> LazyHTML.text() == "PED-1"

      assert find(html, "#order-1 .linea-ctable-ctip .l2") |> LazyHTML.text() =~
               "· Número copiado"

      # the icon swaps to a check while data-copied is set
      assert html =~ "group-data-copied/clip:inline"
      assert html =~ "m5 12.5 4.5 4.5L19 7.5"
    end

    test "meta sits inline after the title; the actions are in their own box" do
      assigns = %{rows: @rows}

      html =
        rendered_to_string(~H"""
        <.card_table id="m" rows={@rows} title="Pedidos" meta="128 no período">
          <:actions><a href="/o">Ver todos</a></:actions>
          <:col :let={o} label="A">{o.number}</:col>
        </.card_table>
        """)

      assert find(html, ".linea-ctable-title-row h3.linea-ctable-title") |> LazyHTML.text() ==
               "Pedidos"

      assert find(html, ".linea-ctable-title-row .linea-ctable-meta") |> LazyHTML.text() ==
               "128 no período"

      assert find(html, ".linea-ctable-top-act > a") |> LazyHTML.text() == "Ver todos"
      refute orders() =~ "linea-ctable-title-row"
    end

    test "foot slot renders under the rows, inside the card, in both variants" do
      assigns = %{rows: @rows}

      html =
        rendered_to_string(~H"""
        <.card_table id="f" rows={@rows}>
          <:col :let={o} label="A">{o.number}</:col>
          <:foot><span>Mostrando 1–2 de 2</span></:foot>
        </.card_table>
        """)

      assert find(html, "#f-box > .linea-ctable-foot") |> LazyHTML.text() =~ "Mostrando 1–2 de 2"
      refute orders() =~ "linea-ctable-foot"

      flat =
        rendered_to_string(~H"""
        <.card_table id="g" variant="flat" title="Pedidos" description="Os mais recentes." rows={@rows}>
          <:col :let={o} label="A">{o.number}</:col>
          <:foot><span>Total</span></:foot>
        </.card_table>
        """)

      assert find(flat, "#g-box > .linea-ctable-foot") |> LazyHTML.text() =~ "Total"
      assert find(flat, "#g-box .sg-card-h h3") |> LazyHTML.text() == "Pedidos"

      assert find(flat, "#g-box .sg-card-h .linea-ctable-flat-text p") |> LazyHTML.text() ==
               "Os mais recentes."
    end

    test "an empty label and a prioritised action column" do
      assigns = %{rows: @rows}

      html =
        rendered_to_string(~H"""
        <.card_table id="a" rows={@rows}>
          <:col :let={o} role="head">{o.number}</:col>
          <:col :let={o} label="B" priority={3}>{o.issuer}</:col>
          <:action :let={o} priority={3}><button>{o.id}</button></:action>
        </.card_table>
        """)

      assert opt_attr(html, ".linea-ctable-head .linea-ctable-act", "data-p") == "3"
      assert opt_attr(html, "li .linea-ctable-act", "data-p") == "3"
      style = opt_attr(html, ".linea-ctable", "style")
      assert style =~ "--ct-c2:max-content max-content 2.75rem"
      assert style =~ "--ct-c3:max-content;"
    end
  end
end
