defmodule LineaUI.Components.ScrollAreaTest do
  use LineaUI.ComponentCase, async: true

  test "a vertical box with LineOne's thin scrollbar" do
    html = render(~H|<.scroll_area class="max-h-64" id="s">
  <p>x</p>
</.scroll_area>|)

    assert ["scrollbar-sm", "overflow-y-auto", "overflow-x-hidden", "max-h-64"] --
             classes(html, "#s") == []

    assert find(html, "#s") |> LazyHTML.attribute("tabindex") == []
    assert [_] = find(html, "#s[data-scroll-area] > p") |> Enum.to_list()
  end

  test "no hook unless it sticks to the bottom" do
    html = render(~H|<.scroll_area id="s">x</.scroll_area>|)

    assert find(html, "#s") |> LazyHTML.attribute("phx-hook") == []
  end

  test "stick_bottom adds the hook on the box" do
    html = render(~H|<.scroll_area id="messages" stick_bottom class="h-96">x</.scroll_area>|)

    assert find(html, "#messages") |> LazyHTML.attribute("phx-hook") == ["LineaUI.ScrollBottom"]
    assert ["scrollbar-sm", "overflow-y-auto", "h-96"] -- classes(html, "#messages") == []
  end

  test "orientations, scrollbars and focus" do
    html =
      render(
        ~H|<.scroll_area id="s" orientation="horizontal" scrollbar="always" focusable>x</.scroll_area>|
      )

    assert ["overflow-x-auto", "scrollbar-sm", "scrollbar-always"] -- classes(html, "#s") == []
    assert find(html, "#s") |> LazyHTML.attribute("tabindex") == ["0"]
    assert find(html, "#s") |> LazyHTML.attribute("role") == []

    html = render(~H|<.scroll_area id="s" focusable label="Notes">x</.scroll_area>|)
    assert find(html, "#s") |> LazyHTML.attribute("role") == ["region"]
    assert find(html, "#s") |> LazyHTML.attribute("aria-label") == ["Notes"]

    html = render(~H|<.scroll_area id="s" label="Notes">x</.scroll_area>|)
    assert find(html, "#s") |> LazyHTML.attribute("role") == []
    assert find(html, "#s") |> LazyHTML.attribute("aria-label") == []

    html = render(~H|<.scroll_area id="s" orientation="both" scrollbar="hidden">x</.scroll_area>|)
    assert ["overflow-auto", "is-scrollbar-hidden"] -- classes(html, "#s") == []
    refute "scrollbar-sm" in classes(html, "#s")
  end
end
