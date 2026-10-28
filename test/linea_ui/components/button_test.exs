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
    assert "size-9" in classes(render(~H(<.button icon aria-label="x">x</.button>)), "button")
  end

  test "navigate renders a link, and disabled marks it" do
    html = render(~H(<.button navigate="/orders" disabled>Orders</.button>))
    assert [_] = find(html, "a[href='/orders'][aria-disabled=true]") |> Enum.to_list()
  end

  test "current color inherits the parent's text" do
    html =
      render(~H"""
      <.button id="a" variant="flat" color="current">A</.button>
      <.button id="b" variant="soft" color="current">B</.button>
      <.button id="c" variant="outline" color="current">C</.button>
      """)

    assert "text-current" in classes(html, "#a")
    assert "dark:text-current" in classes(html, "#a")
    assert "hover:bg-slate-300/20" in classes(html, "#a")
    assert "text-current" in classes(html, "#b")
    assert "border-current" in classes(html, "#c")
  end

  test "white color for colored surfaces" do
    html =
      render(~H"""
      <.button id="a" variant="flat" color="white">A</.button>
      <.button id="b" color="white">B</.button>
      <.button id="c" variant="outline" color="white">C</.button>
      """)

    assert ["text-white", "hover:bg-white/20"] -- classes(html, "#a") == []
    assert ["bg-white", "text-slate-800"] -- classes(html, "#b") == []
    assert ["border-white", "text-white"] -- classes(html, "#c") == []
  end

  test "glass is translucent white whatever the color" do
    html =
      render(~H"""
      <.button id="a" variant="glass">A</.button>
      <.button id="b" variant="glass" color="primary" size="sm">B</.button>
      """)

    for id <- ["#a", "#b"] do
      assert ["bg-white/20", "border-white/10", "text-white", "hover:bg-white/30"] --
               classes(html, id) == []
    end

    refute "bg-primary" in classes(html, "#b")
    assert "h-8" in classes(html, "#b")
  end
end
