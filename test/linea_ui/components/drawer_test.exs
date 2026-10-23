defmodule LineaUI.Components.DrawerTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "a closed left drawer with its backdrop, wired to the dialog hook" do
    html = render(~H|<.drawer id="d">Menu</.drawer>|)

    assert attr_of(html, "#d", "phx-hook") == ["LineaUI.Dialog"]
    assert attr_of(html, "#d", "data-kind") == ["drawer"]
    assert attr_of(html, "#d", "data-lock") == ["false"]
    assert ["drawer-overlay", "hidden"] -- classes(html, "#d > [data-backdrop]") == []

    assert ["drawer-content", "hidden", "left-0", "w-72"] -- classes(html, "#d > div:last-child") ==
             []

    refute "drawer-right" in classes(html, "#d")
  end

  test "right side, no overlay, open, a frame class and a panel class" do
    html =
      render(
        ~H|<.drawer id="d" side="right" overlay={false} open class="w-80" panel_class="p-4">x</.drawer>|
      )

    assert "drawer-right" in classes(html, "#d")
    assert "right-0" in classes(html, "#d > div")
    assert find(html, "#d [data-backdrop]") |> Enum.to_list() == []
    assert attr_of(html, "#d", "data-open") == ["true"]
    frame = classes(html, ".drawer-content")
    assert "w-80" in frame
    refute "w-72" in frame
    assert "p-4" in classes(html, "#d-panel")
  end

  test "on_close with a target pushes to it" do
    html = render(~H|<.drawer id="d" on_close="closed" target="#comp">x</.drawer>|)
    assert attr_of(html, "#d", "data-on-close") |> hd() =~ ~s("target":"#comp")
  end
end
