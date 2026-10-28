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

  test "the md radio is 18px with the 6px dot; other sizes keep the scale and a checkbox stays 20px" do
    md = render(~H|<.radio_group name="r" options={~w(a)} />|)
    assert "size-[18px]" in classes(md, "input")
    assert "is-md" in classes(md, "input")
    refute "size-5" in classes(md, "input")

    sm = render(~H|<.radio_group name="r" size="sm" options={~w(a)} />|)
    assert "size-4" in classes(sm, "input")
    refute "is-md" in classes(sm, "input")

    lg = render(~H|<.radio_group name="r" size="lg" options={~w(a)} />|)
    assert "size-6" in classes(lg, "input")

    assert "size-5" in classes(render(~H|<.checkbox name="c" />|), "input")
  end

  test "the card has 14px side padding, a 1px border and a 3px ring when chosen" do
    html = render(~H|<.radio_group name="r" variant="card" value="a" options={~w(a b)} />|)
    card = classes(html, "label")
    assert "px-3.5" in card
    assert "border" in card
    assert "has-checked:ring-3" in card
    refute "has-checked:ring-4" in card
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

  test "errors paint the radios with the error border" do
    form =
      Phoenix.Component.to_form(%{"plan" => "free"}, as: :s, errors: [plan: {"is invalid", []}])

    assigns = %{form: form}

    html =
      rendered_to_string(~H'<.radio_group field={@form[:plan]} options={["free", "pro"]} />')

    assert "border-error" in classes(html, "input")

    html = render(~H'<.radio_group name="plan" options={["free", "pro"]} />')
    refute "border-error" in classes(html, "input")
  end
end
