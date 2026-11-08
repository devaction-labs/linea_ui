defmodule LineaUI.Components.ThemeSwitchTest do
  use LineaUI.ComponentCase, async: true

  defp labels(html),
    do: html |> find("#t .lbl") |> LazyHTML.to_tree() |> Enum.map(fn {_, _, [text]} -> text end)

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  describe "segmented (default)" do
    test "is a radiogroup of three radios: light, dark, system" do
      html = render(~H|<.theme_switch id="t" />|)

      assert classes(html, "#t") == ["sg-theme"]
      assert attr_of(html, "#t", "role") == ["radiogroup"]
      assert attr_of(html, "#t", "aria-label") == ["Theme"]
      assert attr_of(html, "#t", "data-value") == ["light"]
      assert attr_of(html, "#t", "phx-hook") == ["LineaUI.ThemeSwitch"]
      assert attr_of(html, "#t > button", "role") == ["radio", "radio", "radio"]
      assert attr_of(html, "#t > button", "type") == ["button", "button", "button"]
      assert attr_of(html, "#t > button", "data-theme-value") == ["light", "dark", "system"]
      assert attr_of(html, "#t > button", "aria-checked") == ["true", "false", "false"]
      assert attr_of(html, "#t > button", "tabindex") == ["0", "-1", "-1"]

      assert labels(html) == [
               "Light",
               "Dark",
               "System"
             ]

      assert find(html, "#t > button > svg.i") |> Enum.count() == 3
    end

    test "the labels and the group name can be overridden" do
      html =
        render(~H"""
        <.theme_switch id="t" label="Tema" light_label="Claro" dark_label="Escuro" system_label="Sistema" />
        """)

      assert attr_of(html, "#t", "aria-label") == ["Tema"]

      assert labels(html) == [
               "Claro",
               "Escuro",
               "Sistema"
             ]
    end

    test "the client owns data-value and the radios' state" do
      html = render(~H|<.theme_switch id="t" />|)
      assert attr_of(html, "#t", "phx-mounted") |> hd() =~ "data-value"
      assert attr_of(html, "#t > button", "phx-mounted") |> hd() =~ "aria-checked"
      assert attr_of(html, "#t > button", "phx-mounted") |> hd() =~ "tabindex"
    end
  end

  describe "icons" do
    test "has the icons class and each radio carries its label as title" do
      html = render(~H|<.theme_switch id="t" variant="icons" dark_label="Escuro" />|)

      assert classes(html, "#t") == ["sg-theme", "icons"]
      assert attr_of(html, "#t > button", "title") == ["Light", "Escuro", "System"]
      assert find(html, "#t .lbl") |> Enum.count() == 3
    end

    test "the segmented one has no title" do
      html = render(~H|<.theme_switch id="t" />|)
      assert attr_of(html, "#t > button", "title") == []
    end
  end

  describe "size and system" do
    test "size sm" do
      html = render(~H|<.theme_switch id="t" size="sm" variant="icons" class="extra" />|)
      assert classes(html, "#t") == ["sg-theme", "icons", "sm", "extra"]
    end

    test "system={false} leaves light and dark and marks the group two" do
      html = render(~H|<.theme_switch id="t" system={false} />|)

      assert classes(html, "#t") == ["sg-theme", "two"]
      assert attr_of(html, "#t", "data-system") == ["false"]
      assert attr_of(html, "#t > button", "data-theme-value") == ["light", "dark"]
    end

    test "system is offered by default and not marked" do
      html = render(~H|<.theme_switch id="t" />|)
      assert attr_of(html, "#t", "data-system") == []
    end
  end

  describe "switch" do
    test "is one switch button with the sun and moon" do
      html = render(~H|<.theme_switch id="t" variant="switch" class="extra" />|)

      assert classes(html, "button#t") == ["sg-theme-sw", "extra"]
      assert attr_of(html, "#t", "role") == ["switch"]
      assert attr_of(html, "#t", "aria-checked") == ["false"]
      assert attr_of(html, "#t", "aria-label") == ["Dark mode"]
      assert attr_of(html, "#t", "phx-hook") == ["LineaUI.ThemeSwitch"]
      assert attr_of(html, "#t", "phx-mounted") |> hd() =~ "aria-checked"
      assert find(html, "#t > .end") |> Enum.count() == 2
      assert find(html, "#t > .k > .sun svg") |> Enum.count() == 1
      assert find(html, "#t > .k > .moon svg") |> Enum.count() == 1
      assert find(html, "#t [role=radio]") |> Enum.count() == 0
    end

    test "the label names the switch" do
      html = render(~H|<.theme_switch id="t" variant="switch" label="Escuro" />|)
      assert attr_of(html, "#t", "aria-label") == ["Escuro"]
    end
  end

  test "extra attributes go to the root" do
    html = render(~H|<.theme_switch id="t" data-x="1" />|)
    assert attr_of(html, "#t", "data-x") == ["1"]
  end
end
