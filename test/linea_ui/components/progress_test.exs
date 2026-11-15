defmodule LineaUI.Components.ProgressTest do
  use LineaUI.ComponentCase, async: true

  test "the canvas meter fills to value over max" do
    html = render(~H|<.progress id="p" value={36} max={50} label="Notas" />|)
    assert "sg-meter" in classes(html, "#p")
    assert LazyHTML.attribute(find(html, "#p"), "role") == ["progressbar"]
    assert LazyHTML.attribute(find(html, "#p"), "aria-valuenow") == ["36"]
    assert LazyHTML.attribute(find(html, "#p i"), "style") == ["width: 72.0%"]
  end

  test "the accent color paints the meter in teal" do
    assert "acc" in classes(render(~H|<.progress id="p" value={5} color="primary" />|), "#p")
    refute "acc" in classes(render(~H|<.progress id="p" value={5} />|), "#p")
  end

  test "an indeterminate meter has no width or value" do
    html = render(~H|<.progress id="p" indeterminate />|)
    assert LazyHTML.attribute(find(html, "#p"), "aria-valuenow") == []
    assert "is-indeterminate" in classes(html, "#p i")
  end

  test "the value stays between 0 and 100 percent" do
    assert LazyHTML.attribute(
             find(render(~H|<.progress id="p" value={250} max={100} />|), "#p i"),
             "style"
           ) == ["width: 100.0%"]

    assert LazyHTML.attribute(find(render(~H|<.progress id="p" value={-5} />|), "#p i"), "style") ==
             ["width: 0.0%"]
  end

  test "success, warning, error and info map to the canvas tones" do
    assert "pos" in classes(render(~H|<.progress id="p" value={5} color="success" />|), "#p")
    assert "warn" in classes(render(~H|<.progress id="p" value={5} color="warning" />|), "#p")
    assert "neg" in classes(render(~H|<.progress id="p" value={5} color="error" />|), "#p")
    assert "info" in classes(render(~H|<.progress id="p" value={5} color="info" />|), "#p")
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
