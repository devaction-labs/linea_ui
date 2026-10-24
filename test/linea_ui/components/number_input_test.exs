defmodule LineaUI.Components.NumberInputTest do
  use LineaUI.ComponentCase, async: true

  alias LineaUI.Components.NumberInput.Format

  doctest Format

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  describe "format" do
    test "separators by locale" do
      assert Format.separators("pt-BR") == {",", "."}
      assert Format.separators("pt_BR") == {",", "."}
      assert Format.separators("en") == {".", ","}
      assert Format.separators("en-US") == {".", ","}
      assert Format.separators("de-DE") == {",", "."}
      assert Format.separators("fr") == {",", " "}
      assert Format.separators("es-MX") == {".", ","}
      assert Format.separators("xx") == {".", ","}
    end

    test "machine text of every kind of value" do
      assert Format.machine(nil) == nil
      assert Format.machine("") == nil
      assert Format.machine(" 12.5 ") == "12.5"
      assert Format.machine(3) == "3"
      assert Format.machine(1234.5) == "1234.5"
      assert Format.machine(1.0e-5) == "0.00001"
      assert Format.machine(%{__struct__: Decimal, sign: 1, coef: 2050, exp: -2}) == "20.50"
      assert Format.machine(%{__struct__: Decimal, sign: -1, coef: 5, exp: -3}) == "-0.005"
      assert Format.machine(%{__struct__: Decimal, sign: 1, coef: 12, exp: 2}) == "1200"
      assert Format.machine(:other) == "other"
    end

    test "display and submitted text" do
      br = %{decimal: ",", group: ".", decimals: nil, max_decimals: nil}
      assert Format.display("1234567.5", br) == "1.234.567,5"
      assert Format.display("-1234.50", br) == "-1.234,5"
      assert Format.display("12", br) == "12"
      assert Format.display(nil, br) == ""
      assert Format.display("abc", br) == "abc"
      assert Format.display("10", %{br | decimals: 2}) == "10,00"
      assert Format.display("1.005", %{br | decimals: 2}) == "1,01"
      assert Format.display("-1.005", %{br | decimals: 2}) == "-1,01"
      assert Format.display("1.23456", %{br | max_decimals: 3}) == "1,235"
      assert Format.display("1.2", %{br | max_decimals: 3}) == "1,2"
      assert Format.display("1234.5", %{br | group: ""}) == "1234,5"
      assert Format.submitted("20.50", br) == "20.5"
      assert Format.submitted("20.5", %{br | decimals: 2}) == "20.50"
      assert Format.submitted(nil, br) == nil
      assert Format.submitted("x", br) == "x"
      assert Format.decimals_of("0.001") == 3
      assert Format.decimals_of(nil) == 0
      assert Format.decimals_of("x") == 0
    end
  end

  test "the hook, the formatted display and the hidden machine value" do
    html =
      render(~H"""
      <.number_input name="price" value={1234.5} decimals={2} min={0} max={99999} step="0.01" />
      """)

    assert attr_of(html, "[phx-hook='LineaUI.NumberInput']", "id") == ["price-number"]
    assert attr_of(html, "input[data-display]", "value") == ["1.234,50"]
    assert attr_of(html, "input[data-display]", "id") == ["price"]
    assert attr_of(html, "input[data-display]", "name") == []
    assert attr_of(html, "input[data-display]", "inputmode") == ["decimal"]
    assert attr_of(html, "input[data-display]", "role") == ["spinbutton"]
    assert attr_of(html, "input[type=hidden][name=price]", "value") == ["1234.50"]
    assert attr_of(html, "input[type=hidden][name=price]", "phx-update") == ["ignore"]
    root = "[phx-hook='LineaUI.NumberInput']"
    assert attr_of(html, root, "data-decimal") == [","]
    assert attr_of(html, root, "data-group") == ["."]
    assert attr_of(html, root, "data-decimals") == ["2"]
    assert attr_of(html, root, "data-min") == ["0"]
    assert attr_of(html, root, "data-max") == ["99999"]
    assert attr_of(html, root, "data-step") == ["0.01"]
    assert attr_of(html, root, "data-negative") == ["false"]
  end

  test "a Decimal field value, the locale and the separators" do
    form = to_form(%{"margin" => %{__struct__: Decimal, sign: 1, coef: 2050, exp: -2}}, as: :rule)
    assigns = %{__changed__: nil, form: form}

    html = rendered_to_string(~H|<.number_input field={@form[:margin]} locale="en" />|)
    assert attr_of(html, "input[type=hidden][name='rule[margin]']", "value") == ["20.5"]
    assert attr_of(html, "input[data-display]", "id") == ["rule_margin"]
    assert attr_of(html, "[data-group]", "data-group") == [","]

    html =
      render(~H"""
      <.number_input name="n" value="1234.5" thousands_separator="" decimal_separator="," />
      """)

    assert attr_of(html, "input[data-display]", "value") == ["1234,5"]
  end

  test "blank values and integers" do
    html =
      render(~H"""
      <.number_input name="blank" value={nil} />
      <.number_input name="count" value={3} max_decimals={0} />
      """)

    assert attr_of(html, "input[name=blank]", "value") == []
    assert attr_of(html, "#count", "value") == ["3"]
    assert attr_of(html, "#count", "inputmode") == ["numeric"]
    assert attr_of(html, "#blank-number", "data-negative") == ["true"]
  end

  test "steppers, prefix, suffix, sizes and debounce" do
    html =
      render(~H"""
      <.number_input
        id="q"
        name="qty"
        steppers
        prefix="R$"
        suffix="un"
        size="sm"
        phx-debounce="200"
        placeholder="0"
        min={-5}
      />
      """)

    assert attr_of(html, "button[data-step-by]", "data-step-by") == ["down", "up"]
    assert attr_of(html, "button[data-step-by=up]", "aria-label") == ["Increase"]
    assert "h-8" in classes(html, "button[data-step-by=up]")
    assert html |> find("span.bg-slate-150") |> LazyHTML.text() =~ "R$"
    assert html |> find("span.bg-slate-150") |> LazyHTML.text() =~ "un"
    assert attr_of(html, "input[name=qty]", "phx-debounce") == ["200"]
    assert attr_of(html, "#q", "phx-debounce") == []
    assert attr_of(html, "#q", "placeholder") == ["0"]
    assert attr_of(html, "#q-number", "data-negative") == ["true"]
  end

  test "label, help, errors, disabled and the generated id" do
    html =
      render(~H"""
      <.number_input name="a" label="Amount" help="In reais" errors={["is invalid"]} disabled steppers />
      """)

    assert html |> find("label") |> LazyHTML.text() =~ "Amount"
    assert html |> find(".text-error") |> LazyHTML.text() =~ "is invalid"
    assert "border-error" in classes(html, "#a")
    assert attr_of(html, "#a", "disabled") == [""]
    assert attr_of(html, "input[name=a]", "disabled") == [""]
    assert attr_of(html, "button[data-step-by=up]", "disabled") == [""]

    html = render(~H|<.number_input align="center" />|)
    assert [id] = attr_of(html, "input[data-display]", "id")
    assert id =~ "number-"
    assert "text-center" in classes(html, "input[data-display]")
  end
end
