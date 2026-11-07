defmodule LineaUI.Components.SkeletonTest do
  use LineaUI.ComponentCase, async: true

  test "the default skeleton is LineOne's waving block" do
    html = render(~H|<.skeleton class="h-3 w-full" />|)
    assert "skeleton" in classes(html, "div")
    refute "sg-skel" in classes(html, "div")
  end

  test "the canvas variant renders sg-skel with its shape" do
    html = render(~H|<.skeleton variant="canvas" shape="circle" class="size-8" />|)
    classes = classes(html, "div")
    assert "sg-skel" in classes
    assert "circle" in classes
    assert "size-8" in classes
    assert LazyHTML.attribute(find(html, "div"), "aria-hidden") == ["true"]
  end
end
