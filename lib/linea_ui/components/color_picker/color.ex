defmodule LineaUI.Components.ColorPicker.Color do
  @moduledoc """
  Hex colors for `color_picker`: reading `#RGB`, `#RRGGBB` and `#RRGGBBAA` text, writing it back in
  upper case, and the hue, saturation and brightness the picker draws from.

      iex> LineaUI.Components.ColorPicker.Color.normalize("#6366f1")
      "#6366F1"
      iex> LineaUI.Components.ColorPicker.Color.normalize("f00")
      "#FF0000"
      iex> LineaUI.Components.ColorPicker.Color.normalize("not a color")
      nil
  """

  @type rgba :: {0..255, 0..255, 0..255, 0..100}

  @doc "The color as `{r, g, b, alpha}` (alpha 0 to 100), or `nil` when the text is not a hex color."
  @spec parse(term()) :: rgba() | nil
  def parse(value) when is_binary(value) do
    with [_, digits] <- Regex.run(~r/\A#?([0-9a-f]+)\z/i, String.trim(value)),
         {:ok, full} <- expand(String.upcase(digits)) do
      channels(full)
    else
      _invalid -> nil
    end
  end

  def parse(_value), do: nil

  defp expand(digits) when byte_size(digits) in [3, 4],
    do: {:ok, digits |> String.graphemes() |> Enum.map_join(&(&1 <> &1))}

  defp expand(digits) when byte_size(digits) in [6, 8], do: {:ok, digits}
  defp expand(_digits), do: :error

  defp channels(<<r::binary-2, g::binary-2, b::binary-2>>),
    do: {byte(r), byte(g), byte(b), 100}

  defp channels(<<r::binary-2, g::binary-2, b::binary-2, a::binary-2>>),
    do: {byte(r), byte(g), byte(b), round(byte(a) / 255 * 100)}

  defp byte(digits), do: String.to_integer(digits, 16)

  @doc """
  The color as upper case hex text. With `alpha?` a color that is not fully opaque has eight digits.
  `nil` when the text is not a hex color.
  """
  @spec normalize(term(), boolean()) :: String.t() | nil
  def normalize(value, alpha? \\ false), do: value |> parse() |> write(alpha?)

  @doc "The text of `{r, g, b, alpha}`; see `normalize/2`."
  @spec write(rgba() | nil, boolean()) :: String.t() | nil
  def write(nil, _alpha?), do: nil

  def write({r, g, b, a}, true) when a < 100,
    do: write({r, g, b, 100}, false) <> pair(a * 255 / 100)

  def write({r, g, b, _a}, _alpha?), do: "#" <> pair(r) <> pair(g) <> pair(b)

  defp pair(number),
    do: number |> round() |> Integer.to_string(16) |> String.pad_leading(2, "0")

  @doc "The color as `{hue 0-359, saturation 0-100, brightness 0-100, alpha 0-100}`."
  @spec hsv(rgba()) :: {0..359, 0..100, 0..100, 0..100}
  def hsv({r, g, b, a}) do
    {low, high} = Enum.min_max([r, g, b])
    spread = high - low

    {rem(round(hue({r, g, b}, high, spread)), 360), percent(spread, high), percent(high, 255), a}
  end

  defp percent(_part, 0), do: 0
  defp percent(part, whole), do: round(part / whole * 100)

  defp hue(_rgb, _high, 0), do: 0

  defp hue({r, g, b}, high, spread) do
    cond do
      high == r -> 60 * wrap((g - b) / spread, 6)
      high == g -> 60 * ((b - r) / spread + 2)
      true -> 60 * ((r - g) / spread + 4)
    end
  end

  defp wrap(value, divisor) when value < 0, do: value + divisor
  defp wrap(value, _divisor), do: value
end
