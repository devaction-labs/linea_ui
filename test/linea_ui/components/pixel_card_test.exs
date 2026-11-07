defmodule LineaUI.Components.PixelCardTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "the canvas markup: icon chip, title, description and the arrow" do
    html =
      render(~H"""
      <.pixel_card
        id="p"
        navigate="/novo/loja"
        color="red"
        icon="huge-shopping-cart-01"
        title="Loja"
        description="PDV, estoque, NFC-e"
      />
      """)

    assert ["sg-px", "red"] == classes(html, "#p")
    assert ["huge-shopping-cart-01", "size-[13px]"] == classes(html, "#p > .ico > span")
    assert LazyHTML.text(find(html, "#p > b")) == "Loja"
    assert LazyHTML.text(find(html, "#p > span.d")) == "PDV, estoque, NFC-e"
    assert "huge-arrow-up-right-01" in classes(html, "#p > .go > span")
  end

  test "with navigate, patch or href it is a link" do
    html = render(~H|<.pixel_card id="p" navigate="/a" title="A" />|)
    assert attr_of(html, "a#p", "href") == ["/a"]

    html = render(~H|<.pixel_card id="p" href="/a" title="A" />|)
    assert attr_of(html, "a#p", "href") == ["/a"]

    html = render(~H|<.pixel_card id="p" patch="/a" title="A" />|)
    assert attr_of(html, "a#p", "href") == ["/a"]
  end

  test "with no destination it is a button that takes events" do
    html = render(~H|<.pixel_card id="p" phx-click="pick" phx-value-id="x" title="A" />|)
    assert attr_of(html, "button#p", "type") == ["button"]
    assert attr_of(html, "button#p", "phx-click") == ["pick"]
    assert find(html, "a#p") |> Enum.count() == 0
  end

  test "the colour is optional, the arrow and the icon can be left out" do
    html = render(~H|<.pixel_card id="p" title="Marca" arrow={false} class="extra" />|)
    assert ["sg-px", "extra"] == classes(html, "#p")
    assert find(html, "#p .go") |> Enum.count() == 0
    assert find(html, "#p .ico") |> Enum.count() == 0
    assert find(html, "#p .d") |> Enum.count() == 0
  end

  test "--px reaches the element through style, and the inner block comes after the description" do
    html =
      render(~H"""
      <.pixel_card id="p" title="A" description="d" style="--px: #f97316"><i>x</i></.pixel_card>
      """)

    assert attr_of(html, "#p", "style") == ["--px: #f97316"]
    assert LazyHTML.text(find(html, "#p > i")) == "x"
  end
end
