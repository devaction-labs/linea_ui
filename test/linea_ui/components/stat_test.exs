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

    assert ["sg-card", "sg-stat-group"] == classes(html, "#g")
    assert find(html, "#g > .sg-stat") |> Enum.count() == 3
    assert LazyHTML.text(find(html, ".sg-stat:nth-child(2) .v small")) == "dias"
    assert ["v", "acc"] == classes(html, ".sg-stat:nth-child(3) .v")
    assert LazyHTML.text(find(html, ".sg-stat:first-child .l")) == "Subtotal"
  end

  test "card false drops the frame" do
    html =
      render(
        ~H|<.stat_group id="g" card={false}><.stat_item label="a" value="1" /></.stat_group>|
      )

    assert ["sg-stat-group"] == classes(html, "#g")
  end

  test "no empty small without a unit" do
    html = render(~H|<.stat_item label="a" value="1" />|)
    assert [] == find(html, ".v small") |> Enum.to_list()
  end

  test "size sm adds the sm class to the figure" do
    html = render(~H|<.stat_item label="a" value="Boleto" size="sm" />|)
    assert ["v", "sm"] == classes(html, ".v")
  end

  test "sunken variant" do
    html =
      render(
        ~H|<.stat_group id="g" variant="sunken"><.stat_item label="a" value="1" /></.stat_group>|
      )

    assert ["sg-card", "sg-stat-group", "sg-stat-sunken"] == classes(html, "#g")
  end
end
