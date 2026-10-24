defmodule LineaUI.Components.ColorPickerTest do
  use LineaUI.ComponentCase, async: true

  alias LineaUI.Components.ColorPicker.Color

  doctest Color

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  describe "Color" do
    test "reads hex text of three, four, six and eight digits" do
      assert Color.parse("#6366f1") == {99, 102, 241, 100}
      assert Color.parse("f00") == {255, 0, 0, 100}
      assert Color.parse("#FF000080") == {255, 0, 0, 50}
      assert Color.parse("#f008") == {255, 0, 0, 53}
    end

    test "rejects what is not a hex color" do
      for text <- ["", "#12", "#12345", "blue", "#GGGGGG", nil, 12] do
        assert Color.parse(text) == nil
        assert Color.normalize(text) == nil
      end
    end

    test "writes upper case hex and keeps the alpha digits only on request" do
      assert Color.normalize("#6366f1") == "#6366F1"
      assert Color.normalize("#FF000080") == "#FF0000"
      assert Color.normalize("#FF000080", true) == "#FF000080"
      assert Color.normalize("#FF0000FF", true) == "#FF0000"
    end

    test "hue, saturation and brightness of the primaries, the grays and a mixed color" do
      assert Color.hsv({255, 0, 0, 100}) == {0, 100, 100, 100}
      assert Color.hsv({0, 255, 0, 100}) == {120, 100, 100, 100}
      assert Color.hsv({0, 0, 255, 100}) == {240, 100, 100, 100}
      assert Color.hsv({0, 0, 0, 100}) == {0, 0, 0, 100}
      assert Color.hsv({128, 128, 128, 100}) == {0, 0, 50, 100}
      assert Color.hsv({99, 102, 241, 100}) == {239, 59, 95, 100}
      assert Color.hsv({255, 0, 64, 100}) == {345, 100, 100, 100}
    end
  end

  describe "markup" do
    test "a hidden input carries the field name and the upper case hex" do
      html = render(~H|<.color_picker name="stage[color]" value="#4c3fe0" />|)

      assert attr_of(html, "input[type=hidden]", "name") == ["stage[color]"]
      assert attr_of(html, "input[type=hidden]", "value") == ["#4C3FE0"]
      assert attr_of(html, "input[type=hidden]", "phx-update") == ["ignore"]
    end

    test "the hook, its id and the color go on the picker" do
      html = render(~H|<.color_picker id="c" name="c" value="#4C3FE0" />|)

      assert attr_of(html, "#c-picker", "phx-hook") == ["LineaUI.ColorPicker"]
      assert attr_of(html, "#c-picker", "data-value") == ["#4C3FE0"]
      assert attr_of(html, "#c-picker", "data-alpha") == ["false"]
    end

    test "the area is a slider that says where the knob is" do
      html = render(~H|<.color_picker name="c" value="#FF0000" />|)

      assert attr_of(html, "[data-area]", "role") == ["slider"]
      assert attr_of(html, "[data-area]", "tabindex") == ["0"]

      assert attr_of(html, "[data-area]", "aria-valuetext") == [
               "Saturation 100%, brightness 100%"
             ]

      assert attr_of(html, "[data-area]", "style") == ["background-color: hsl(0 100% 50%)"]

      assert attr_of(html, "[data-knob]", "style") == [
               "left: 100%; top: 0%; background-color: #FF0000"
             ]
    end

    test "the hue slider and the hex field show the color" do
      html = render(~H|<.color_picker id="c" name="c" value="#00FF00" />|)

      assert attr_of(html, "input[data-hue]", "value") == ["120"]
      assert attr_of(html, "input[data-hue]", "aria-label") == ["Hue"]
      assert attr_of(html, "input#c", "value") == ["#00FF00"]
      assert attr_of(html, "input#c", "aria-label") == ["Color in hex"]
      assert attr_of(html, "input#c", "name") == []
    end

    test "the opacity slider and the eight digits come with alpha" do
      without = render(~H|<.color_picker name="c" value="#FF000080" />|)
      with = render(~H|<.color_picker name="c" value="#FF000080" alpha />|)

      assert find(without, "[data-alpha-input]") |> Enum.to_list() == []
      assert attr_of(without, "input[type=hidden]", "value") == ["#FF0000"]
      assert attr_of(with, "[data-alpha-input]", "value") == ["50"]
      assert attr_of(with, "input[type=hidden]", "value") == ["#FF000080"]
      assert attr_of(with, "[data-chip]", "style") |> hd() =~ "opacity: 0.5"
    end

    test "the presets are swatches and the one matching the color is pressed" do
      html = render(~H|<.color_picker name="c" value="#eb3b2f" />|)

      assert [_ | _] = find(html, "[data-preset]") |> Enum.to_list()
      assert attr_of(html, "[data-preset][aria-pressed=true]", "data-preset") == ["#EB3B2F"]
    end

    test "custom presets replace the defaults and an empty list hides them" do
      custom = render(~H|<.color_picker name="c" presets={["#f00", "00f", "nope"]} />|)
      none = render(~H|<.color_picker name="c" presets={[]} />|)

      assert attr_of(custom, "[data-preset]", "data-preset") == ["#FF0000", "#0000FF"]
      assert find(none, "[role=group]") |> Enum.to_list() == []
    end

    test "an invalid or missing value falls back to the default color" do
      html = render(~H|<.color_picker name="c" value="not a color" default="#112233" />|)
      assert attr_of(html, "input[type=hidden]", "value") == ["#112233"]

      html = render(~H|<.color_picker name="c" />|)
      assert attr_of(html, "input[type=hidden]", "value") == ["#4C3FE0"]
    end

    test "pt_BR names the controls in Portuguese and labels override single texts" do
      html =
        render(~H|<.color_picker name="c" alpha locale="pt_BR" labels={%{color_hex: "Hex"}} />|)

      assert attr_of(html, "[data-area]", "aria-label") == ["Saturação e brilho"]
      assert attr_of(html, "input[data-hue]", "aria-label") == ["Matiz"]
      assert attr_of(html, "[data-alpha-input]", "aria-label") == ["Opacidade"]
      assert attr_of(html, "[role=group]", "aria-label") == ["Cores sugeridas"]
      assert attr_of(html, "input[data-hex]", "aria-label") == ["Hex"]
    end

    test "disabled takes the area out of the tab order and disables the inputs" do
      html = render(~H|<.color_picker name="c" disabled />|)

      assert attr_of(html, "[data-area]", "tabindex") == []
      assert attr_of(html, "[data-area]", "aria-disabled") == ["true"]
      assert "pointer-events-none" in classes(html, "[data-area]")
      assert attr_of(html, "input[data-hue]", "disabled") == [""]
      assert attr_of(html, "input[type=hidden]", "disabled") == [""]
    end

    test "on_change, target and debounce reach the hook and the hidden input" do
      html =
        render(
          ~H|<.color_picker id="c" name="c" on_change="picked" target="#form" phx-debounce="200" />|
        )

      assert attr_of(html, "#c-picker", "data-on-change") == ["picked"]
      assert attr_of(html, "#c-picker", "phx-target") == ["#form"]
      assert attr_of(html, "input[type=hidden]", "phx-debounce") == ["200"]
      assert attr_of(html, "#c-picker", "phx-debounce") == []
    end

    test "label and help wrap the picker and the label points at the hex field" do
      html = render(~H|<.color_picker id="c" name="c" label="Color" help="Pick one" />|)

      assert attr_of(html, "label", "for") == ["c"]
      assert html =~ "Color"
      assert html =~ "Pick one"
    end

    test "a field fills id, name, value and shows errors once it was used" do
      form =
        Phoenix.Component.to_form(%{"color" => "#18996E"},
          as: :stage,
          errors: [color: {"is invalid", []}]
        )

      assigns = %{form: form}
      html = rendered_to_string(~H|<.color_picker field={@form[:color]} />|)

      assert attr_of(html, "input[type=hidden]", "name") == ["stage[color]"]
      assert attr_of(html, "input[type=hidden]", "value") == ["#18996E"]
      assert attr_of(html, "#stage_color", "value") == ["#18996E"]
      assert html =~ "is invalid"
    end
  end
end
