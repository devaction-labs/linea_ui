defmodule LineaUI.Components.PhoneInput.Countries do
  @moduledoc false

  @source Path.expand("../../../../assets/js/linea_ui/lib/phone_countries.js", __DIR__)
  @external_resource @source

  @row ~r/^  \["([A-Z]{2})", "([^"]*)", "([^"]*)", "(\d+)", "([^"]*)", "([^"]*)", "([^"]*)"\],$/m
  @main_row ~r/^  (\d+): "([A-Z]{2})",$/m

  @text File.read!(@source)

  @countries Enum.map(Regex.scan(@row, @text), fn [
                                                    _row,
                                                    iso,
                                                    en,
                                                    pt,
                                                    code,
                                                    patterns,
                                                    leads,
                                                    trunk
                                                  ] ->
               %{
                 iso: iso,
                 en: en,
                 pt: pt,
                 code: code,
                 patterns: String.split(patterns, "|"),
                 leads: String.split(leads, ",", trim: true),
                 trunk: trunk
               }
             end)

  @main Map.new(Regex.scan(@main_row, @text), fn [_row, code, iso] -> {code, iso} end)

  @by_iso Map.new(@countries, &{&1.iso, &1})
  @codes @countries |> Enum.map(& &1.code) |> Enum.uniq() |> MapSet.new()

  @doc false
  @spec all() :: [map()]
  def all, do: @countries

  @doc false
  @spec get(term()) :: map() | nil
  def get(iso) when is_binary(iso), do: Map.get(@by_iso, String.upcase(iso))
  def get(_iso), do: nil

  @doc false
  @spec code_of(String.t()) :: String.t() | nil
  def code_of(digits) do
    [1, 2, 3]
    |> Enum.map(&String.slice(digits, 0, &1))
    |> Enum.find(&MapSet.member?(@codes, &1))
  end

  @doc false
  @spec main_of(String.t()) :: map() | nil
  def main_of(code) do
    sharing = Enum.filter(@countries, &(&1.code == code))
    Enum.find(sharing, &(&1.iso == Map.get(@main, code))) || List.first(sharing)
  end

  @doc false
  @spec lead_of(String.t(), String.t()) :: map() | nil
  def lead_of(code, national) do
    @countries
    |> Enum.filter(&(&1.code == code))
    |> Enum.flat_map(fn country ->
      for lead <- country.leads,
          String.starts_with?(national, lead),
          do: {String.length(lead), country}
    end)
    |> Enum.max_by(&elem(&1, 0), fn -> nil end)
    |> country_of()
  end

  defp country_of(nil), do: nil
  defp country_of({_size, country}), do: country
end
