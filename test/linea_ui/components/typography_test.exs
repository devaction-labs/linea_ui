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
    assert d2 |> LazyHTML.attribute("class") |> hd() == "text-7xl font-semibold"
    assert "text-2xl" in classes(html, "h2")
    refute "font-semibold" in classes(html, "h2")
  end

  test "a display heading is semibold unless the weight is given" do
    html =
      render(~H"""
      <.heading display={1} weight="light">D1</.heading>
      <.heading display={3}>D3</.heading>
      """)

    assert "font-light" in classes(html, "h1:first-child")
    refute "font-semibold" in classes(html, "h1:first-child")
    assert "font-semibold" in classes(html, "h1:last-child")
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

    assert ["underline", "decoration-1", "decoration-info", "decoration-wavy"] =
             classes(html, "a")

    assert [_] = find(html, "code.inline-code") |> Enum.to_list()
    assert [_] = find(html, "kbd") |> Enum.to_list()
    assert "font-mono" in classes(html, "kbd")
    assert "text-[11.5px]" in classes(html, "kbd")
    assert "rounded-[5px]" in classes(html, "kbd")
  end

  test "the canvas text colours, sizes, mono and the page title" do
    html =
      render(~H"""
      <.heading level={1} size="title">Financeiro</.heading>
      <.text id="l" size="lead" color="subtle">Contas</.text>
      <.text id="m" as="span" size="meta" color="faint">Meta</.text>
      <.text id="n" as="span" mono color="ink">R$ 3.120,50</.text>
      <.text id="f" as="span" color="fg">fg</.text>
      """)

    assert ["text-[34px]/[40px]", "tracking-[-.03em]", "text-[var(--ink)]", "font-semibold"] ==
             classes(html, "h1")

    assert ["text-[15px]/[22px]", "text-[var(--muted)]"] == classes(html, "#l")
    assert ["text-[12.5px]/[18px]", "text-[var(--faint)]"] == classes(html, "#m")
    assert ["font-mono", "text-[var(--ink)]"] == classes(html, "#n")
    assert ["text-[var(--fg)]"] == classes(html, "#f")
  end

  test "a flat kbd is the canvas key" do
    html = render(~H|<.kbd variant="flat">⌘ K</.kbd>|)
    assert "sg-kbd" in classes(html, "kbd")

    refute "shadow-[inset_0_0_0_1px_var(--color-slate-300),0_1px_0_var(--color-slate-300)]" in classes(
             html,
             "kbd"
           )
  end
end
