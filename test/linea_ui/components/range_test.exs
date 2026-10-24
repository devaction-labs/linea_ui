defmodule LineaUI.Components.RangeTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)
  defp count(html, selector), do: html |> find(selector) |> Enum.count()
  defp text(html, selector), do: html |> find(selector) |> LazyHTML.text() |> String.trim()

  describe "plain" do
    test "a slider without the extras keeps the bare input and no hook" do
      html = render(~H|<.range name="v" value={50} />|)

      assert count(html, "[phx-hook]") == 0
      assert count(html, "output") == 0
      assert attr_of(html, "input[type=range]", "value") == ["50"]
      assert "form-range" in classes(html, "input")
    end
  end

  describe "value, fill and marks" do
    test "show_value writes the formatted value beside the label" do
      html =
        render(
          ~H|<.range id="m" name="m" value={60} label="Markup" show_value value_format="%{value}%" />|
        )

      assert attr_of(html, "#m-slider", "phx-hook") == ["LineaUI.Range"]
      assert attr_of(html, "#m-slider", "data-format") == ["%{value}%"]
      assert text(html, "output[data-output]") == "60%"
      assert attr_of(html, "output", "for") == ["m"]
      assert text(html, "label") == "Markup"
      assert attr_of(html, "label", "for") == ["m"]
    end

    test "filled adds the class and the position of the thumb as --p" do
      html = render(~H|<.range name="m" value={50} min={0} max={200} filled />|)

      assert "linea-range-filled" in classes(html, "input")
      assert attr_of(html, "input", "style") == ["--p: 25.0%"]
    end

    test "marks are values or value and label pairs, placed by their position" do
      html =
        render(~H|<.range
  name="m"
  value={100}
  min={0}
  max={200}
  marks={[{0, "0%"}, 50, {100, "100%"}, {200, "200%"}]}
/>|)

      assert attr_of(html, "[data-mark]", "data-mark") == ["0", "50", "100", "200"]

      assert find(html, "[data-mark]") |> Enum.map(&String.trim(LazyHTML.text(&1))) == [
               "0%",
               "50",
               "100%",
               "200%"
             ]

      assert attr_of(html, "[data-mark]", "aria-pressed") == ["false", "false", "true", "false"]
      assert "translate-x-0" in classes(html, "[data-mark='0']")
      assert "-translate-x-1/2" in classes(html, "[data-mark='100']")
      assert "-translate-x-full" in classes(html, "[data-mark='200']")
      assert attr_of(html, "[data-mark='0']", "style") == ["left: calc(0.0% + 0px)"]
      assert attr_of(html, "[data-mark='100']", "style") == ["left: calc(50.0% + 0.0px)"]
      assert attr_of(html, "[data-mark]", "tabindex") |> Enum.uniq() == ["-1"]
    end

    test "steppers add minus and plus buttons" do
      html = render(~H|<.range name="m" steppers decrease_label="Menos" increase_label="Mais" />|)

      assert attr_of(html, "[data-step-by]", "data-step-by") == ["down", "up"]
      assert attr_of(html, "[data-step-by]", "aria-label") == ["Menos", "Mais"]
    end

    test "help and errors go under the control" do
      html = render(~H|<.range name="m" show_value help="Help me" errors={["too low"]} />|)

      assert html =~ "Help me"
      assert html =~ "too low"
    end

    test "a Decimal or text value is read as a number" do
      html = render(~H|<.range name="m" value="25" show_value filled />|)

      assert text(html, "output") == "25"
      assert attr_of(html, "input", "style") == ["--p: 25.0%"]
    end
  end

  describe "a range of two" do
    test "two inputs named for the ends carry the pair and the fill" do
      html =
        render(~H|<.range
  id="p"
  start_name="from"
  end_name="to"
  value={{40, 280}}
  min={0}
  max={500}
  step={10}
  show_value
  value_format="R$ %{value}"
  label="Price"
/>|)

      assert attr_of(html, "#p-pair", "phx-hook") == ["LineaUI.RangePair"]
      assert attr_of(html, "input[data-low]", "name") == ["from"]
      assert attr_of(html, "input[data-high]", "name") == ["to"]
      assert attr_of(html, "input[data-low]", "value") == ["40"]
      assert attr_of(html, "input[data-high]", "value") == ["280"]
      assert attr_of(html, "input[type=range]", "max") == ["500", "500"]
      assert attr_of(html, "input[type=range]", "step") == ["10", "10"]
      assert attr_of(html, "[data-fill]", "style") == ["left: 8.0%; width: 48.0%"]
      assert text(html, "output") == "R$ 40 – R$ 280"
      assert attr_of(html, "[role=group]", "aria-labelledby") == ["p-label"]
    end

    test "fields fill the names and the values" do
      form = Phoenix.Component.to_form(%{"from" => "10", "to" => "90"}, as: :price)
      assigns = %{form: form}

      html =
        rendered_to_string(~H|<.range start_field={@form[:from]} end_field={@form[:to]} />|)

      assert attr_of(html, "input[data-low]", "name") == ["price[from]"]
      assert attr_of(html, "input[data-high]", "name") == ["price[to]"]
      assert attr_of(html, "input[data-low]", "value") == ["10"]
      assert attr_of(html, "input[data-high]", "value") == ["90"]
    end

    test "without a value the thumbs sit at the ends" do
      html = render(~H|<.range start_name="a" end_name="b" min={0} max={10} />|)

      assert attr_of(html, "input[data-low]", "value") == ["0"]
      assert attr_of(html, "input[data-high]", "value") == ["10"]
      assert attr_of(html, "[data-fill]", "style") == ["left: 0.0%; width: 100.0%"]
    end

    test "marks sit under the pair and the nearer value is pressed" do
      html =
        render(~H|<.range start_name="a" end_name="b" value={{0, 100}} marks={[0, 50, 100]} />|)

      assert attr_of(html, "[data-mark]", "aria-pressed") == ["true", "false", "true"]
    end

    test "color and size style both inputs" do
      html = render(~H|<.range start_name="a" end_name="b" color="primary" size="lg" />|)

      assert "text-primary" in classes(html, "input[data-low]")
      assert "[--range-thumb-size:24px]" in classes(html, "input[data-high]")
      assert "text-primary" in classes(html, "[data-pair] > div")
    end
  end

  describe "vertical" do
    test "stands the input up and gives it its length" do
      html = render(~H|<.range name="w" value={40} orientation="vertical" height="10rem" />|)

      assert "linea-range-vertical" in classes(html, "input")
      assert "[writing-mode:vertical-lr]" in classes(html, "input")
      assert attr_of(html, "input", "aria-orientation") == ["vertical"]
      assert attr_of(html, "input", "value") == ["40"]
      assert attr_of(html, "[data-slider] > div > div", "style") == ["height: 10rem"]
    end

    test "the column is reversed so the value sits below and the plus button above" do
      html =
        render(~H|<.range name="w" orientation="vertical" show_value steppers label="Price" />|)

      assert attr_of(html, "[data-step-by]", "data-step-by") == ["down", "up"]
      assert count(html, "[data-slider] > div > output") == 1
      assert "flex-col-reverse" in classes(html, "[data-slider] > div:nth-child(2)")
    end

    test "marks hang from the bottom of the track" do
      html = render(~H|<.range name="w" orientation="vertical" marks={[0, 100]} />|)

      assert "translate-y-0" in classes(html, "[data-mark='0']")
      assert "translate-y-full" in classes(html, "[data-mark='100']")
      assert attr_of(html, "[data-mark='0']", "style") == ["bottom: calc(0.0% + 0px)"]
    end
  end
end
