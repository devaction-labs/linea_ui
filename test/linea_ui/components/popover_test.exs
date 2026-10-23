defmodule LineaUI.Components.PopoverTest do
  use LineaUI.ComponentCase, async: true

  defp attr(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "LineOne's card with title and arrow, opening right-start with fallbacks" do
    html =
      render(~H"""
      <.popover id="p" class="max-w-xs">
        <:trigger><button>Open</button></:trigger>
        <:title>UI/UX Design</:title>
        <p>Body</p>
      </.popover>
      """)

    assert attr(html, "#p", "phx-hook") == ["LineaUI.Popover"]
    assert attr(html, "#p", "data-placement") == ["right-start"]
    assert attr(html, "#p", "data-fallbacks") == ["bottom,top"]
    assert attr(html, "#p", "data-offset") == ["12"]
    assert attr(html, "#p", "data-trigger-on") == ["click"]
    assert attr(html, "#p-panel", "role") == ["dialog"]
    assert ["rounded-md", "p-4", "max-w-xs"] -- classes(html, "#p-panel .popper-box > div") == []
    assert find(html, "#p-panel h3") |> LazyHTML.text() =~ "UI/UX Design"
    assert [_] = find(html, "[data-popper-arrow] svg") |> Enum.to_list()
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

    assert attr(html, "#p", "data-trigger-on") == ["hover"]
    assert attr(html, "#p", "data-placement") == ["top"]
    assert attr(html, "#p", "data-open") == ["true"]
    assert find(html, "[data-popper-arrow]") |> Enum.to_list() == []
    assert attr(html, "#p", "data-on-close") |> hd() =~ "gone"
  end
end
