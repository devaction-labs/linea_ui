defmodule LineaUI.Components.DividerTest do
  use LineaUI.ComponentCase, async: true

  test "daisyUI's divider, vertical as divider-horizontal" do
    assert "divider" in classes(render(~H|<.divider id="d" />|), "#d")

    assert ["divider", "divider-horizontal"] --
             classes(render(~H|<.divider id="d" orientation="vertical" />|), "#d") == []
  end

  test "align left writes the text as a title before a single line" do
    html = render(~H|<.divider id="d" align="left">Entrega</.divider>|)

    assert find(html, "#d > b") |> LazyHTML.text() =~ "Entrega"
    assert ["divider-start", "uppercase"] -- classes(html, "#d") == []
  end
end
