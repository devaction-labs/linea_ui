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

    assert "sg-card" in classes(html, "#k")
    assert "sg-kpi" in classes(html, "#k")
    assert LazyHTML.text(find(html, ".sg-kpi-l")) |> String.trim() == "Faturamento"
    assert LazyHTML.text(find(html, ".sg-kpi-v")) =~ "R$ 248,6"
    assert LazyHTML.text(find(html, ".sg-kpi-v small")) == "mil"
    assert "up" in classes(html, ".sg-delta")
    assert [_] = find(html, "svg.sg-spark") |> Enum.to_list()
  end

  test "a fall is bad by default and a tone can reverse it" do
    html = render(~H|<.kpi_card label="Ticket" value="R$ 164" delta="2,3%" trend="down" />|)
    assert "down" in classes(html, ".sg-delta")

    html =
      render(~H|<.kpi_card label="Atraso" value="17" delta="2" trend="up" delta_tone="error" />|)

    assert "down" in classes(html, ".sg-delta")
  end

  test "without a series there is no sparkline, and the accent color paints it" do
    html = render(~H|<.kpi_card label="a" value="1" />|)
    assert find(html, "svg.sg-spark") |> Enum.to_list() == []

    html = render(~H|<.kpi_card label="a" value="1" spark={[1, 2, 3]} color="primary" />|)
    assert LazyHTML.attribute(find(html, "svg.sg-spark"), "style") == ["color:var(--accent)"]
    html = render(~H|<.kpi_card label="a" value="1" spark={[1, 2, 3]} color="neutral" />|)
    assert LazyHTML.attribute(find(html, "svg.sg-spark"), "style") == ["color:var(--ink)"]
  end

  test "loading shows placeholders" do
    html = render(~H|<.kpi_card id="k" loading />|)
    assert LazyHTML.attribute(find(html, "#k"), "aria-busy") == ["true"]
    assert [_ | _] = find(html, ".sg-skel") |> Enum.to_list()
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

    assert ["sg-kpi-tight", "sg-kpi-goal"] -- classes(html, "#k") == []
    assert attr_of(html, ".sg-meter.acc > i", "style") == ["width:78%"]
    assert attr_of(html, ".sg-meter", "aria-valuenow") == ["78"]
    assert LazyHTML.text(find(html, ".sg-kpi-c")) == "78% da meta de R$ 320 mil"
    assert find(html, "svg.sg-spark") |> Enum.to_list() == []
  end

  test "gap false sets the figure right under the top line" do
    html = render(~H|<.kpi_card id="k" label="a" value="1" gap={false} />|)
    assert "sg-kpi-tight" in classes(html, "#k")
    html = render(~H|<.kpi_card id="k" label="a" value="1" />|)
    refute "sg-kpi-tight" in classes(html, "#k")
  end
end
