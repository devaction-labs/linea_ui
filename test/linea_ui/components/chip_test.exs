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

  test "a chip with patch, navigate or href is a link" do
    html =
      render(~H"""
      <.chip id="a" patch="/extract?account=1" label="Conta 1" />
      <.chip id="b" navigate="/tasks" avatar="Ana Souza">Tarefas</.chip>
      <.chip id="c" href="/x" label="X" class="mine" />
      """)

    assert "sg-chip" in classes(html, "a#a")
    assert "static" in classes(html, "a#a")
    assert LazyHTML.attribute(find(html, "a#a"), "data-phx-link") == ["patch"]
    assert "has-av" in classes(html, "a#b")
    assert LazyHTML.attribute(find(html, "a#c"), "href") == ["/x"]
    assert "mine" in classes(html, "a#c")
    assert find(html, "button") |> Enum.to_list() == []
  end

  test "remove_patch turns the x into a patch link" do
    html = render(~H|<.chip id="c" label="Aberta" remove_patch="/tasks" remove_label="Tirar" />|)

    assert "sg-chip" in classes(html, "span#c")
    refute "static" in classes(html, "span#c")
    assert LazyHTML.attribute(find(html, "a.sg-chip-x"), "href") == ["/tasks"]
    assert LazyHTML.attribute(find(html, "a.sg-chip-x"), "data-phx-link") == ["patch"]
    assert LazyHTML.attribute(find(html, "a.sg-chip-x"), "aria-label") == ["Tirar"]
    assert find(html, "button") |> Enum.to_list() == []
  end
end
