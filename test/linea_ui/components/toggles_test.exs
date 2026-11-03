defmodule LineaUI.Components.TogglesTest do
  use LineaUI.ComponentCase, async: true

  test "a checkbox, a radio and a switch are one input each" do
    html =
      render(~H"""
      <.checkbox_input id="c" name="terms" checked />
      <.radio_input id="r" name="plan" value="pro" />
      <.switch_input id="s" name="alerts" size="lg" disabled />
      """)

    assert [_] = find(html, "input#c[type=checkbox][name=terms][checked]") |> Enum.to_list()
    assert [_] = find(html, "input#r[type=radio][value=pro]") |> Enum.to_list()
    assert [_] = find(html, "input#s[type=checkbox][role=switch][disabled]") |> Enum.to_list()
    assert "check-input" in classes(html, "#c")
    assert "radio-input" in classes(html, "#r")
    assert "switch-input" in classes(html, "#s")
    assert "switch-input-lg" in classes(html, "#s")
  end

  test "class and extra attributes reach the input and the md switch has no size class" do
    html = render(~H|<.switch_input id="m" class="ms-2" data-x="1" />|)

    assert "ms-2" in classes(html, "#m")
    refute "switch-input-sm" in classes(html, "#m")
    assert [_] = find(html, "#m[data-x='1']") |> Enum.to_list()
  end
end
