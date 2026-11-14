defmodule LineaUI.Components.RadioTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

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

  test "the card is the canvas sg-choice: radio at the start by default, at the end with control=end" do
    html = render(~H|<.radio_group name="r" variant="card" value="a" options={~w(a b)} />|)
    assert "lu-rcard" in classes(html, "label")
    assert attr_of(html, "label", "data-color") == ["neutral", "neutral"]
    assert ["lu-rcard-control" | _] = html |> find("label > span") |> LazyHTML.attribute("class")

    html =
      render(~H"""
      <.radio_group name="r" variant="card" control="end" value="a">
        <:radio value="a" icon="huge-flash" description="Na hora">Pix</:radio>
        <:radio value="b" count="R$ 18" description="1 a 2 dias">Entrega</:radio>
      </.radio_group>
      """)

    assert "sg-ic" in classes(html, "label .lu-rcard-icon")
    assert html |> find("label:first-child > span:last-child input") |> Enum.count() == 1

    assert "is-stacked" in (html
                            |> find("label")
                            |> Enum.at(1)
                            |> LazyHTML.attribute("class")
                            |> hd()
                            |> String.split())

    assert html |> find(".lu-rcard-head input[value=b]") |> Enum.count() == 1
    assert html |> find(".lu-rcard-figure") |> LazyHTML.text() == "R$ 18"
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

  describe "variant segmented" do
    test "real radios hidden inside segments on the segmented track" do
      html =
        render(~H"""
        <.radio_group
          id="period"
          name="period"
          value="week"
          variant="segmented"
          options={[
            %{label: "Day", value: "day"},
            %{label: "Week", value: "week", count: 3},
            %{label: "Month", value: "month", disabled: true}
          ]}
        />
        """)

      assert [_, _, _] = find(html, "input[type=radio][name=period]") |> Enum.to_list()
      assert [_] = find(html, "input#period-1[value=week][checked]") |> Enum.to_list()
      assert [_] = find(html, "input#period-2[disabled]") |> Enum.to_list()
      assert "sr-only" in classes(html, "#period-0")
      refute "form-radio" in classes(html, "#period-0")

      track = classes(html, "[role=radiogroup]")
      assert "bg-slate-150" in track
      assert "inline-flex" in track

      assert "has-checked:bg-white" in classes(html, "label")
      assert "h-[30px]" in classes(html, "label")
      assert LazyHTML.text(find(html, "label:nth-child(2)")) =~ "Week"
      assert LazyHTML.text(find(html, "label:nth-child(2)")) =~ "3"
    end

    test "sizes follow segmented and errors ring the track" do
      form =
        Phoenix.Component.to_form(%{"plan" => "free"}, as: :s, errors: [plan: {"is invalid", []}])

      assigns = %{form: form}

      html =
        rendered_to_string(
          ~H'<.radio_group field={@form[:plan]} variant="segmented" size="lg" options={["free", "pro"]} />'
        )

      assert "h-9.5" in classes(html, "label")
      assert "ring-error" in classes(html, "[role=radiogroup]")
      refute "border-error" in classes(html, "input")
      assert LazyHTML.text(find(html, ".text-error")) =~ "is invalid"
    end
  end

  test "a radio shows the keyboard focus as a ring around it" do
    css = File.read!(Path.expand("../../../assets/css/linea_ui.css", __DIR__))

    assert css =~
             ~r/\.form-radio \{\s*@apply focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary\/50/
  end

  test "label_hint sits beside the caption of the group" do
    html =
      render(~H"""
      <.radio_group name="b" label="Forma" label_hint="billingType" options={~w(a b)} />
      """)

    assert LazyHTML.text(find(html, "span[id$=-label] > span")) =~ "billingType"
  end

  test "variant tile renders free content with aria-label and disabled per option" do
    html =
      render(~H"""
      <.radio_group id="mk" name="mk" value="a" variant="tile">
        <:radio value="a" aria_label="Segmento A"><svg id="svg-a"></svg></:radio>
        <:radio value="b" aria_label="Segmento B" disabled><svg id="svg-b"></svg></:radio>
      </.radio_group>
      """)

    assert [_, _] = find(html, "label.lu-tile") |> Enum.to_list()
    assert [_] = find(html, "label.lu-tile > svg#svg-a") |> Enum.to_list()
    assert attr_of(html, "input#mk-0", "aria-label") == ["Segmento A"]
    assert [_] = find(html, "input#mk-0[checked]") |> Enum.to_list()
    assert [_] = find(html, "input#mk-1[disabled]") |> Enum.to_list()
    assert "sr-only" in classes(html, "input#mk-0")
    assert "flex" in classes(html, "[role=radiogroup]")
  end

  test "variant tile with options reads aria_label from the map" do
    html =
      render(~H"""
      <.radio_group
        id="t"
        name="t"
        variant="tile"
        options={[%{value: "x", aria_label: "Xis", label: "X"}]}
      />
      """)

    assert attr_of(html, "input#t-0", "aria-label") == ["Xis"]
  end
end
