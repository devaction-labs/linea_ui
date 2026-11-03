defmodule LineaUI.Components.PageFurnitureTest do
  use LineaUI.ComponentCase, async: true

  describe "image_input" do
    test "a file input, the remove flag and a frame with the picture, filled while it holds one" do
      html = render(~H|<.image_input name="avatar" value="/me.png" />|)

      assert [_] =
               find(
                 html,
                 "#avatar[phx-hook='LineaUI.ImageInput'][data-state=filled][data-initial='/me.png']"
               )
               |> Enum.to_list()

      assert [_] = find(html, "input[type=file][name=avatar]") |> Enum.to_list()
      assert [_] = find(html, "input[type=hidden][name=avatar_remove]") |> Enum.to_list()
      assert [frame] = find(html, "label[data-frame]") |> Enum.to_list()
      assert [style] = LazyHTML.attribute(frame, "style")
      assert style =~ "/me.png"
      assert [_] = find(html, "button[data-remove]") |> Enum.to_list()
    end

    test "empty without a value, with the size and the shape" do
      html = render(~H|<.image_input name="logo" size="xl" shape="rounded" />|)

      assert [_] = find(html, "#logo[data-state=empty]") |> Enum.to_list()
      assert "size-32" in classes(html, "#logo")
      assert "rounded-xl" in classes(html, "label[data-frame]")
    end
  end

  describe "password_input" do
    test "is a password field with a button that flips its type" do
      html = render(~H|<.password_input id="pw" name="password" />|)

      assert [_] = find(html, "input#pw[type=password][name=password]") |> Enum.to_list()
      assert [button] = find(html, "button[aria-controls=pw]") |> Enum.to_list()
      [click] = LazyHTML.attribute(button, "phx-click")
      assert click =~ "toggle_attr"
      assert click =~ "#pw"
      assert [_, _] = find(html, "button svg") |> Enum.to_list()
    end
  end

  describe "sticky" do
    test "a sticky block with the hook, the offset and the classes of the stuck state" do
      html = render(~H|<.sticky id="bar" offset={12} stuck_class="shadow-md">Bar</.sticky>|)

      assert [_] =
               find(
                 html,
                 "#bar[phx-hook='LineaUI.Sticky'][data-offset='12'][data-stuck-class='shadow-md']"
               )
               |> Enum.to_list()

      assert "sticky" in classes(html, "#bar")
    end
  end

  describe "scrollspy" do
    test "a navigation of anchors with the hook and its offset" do
      html =
        render(~H"""
        <.scrollspy id="nav" offset={96}>
          <:item href="#a">A</:item>
          <:item href="#b">B</:item>
        </.scrollspy>
        """)

      assert [_] =
               find(html, "nav#nav[phx-hook='LineaUI.Scrollspy'][data-offset='96']")
               |> Enum.to_list()

      assert ["#a", "#b"] =
               find(html, "a[data-spy-link]") |> Enum.flat_map(&LazyHTML.attribute(&1, "href"))
    end
  end

  describe "context_menu" do
    test "the area, a hidden menu of items and a line above the item that asks for one" do
      html =
        render(~H"""
        <.context_menu id="cm">
          <p id="area">Area</p>
          <:item phx-click="rename">Rename</:item>
          <:item phx-click="delete" tone="danger" divider>Delete</:item>
        </.context_menu>
        """)

      assert [_] = find(html, "#cm[phx-hook='LineaUI.ContextMenu'] #area") |> Enum.to_list()
      assert [_] = find(html, "#cm-menu[role=menu][hidden]") |> Enum.to_list()
      assert [_, _] = find(html, "[role=menuitem]") |> Enum.to_list()
      assert [_] = find(html, "[role=separator]") |> Enum.to_list()
      assert "text-error" in classes(html, "[role=menuitem]:last-of-type")
    end
  end
end
