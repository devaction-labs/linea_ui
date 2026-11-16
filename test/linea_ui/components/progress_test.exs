defmodule LineaUI.Components.ProgressTest do
  use LineaUI.ComponentCase, async: true

  test "daisyUI's progress with its value over max" do
    html = render(~H|<.progress id="p" value={36} max={50} label="Notas" />|)
    assert ["progress", "w-full"] == classes(html, "progress#p")
    assert LazyHTML.attribute(find(html, "#p"), "value") == ["36"]
    assert LazyHTML.attribute(find(html, "#p"), "max") == ["50"]
    assert LazyHTML.attribute(find(html, "#p"), "aria-label") == ["Notas"]
  end

  test "color, soft track and size map to daisyUI's classes" do
    assert "progress-primary" in classes(
             render(~H|<.progress id="p" value={5} color="primary" />|),
             "#p"
           )

    assert "progress-success" in classes(
             render(~H|<.progress id="p" value={5} color="success" />|),
             "#p"
           )

    assert ["progress-warning", "bg-warning/15", "h-3"] --
             classes(
               render(
                 ~H|<.progress id="p" value={5} color="warning" variant="soft" size="lg" />|
               ),
               "#p"
             ) ==
             []

    assert "h-1.5" in classes(render(~H|<.progress id="p" value={5} height="1.5" />|), "#p")
  end

  test "an indeterminate bar has no value" do
    html = render(~H|<.progress id="p" indeterminate />|)
    assert LazyHTML.attribute(find(html, "#p"), "value") == []
  end

  test "the value stays between 0 and max" do
    assert LazyHTML.attribute(find(render(~H|<.progress id="p" value={250} />|), "#p"), "value") ==
             ["100"]

    assert LazyHTML.attribute(find(render(~H|<.progress id="p" value={-5} />|), "#p"), "value") ==
             ["0"]
  end

  test "progress_stack draws one segment per part in the chart colors" do
    html =
      render(~H"""
      <.progress_stack id="s" label="Canais">
        <:segment value={46} label="Balcão" />
        <:segment value={33} />
        <:segment value={21} color="c4" />
      </.progress_stack>
      """)

    assert "sg-stack" in classes(html, "#s")
    assert LazyHTML.attribute(find(html, "#s"), "aria-label") == ["Canais"]

    assert LazyHTML.attribute(find(html, "#s i"), "style") == [
             "width: 46.0%; background: var(--c1)",
             "width: 33.0%; background: var(--c2)",
             "width: 21.0%; background: var(--c4)"
           ]

    assert LazyHTML.attribute(find(html, "#s i"), "title") == ["Balcão"]
  end

  test "variant gradient draws the thin app-gradient meter" do
    html = render(~H|<.progress id="p" value={72} variant="gradient" color="success" />|)

    assert ["sg-meter", "grad"] == classes(html, "#p")
    assert LazyHTML.attribute(find(html, "#p i"), "style") == ["width: 72.0%"]
  end
end
