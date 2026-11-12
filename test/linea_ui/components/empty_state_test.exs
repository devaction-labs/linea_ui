defmodule LineaUI.Components.EmptyStateTest do
  use LineaUI.ComponentCase, async: true

  defp texts(html, selector),
    do:
      html
      |> find(selector)
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

  test "a card with the grid, the icon, the kicker, the title and the reason" do
    html =
      render(~H"""
      <.empty_state variant="card" icon="huge-search-01" kicker="Receivables" title="No receivable yet">
        A receivable is created when an invoice is authorized.
      </.empty_state>
      """)

    assert [_] = find(html, "section .empty-grid[aria-hidden=true]") |> Enum.to_list()
    assert [_] = find(html, "section span.huge-search-01") |> Enum.to_list()
    assert texts(html, "section > span:not([aria-hidden])") == ["Receivables"]
    assert texts(html, "h2") == ["No receivable yet"]
    assert texts(html, "p") == ["A receivable is created when an invoice is authorized."]
    assert "shadow-soft" in classes(html, "section")
  end

  test "the table variant is a centered notice with a disc, the reason and the next step" do
    html =
      render(~H"""
      <.empty_state variant="table" icon="huge-inbox" title="No order found">
        Nothing matches "Souza".
        <:action><a href="#">Clear search</a></:action>
      </.empty_state>
      """)

    assert [_] = find(html, "span.size-12.rounded-full span.huge-inbox") |> Enum.to_list()
    assert texts(html, "b") == ["No order found"]
    assert texts(html, "div > span:not([aria-hidden])") == ["Nothing matches \"Souza\"."]
    assert texts(html, "a") == ["Clear search"]
    assert [] = find(html, "section") |> Enum.to_list()
  end

  test "the heading level" do
    html = render(~H|<.empty_state variant="card" title="Empty" level={3} />|)
    assert texts(html, "h3") == ["Empty"]
    assert find(html, "h2") |> Enum.count() == 0
  end

  test "without a reason, a kicker or an action those parts are not drawn" do
    html = render(~H|<.empty_state variant="card" title="Empty" />|)

    assert find(html, "p") |> Enum.count() == 0
    assert find(html, "section > span:not([aria-hidden])") |> Enum.count() == 0
    assert find(html, "section > div") |> Enum.count() == 0
  end

  test "the action slot holds the next step" do
    html =
      render(~H"""
      <.empty_state variant="card" title="Empty">
        <:action><.button>New order</.button></:action>
      </.empty_state>
      """)

    assert texts(html, "section > div button") == ["New order"]
  end

  test "tone paints the icon tile" do
    html =
      render(~H"""
      <.empty_state variant="card" title="A" icon="huge-search-01" />
      <.empty_state variant="card" title="B" icon="huge-search-01" tone="gradient" class="mt-4" />
      """)

    assert find(html, ".from-blue-600") |> Enum.count() == 1
    assert find(html, "section > span.size-15") |> Enum.count() == 2
    assert find(html, "section.mt-4") |> Enum.count() == 1
  end

  test "an illustration replaces the icon" do
    html =
      render(~H"""
      <.empty_state variant="card" title="Empty" icon="huge-search-01">
        <:illustration><img src="/empty.svg" alt="" /></:illustration>
      </.empty_state>
      """)

    assert [_] = find(html, "section img[src='/empty.svg']") |> Enum.to_list()
    assert find(html, "span.huge-search-01") |> Enum.count() == 0
  end

  test "the inline variant is a compact notice with a bold title" do
    html =
      render(~H"""
      <.empty_state variant="inline" icon="huge-search-01" title="Nothing for “dipirona”">
        Try another term.
      </.empty_state>
      """)

    assert find(html, "section") |> Enum.count() == 0
    assert find(html, ".empty-grid") |> Enum.count() == 0
    assert texts(html, "b") == ["Nothing for “dipirona”"]
    assert html |> find("div") |> LazyHTML.text() =~ "Try another term."
    assert [_] = find(html, "span.huge-search-01") |> Enum.to_list()
    assert "ring-1" in classes(html, "div")
    assert "text-slate-800" in classes(html, "b")
  end

  test "the inline colors" do
    html =
      render(~H"""
      <.empty_state variant="inline" color="success" title="Done" />
      <.empty_state variant="inline" color="error" title="Failed">
        <:action><.button>Try again</.button></:action>
      </.empty_state>
      """)

    assert "bg-success/10" in classes(html, "div")
    assert find(html, "[role=alert]") |> Enum.count() == 1
    assert "bg-error/10" in classes(html, "[role=alert]")
    assert texts(html, "[role=alert] button") == ["Try again"]
  end

  test "class and rest land on the root" do
    html =
      render(~H"""
      <.empty_state variant="card" id="e" title="Empty" class="max-w-sm" data-x="1" />
      <.empty_state id="i" variant="inline" title="Empty" class="mt-2" data-y="2" />
      """)

    assert "max-w-sm" in classes(html, "#e")
    assert html |> find("#e") |> LazyHTML.attribute("data-x") == ["1"]
    assert "mt-2" in classes(html, "#i")
    assert html |> find("#i") |> LazyHTML.attribute("data-y") == ["2"]
  end

  test "the canvas variant is sg-empty with the art tile, the title, the reason and the actions" do
    html =
      render(~H"""
      <.empty_state variant="canvas" icon="huge-search-01" title="Nada encontrado">
        Verifique a grafia.
        <:action><button>Limpar</button></:action>
      </.empty_state>
      """)

    assert [_] =
             find(html, ".sg-empty > .art[aria-hidden=true] span.huge-search-01")
             |> Enum.to_list()

    refute "pos" in classes(html, ".art")
    assert texts(html, ".sg-empty h2") == ["Nada encontrado"]
    assert texts(html, ".sg-empty p") == ["Verifique a grafia."]
    assert texts(html, ".sg-empty-actions button") == ["Limpar"]

    positive = render(~H|<.empty_state variant="canvas" tone="positive" title="Em dia" />|)
    assert "pos" in classes(positive, ".art")
    assert find(positive, ".sg-empty-actions") |> Enum.empty?()
  end

  test "the plain variant is the one-line canvas notice" do
    html =
      render(~H"""
      <.empty_state variant="plain" icon="huge-attachment-01" title="Nenhum anexo.">
        <a href="#">Adicionar</a>
      </.empty_state>
      """)

    assert [_] = find(html, ".sg-empty-line span.huge-attachment-01") |> Enum.to_list()
    assert texts(html, ".sg-empty-line") == ["Nenhum anexo. Adicionar"]
  end
end
