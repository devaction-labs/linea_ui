defmodule LineaUI.Components.ChipTest do
  use LineaUI.ComponentCase, async: true

  test "a canvas chip with its label and no x when it cannot be removed" do
    html = render(~H|<.chip label="Matriz" />|)
    assert "sg-chip" in classes(html, "span")
    assert "static" in classes(html, "span")
    assert String.trim(LazyHTML.text(find(html, "span"))) == "Matriz"
    assert find(html, "button") |> Enum.to_list() == []
  end

  test "the inner block replaces the label" do
    html = render(~H|<.chip label="x">Simples Nacional</.chip>|)
    assert String.trim(LazyHTML.text(find(html, "span"))) == "Simples Nacional"
  end

  test "on_remove adds the x button that pushes the event with the id" do
    html =
      render(
        ~H|<.chip id="c1" label="Vendedor: Rafael" on_remove="remove" remove_label="Remover" />|
      )

    assert LazyHTML.attribute(find(html, "button.sg-chip-x"), "aria-label") == ["Remover"]
    [click] = LazyHTML.attribute(find(html, "button.sg-chip-x"), "phx-click")
    assert click =~ "remove"
    assert click =~ "c1"
    refute "static" in classes(html, "#c1")
  end

  test "avatar draws the initials in the given color" do
    html = render(~H|<.chip avatar="Marina Costa" avatar_color="#8a5cd6" label="Marina Costa" />|)
    assert "has-av" in classes(html, "span.sg-chip")
    assert LazyHTML.text(find(html, ".sg-chip-av")) =~ "MC"
    assert html =~ "#8a5cd6"
  end
end
