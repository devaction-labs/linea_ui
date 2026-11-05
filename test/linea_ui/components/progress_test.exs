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
end
