defmodule LineaUI.Components.BadgeTest do
  use LineaUI.ComponentCase, async: true

  test "a neutral solid badge by default" do
    html = render(~H"<.badge>Default</.badge>")
    assert [badge] = find(html, "span.badge") |> Enum.to_list()
    assert String.trim(LazyHTML.text(badge)) == "Default"
    assert "bg-slate-150" in classes(html, "span")
  end

  test "colors, variants and shapes" do
    html =
      render(~H"""
      <.badge id="s" color="success" shape="pill">Paid</.badge>
      <.badge id="g" color="primary" variant="glow">Glow</.badge>
      <.badge id="o" color="error" variant="outline">Out</.badge>
      <.badge id="f" color="info" variant="flat">Flat</.badge>
      <.badge id="d" color="dark">Dark</.badge>
      <.badge id="c" color="warning" variant="soft" class="rounded-none">Soft</.badge>
      """)

    assert "bg-success" in classes(html, "#s")
    assert "rounded-full" in classes(html, "#s")
    assert "shadow-primary/50" in classes(html, "#g")
    assert "dark:shadow-accent/50" in classes(html, "#g")
    assert "border-error" in classes(html, "#o")
    assert "text-info" in classes(html, "#f")
    refute Enum.any?(classes(html, "#f"), &String.starts_with?(&1, "bg-"))
    assert "bg-navy-700" in classes(html, "#d")
    assert "bg-warning/10" in classes(html, "#c")
    assert "rounded-none" in classes(html, "#c")
  end

  test "dot adds a dot in the badge's color" do
    html =
      render(~H"""
      <.badge color="primary" dot>On</.badge>
      """)

    assert [_] = find(html, "span.badge > span.bg-current") |> Enum.to_list()
    assert "gap-2.5" in classes(html, "span.badge")
  end

  test "on_remove adds the round remove button" do
    html =
      render(~H"""
      <.badge on_remove={Phoenix.LiveView.JS.hide()}>Tag</.badge>
      """)

    assert [button] = find(html, "button[aria-label=Remove]") |> Enum.to_list()
    assert button |> LazyHTML.attribute("phx-click") |> hd() =~ "hide"
    assert [] = render(~H"<.badge>Tag</.badge>") |> find("button") |> Enum.to_list()
  end

  test "size sets LineOne's compact heights and the default is unchanged" do
    html =
      render(~H"""
      <.badge id="a" size="xs">A</.badge>
      <.badge id="b" size="sm">B</.badge>
      <.badge id="c" size="md">C</.badge>
      <.badge id="d">D</.badge>
      """)

    assert "h-4.5" in classes(html, "#a")
    assert "h-5" in classes(html, "#b")
    assert ["h-5.5", "text-xs-plus"] -- classes(html, "#c") == []
    refute Enum.any?(classes(html, "#d"), &String.starts_with?(&1, "h-"))
  end

  test "white badges for colored cards" do
    html =
      render(~H"""
      <.badge id="a" color="white" variant="outline" shape="pill">A</.badge>
      <.badge id="b" color="white" variant="soft">B</.badge>
      """)

    assert ["border", "border-white", "text-white"] -- classes(html, "#a") == []
    assert ["bg-white/20", "text-white"] -- classes(html, "#b") == []
  end
end
