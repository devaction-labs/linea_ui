defmodule LineaUI.Components.CheckboxTest do
  use LineaUI.ComponentCase, async: true

  test "a basic neutral checkbox with its label and hidden unchecked value" do
    html = render(~H'<.checkbox name="terms" label="Default" />')
    assert [_] = find(html, "input[type=hidden][name=terms][value=false]") |> Enum.to_list()

    assert [_] =
             find(html, "label.inline-flex > input[type=checkbox][value=true]") |> Enum.to_list()

    assert LazyHTML.text(find(html, "label span")) =~ "Default"
    classes = classes(html, "input[type=checkbox]")
    assert "form-checkbox" in classes
    assert "is-basic" in classes
    assert "size-5" in classes
    assert "rounded-sm" in classes
    assert "checked:bg-slate-500" in classes
  end

  test "color, variant, filled, shape and size" do
    html =
      render(~H"""
      <.checkbox name="x" color="primary" variant="outline" filled shape="circle" size="lg" />
      """)

    classes = classes(html, "input[type=checkbox]")
    assert "is-outline" in classes
    assert "before:bg-primary" in classes
    assert "dark:before:bg-accent" in classes
    assert "bg-slate-100" in classes
    assert "rounded-full" in classes
    assert "size-6" in classes
  end

  test "checked comes from value or field" do
    html = render(~H'<.checkbox name="x" value={true} />')
    assert [_] = find(html, "input[type=checkbox][checked]") |> Enum.to_list()

    field = Phoenix.Component.to_form(%{"remember" => "false"}, as: :user)[:remember]
    assigns = %{field: field}
    html = rendered_to_string(~H'<.checkbox field={@field} label="Remember" />')

    assert [_] =
             find(html, "input#user_remember[name='user[remember]']:not([checked])")
             |> Enum.to_list()
  end

  test "description and slot label" do
    html =
      render(~H'<.checkbox name="p" description="Billed yearly">Pro <b>plan</b></.checkbox>')

    assert LazyHTML.text(find(html, "label")) =~ "Billed yearly"
    assert [_] = find(html, "label b") |> Enum.to_list()
  end

  test "errors are shown under it" do
    field =
      Phoenix.Component.to_form(%{"terms" => "false"},
        as: :u,
        errors: [terms: {"must be accepted", []}]
      )[:terms]

    assigns = %{field: field}

    html = rendered_to_string(~H'<.checkbox field={@field} />')
    assert LazyHTML.text(find(html, ".text-error")) =~ "must be accepted"
  end

  test "a group renders one checkbox per option with the list name" do
    html =
      render(~H"""
      <.checkbox_group
        id="days"
        name="days[]"
        value={["mon"]}
        label="Days"
        options={[{"Monday", "mon"}, {"Tuesday", "tue"}]}
      />
      """)

    assert [_] = find(html, "input[type=hidden][name='days[]'][value='']") |> Enum.to_list()
    assert [_] = find(html, "input#days-0[value=mon][checked]") |> Enum.to_list()
    assert [_] = find(html, "input#days-1[value=tue]:not([checked])") |> Enum.to_list()
    assert [_] = find(html, "[role=group][aria-labelledby=days-label]") |> Enum.to_list()
  end

  test "group slots set their own color" do
    html =
      render(~H"""
      <.checkbox_group name="r[]">
        <:checkbox value="a" color="success">A</:checkbox>
      </.checkbox_group>
      """)

    assert "checked:bg-success" in classes(html, "input[type=checkbox]")
  end

  test "errors paint the checkboxes with the error border" do
    html = render(~H'<.checkbox name="t" errors={["required"]} />')
    assert "border-error" in classes(html, "input[type=checkbox]")

    html = render(~H'<.checkbox name="t" variant="outline" errors={["required"]} />')
    assert "border-error" in classes(html, "input[type=checkbox]")

    html = render(~H'<.checkbox name="t" />')
    refute "border-error" in classes(html, "input[type=checkbox]")

    html = render(~H'<.checkbox_group name="g[]" options={["a", "b"]} errors={["pick one"]} />')
    assert "border-error" in classes(html, "input[type=checkbox]")

    html = render(~H'<.checkbox_group name="g[]" options={["a", "b"]} />')
    refute "border-error" in classes(html, "input[type=checkbox]")
  end
end
