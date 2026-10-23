defmodule LineaUI.Components.DisclosureTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "collapse is a details element wired to its hook" do
    html =
      render(~H"""
      <.collapse id="c" open on_open="opened">
        <:trigger class="py-4">Title</:trigger>
        Body
      </.collapse>
      """)

    assert attr_of(html, "details#c", "phx-hook") == ["LineaUI.Collapse"]
    assert attr_of(html, "#c", "open") == [""]
    assert attr_of(html, "#c", "data-open") == ["true"]
    assert "py-4" in classes(html, "#c > summary")
    assert find(html, "#c > .ac-panel") |> LazyHTML.text() =~ "Body"
    assert attr_of(html, "#c", "data-on-open") |> hd() =~ "opened"
  end

  test "accordion styles and exclusivity" do
    html =
      render(~H"""
      <.accordion id="a" variant="primary">
        <.accordion_item id="a1" title="Item 1" open>One</.accordion_item>
        <.accordion_item id="a2" title="Item 2">Two</.accordion_item>
      </.accordion>
      """)

    assert attr_of(html, "#a", "data-variant") == ["primary"]
    assert attr_of(html, "#a", "data-exclusive") == ["true"]
    assert "border-primary" in classes(html, "#a")
    assert [_, _] = find(html, "#a > details.ac") |> Enum.to_list()
    assert find(html, "#a1 summary.ac-trigger") |> LazyHTML.text() =~ "Item 1"
    assert attr_of(html, "#a1", "open") == [""]
    assert attr_of(html, "#a2", "open") == []
  end

  test "multiple lets items open independently" do
    html = render(~H|<.accordion id="a" multiple variant="divided">
  <.accordion_item id="i">x</.accordion_item>
</.accordion>|)
    assert attr_of(html, "#a", "data-exclusive") == ["false"]
    assert "space-y-4" in classes(html, "#a")
  end

  test "an item with a header puts the chevron in a button of its own" do
    html =
      render(~H"""
      <.accordion_item id="i" toggle_label="Open Simon">
        <:header>Simon</:header>
        x
      </.accordion_item>
      """)

    assert "pointer-events-none" in classes(html, "#i > summary")
    assert attr_of(html, "#i .ac-trigger", "aria-label") == ["Open Simon"]
    assert find(html, "#i > summary") |> LazyHTML.text() =~ "Simon"
  end
end
