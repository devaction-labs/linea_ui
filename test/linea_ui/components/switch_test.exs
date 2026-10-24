defmodule LineaUI.Components.SwitchTest do
  use LineaUI.ComponentCase, async: true

  test "a basic switch is a checkbox with role switch and a hidden off value" do
    html = render(~H'<.switch name="n" label="Notify" color="primary" />')
    assert [_] = find(html, "input[type=hidden][name=n][value=false]") |> Enum.to_list()
    assert [_] = find(html, "input[type=checkbox][role=switch][value=true]") |> Enum.to_list()
    classes = classes(html, "input[role=switch]")
    assert "form-switch" in classes
    assert "h-5" in classes
    assert "rounded-full" in classes
    assert "checked:bg-primary" in classes
    assert "dark:checked:bg-accent" in classes
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
    assert "is-outline" in classes
    assert "bg-slate-100" in classes
    assert "rounded-lg" in classes
    assert "before:rounded-md" in classes
    assert "h-7" in classes
    assert "[--thumb-border:5px]" in classes
    assert "checked:before:!bg-error" in classes
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
end
