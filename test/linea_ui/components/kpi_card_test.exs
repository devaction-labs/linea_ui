defmodule LineaUI.Components.KpiCardTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "renders label, figure, change and sparkline as the canvas card" do
    html =
      render(~H"""
      <.kpi_card
        id="k"
        label="Faturamento"
        value="R$ 248,6"
        unit="mil"
        delta="12,4%"
        trend="up"
        spark={[8, 12, 9, 14]}
      />
      """)

    assert ["card", "card-border", "kpi-card"] -- classes(html, "#k") == []
    assert LazyHTML.text(find(html, ".kpi-label")) |> String.trim() == "Faturamento"
    assert LazyHTML.text(find(html, ".kpi-value")) =~ "R$ 248,6"
    assert LazyHTML.text(find(html, ".kpi-value small")) == "mil"
    assert ["badge", "badge-soft", "badge-success"] -- classes(html, ".kpi-delta") == []
    assert [_] = find(html, "svg.kpi-spark") |> Enum.to_list()
  end

  test "a fall is bad by default and a tone can reverse it" do
    html = render(~H|<.kpi_card label="Ticket" value="R$ 164" delta="2,3%" trend="down" />|)
    assert "badge-error" in classes(html, ".kpi-delta")

    html =
      render(~H|<.kpi_card label="Atraso" value="17" delta="2" trend="up" delta_tone="error" />|)

    assert "badge-error" in classes(html, ".kpi-delta")
  end

  test "without a series there is no sparkline, and the accent color paints it" do
    html = render(~H|<.kpi_card label="a" value="1" />|)
    assert find(html, "svg.kpi-spark") |> Enum.to_list() == []

    html = render(~H|<.kpi_card label="a" value="1" spark={[1, 2, 3]} color="primary" />|)
    assert "text-primary" in classes(html, "svg.kpi-spark")
    html = render(~H|<.kpi_card label="a" value="1" spark={[1, 2, 3]} color="neutral" />|)
    assert "text-base-content" in classes(html, "svg.kpi-spark")
  end

  test "loading shows placeholders" do
    html = render(~H|<.kpi_card id="k" loading />|)
    assert LazyHTML.attribute(find(html, "#k"), "aria-busy") == ["true"]
    assert [_ | _] = find(html, ".skeleton") |> Enum.to_list()
  end

  test "progress swaps the sparkline for the goal meter and its caption" do
    html =
      render(~H"""
      <.kpi_card
        id="k"
        label="Vendas do mês"
        value="R$ 248,6"
        unit="mil"
        delta="12,4%"
        progress={78}
        caption="78% da meta de R$ 320 mil"
        spark={[1, 2, 3]}
      />
      """)

    assert ["kpi-tight", "kpi-goal"] -- classes(html, "#k") == []
    assert attr_of(html, "progress.progress-primary", "value") == ["78"]
    assert attr_of(html, "progress", "max") == ["100"]
    assert LazyHTML.text(find(html, ".kpi-caption")) == "78% da meta de R$ 320 mil"
    assert find(html, "svg.kpi-spark") |> Enum.to_list() == []
  end

  test "gap false sets the figure right under the top line" do
    html = render(~H|<.kpi_card id="k" label="a" value="1" gap={false} />|)
    assert "kpi-tight" in classes(html, "#k")
    html = render(~H|<.kpi_card id="k" label="a" value="1" />|)
    refute "kpi-tight" in classes(html, "#k")
  end

  test "icon slot renders a tinted chip before the label" do
    html =
      render(~H"""
      <.kpi_card id="k" label="Ativas" value="12" icon_tone="pos">
        <:icon><i class="x"></i></:icon>
      </.kpi_card>
      """)

    assert ["kpi-icon", "bg-success/10", "text-success"] -- classes(html, ".stat-title > span:first-child") == []
    assert [_] = find(html, ".stat-title > .kpi-icon + .kpi-label") |> Enum.to_list()
    assert [_] = find(html, ".kpi-icon .x") |> Enum.to_list()
  end

  test "no icon chip without the slot and acc is the default tone" do
    html = render(~H|<.kpi_card id="k" label="a" value="1" />|)
    assert [] == find(html, ".kpi-icon") |> Enum.to_list()

    html = render(~H|<.kpi_card id="k" label="a" value="1">
  <:icon>i</:icon>
</.kpi_card>|)
    assert ["kpi-icon", "bg-primary/10", "text-primary"] -- classes(html, ".kpi-icon") == []
  end

  test "value_id sets the id of the figure, with and without progress" do
    html = render(~H|<.kpi_card label="a" value="1" value_id="kv" />|)
    assert "kpi-value" in classes(html, "#kv")

    html = render(~H|<.kpi_card label="a" value="1" value_id="kv" progress={50} />|)
    assert "kpi-value" in classes(html, "#kv")
  end

  test "caption shows without progress and once with it" do
    html = render(~H|<.kpi_card label="a" value="1" caption="3 pausadas" />|)
    assert LazyHTML.text(find(html, ".kpi-caption")) == "3 pausadas"

    html = render(~H|<.kpi_card label="a" value="1" progress={50} caption="meta" />|)
    assert [_] = find(html, ".kpi-caption") |> Enum.to_list()

    html = render(~H|<.kpi_card label="a" value="1" />|)
    assert [] == find(html, ".kpi-caption") |> Enum.to_list()
  end
end
