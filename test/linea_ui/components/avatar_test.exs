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
end
