defmodule LineaUI.Components.CardTest do
  use LineaUI.ComponentCase, async: true

  test "a canvas card holds its content" do
    html = render(~H|<.card id="c">Texto</.card>|)
    assert "sg-card" in classes(html, "#c")
    assert String.trim(LazyHTML.text(find(html, "#c"))) == "Texto"
  end

  test "soft and flush are the canvas variants, class is kept" do
    assert "soft" in classes(render(~H|<.card id="c" variant="soft">x</.card>|), "#c")
    assert "flush" in classes(render(~H|<.card id="c" variant="flush">x</.card>|), "#c")
    assert "flush" in classes(render(~H|<.card id="c" padded={false}>x</.card>|), "#c")
    assert "mt-4" in classes(render(~H|<.card id="c" class="mt-4">x</.card>|), "#c")
  end

  test "the title slot draws the card header" do
    html =
      render(~H"""
      <.card id="c">
        <:title>Faturamento</:title>
        Corpo
      </.card>
      """)

    assert [h3] = find(html, "#c > .sg-card-h > h3") |> Enum.to_list()
    assert String.trim(LazyHTML.text(h3)) == "Faturamento"
  end

  test "the header, subheading, actions and footer parts" do
    html =
      render(~H"""
      <.card id="c">
        <.card_header>
          <.card_heading level={3}>Vendas</.card_heading>
          <.card_subheading>novembro</.card_subheading>
          <.card_actions><span>Ver</span></.card_actions>
        </.card_header>
        <.card_footer>Rodapé</.card_footer>
      </.card>
      """)

    assert [_] = find(html, "#c .sg-card-h h3") |> Enum.to_list()
    assert [_] = find(html, "#c .sg-card-h .meta") |> Enum.to_list()
    assert [_] = find(html, "#c .sg-card-h .end") |> Enum.to_list()
    assert [_] = find(html, "#c .sg-card-f") |> Enum.to_list()
  end
end
