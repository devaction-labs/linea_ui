defmodule LineaUI.Components.AuraTest do
  use LineaUI.ComponentCase, async: true

  test "the default aura is the spinning accent ring around its content" do
    html = render(~H|<.aura>
  <p>Dentro</p>
</.aura>|)
    assert classes(html, "div") == ["sg-aura"]
    assert [_] = find(html, "p") |> Enum.to_list()
  end

  test "mode, tone, width, radius and shadow are classes of the canvas" do
    html =
      render(~H"""
      <.aura mode="dual" tone="ai" width="lg" radius="pill" shadow class="w-80">
        <p>x</p>
      </.aura>
      """)

    cls = classes(html, "div")

    for c <- ~w(sg-aura sg-aura-shadow ai dual lg pill w-80), do: assert(c in cls)
  end

  test "glow with a status tone and the thin widths" do
    html = render(~H|<.aura mode="glow" tone="warn" width="xs" radius="r12">
  <p>x</p>
</.aura>|)
    cls = classes(html, "div")
    for c <- ~w(glow warn xs r12), do: assert(c in cls)
    refute "sg-aura-shadow" in cls
  end

  test "global attributes pass through" do
    html = render(~H|<.aura id="a" style="width:300px">
  <p>x</p>
</.aura>|)
    assert find(html, "div") |> LazyHTML.attribute("id") == ["a"]
  end
end
