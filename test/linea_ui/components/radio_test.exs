defmodule LineaUI.Components.RadioTest do
  use LineaUI.ComponentCase, async: true

  test "options render radios sharing a name, the value checked" do
    html =
      render(~H"""
      <.radio_group id="plan" name="plan" value="pro" options={[{"Free", "free"}, {"Pro", "pro"}]} />
      """)

    assert [_] =
             find(
               html,
               "[role=radiogroup] input#plan-0[type=radio][name=plan][value=free]:not([checked])"
             )
             |> Enum.to_list()

    assert [_] = find(html, "input#plan-1[value=pro][checked]") |> Enum.to_list()
    classes = classes(html, "input")
    assert "form-radio" in classes
    assert "is-basic" in classes
    assert "rounded-full" in classes
  end

  test "slots override color and disabled; shape and variant apply to all" do
    html =
      render(~H"""
      <.radio_group name="r" variant="outline" shape="squircle" filled>
        <:radio value="a" color="primary">Primary</:radio>
        <:radio value="b" disabled>Off</:radio>
      </.radio_group>
      """)

    [first | _] = find(html, "input") |> LazyHTML.attribute("class")
    assert first =~ "before:bg-primary"
    assert first =~ "rounded-md"
    assert first =~ "bg-slate-100"
    assert [_] = find(html, "input[value=b][disabled]") |> Enum.to_list()
  end

  test "field wiring and errors" do
    form =
      Phoenix.Component.to_form(%{"plan" => "free"}, as: :s, errors: [plan: {"is invalid", []}])

    assigns = %{form: form}

    html =
      rendered_to_string(
        ~H'<.radio_group field={@form[:plan]} label="Plan" options={["free", "pro"]} />'
      )

    assert [_] = find(html, "input[name='s[plan]'][value=free][checked]") |> Enum.to_list()
    assert LazyHTML.text(find(html, ".text-error")) =~ "is invalid"
    assert LazyHTML.text(find(html, "#s_plan-label")) =~ "Plan"
  end
end
