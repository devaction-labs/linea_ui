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
      calendar_day: "%{weekday}, %{month} %{day}, %{year}",
      calendar_more: "%{count} more",
      signature_draw: "Draw",
      signature_type: "Type",
      signature_clear: "Clear",
      signature_area: "Signature area",
      signature_hint: "Sign here with your finger or the mouse",
      signature_name: "Type your name",
      signature_ready: "Signature ready",
      signature_empty: "No signature",
      filter_label: "Filters",
      filter_clear: "Clear",
      filter_apply: "Apply",
      datetime_select: "Select",
      datetime_select_range: "Select range",
      datetime_start: "Start",
      datetime_end: "End",
      datetime_time: "Time",
      datetime_times: "Times",
      datetime_no_times: "No times available",
      datetime_time_placeholder: "hh:mm",
      datetime_previous: "Previous month",
      datetime_next: "Next month",
      datetime_day: "%{weekday}, %{month} %{day}, %{year}",
      datetime_title: "%{month} %{year}",
      datetime_dialog: "Choose date and time",
      datetime_dialog_range: "Choose a date and time range",
      datetime_placeholder: "Select date and time",
      datetime_placeholder_range: "Select date range"
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
      calendar_day: "%{weekday}, %{day} de %{month} de %{year}",
      calendar_more: "mais %{count}",
      signature_draw: "Desenhar",
      signature_type: "Digitar",
      signature_clear: "Limpar",
      signature_area: "Área de assinatura",
      signature_hint: "Assine aqui com o dedo ou o mouse",
      signature_name: "Digite o nome",
      signature_ready: "Assinatura pronta",
      signature_empty: "Sem assinatura",
      filter_label: "Filtros",
      filter_clear: "Limpar",
      filter_apply: "Aplicar",
      datetime_select: "Selecionar",
      datetime_select_range: "Selecionar período",
      datetime_start: "Início",
      datetime_end: "Fim",
      datetime_time: "Hora",
      datetime_times: "Horários",
      datetime_no_times: "Nenhum horário disponível",
      datetime_time_placeholder: "hh:mm",
      datetime_previous: "Mês anterior",
      datetime_next: "Próximo mês",
      datetime_day: "%{weekday}, %{day} de %{month} de %{year}",
      datetime_title: "%{month} de %{year}",
      datetime_dialog: "Escolher data e hora",
      datetime_dialog_range: "Escolher período com data e hora",
      datetime_placeholder: "Selecionar data e hora",
      datetime_placeholder_range: "Selecionar período"
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
