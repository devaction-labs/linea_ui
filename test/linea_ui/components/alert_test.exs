defmodule LineaUI.Components.AlertTest do
  use LineaUI.ComponentCase, async: true

  test "a neutral solid alert by default" do
    html = render(~H"<.alert>Hello</.alert>")
    assert [_] = find(html, "div[role=alert]") |> Enum.to_list()
    classes = classes(html, "[role=alert]")
    assert "bg-slate-200" in classes
    assert "rounded-lg" in classes
    assert "px-4" in classes
  end

  test "variant, color and shape pick LineOne's classes, class overrides" do
    html =
      render(~H"""
      <.alert color="primary" variant="soft" shape="pill" class="px-8">Hi</.alert>
      """)

    classes = classes(html, "[role=alert]")
    assert "bg-primary/10" in classes
    assert "dark:bg-accent-light/15" in classes
    assert "rounded-full" in classes
    assert "px-8" in classes
    refute "px-4" in classes
  end

  test "outline, bordered and dark" do
    html =
      render(~H"""
      <.alert id="o" color="info" variant="outline">x</.alert>
      <.alert id="b" color="success" variant="bordered">x</.alert>
      <.alert id="d" color="dark">x</.alert>
      """)

    assert "border-info" in classes(html, "#o")
    assert "border-success/30" in classes(html, "#b")
    assert "bg-navy-900" in classes(html, "#d")
  end

  test "an accent bar moves the padding to the content" do
    html =
      render(~H"""
      <.alert color="secondary" variant="soft" accent="left">x</.alert>
      """)

    assert "overflow-hidden" in classes(html, "[role=alert]")
    refute "px-4" in classes(html, "[role=alert]")
    assert [_] = find(html, "div.w-1\\.5.bg-secondary") |> Enum.to_list()
    assert [_] = find(html, "div.p-4") |> Enum.to_list()
  end

  test "a boxed icon sits on a filled block" do
    html =
      render(~H"""
      <.alert color="info" variant="outline">
        <:icon boxed><svg id="i"></svg></:icon>
        Text
      </.alert>
      """)

    assert [_] = find(html, "div.bg-info.p-3 > svg#i") |> Enum.to_list()
  end

  test "an inline icon comes before the text" do
    html =
      render(~H"""
      <.alert color="error"><:icon><svg id="i"></svg></:icon>Text</.alert>
      """)

    assert "gap-2" in classes(html, "[role=alert]")
    assert [_] = find(html, "[role=alert] > svg#i") |> Enum.to_list()
  end

  test "dismissible adds the close button that hides the alert" do
    html =
      render(~H"""
      <.alert id="a" color="info" variant="outline" dismissible>x</.alert>
      """)

    assert [button] = find(html, "button[aria-label=Close]") |> Enum.to_list()
    click = button |> LazyHTML.attribute("phx-click") |> hd()
    assert click =~ "hide"
    assert click =~ "[role=alert]"
    assert "text-info" in classes(html, "button")
  end

  test "open={false} renders it hidden, and actions render after the content" do
    html =
      render(~H"""
      <.alert open={false}>
        x
        <:action><button id="act">Go</button></:action>
      </.alert>
      """)

    assert [_] = find(html, "[role=alert][hidden]") |> Enum.to_list()
    assert [_] = find(html, "button#act") |> Enum.to_list()
  end

  test "dismiss_alert/1 targets the closest alert" do
    assert %Phoenix.LiveView.JS{ops: [["hide", %{to: %{closest: "[role=alert]"}}]]} =
             dismiss_alert()
  end
end
