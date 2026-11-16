defmodule LineaUI.Components.AlertTest do
  use LineaUI.ComponentCase, async: true

  test "a neutral solid alert by default" do
    html = render(~H"<.alert variant=\"solid\">Hello</.alert>")
    assert [_] = find(html, "div[role=alert]") |> Enum.to_list()
    classes = classes(html, "[role=alert]")
    assert ["alert", "px-4"] -- classes == []
    refute Enum.any?(classes, &String.starts_with?(&1, "alert-"))
  end

  test "variant, color and shape pick LineOne's classes, class overrides" do
    html =
      render(~H"""
      <.alert color="primary" variant="soft" shape="pill" class="px-8">Hi</.alert>
      """)

    classes = classes(html, "[role=alert]")
    assert ["alert", "alert-soft", "alert-primary"] -- classes == []
    assert "rounded-full" in classes
    assert "px-8" in classes
    refute "px-4" in classes
  end

  test "outline, bordered and dark" do
    html =
      render(~H"""
      <.alert id="o" color="info" variant="outline">x</.alert>
      <.alert id="b" color="success" variant="bordered">x</.alert>
      <.alert variant="solid" id="d" color="dark">x</.alert>
      """)

    assert ["alert-outline", "alert-info"] -- classes(html, "#o") == []
    assert ["alert-soft", "alert-success", "border-current/25"] -- classes(html, "#b") == []
    assert "bg-neutral" in classes(html, "#d")
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
      <.alert variant="solid" color="error"><:icon><svg id="i"></svg></:icon>Text</.alert>
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
    assert "btn-ghost" in classes(html, "button")
  end

  test "open={false} renders it hidden, and actions render after the content" do
    html =
      render(~H"""
      <.alert variant="solid" open={false}>
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

  test "the canvas variant is a soft daisyUI alert with its tone, actions and a muted close button" do
    html =
      render(~H"""
      <.alert id="a" variant="canvas" color="warning" dismissible close_label="Fechar">
        <b>Title</b>
        <:action><button>Go</button></:action>
      </.alert>
      """)

    assert ["alert", "alert-soft", "alert-warning"] -- classes(html, "#a") == []
    assert [_] = find(html, "#a > div > div button") |> Enum.to_list()
    assert find(html, "#a > button.btn-ghost") |> LazyHTML.attribute("aria-label") == ["Fechar"]

    assert "alert-primary" in classes(
             render(~H|<.alert id="a" variant="canvas" color="primary">x</.alert>|),
             "#a"
           )

    assert "alert-error" in classes(
             render(~H|<.alert id="a" variant="canvas" color="error">x</.alert>|),
             "#a"
           )

    assert "alert-info" in classes(
             render(~H|<.alert id="a" variant="canvas" color="info">x</.alert>|),
             "#a"
           )

    assert "alert-success" in classes(
             render(~H|<.alert id="a" variant="canvas" color="success">x</.alert>|),
             "#a"
           )
  end
end
