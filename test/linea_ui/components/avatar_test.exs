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

    assert [
             "is-initial",
             "font-inter",
             "font-semibold",
             "uppercase",
             "rounded-full",
             "text-[17px]" | _
           ] =
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
    assert "text-[10px]" in classes(html, "#b > div")
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

  test "avatar_group spread and label" do
    assigns = %{}

    out =
      rendered_to_string(~H"""
      <.avatar_group spread label="7 people"><.avatar src="/a.jpg" ring /></.avatar_group>
      """)

    assert out =~ ~s(role="group")
    assert out =~ ~s(aria-label="7 people")
    assert out =~ ~s(tabindex="0")
    assert out =~ "hover:space-x-1"

    plain =
      rendered_to_string(~H"""
      <.avatar_group><.avatar src="/a.jpg" /></.avatar_group>
      """)

    refute plain =~ "tabindex"
    refute plain =~ "role="
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

  test "a name gives the initials, the alt and a color that never changes" do
    html =
      render(~H"""
      <.avatar id="a" name="Ana Souza" color="auto" />
      <.avatar id="b" name="Ana Souza" color="auto" />
      <.avatar id="c" name="Hospital Dom Pedro de Alcântara" />
      <.avatar id="d" name="Madonna" src="/m.jpg" />
      """)

    assert find(html, "#a > div") |> LazyHTML.text() =~ "AS"
    assert classes(html, "#a > div") == classes(html, "#b > div")
    assert find(html, "#c > div") |> LazyHTML.text() =~ "HA"
    assert "bg-slate-200" in classes(html, "#c > div")
    assert LazyHTML.attribute(find(html, "#d > img"), "alt") == ["Madonna"]

    colors =
      for name <- ~w(Ana Carlos Juliana Marcos Patricia Beto Lia Rui Zeca) do
        assigns = %{name: name}

        Phoenix.LiveViewTest.rendered_to_string(~H|<.avatar name={@name} color="auto" />|)
        |> then(&classes(&1, "div.avatar > div"))
        |> Enum.find(&String.starts_with?(&1, "bg-"))
      end

    assert length(Enum.uniq(colors)) > 2
  end

  test "the pixel sizes are the canvas sizes" do
    html =
      render(~H"""
      <.avatar id="a" initials="a" size="24" />
      <.avatar id="b" initials="a" size="32" />
      <.avatar id="c" initials="a" size="40" />
      <.avatar id="d" initials="a" size="48" />
      <.avatar id="e" initials="a" size="64" />
      """)

    for {id, size} <- [a: "size-6", b: "size-8", c: "size-10", d: "size-12", e: "size-16"] do
      assert size in classes(html, "##{id}")
    end
  end

  test "a presence is a dot at the bottom right" do
    html =
      render(~H"""
      <.avatar id="a" initials="a" status="online" />
      <.avatar id="b" initials="a" status="away" />
      <.avatar id="c" initials="a" status="busy" />
      <.avatar id="d" initials="a" status="offline" />
      <.avatar id="e" initials="a" status="online" status_position="top-left" />
      """)

    assert "bg-success-focus" in classes(html, "#a > div:last-child")
    assert "-bottom-px" in classes(html, "#a > div:last-child")
    assert "bg-warning-focus" in classes(html, "#b > div:last-child")
    assert "bg-error-focus" in classes(html, "#c > div:last-child")
    assert "bg-slate-400" in classes(html, "#d > div:last-child")
    assert "left-0" in classes(html, "#e > div:last-child")
  end

  test "kinds draw a company, a customer, a supplier, the assistant and the invite" do
    html =
      render(~H"""
      <.avatar id="a" kind="company" name="Farmácia Signetum" />
      <.avatar id="b" kind="customer" initials="df" />
      <.avatar id="c" kind="supplier" initials="nf" />
      <.avatar id="d" kind="assistant" />
      <.avatar id="e" kind="invite" />
      """)

    assert "bg-navy-900" in classes(html, "#a > div")
    assert "rounded-[10px]" in classes(html, "#a > div")
    assert find(html, "#a > div") |> LazyHTML.text() =~ "FS"
    assert "bg-success-focus" in classes(html, "#b > div")
    assert "bg-warning-focus" in classes(html, "#c > div")
    assert "from-primary" in classes(html, "#d > div")
    assert "rounded-full" in classes(html, "#d > div")
    assert [_] = find(html, "#d > div > svg") |> Enum.to_list()
    assert "border-[1.5px]" in classes(html, "#e > div")
    assert [_] = find(html, "#e > div > svg") |> Enum.to_list()
  end

  test "a group closes with the +N of the people that did not fit" do
    html =
      render(~H"""
      <.avatar_group id="g" more={3} size="32">
        <.avatar name="Ana Souza" size="32" ring />
      </.avatar_group>
      """)

    assert [_, _] = find(html, "#g > .avatar") |> Enum.to_list()
    assert "size-8" in classes(html, "#g > .avatar:last-child")
    assert find(html, "#g > .avatar:last-child") |> LazyHTML.text() =~ "+3"

    assert [_] =
             find(
               render(~H|<.avatar_group id="h"><.avatar initials="a" /></.avatar_group>|),
               "#h > .avatar"
             )
             |> Enum.to_list()
  end
end
