defmodule LineaUI.Components.DropdownTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "label draws LineOne's button with the chevron; the menu is a popper root" do
    html =
      render(~H"""
      <.dropdown id="dd" label="Dropdown">
        <.dropdown_item href="#">Action</.dropdown_item>
        <.dropdown_separator />
        <.dropdown_item phx-click="go">Go</.dropdown_item>
      </.dropdown>
      """)

    assert attr_of(html, "#dd", "phx-hook") == ["LineaUI.Dropdown"]
    assert attr_of(html, "#dd", "data-placement") == ["bottom-start"]
    assert attr_of(html, "#dd", "data-offset") == ["4"]
    assert find(html, "#dd-button") |> LazyHTML.text() =~ "Dropdown"
    assert [_] = find(html, "#dd-button svg") |> Enum.to_list()
    assert "popper-root" in classes(html, "#dd-menu")
    assert "fixed" in classes(html, "#dd-menu")
    assert attr_of(html, "#dd-menu", "popover") == ["manual"]
    assert attr_of(html, "#dd-menu [role=menu]", "aria-labelledby") == ["dd-button"]
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
    assert attr_of(html, "#dd", "data-placement") == ["top-end"]
    assert attr_of(html, "#dd", "data-open") == ["true"]
    assert attr_of(html, "#dd", "data-close-on-select") == ["false"]
    assert attr_of(html, "#dd", "data-on-open") |> hd() =~ "opened"
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
    assert attr_of(html, "input", "name") == ["q"]
    assert attr_of(html, "input", "phx-debounce") == ["300"]
  end

  test "toggle_icon draws the flat round dots button" do
    html =
      render(~H"""
      <.dropdown id="a" toggle_icon="dots" toggle_class="-mr-2 size-7">
        <.dropdown_item href="#">Action</.dropdown_item>
      </.dropdown>
      <.dropdown id="b" toggle_icon="dots-vertical" shape="square" toggle_label="Row actions">
        <.dropdown_item href="#">Action</.dropdown_item>
      </.dropdown>
      """)

    a = classes(html, "#a-button")
    assert ["text-current", "rounded-full", "size-7", "-mr-2"] -- a == []
    refute "size-8" in a
    assert attr_of(html, "#a-button", "aria-label") == ["Menu"]
    assert [_] = find(html, "#a-button svg path[d^='M5 12h.01']") |> Enum.to_list()
    assert "rounded-none" in classes(html, "#b-button")
    assert attr_of(html, "#b-button", "aria-label") == ["Row actions"]
    assert [_] = find(html, "#b-button svg path[d^='M12 5v.01']") |> Enum.to_list()
    assert attr_of(html, "#a-menu [role=menu]", "aria-labelledby") == ["a-button"]
  end

  test "shape applies to the label button, rounded by default" do
    html =
      render(~H"""
      <.dropdown id="a" label="A">
        <.dropdown_item href="#">x</.dropdown_item>
      </.dropdown>
      <.dropdown id="b" label="B" shape="square">
        <.dropdown_item href="#">x</.dropdown_item>
      </.dropdown>
      <.dropdown id="c" label="C" shape="pill">
        <.dropdown_item href="#">x</.dropdown_item>
      </.dropdown>
      """)

    refute "rounded-full" in classes(html, "#a-button")
    refute "rounded-none" in classes(html, "#a-button")
    assert "rounded-none" in classes(html, "#b-button")
    assert "rounded-full" in classes(html, "#c-button")
  end

  test "a submenu: an item that opens a nested menu to its side" do
    html =
      render(~H"""
      <.dropdown id="dd" label="Menu">
        <.dropdown_item>Edit</.dropdown_item>
        <.dropdown_submenu id="move" label="Move to" class="w-48">
          <:icon><i id="ic"></i></:icon>
          <.dropdown_item id="archive">Archive</.dropdown_item>
        </.dropdown_submenu>
      </.dropdown>
      """)

    assert [sub] = find(html, "#dd [role=menu] > #move[data-submenu]") |> Enum.to_list()
    assert LazyHTML.attribute(sub, "data-open") == ["false"]
    assert LazyHTML.attribute(sub, "data-placement") == ["right"]
    assert LazyHTML.attribute(sub, "phx-mounted") |> hd() =~ "data-open"

    trigger = find(html, "#move-trigger")
    assert LazyHTML.attribute(trigger, "role") == ["menuitem"]
    assert LazyHTML.attribute(trigger, "aria-haspopup") == ["menu"]
    assert LazyHTML.attribute(trigger, "aria-expanded") == ["false"]
    assert LazyHTML.attribute(trigger, "aria-controls") == ["move-menu"]
    assert LazyHTML.attribute(trigger, "data-submenu-trigger") == [""]
    assert LazyHTML.text(trigger) =~ "Move to"
    assert [_] = find(html, "#move-trigger > #ic") |> Enum.to_list()
    assert [_] = find(html, "#move-trigger > svg") |> Enum.to_list()

    assert "linea-submenu" in classes(html, "#move > [data-submenu-panel]")
    menu = find(html, "#move [data-submenu-panel] > #move-menu")
    assert LazyHTML.attribute(menu, "role") == ["menu"]
    assert LazyHTML.attribute(menu, "aria-labelledby") == ["move-trigger"]
    assert "w-48" in classes(html, "#move-menu")
    assert [_] = find(html, "#move-menu > #archive") |> Enum.to_list()
  end

  test "a submenu opening left, disabled, with a generated id" do
    html =
      render(~H"""
      <.dropdown_submenu label="More" placement="left" disabled trigger_class="text-error">
        <.dropdown_item>X</.dropdown_item>
      </.dropdown_submenu>
      """)

    assert [id] = find(html, "[data-submenu]") |> LazyHTML.attribute("id")
    assert id =~ "submenu"
    assert find(html, "[data-submenu]") |> LazyHTML.attribute("data-side") == ["left"]
    trigger = find(html, "[data-submenu-trigger]")
    assert LazyHTML.attribute(trigger, "disabled") == [""]
    assert LazyHTML.attribute(trigger, "aria-disabled") == ["true"]
    assert ["opacity-60", "text-error"] -- classes(html, "[data-submenu-trigger]") == []
  end

  test "a link item forwards target, rel and download" do
    html =
      render(~H"""
      <.dropdown id="dd" label="Files">
        <.dropdown_item href="/danfe.pdf" target="_blank" rel="noopener noreferrer">
          DANFE
        </.dropdown_item>
        <.dropdown_item href="/nfe.xml" download="nfe.xml">XML</.dropdown_item>
      </.dropdown>
      """)

    assert [_] =
             find(
               html,
               "a[role=menuitem][href='/danfe.pdf'][target=_blank][rel='noopener noreferrer']"
             )
             |> Enum.to_list()

    assert [_] =
             find(html, "a[role=menuitem][href='/nfe.xml'][download='nfe.xml']") |> Enum.to_list()
  end
end
