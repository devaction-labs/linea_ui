defmodule LineaUI.Components.ButtonTest do
  use LineaUI.ComponentCase, async: true

  test "a neutral solid button by default, typed as a plain button" do
    html = render(~H"<.button>Go</.button>")
    assert [button] = find(html, "button[type=button]") |> Enum.to_list()
    assert String.trim(LazyHTML.text(button)) == "Go"
    assert "bg-slate-150" in classes(html, "button")
  end

  test "color, variant, size and shape pick LineOne's classes, and class overrides them" do
    html =
      render(~H"""
      <.button color="primary" variant="outline" size="sm" shape="pill" class="px-8">Go</.button>
      """)

    classes = classes(html, "button")
    assert "border-primary" in classes
    assert "dark:text-accent-light" in classes
    assert "h-8" in classes
    assert "rounded-full" in classes
    assert "px-8" in classes
    refute "px-4" in classes
    refute "rounded-md" in classes
  end

  test "icon makes a square button" do
    assert "size-9" in classes(render(~H"<.button icon aria-label='x'>x</.button>"), "button")
  end

  test "navigate renders a link, and disabled marks it" do
    html = render(~H"<.button navigate=\"/orders\" disabled>Orders</.button>")
    assert [_] = find(html, "a[href='/orders'][aria-disabled=true]") |> Enum.to_list()
  end
end
