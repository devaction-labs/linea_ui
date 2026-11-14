defmodule LineaUI.Components.TagTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "a button by default, a link with href or navigate" do
    html =
      render(~H"""
      <.tag id="b">Button</.tag>
      <.tag id="h" href="#" color="primary">Link</.tag>
      <.tag id="n" navigate="/tags" shape="pill">Nav</.tag>
      """)

    assert [_] = find(html, "button#b[type=button].tag") |> Enum.to_list()
    assert [_] = find(html, "a#h[href='#']") |> Enum.to_list()
    assert [_] = find(html, "a#n[href='/tags']") |> Enum.to_list()
    assert "bg-primary" in classes(html, "#h")
    assert "hover:bg-primary-focus" in classes(html, "#h")
    assert "rounded-full" in classes(html, "#n")
  end

  test "soft, bordered and outline variants" do
    html =
      render(~H"""
      <.tag id="s" color="info" variant="soft">x</.tag>
      <.tag id="b" color="error" variant="bordered">x</.tag>
      <.tag id="o" color="warning" variant="outline">x</.tag>
      """)

    assert "bg-info/10" in classes(html, "#s")
    assert "border-error/30" in classes(html, "#b")
    assert "border-warning" in classes(html, "#o")
  end

  test "tag_group squares the inner corners" do
    html =
      render(~H"""
      <.tag_group>
        <.tag>a</.tag><.tag>b</.tag>
      </.tag_group>
      """)

    classes = classes(html, "div")
    assert "-space-x-px" in classes
    assert "inline-flex" in classes
    assert "[&>*:not(:first-child)]:rounded-l-none" in classes
  end

  test "active is a solid primary fill whatever the variant and color" do
    html =
      render(~H"""
      <.tag id="a" variant="soft" color="info" active phx-click="x">A</.tag>
      <.tag id="o" variant="outline" color="error" active phx-click="x">O</.tag>
      <.tag id="b" variant="soft" color="info" phx-click="x">B</.tag>
      <.tag id="c" href="#" active>C</.tag>
      """)

    for id <- ~w(a o) do
      classes = classes(html, "##{id}")
      assert "bg-primary" in classes
      assert "text-white" in classes
      assert "border-primary" in classes
    end

    refute "bg-info/10" in classes(html, "#a")
    refute "text-error" in classes(html, "#o")
    assert [_] = find(html, "#a[aria-pressed=true]") |> Enum.to_list()
    assert "bg-info/10" in classes(html, "#b")
    assert [] = find(html, "#b[aria-pressed]") |> Enum.to_list()
    assert [_] = find(html, "a#c[aria-current=true]") |> Enum.to_list()
  end

  test "count draws a pill inside the tag" do
    html =
      render(~H"""
      <.tag id="a" count={12}>Open</.tag>
      <.tag id="b" href="#" count={0}>Done</.tag>
      <.tag id="c">None</.tag>
      """)

    assert html |> find("#a .tag-count") |> Enum.map(&LazyHTML.text/1) |> Enum.map(&String.trim/1) ==
             ["12"]

    assert [_] = find(html, "a#b .tag-count") |> Enum.to_list()
    assert [] = find(html, "#c .tag-count") |> Enum.to_list()
  end

  test "the flat variant is the canvas tag, the accent tint when active" do
    html =
      render(~H"""
      <.tag id="f" variant="flat">Tintas</.tag>
      <.tag id="a" variant="flat" active>Todos</.tag>
      """)

    assert "sg-tag" in classes(html, "#f")
    refute "on" in classes(html, "#f")
    assert ["sg-tag", "on"] -- classes(html, "#a") == []
    refute "bg-primary" in classes(html, "#a")
    assert attr_of(html, "#a", "aria-pressed") == ["true"]
  end

  test "tint paints the tag in a colour of its own" do
    html = render(~H|<.tag id="t" variant="flat" tint="#8a5cd6">Novo cliente</.tag>|)
    assert "tag-tint" in classes(html, "#t")
    assert "sg-tag" in classes(html, "#t")
    assert attr_of(html, "#t", "style") == ["--tag-tint:#8a5cd6"]
  end

  test "as=span and static render a non-interactive span with the same classes" do
    html =
      render(~H"""
      <.tag id="a" as="span" variant="flat" href="#">teste</.tag>
      <.tag id="b" static variant="flat" count={2}>teste</.tag>
      <.tag id="c" variant="flat">teste</.tag>
      """)

    assert [_] = find(html, "span#a.sg-tag") |> Enum.to_list()
    assert [_] = find(html, "span#b.sg-tag") |> Enum.to_list()
    assert [_] = find(html, "button#c.sg-tag") |> Enum.to_list()
    assert attr_of(html, "#a", "href") == []
    assert attr_of(html, "#a", "type") == []
    assert find(html, "#b .tag-count") |> Enum.count() == 1
  end
end
