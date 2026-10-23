defmodule LineaUI.Components.CardTest do
  use LineaUI.ComponentCase, async: true

  test "the white card with a title and a body" do
    html =
      render(~H"""
      <.card>
        <:title>Simple Card</:title><p>Body</p>
      </.card>
      """)

    classes = classes(html, "div")
    assert "card" in classes
    assert "px-4" in classes
    assert [title] = find(html, "h2") |> Enum.to_list()
    assert String.trim(LazyHTML.text(title)) == "Simple Card"
    assert [_] = find(html, "div.pt-2 > p") |> Enum.to_list()
  end

  test "without a title the content fills the card, padded or not" do
    html =
      render(~H"""
      <.card padded={false} class="p-2"><span id="x"></span></.card>
      """)

    assert [_] = find(html, "div.card > span#x") |> Enum.to_list()
    refute "px-4" in classes(html, "div")
  end

  test "variants" do
    html =
      render(~H"""
      <.card id="b" variant="bordered" shape="xl">x</.card>
      <.card id="s" variant="solid" color="info">x</.card>
      <.card id="g" variant="glow" color="primary">x</.card>
      <.card id="r" variant="gradient" gradient="fuchsia-pink">x</.card>
      <.card id="o" variant="gradient_outline" gradient="sky-blue">x</.card>
      """)

    assert "border-slate-150" in classes(html, "#b")
    assert "rounded-2xl" in classes(html, "#b")
    assert "bg-info" in classes(html, "#s")
    assert "shadow-primary/50" in classes(html, "#g")
    assert "from-fuchsia-600" in classes(html, "#r")
    assert "p-1" in classes(html, "#o")
    assert [_] = find(html, "#o > div.bg-slate-50") |> Enum.to_list()
  end
end
