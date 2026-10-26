defmodule LineaUI.Components.PhoneInput.Format do
  @moduledoc """
  Phone numbers on the server: the same reading of a number the `phone_input` does in the browser,
  for the value it submits and for checking what comes back.

  The browser formats what is typed so that it is easy to read; that is not validation. A
  person can submit anything, so a LiveView must run the submitted value through `e164/2` (or
  `parse/2`) and check the result itself. These functions work out the calling code, the
  country and the national digits, and accept lengths that E.164 allows; they do not know which
  numbers a carrier issues. For that, use a library with number metadata (`ex_phone_number`,
  `lib_phone_number`...) on the E.164 string.

      iex> LineaUI.Components.PhoneInput.Format.e164("(11) 91234-5678", "BR")
      {:ok, "+5511912345678"}
      iex> LineaUI.Components.PhoneInput.Format.e164("+55 11 91234-5678", "US")
      {:ok, "+5511912345678"}
      iex> LineaUI.Components.PhoneInput.Format.e164("", "BR")
      {:error, :blank}

  A number is read in one of two ways. Text starting with `+` is international: the calling code
  picks the country and the rest is the national number. Any other text is the national number of
  the country given (the second argument, `"BR"` unless said otherwise). Spaces, dashes, dots and
  parentheses are ignored, and so is the trunk prefix people dial before a national number (the
  `0` of `011 91234-5678` in Brazil, the `1` of `1 (201) 555-0123` in the United States).

  Countries that share a calling code are told apart by the national number's first digits, as
  the browser does: `+1 876…` is Jamaica, `+1 416…` is Canada, `+44 7911…` is Guernsey.

      iex> LineaUI.Components.PhoneInput.Format.parse("+1 876 555 0123")
      {:ok, %{country: "JM", code: "1", national: "8765550123", e164: "+18765550123"}}
  """

  alias LineaUI.Components.PhoneInput.Countries

  @max_digits 15
  @min_national 4
  @regional_a 0x1F1E6

  @type error :: :blank | :unknown_country | :invalid_length
  @type parsed :: %{country: String.t(), code: String.t(), national: String.t(), e164: String.t()}

  @doc """
  The E.164 number of `input` (`"+5511912345678"`), or the reason it is not one.

  `country` is the ISO 3166-1 alpha-2 code the national numbers are read in. Errors:

    * `:blank` - nothing but separators.
    * `:unknown_country` - an international number whose calling code does not exist, or a
      `country` that is not an ISO code.
    * `:invalid_length` - fewer than 4 or more than 15 digits in all, or a +1 number (the NANP)
      that does not have exactly 10 national digits.

  ## Examples

      iex> LineaUI.Components.PhoneInput.Format.e164("(201) 555-0123", "US")
      {:ok, "+12015550123"}
      iex> LineaUI.Components.PhoneInput.Format.e164("912 345 678", "PT")
      {:ok, "+351912345678"}
      iex> LineaUI.Components.PhoneInput.Format.e164("+999 123456", "BR")
      {:error, :unknown_country}
      iex> LineaUI.Components.PhoneInput.Format.e164("123", "BR")
      {:error, :invalid_length}
  """
  @spec e164(String.t() | nil, String.t()) :: {:ok, String.t()} | {:error, error()}
  def e164(input, country \\ "BR") do
    with {:ok, %{e164: e164}} <- parse(input, country), do: {:ok, e164}
  end

  @doc """
  Reads `input` like `e164/2` and returns the parts: the `country` ISO code the number belongs
  to (which, for an international number, may differ from the one given), its calling `code`,
  the `national` digits and the `e164` number.

      iex> LineaUI.Components.PhoneInput.Format.parse("+351 912 345 678")
      {:ok, %{country: "PT", code: "351", national: "912345678", e164: "+351912345678"}}
      iex> LineaUI.Components.PhoneInput.Format.parse("011 91234-5678", "BR")
      {:ok, %{country: "BR", code: "55", national: "11912345678", e164: "+5511912345678"}}
  """
  @spec parse(String.t() | nil, String.t()) :: {:ok, parsed()} | {:error, error()}
  def parse(input, country \\ "BR")

  def parse(input, country) when is_binary(input) do
    with {:ok, %{country: found, national: national}} <- resolve(input, country),
         :ok <- check_length(found, national) do
      {:ok,
       %{
         country: found.iso,
         code: found.code,
         national: national,
         e164: "+" <> found.code <> national
       }}
    end
  end

  def parse(_input, _country), do: {:error, :blank}

  @doc """
  The national format of a number, as the field shows it: `(11) 91234-5678` in Brazil,
  `(201) 555-0123` in the United States, `912 345 678` in Portugal. `input` is read like in
  `e164/2`; text that is not a number is returned as it is.

      iex> LineaUI.Components.PhoneInput.Format.national("+5511912345678")
      "(11) 91234-5678"
      iex> LineaUI.Components.PhoneInput.Format.national("2015550123", "US")
      "(201) 555-0123"
      iex> LineaUI.Components.PhoneInput.Format.national("11912", "BR")
      "(11) 912"
  """
  @spec national(String.t(), String.t()) :: String.t()
  def national(input, country \\ "BR") when is_binary(input) do
    case resolve(input, country) do
      {:ok, %{country: found, national: national}} -> display(national, found)
      {:error, _reason} -> input
    end
  end

  @doc """
  The flag emoji of an ISO 3166-1 alpha-2 code: its two letters as regional indicator symbols.

      iex> LineaUI.Components.PhoneInput.Format.flag("BR")
      "🇧🇷"
  """
  @spec flag(String.t()) :: String.t()
  def flag(iso) do
    iso
    |> String.upcase()
    |> String.to_charlist()
    |> Enum.map(&(@regional_a + &1 - ?A))
    |> List.to_string()
  end

  @doc """
  The calling code of an ISO code, without the `+`, or `nil` for a code that is not in the table.

      iex> LineaUI.Components.PhoneInput.Format.calling_code("BR")
      "55"
      iex> LineaUI.Components.PhoneInput.Format.calling_code("US")
      "1"
      iex> LineaUI.Components.PhoneInput.Format.calling_code("ZZ")
      nil
  """
  @spec calling_code(String.t()) :: String.t() | nil
  def calling_code(iso) do
    case Countries.get(iso) do
      nil -> nil
      country -> country.code
    end
  end

  @doc false
  @spec resolve(String.t(), String.t()) ::
          {:ok, %{country: map(), national: String.t()}} | {:error, :unknown_country}
  def resolve(input, default) do
    text = String.trim(input)
    digits = String.replace(text, ~r/\D/, "")
    read(text, digits, default)
  end

  @doc false
  @spec display(String.t(), map()) :: String.t()
  def display(national, country) do
    clipped = clip(national, country)
    pattern = pattern_for(country.patterns, String.length(clipped))
    fill(String.graphemes(pattern), String.graphemes(clipped), "", "")
  end

  @doc false
  @spec number(String.t(), map()) :: String.t()
  def number("", _country), do: ""
  def number(national, country), do: "+" <> country.code <> clip(national, country)

  defp clip(national, country),
    do: String.slice(national, 0, @max_digits - String.length(country.code))

  defp read("+" <> _rest, digits, _default) do
    with code when is_binary(code) <- Countries.code_of(digits),
         %{} = base <- Countries.main_of(code) do
      {:ok, settle(String.replace_prefix(digits, code, ""), base)}
    else
      nil -> {:error, :unknown_country}
    end
  end

  defp read(_text, digits, default) do
    case Countries.get(default) do
      nil -> {:error, :unknown_country}
      base -> {:ok, settle(digits, base)}
    end
  end

  defp settle(digits, base) do
    national = String.replace_prefix(digits, base.trunk, "")
    %{country: Countries.lead_of(base.code, national) || base, national: national}
  end

  defp check_length(country, national) do
    size = String.length(national)

    cond do
      size == 0 -> {:error, :blank}
      country.code == "1" and size != 10 -> {:error, :invalid_length}
      size < @min_national -> {:error, :invalid_length}
      size > @max_digits - String.length(country.code) -> {:error, :invalid_length}
      true -> :ok
    end
  end

  defp pattern_for(patterns, count),
    do: Enum.find(patterns, &(capacity(&1) >= count)) || List.last(patterns)

  defp capacity(pattern), do: pattern |> String.graphemes() |> Enum.count(&(&1 == "#"))

  defp fill(_pattern, [], out, _pending), do: out
  defp fill([], rest, out, _pending), do: out <> Enum.join(rest)

  defp fill(["#" | pattern], [digit | rest], out, pending),
    do: fill(pattern, rest, out <> pending <> digit, "")

  defp fill([literal | pattern], digits, out, pending),
    do: fill(pattern, digits, out, pending <> literal)
end
