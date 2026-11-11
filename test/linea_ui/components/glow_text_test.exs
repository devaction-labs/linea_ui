defmodule LineaUI.Components.GlowTextTest do
  use LineaUI.ComponentCase, async: true

  defp text(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

  test "a span with the glow class by default" do
    html = render(~H|<.glow_text id="g">Hello</.glow_text>|)

    assert text(html, "span#g.sg-glow-text") == ["Hello"]
    refute "warm" in classes(html, "span#g")
  end

  test "warm tone, another tag, class and rest" do
    html =
      render(~H|<.glow_text as="h1" tone="warm" class="mt-2" data-x="1">Hi</.glow_text>|)

    assert text(html, "h1.sg-glow-text.warm.mt-2[data-x='1']") == ["Hi"]
  end

  test "stylesheet slows the animation under reduced motion" do
    css = File.read!("assets/css/parts/canvas-glow-text.css")
    assert css =~ "prefers-reduced-motion:reduce"
  end
end
