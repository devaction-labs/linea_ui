defmodule LineaUI.Components.NumberInput.Format do
  @moduledoc """
  The text of a number input, worked out on the server so the first paint already shows it.

  A value (an integer, a float, a numeric string or a `Decimal`) becomes its machine text
  (`"1234.5"`: a dot, no grouping), and the machine text becomes what the person reads
  (`"1.234,50"`) with the separators of a locale and a number of decimals. The browser hook
  does the same arithmetic in `number_input_logic.js`.

      iex> LineaUI.Components.NumberInput.Format.machine(1234.5)
      "1234.5"
      iex> LineaUI.Components.NumberInput.Format.display("1234.5", %{decimal: ",", group: ".", decimals: 2, max_decimals: nil})
      "1.234,50"
  """

  @dot_group ~w(pt es de it nl id da tr ro el hr sl sr vi)
  @space_group ~w(fr ru pl cs sk sv fi nb nn no uk hu bg lt lv et)

  @regions %{
    "es-mx" => {".", ","},
    "es-us" => {".", ","},
    "pt-pt" => {",", " "},
    "de-ch" => {".", "'"}
  }

  @number ~r/\A([+-]?)(\d*)(?:\.(\d+))?\z/

  @doc """
  The decimal and thousands separators of a locale (`"pt-BR"`, `"en"`, `"de-DE"`), as
  `{decimal, group}`. Unknown locales read like English.
  """
  @spec separators(String.t()) :: {String.t(), String.t()}
  def separators(locale) do
    key = locale |> String.downcase() |> String.replace("_", "-")
    Map.get(@regions, key) || language(key |> String.split("-") |> hd())
  end

  defp language(code) when code in @dot_group, do: {",", "."}
  defp language(code) when code in @space_group, do: {",", " "}
  defp language(_code), do: {".", ","}

  @doc """
  The machine text of a value: digits with a dot, no grouping, or `nil` for nothing. A
  `Decimal` is read through its fields, so LineaUI does not depend on the library.
  """
  @spec machine(term()) :: String.t() | nil
  def machine(nil), do: nil
  def machine(value) when is_integer(value), do: Integer.to_string(value)
  def machine(value) when is_float(value), do: float_text(value)

  def machine(%{__struct__: Decimal, sign: sign, coef: coef, exp: exp}) when is_integer(coef),
    do: decimal_text(sign, coef, exp)

  def machine(value) when is_binary(value), do: blank(String.trim(value))
  def machine(value), do: value |> to_string() |> machine()

  defp blank(""), do: nil
  defp blank(text), do: text

  defp float_text(value) do
    short = :erlang.float_to_binary(value, [:short])

    case String.contains?(short, "e") do
      true -> :erlang.float_to_binary(value, [{:decimals, 20}, :compact])
      false -> short
    end
  end

  defp decimal_text(sign, coef, exp) when exp >= 0,
    do: sign_text(sign) <> Integer.to_string(coef) <> String.duplicate("0", exp)

  defp decimal_text(sign, coef, exp) do
    digits = coef |> Integer.to_string() |> String.pad_leading(-exp + 1, "0")
    {whole, fraction} = String.split_at(digits, String.length(digits) + exp)
    sign_text(sign) <> whole <> "." <> fraction
  end

  defp sign_text(-1), do: "-"
  defp sign_text(_sign), do: ""

  @doc """
  The machine text the form submits: rounded to `decimals` (always that many) or to
  `max_decimals` (at most that many, trailing zeros dropped); with neither, the number with only
  the decimals it has. Text that is not a number is returned as it is.
  """
  @spec submitted(String.t() | nil, map()) :: String.t() | nil
  def submitted(nil, _opts), do: nil

  def submitted(text, opts) do
    case parse(text) do
      nil -> text
      number -> number |> round_to(opts) |> to_text(".")
    end
  end

  @doc """
  What the person reads: `submitted/2` with the locale's decimal separator and the whole part
  grouped by thousands. Text that is not a number is returned as it is; nothing is `""`.
  """
  @spec display(String.t() | nil, map()) :: String.t()
  def display(nil, _opts), do: ""

  def display(text, opts) do
    case parse(text) do
      nil -> text
      number -> number |> round_to(opts) |> to_text(opts.decimal, opts.group)
    end
  end

  @doc "The number of decimals a step like `\"0.01\"` has."
  @spec decimals_of(String.t() | nil) :: non_neg_integer()
  def decimals_of(nil), do: 0

  def decimals_of(text) do
    case parse(text) do
      nil -> 0
      {_int, scale, _fixed} -> scale
    end
  end

  defp parse(text) do
    case Regex.run(@number, text) do
      [_all, _sign, "" | _rest] ->
        nil

      [_all, sign, whole] ->
        {String.to_integer(sign <> whole), 0, nil}

      [_all, sign, whole, fraction] ->
        {String.to_integer(sign <> whole <> fraction), String.length(fraction), nil}

      nil ->
        nil
    end
  end

  defp round_to({int, scale, _fixed}, %{decimals: decimals}) when is_integer(decimals),
    do: {rescale(int, scale, decimals), decimals, decimals}

  defp round_to({int, scale, _fixed}, %{max_decimals: max}) when is_integer(max) and scale > max,
    do: trim({rescale(int, scale, max), max, nil})

  defp round_to(number, _opts), do: trim(number)

  defp rescale(int, scale, precision) when scale <= precision,
    do: int * pow10(precision - scale)

  defp rescale(int, scale, precision) do
    unit = pow10(scale - precision)
    sign = sign_of(int)
    sign * div(abs(int) * 2 + unit, unit * 2)
  end

  defp sign_of(int) when int < 0, do: -1
  defp sign_of(_int), do: 1

  defp pow10(exp), do: Integer.pow(10, exp)

  defp trim({int, scale, nil}) when scale > 0 and rem(int, 10) == 0,
    do: trim({div(int, 10), scale - 1, nil})

  defp trim(number), do: number

  defp to_text(number, decimal, group \\ "") do
    {int, scale, _fixed} = number
    digits = int |> abs() |> Integer.to_string() |> String.pad_leading(scale + 1, "0")
    {whole, fraction} = String.split_at(digits, String.length(digits) - scale)
    sign_text(sign_of(int)) <> group(whole, group) <> fraction_text(fraction, decimal)
  end

  defp fraction_text("", _decimal), do: ""
  defp fraction_text(fraction, decimal), do: decimal <> fraction

  defp group(whole, ""), do: whole

  defp group(whole, separator) do
    whole
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map_join(separator, &Enum.join/1)
    |> String.reverse()
  end
end
