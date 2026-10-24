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

  test "orientations, scrollbars and focus" do
    html =
      render(
        ~H|<.scroll_area id="s" orientation="horizontal" scrollbar="always" focusable>x</.scroll_area>|
      )

    assert ["overflow-x-auto", "scrollbar-sm", "scrollbar-always"] -- classes(html, "#s") == []
    assert find(html, "#s") |> LazyHTML.attribute("tabindex") == ["0"]

    html = render(~H|<.scroll_area id="s" orientation="both" scrollbar="hidden">x</.scroll_area>|)
    assert ["overflow-auto", "is-scrollbar-hidden"] -- classes(html, "#s") == []
    refute "scrollbar-sm" in classes(html, "#s")
  end
end
