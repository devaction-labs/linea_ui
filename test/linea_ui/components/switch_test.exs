defmodule LineaUI.Components.SwitchTest do
  use LineaUI.ComponentCase, async: true

  test "a basic switch is a checkbox with role switch and a hidden off value" do
    html = render(~H'<.switch name="n" label="Notify" color="primary" />')
    assert [_] = find(html, "input[type=hidden][name=n][value=false]") |> Enum.to_list()
    assert [_] = find(html, "input[type=checkbox][role=switch][value=true]") |> Enum.to_list()
    assert classes(html, "input[role=switch]") == ["toggle", "toggle-primary"]
  end

  test "outline, filled, squircle, size and thumb" do
    html =
      render(~H"""
      <.switch
        name="n"
        variant="outline"
        filled
        shape="squircle"
        size="lg"
        thumb_inset={5}
        color="error"
        label="L"
      />
      """)

    classes = classes(html, "input[role=switch]")

    assert [
             "toggle",
             "toggle-error",
             "toggle-lg",
             "bg-base-200",
             "[--radius-selector:calc(var(--radius-field)*.6)]",
             "[--toggle-p:5px]"
           ] -- classes == []

    assert "text-base" in classes(html, "label span")
  end

  test "checked from a field" do
    field = Phoenix.Component.to_form(%{"public" => "true"}, as: :p)[:public]
    assigns = %{field: field}
    html = rendered_to_string(~H'<.switch field={@field} />')
    assert [_] = find(html, "input#p_public[name='p[public]'][checked]") |> Enum.to_list()
  end

  test "label_position left puts the caption before the switch" do
    html =
      render(~H"""
      <.switch id="a" name="a" label="A" label_position="left" wrapper_class="w-full justify-between" />
      <.switch id="b" name="b" label="B" />
      """)

    assert ["flex-row-reverse", "space-x-reverse", "w-full"] -- classes(html, "label:has(#a)") ==
             []

    refute "flex-row-reverse" in classes(html, "label:has(#b)")
  end

  test "the small switch is daisyUI's toggle-sm" do
    assert "toggle-sm" in classes(
             render(~H|<.switch name="a" size="sm" />|),
             "input[role=switch]"
           )

    refute "toggle-sm" in classes(render(~H|<.switch name="a" />|), "input[role=switch]")
  end
end
