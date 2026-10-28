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

  test "the primary accordion style takes any theme color" do
    html =
      render(~H"""
      <.accordion id="a" variant="primary">
        <.accordion_item id="a1" title="T">x</.accordion_item>
      </.accordion>
      <.accordion id="b" variant="primary" color="warning">
        <.accordion_item id="b1" title="T">x</.accordion_item>
      </.accordion>
      <.accordion id="c" variant="bordered" color="info">
        <.accordion_item id="c1" title="T">x</.accordion_item>
      </.accordion>
      """)

    assert [
             "border-primary",
             "divide-[color-mix(in_oklab,var(--color-primary)_55%,white)]",
             "dark:border-accent"
           ] -- classes(html, "#a") ==
             []

    assert [_] = find(html, "#a[data-color=primary]") |> Enum.to_list()

    assert [
             "border-warning",
             "divide-[color-mix(in_oklab,var(--color-warning)_55%,white)]",
             "dark:border-warning"
           ] -- classes(html, "#b") ==
             []

    assert [_] = find(html, "#b[data-color=warning]") |> Enum.to_list()
    refute "border-info" in classes(html, "#c")
    assert [] = find(html, "#c[data-color]") |> Enum.to_list()
  end

  test "collapse chevron rotates with the open state" do
    html =
      render(~H"""
      <.collapse id="a" chevron="down"><:trigger>A</:trigger>x</.collapse>
      <.collapse id="b" chevron="right" chevron_class="size-4"><:trigger>B</:trigger>x</.collapse>
      <.collapse id="c"><:trigger>C</:trigger>x</.collapse>
      """)

    assert "group/collapse" in classes(html, "#a")
    assert ["flex", "justify-between"] -- classes(html, "#a > summary") == []
    assert "group-open/collapse:rotate-180" in classes(html, "#a > summary > svg")
    assert "group-open/collapse:rotate-90" in classes(html, "#b > summary > svg")
    assert "size-4" in classes(html, "#b > summary > svg")
    assert [] = find(html, "#c svg") |> Enum.to_list()
    refute "group/collapse" in classes(html, "#c")
    assert ["size-4", "text-slate-400"] -- classes(html, "#a > summary > svg") == []
  end

  test "collapse variant is a data attribute and the panel takes a class" do
    html =
      render(~H"""
      <.collapse id="a" variant="framed" panel_class="px-6"><:trigger>A</:trigger>x</.collapse>
      <.collapse id="b"><:trigger>B</:trigger>x</.collapse>
      """)

    assert find(html, "#a") |> LazyHTML.attribute("data-variant") == ["framed"]
    assert find(html, "#b") |> LazyHTML.attribute("data-variant") == []
    assert ["ac-panel", "px-6"] -- classes(html, "#a > .ac-panel") == []
    assert classes(html, "#b > .ac-panel") == ["ac-panel"]
  end
end
