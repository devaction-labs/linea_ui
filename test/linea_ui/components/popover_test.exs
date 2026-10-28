defmodule LineaUI.Components.PopoverTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "LineOne's card with title and arrow, opening right-start with fallbacks" do
    html =
      render(~H"""
      <.popover id="p" class="max-w-xs">
        <:trigger><button>Open</button></:trigger>
        <:title>UI/UX Design</:title>
        <p>Body</p>
      </.popover>
      """)

    assert attr_of(html, "#p", "phx-hook") == ["LineaUI.Popover"]
    assert attr_of(html, "#p", "data-placement") == ["right-start"]
    assert attr_of(html, "#p", "data-fallbacks") == ["bottom,top"]
    assert attr_of(html, "#p", "data-offset") == ["12"]
    assert attr_of(html, "#p", "data-trigger-on") == ["click"]
    assert attr_of(html, "#p-panel", "role") == ["dialog"]
    assert attr_of(html, "#p-panel", "popover") == ["manual"]
    assert "fixed" in classes(html, "#p-panel")
    assert ["rounded-md", "p-4", "max-w-xs"] -- classes(html, "#p-panel .popper-box > div") == []
    assert find(html, "#p-panel h3") |> LazyHTML.text() =~ "UI/UX Design"
    assert [_] = find(html, "[data-popper-arrow] svg") |> Enum.to_list()
  end

  test "the dialog is named by its title or by label, and the card has a default width" do
    html =
      render(~H"""
      <.popover id="p">
        <:trigger><button>Open</button></:trigger>
        <:title>Lessons</:title>
        x
      </.popover>
      """)

    assert attr_of(html, "#p-panel", "aria-labelledby") == ["p-title"]
    assert attr_of(html, "#p-panel", "aria-label") == []
    assert attr_of(html, "#p-title", "id") == ["p-title"]
    assert ["w-68", "max-w-[90vw]"] -- classes(html, "#p-panel .popper-box > div") == []

    html =
      render(~H"""
      <.popover id="q" label="Profile" class="w-48">
        <:trigger><button>Open</button></:trigger>
        x
      </.popover>
      """)

    assert attr_of(html, "#q-panel", "aria-label") == ["Profile"]
    assert attr_of(html, "#q-panel", "aria-labelledby") == []
    assert "w-48" in classes(html, "#q-panel .popper-box > div")
    refute "w-68" in classes(html, "#q-panel .popper-box > div")
  end

  test "hover, placement, no arrow, open and callbacks" do
    html =
      render(~H"""
      <.popover id="p" trigger_on="hover" placement="top" arrow={false} open on_close="gone">
        <:trigger>
          <div>A</div>
        </:trigger>
        x
      </.popover>
      """)

    assert attr_of(html, "#p", "data-trigger-on") == ["hover"]
    assert attr_of(html, "#p", "data-placement") == ["top"]
    assert attr_of(html, "#p", "data-open") == ["true"]
    assert find(html, "[data-popper-arrow]") |> Enum.to_list() == []
    assert attr_of(html, "#p", "data-on-close") |> hd() =~ "gone"
  end
end
