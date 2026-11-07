defmodule LineaUI.Components.BadgeTest do
  use LineaUI.ComponentCase, async: true

  test "a canvas badge with its text" do
    html = render(~H|<.badge>Novo</.badge>|)
    assert "sg-badge" in classes(html, "span")
    assert String.trim(LazyHTML.text(find(html, "span"))) == "Novo"
  end

  test "color picks the canvas tone" do
    assert "pos" in classes(render(~H|<.badge color="success">x</.badge>|), "span")
    assert "neg" in classes(render(~H|<.badge color="error">x</.badge>|), "span")
    assert "warn" in classes(render(~H|<.badge color="warning">x</.badge>|), "span")
    assert "info" in classes(render(~H|<.badge color="info">x</.badge>|), "span")
    assert "acc" in classes(render(~H|<.badge color="primary">x</.badge>|), "span")
    assert "solid" in classes(render(~H|<.badge color="dark">x</.badge>|), "span")
  end

  test "dot draws the dot of the canvas badge" do
    html = render(~H|<.badge dot>Ativo</.badge>|)
    assert [_] = find(html, "span.dot") |> Enum.to_list()
    assert find(render(~H|<.badge>Ativo</.badge>|), "span.dot") |> Enum.to_list() == []
  end

  test "class and attributes land on the badge" do
    html = render(~H|<.badge id="b" class="ml-2" data-x="1">x</.badge>|)
    assert "ml-2" in classes(html, "#b")
    assert LazyHTML.attribute(find(html, "#b"), "data-x") == ["1"]
  end
end
