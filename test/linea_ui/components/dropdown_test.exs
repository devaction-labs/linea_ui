defmodule LineaUI.Components.DropdownTest do
  use LineaUI.ComponentCase, async: true

  defp attr(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "label draws LineOne's button with the chevron; the menu is a popper root" do
    html =
      render(~H"""
      <.dropdown id="dd" label="Dropdown">
        <.dropdown_item href="#">Action</.dropdown_item>
        <.dropdown_separator />
        <.dropdown_item phx-click="go">Go</.dropdown_item>
      </.dropdown>
      """)

    assert attr(html, "#dd", "phx-hook") == ["LineaUI.Dropdown"]
    assert attr(html, "#dd", "data-placement") == ["bottom-start"]
    assert attr(html, "#dd", "data-offset") == ["4"]
    assert find(html, "#dd-button") |> LazyHTML.text() =~ "Dropdown"
    assert [_] = find(html, "#dd-button svg") |> Enum.to_list()
    assert "popper-root" in classes(html, "#dd-menu")
    assert attr(html, "#dd-menu [role=menu]", "aria-labelledby") == ["dd-button"]
    assert [_, _] = find(html, "[role=menuitem][tabindex='-1']") |> Enum.to_list()
    assert [_] = find(html, "a[role=menuitem][href='#']") |> Enum.to_list()
    assert [_] = find(html, "button[role=menuitem][phx-click=go]") |> Enum.to_list()
    assert [_] = find(html, "[role=separator]") |> Enum.to_list()
  end

  test "a custom toggle, placement, open, close_on_select and the menu class" do
    html =
      render(~H"""
      <.dropdown
        id="dd"
        placement="top-end"
        open
        close_on_select={false}
        class="w-72"
        on_open="opened"
      >
        <:toggle><button id="mine">⋮</button></:toggle>
        <.dropdown_item>x</.dropdown_item>
      </.dropdown>
      """)

    assert [_] = find(html, "#dd [data-trigger] #mine") |> Enum.to_list()
    assert find(html, "#dd-button") |> Enum.to_list() == []
    assert attr(html, "#dd", "data-placement") == ["top-end"]
    assert attr(html, "#dd", "data-open") == ["true"]
    assert attr(html, "#dd", "data-close-on-select") == ["false"]
    assert attr(html, "#dd", "data-on-open") |> hd() =~ "opened"
    assert "w-72" in classes(html, "#dd-menu > div")
  end

  test "item colors, media rows, icons and disabled items" do
    html =
      render(~H"""
      <.dropdown_item color="primary">A</.dropdown_item>
      <.dropdown_item color="error"><:icon><svg /></:icon>B</.dropdown_item>
      <.dropdown_item variant="media">C</.dropdown_item>
      <.dropdown_item disabled>D</.dropdown_item>
      """)

    [primary, error, media, disabled] = find(html, "button") |> Enum.to_list()
    assert "hover:bg-primary" in (LazyHTML.attribute(primary, "class") |> hd() |> String.split())

    assert ["text-error", "space-x-3"] --
             (LazyHTML.attribute(error, "class") |> hd() |> String.split()) == []

    assert "py-2" in (LazyHTML.attribute(media, "class") |> hd() |> String.split())
    assert LazyHTML.attribute(disabled, "aria-disabled") == ["true"]
  end

  test "header and search" do
    html =
      render(~H"""
      <.dropdown_header>People</.dropdown_header>
      <.dropdown_search name="q" placeholder="Type username..." phx-debounce="300" />
      """)

    assert find(html, "h3") |> LazyHTML.text() =~ "People"
    assert attr(html, "input", "name") == ["q"]
    assert attr(html, "input", "phx-debounce") == ["300"]
  end
end
