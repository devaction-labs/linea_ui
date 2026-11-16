defmodule LineaUI.Components.StatTest do
  use LineaUI.ComponentCase, async: true

  test "a strip of figures in a card" do
    html =
      render(~H"""
      <.stat_group id="g">
        <.stat_item label="Subtotal" value="R$ 3.240" />
        <.stat_item label="Prazo" value="28" unit="dias" />
        <.stat_item label="Total" value="R$ 3.120" tone="accent" />
      </.stat_group>
      """)

    assert ["stats", "border", "border-base-300", "bg-base-100"] == classes(html, "#g")
    assert find(html, "#g > .stat") |> Enum.count() == 3
    assert LazyHTML.text(find(html, ".stat:nth-child(2) .stat-value small")) == "dias"
    assert "text-primary" in classes(html, ".stat:nth-child(3) .stat-value")
    assert LazyHTML.text(find(html, ".stat:first-child .stat-title")) == "Subtotal"
  end

  test "card false drops the frame" do
    html =
      render(
        ~H|<.stat_group id="g" card={false}><.stat_item label="a" value="1" /></.stat_group>|
      )

    assert ["stats"] == classes(html, "#g")
  end

  test "no empty small without a unit" do
    html = render(~H|<.stat_item label="a" value="1" />|)
    assert [] == find(html, ".v small") |> Enum.to_list()
  end

  test "size sm adds the sm class to the figure" do
    html = render(~H|<.stat_item label="a" value="Boleto" size="sm" />|)
    assert "text-lg" in classes(html, ".stat-value")
  end

  test "sunken variant" do
    html =
      render(
        ~H|<.stat_group id="g" variant="sunken"><.stat_item label="a" value="1" /></.stat_group>|
      )

    assert ["stats", "border", "border-transparent", "bg-base-200"] -- classes(html, "#g") == []
  end
end
