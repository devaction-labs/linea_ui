defmodule LineaUI.Components.ThemeSwitchTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "segmented: a radiogroup of light, dark and system wired to the hook" do
    html = render(~H|<.theme_switch id="t" light_label="Claro" dark_label="Escuro" system_label="Sistema" />|)

    assert ["sg-theme"] == classes(html, "#t")
    assert attr_of(html, "#t", "role") == ["radiogroup"]
    assert attr_of(html, "#t", "phx-hook") == ["LineaUI.ThemeSwitch"]
    assert attr_of(html, "#t > button", "data-theme-value") == ["light", "dark", "system"]
    assert attr_of(html, "#t > button", "role") == ["radio", "radio", "radio"]
    assert html |> find("#t .lbl") |> Enum.map(&LazyHTML.text/1) == ["Claro", "Escuro", "Sistema"]
    assert "huge-computer" in classes(html, "#t > button[data-theme-value=system] > span")
  end

  test "icons, small and without system" do
    html = render(~H|<.theme_switch id="t" variant="icons" size="sm" system={false} />|)

    assert ["sg-theme", "icons", "sm", "two"] == classes(html, "#t")
    assert attr_of(html, "#t > button", "data-theme-value") == ["light", "dark"]
    assert attr_of(html, "#t > button", "title") == ["Light", "Dark"]
  end

  test "switch: a sun/moon switch" do
    html = render(~H|<.theme_switch id="t" variant="switch" on_change="theme" />|)

    assert attr_of(html, "button#t", "role") == ["switch"]
    assert attr_of(html, "#t", "data-variant") == ["switch"]
    assert attr_of(html, "#t", "data-change-event") == ["theme"]
    assert ["sg-theme-sw"] == classes(html, "#t")
    assert html |> find("#t > .k > span") |> Enum.count() == 2
  end
end
