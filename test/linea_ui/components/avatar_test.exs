defmodule LineaUI.Components.AvatarTest do
  use LineaUI.ComponentCase, async: true

  test "an image in a circle, sized" do
    html =
      render(~H"""
      <.avatar src="/a.jpg" alt="Jane" size="lg" />
      """)

    assert "size-16" in classes(html, "div.avatar")
    assert [_] = find(html, "img.rounded-full[src='/a.jpg'][alt=Jane]") |> Enum.to_list()
  end

  test "initials take the color, variant and shape" do
    html =
      render(~H"""
      <.avatar id="a" initials="jd" color="primary" size="md" />
      <.avatar id="b" initials="jd" color="info" variant="soft" shape="square" />
      <.avatar id="c" initials="jd" color="error" variant="bordered" shape="squircle" />
      """)

    assert ["is-initial", "uppercase", "rounded-full", "text-base" | _] =
             classes(html, "#a > div")

    assert "bg-primary" in classes(html, "#a > div")
    assert "bg-info/10" in classes(html, "#b > div")
    assert "rounded-lg" in classes(html, "#b > div")
    assert "is-squircle" in classes(html, "#c > div")
    assert "border-error/30" in classes(html, "#c > div")
  end

  test "the inner block replaces the initials" do
    html =
      render(~H"""
      <.avatar variant="skeleton"><svg id="icon"></svg></.avatar>
      """)

    assert [_] = find(html, ".is-initial > svg#icon") |> Enum.to_list()
    assert "text-white" in classes(html, ".is-initial")
  end

  test "a status dot with its position, size and ping" do
    html =
      render(~H"""
      <.avatar src="/a.jpg" size="xl" status="success" status_position="bottom-left" ping />
      """)

    dot = classes(html, "div.avatar > div")
    assert "bg-success" in dot
    assert "bottom-0" in dot
    assert "left-0" in dot
    assert "m-1" in dot
    assert [_] = find(html, "span.animate-ping") |> Enum.to_list()
  end

  test "a gradient ring wraps the avatar" do
    html =
      render(~H"""
      <.avatar src="/a.jpg" gradient="sky-blue" size="lg" />
      """)

    assert "from-sky-400" in classes(html, "div")
    assert "size-16" in classes(html, "div")
    assert [_] = find(html, "div > div.avatar > img") |> Enum.to_list()
  end

  test "avatar_group stacks rings" do
    html =
      render(~H"""
      <.avatar_group pulse><.avatar src="/a.jpg" ring /></.avatar_group>
      """)

    assert "-space-x-2" in classes(html, "div")
    assert "animate-pulse" in classes(html, "div")
    assert "ring-2" in classes(html, "img")
  end

  test "extra sizes cover size-6, size-7 and size-9" do
    html =
      render(~H"""
      <.avatar id="a" src="/a.jpg" size="3xs" />
      <.avatar id="b" initials="jd" size="2xs" />
      <.avatar id="c" src="/a.jpg" size="xs-plus" status="success" />
      """)

    assert "size-6" in classes(html, "#a")
    assert "size-7" in classes(html, "#b")
    assert "text-xs-plus" in classes(html, "#b > div")
    assert "size-9" in classes(html, "#c")
    assert "size-2.5" in classes(html, "#c > div")
  end

  test "ring takes a width and a color" do
    html =
      render(~H"""
      <.avatar id="a" src="/a.jpg" ring={1} ring_color="primary" />
      <.avatar id="b" initials="jd" ring="4" />
      <.avatar id="c" src="/a.jpg" ring />
      <.avatar id="d" src="/a.jpg" />
      """)

    assert "ring-1" in classes(html, "#a > img")
    assert "ring-primary" in classes(html, "#a > img")
    assert "dark:ring-accent" in classes(html, "#a > img")
    assert "ring-4" in classes(html, "#b > div")
    assert "ring-white" in classes(html, "#b > div")
    assert "ring-2" in classes(html, "#c > img")
    refute Enum.any?(classes(html, "#d > img"), &String.starts_with?(&1, "ring"))
  end

  test "face_class reaches the face, class the wrapper" do
    html =
      render(~H"""
      <.avatar id="a" src="/a.jpg" class="-mt-12" face_class="border-2 border-white" />
      <.avatar id="b" initials="jd" face_class="border-2" />
      <.avatar id="c" src="/a.jpg" gradient="sky-blue" face_class="shadow-lg" />
      """)

    assert "-mt-12" in classes(html, "#a")
    refute "border-2" in classes(html, "#a")
    assert "border-white" in classes(html, "#a > img")
    assert "border-2" in classes(html, "#b > div")
    assert "shadow-lg" in classes(html, "#c img")
  end

  test "an online dot on a plain image sits at the bottom right, and false hides it" do
    html =
      render(~H"""
      <.avatar id="a" src="/a.jpg" status="primary" status_position="bottom-right" />
      <.avatar id="b" src="/a.jpg" status={false} />
      """)

    assert "bottom-0" in classes(html, "#a > div")
    assert "right-0" in classes(html, "#a > div")
    assert "bg-primary" in classes(html, "#a > div")
    assert [] = find(html, "#b > div") |> Enum.to_list()
  end

  test "avatar_group overlap" do
    html =
      render(~H"""
      <.avatar_group id="a" overlap="3"><.avatar src="/a.jpg" /></.avatar_group>
      """)

    assert "-space-x-3" in classes(html, "#a")
    refute "-space-x-2" in classes(html, "#a")
  end

  test "a neutral status is LineOne's slate offline dot" do
    html =
      render(~H"""
      <.avatar src="/a.jpg" status="neutral" status_position="bottom-right" />
      """)

    assert "bg-slate-300" in classes(html, "div.avatar > div")
  end
end
