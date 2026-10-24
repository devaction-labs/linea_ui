defmodule LineaUI.Components.TypographyTest do
  use LineaUI.ComponentCase, async: true

  test "heading levels, weights, colors and display sizes" do
    html =
      render(~H"""
      <.heading level={1}>H1</.heading>
      <.heading level={4} weight="light" color="info">H4</.heading>
      <.heading display={2}>D2</.heading>
      <.heading>H2</.heading>
      """)

    assert "text-3xl" in classes(html, "h1")
    assert ["text-lg", "font-light", "text-info"] = classes(html, "h4")
    assert [_, d2] = find(html, "h1") |> Enum.to_list()
    assert d2 |> LazyHTML.attribute("class") |> hd() == "text-7xl"
    assert "text-2xl" in classes(html, "h2")
  end

  test "a heading takes its type size apart from its level" do
    html =
      render(~H"""
      <.heading level={2} size="2xl">Overview</.heading>
      <.heading level={4} size="xl" weight="semibold">Detail</.heading>
      """)

    assert "text-2xl" in classes(html, "h2")
    assert "text-xl" in classes(html, "h4")
    assert "text-lg" not in classes(html, "h4")
  end

  test "text, gradients and decorations" do
    html =
      render(~H"""
      <.text id="p" size="lg" decoration="line-through">x</.text>
      <.text id="s" as="span" weight="semibold" gradient="sky-blue">y</.text>
      """)

    assert [_] = find(html, "p#p.text-lg.line-through") |> Enum.to_list()
    assert [_] = find(html, "span#s.bg-clip-text.text-transparent") |> Enum.to_list()
  end

  test "text_link, inline_code and kbd" do
    html =
      render(~H"""
      <.text_link href="#" decoration_color="info" decoration_style="wavy">L</.text_link>
      <.inline_code>mix test</.inline_code>
      <.kbd>K</.kbd>
      """)

    assert ["font-semibold", "underline", "decoration-2", "decoration-info", "decoration-wavy"] =
             classes(html, "a")

    assert [_] = find(html, "code.inline-code") |> Enum.to_list()
    assert [_] = find(html, "kbd") |> Enum.to_list()
  end
end
