defmodule LineaUI.Theme.Color do
  @moduledoc """
  The color math the themes are built with: hex in sRGB to and from OKLCH, mixing in OKLab, and the lightness that
  decides whether text on a color is light or dark. Pure functions, no dependencies.

      iex> LineaUI.Theme.Color.to_hex(LineaUI.Theme.Color.oklch("#0d8f91"))
      "#0d8f91"
  """

  @typedoc "Lightness (0..1), chroma (0..~0.4) and hue (degrees)."
  @type oklch :: {float(), float(), float()}

  @doc "The OKLCH of a `#rrggbb` (or `#rgb`) color."
  @spec oklch(String.t()) :: oklch()
  def oklch("#" <> hex),
    do: hex |> rgb() |> Tuple.to_list() |> Enum.map(&linear/1) |> oklab() |> lch()

  @doc "The `#rrggbb` of an OKLCH color; out of the sRGB gamut, the chroma drops until it fits."
  @spec to_hex(oklch()) :: String.t()
  def to_hex({l, c, h}) do
    l = clamp(l, 0.0, 1.0)

    case srgb({l, c, h}) do
      {:ok, channels} -> hex(channels)
      :out when c > 0.0005 -> to_hex({l, fit(l, 0.0, c, h), h})
      :out -> {l, 0.0, h} |> srgb() |> elem(1) |> hex()
    end
  end

  @doc "A color between two hex colors, `amount` (0..1) of the first, mixed in OKLab."
  @spec mix(String.t(), String.t(), float()) :: String.t()
  def mix(a, b, amount) do
    [la, aa, ba] = lab(oklch(a))
    [lb, ab, bb] = lab(oklch(b))
    t = clamp(amount, 0.0, 1.0)
    [la * t + lb * (1 - t), aa * t + ab * (1 - t), ba * t + bb * (1 - t)] |> lch() |> to_hex()
  end

  @doc "The same color with an alpha, as `rgb(r g b/a)`."
  @spec alpha(String.t(), float()) :: String.t()
  def alpha("#" <> hex, a) do
    {r, g, b} = rgb(hex)
    "rgb(#{round(r * 255)} #{round(g * 255)} #{round(b * 255)}/#{trim(a)})"
  end

  @doc "Whether text on `hex` reads better dark than white (its OKLCH lightness is above 0.72)."
  @spec light?(String.t()) :: boolean()
  def light?(hex), do: elem(oklch(hex), 0) > 0.72

  @doc "The WCAG contrast ratio between two hex colors (1..21)."
  @spec contrast(String.t(), String.t()) :: float()
  def contrast(a, b) do
    [x, y] = Enum.sort([luminance(a), luminance(b)], :desc)
    (x + 0.05) / (y + 0.05)
  end

  defp luminance("#" <> hex) do
    [r, g, b] = hex |> rgb() |> Tuple.to_list() |> Enum.map(&linear/1)
    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  # ---------------------------------------------------------------- conversions

  defp rgb(<<r, g, b>>), do: rgb(<<r, r, g, g, b, b>>)

  defp rgb(<<r::binary-2, g::binary-2, b::binary-2>>),
    do: {byte(r) / 255, byte(g) / 255, byte(b) / 255}

  defp byte(pair), do: String.to_integer(pair, 16)

  defp linear(v) when v <= 0.04045, do: v / 12.92
  defp linear(v), do: :math.pow((v + 0.055) / 1.055, 2.4)

  defp gamma(v) when v <= 0.0031308, do: 12.92 * v
  defp gamma(v), do: 1.055 * :math.pow(v, 1 / 2.4) - 0.055

  defp oklab([r, g, b]) do
    l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
    m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
    s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)

    [
      0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
      0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    ]
  end

  defp lch([l, a, b]) do
    h = :math.atan2(b, a) * 180 / :math.pi()
    {l, :math.sqrt(a * a + b * b), if(h < 0, do: h + 360, else: h)}
  end

  defp lab({l, c, h}) do
    rad = h * :math.pi() / 180
    [l, c * :math.cos(rad), c * :math.sin(rad)]
  end

  defp srgb(color) do
    [l, a, b] = lab(color)
    l_ = :math.pow(l + 0.3963377774 * a + 0.2158037573 * b, 3)
    m_ = :math.pow(l - 0.1055613458 * a - 0.0638541728 * b, 3)
    s_ = :math.pow(l - 0.0894841775 * a - 1.2914855480 * b, 3)

    channels = [
      4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_,
      -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_,
      -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_
    ]

    if Enum.all?(channels, &(&1 >= -0.0001 and &1 <= 1.0001)),
      do: {:ok, Enum.map(channels, &(&1 |> clamp(0.0, 1.0) |> gamma()))},
      else: :out
  end

  # the largest chroma that stays in the gamut, by bisection
  defp fit(l, low, high, h) do
    if high - low < 0.0005 do
      low
    else
      mid = (low + high) / 2
      if srgb({l, mid, h}) == :out, do: fit(l, low, mid, h), else: fit(l, mid, high, h)
    end
  end

  defp hex(channels) do
    ("#" <>
       Enum.map_join(channels, fn v ->
         (v * 255)
         |> round()
         |> clamp(0, 255)
         |> Integer.to_string(16)
         |> String.pad_leading(2, "0")
       end))
    |> String.downcase()
  end

  defp cbrt(v) when v < 0, do: -:math.pow(-v, 1 / 3)
  defp cbrt(v), do: :math.pow(v, 1 / 3)

  defp clamp(v, low, high), do: v |> max(low) |> min(high)

  defp trim(a) do
    a
    |> Float.round(3)
    |> :erlang.float_to_binary([:compact, decimals: 3])
    |> String.trim_leading("0")
  end
end
