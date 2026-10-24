defmodule LineaUI.Components.Strings do
  @moduledoc false

  @strings %{
    "en" => %{
      color_area: "Saturation and brightness",
      color_area_text: "Saturation %{s}%, brightness %{v}%",
      color_hue: "Hue",
      color_alpha: "Opacity",
      color_hex: "Color in hex",
      color_presets: "Suggested colors",
      calendar_today: "Today",
      calendar_previous: "Previous",
      calendar_next: "Next",
      calendar_view: "View",
      calendar_month: "Month",
      calendar_week: "Week",
      calendar_all_day: "All day",
      calendar_week_of: "Week of %{from} to %{to}",
      calendar_title_month: "%{month} %{year}",
      signature_draw: "Draw",
      signature_type: "Type",
      signature_clear: "Clear",
      signature_area: "Signature area",
      signature_hint: "Sign here with your finger or the mouse",
      signature_name: "Type your name",
      signature_ready: "Signature ready",
      signature_empty: "No signature",
      filter_clear: "Clear",
      filter_apply: "Apply"
    },
    "pt_BR" => %{
      color_area: "Saturação e brilho",
      color_area_text: "Saturação %{s}%, brilho %{v}%",
      color_hue: "Matiz",
      color_alpha: "Opacidade",
      color_hex: "Cor em hex",
      color_presets: "Cores sugeridas",
      calendar_today: "Hoje",
      calendar_previous: "Anterior",
      calendar_next: "Próximo",
      calendar_view: "Visão",
      calendar_month: "Mês",
      calendar_week: "Semana",
      calendar_all_day: "Dia todo",
      calendar_week_of: "Semana de %{from} a %{to}",
      calendar_title_month: "%{month} de %{year}",
      signature_draw: "Desenhar",
      signature_type: "Digitar",
      signature_clear: "Limpar",
      signature_area: "Área de assinatura",
      signature_hint: "Assine aqui com o dedo ou o mouse",
      signature_name: "Digite o nome",
      signature_ready: "Assinatura pronta",
      signature_empty: "Sem assinatura",
      filter_clear: "Limpar",
      filter_apply: "Aplicar"
    }
  }

  @doc false
  @spec table(String.t(), map()) :: map()
  def table(locale, overrides \\ %{}), do: @strings |> Map.fetch!(locale) |> Map.merge(overrides)

  @doc false
  @spec fill(String.t(), map()) :: String.t()
  def fill(text, values) do
    Enum.reduce(values, text, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
