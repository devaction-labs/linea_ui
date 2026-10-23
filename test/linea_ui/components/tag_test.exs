defmodule LineaUI.Components.TagTest do
  use LineaUI.ComponentCase, async: true

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
    assert "[&>*:not(:first-child)]:rounded-l-none" in classes
  end
end
