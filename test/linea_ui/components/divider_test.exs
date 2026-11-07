defmodule LineaUI.Components.DividerTest do
  use LineaUI.ComponentCase, async: true

  test "the line takes the canvas --line" do
    html = render(~H|<.divider id="d" />|)

    assert "bg-(--line)" in classes(html, "#d")
  end

  test "align left writes the text as a title before a single line" do
    html = render(~H|<.divider id="d" align="left">Entrega</.divider>|)

    assert find(html, "#d > b") |> LazyHTML.text() =~ "Entrega"
    assert "uppercase" in classes(html, "#d > b")
    assert [_] = find(html, "#d > div") |> Enum.to_list()
  end
end
