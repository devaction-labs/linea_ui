defmodule LineaUI.Components.SkeletonTest do
  use LineaUI.ComponentCase, async: true

  test "both variants are daisyUI's skeleton" do
    html = render(~H|<.skeleton variant="lineone" class="h-3 w-full" />|)
    assert "skeleton" in classes(html, "div")
  end

  test "the canvas variant takes its shape" do
    html = render(~H|<.skeleton variant="canvas" shape="circle" class="size-8" />|)
    classes = classes(html, "div")
    assert "skeleton" in classes
    assert "rounded-full" in classes
    assert "size-8" in classes
    assert LazyHTML.attribute(find(html, "div"), "aria-hidden") == ["true"]
  end
end
