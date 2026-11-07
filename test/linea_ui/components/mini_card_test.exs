defmodule LineaUI.Components.MiniCardTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "a shortcut: the icon box over the label" do
    html =
      render(~H|<.mini_card id="m" icon="huge-invoice-01" tone="accent" label="Novo pedido" />|)

    assert ["sg-card", "sg-mini"] == classes(html, "div#m")
    assert ["sg-ic", "acc"] == classes(html, "#m > span.sg-ic")
    assert LazyHTML.text(find(html, "#m > b.sg-mini-t")) == "Novo pedido"
  end

  test "a figure: the faint label over the mono value" do
    html = render(~H|<.mini_card id="m" label="A receber" value="R$ 41,2 mil" />|)
    assert "sg-mini-v" in classes(html, "#m")
    assert LazyHTML.text(find(html, "#m > .sg-mini-l")) == "A receber"
    assert LazyHTML.text(find(html, "#m > b.sg-mini-n")) == "R$ 41,2 mil"
    assert find(html, "#m .sg-ic") |> Enum.count() == 0
  end

  test "with navigate it is a link" do
    html = render(~H|<.mini_card id="m" label="Conciliar" navigate="/conciliar" />|)
    assert attr_of(html, "a#m", "href") == ["/conciliar"]
  end
end
