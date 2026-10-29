defmodule PreviewWeb.Pages.CalendarCanvas do
  use PreviewWeb.Page, title: "Calendar (artboard)", category: :components

  @events [
    %{id: 1, title: "Planejamento do trimestre", date: ~D[2026-09-28], color: "neutral"},
    %{id: 2, title: "Kickoff do projeto", date: ~D[2026-10-01], color: "primary"},
    %{id: 3, title: "Entrega da sprint 14", date: ~D[2026-10-05], color: "success"},
    %{id: 4, title: "Revisão de contrato", date: ~D[2026-10-08], color: "warning"},
    %{id: 5, title: "Feriado", date: ~D[2026-10-12], color: "neutral"},
    %{id: 6, title: "Reunião com Ana Souza", date: ~D[2026-10-14], color: "info"},
    %{id: 7, title: "Pagamento fornecedor", date: ~D[2026-10-15], color: "error"},
    %{id: 8, title: "Daily do time", date: ~D[2026-10-15], color: "neutral"},
    %{id: 9, title: "Revisão de PR", date: ~D[2026-10-15], color: "primary"},
    %{id: 10, title: "Reunião de alinhamento", date: ~D[2026-10-15], color: "info"},
    %{id: 11, title: "Retrospectiva", date: ~D[2026-10-15], color: "secondary"},
    %{id: 12, title: "Visita ao cliente", date: ~D[2026-10-19], color: "info"},
    %{id: 13, title: "Prazo da proposta", date: ~D[2026-10-22], color: "error"},
    %{id: 14, title: "Planejamento da semana", date: ~D[2026-10-26], color: "primary"},
    %{id: 15, title: "1:1 com Carlos Lima", date: ~D[2026-10-26], color: "neutral"},
    %{id: 16, title: "Workshop de design", date: ~D[2026-10-28], color: "secondary"},
    %{id: 17, title: "Fechamento do mês", date: ~D[2026-10-29], color: "warning"},
    %{id: 18, title: "Release 2.4", date: ~D[2026-10-30], color: "success"}
  ]

  @week [
    %{id: 21, title: "Entrega parcial", date: ~D[2026-10-27], color: "success"},
    %{
      id: 22,
      title: "Workshop de design",
      subtitle: "Sala 2 · 09:00–10:00",
      date: ~D[2026-10-28],
      start: "09:00",
      end: "10:00",
      color: "secondary"
    },
    %{
      id: 23,
      title: "Planejamento da semana",
      subtitle: "10:00–11:30",
      date: ~D[2026-10-26],
      start: "10:00",
      end: "11:30",
      color: "primary"
    },
    %{
      id: 24,
      title: "Fechamento do mês",
      subtitle: "10:00–11:00",
      date: ~D[2026-10-29],
      start: "10:00",
      end: "11:00",
      color: "warning"
    },
    %{
      id: 25,
      title: "1:1 com Carlos Lima",
      subtitle: "11:00–12:00",
      date: ~D[2026-10-28],
      start: "11:00",
      end: "12:00",
      color: "neutral"
    },
    %{
      id: 26,
      title: "Release 2.4",
      subtitle: "13:00–14:00",
      date: ~D[2026-10-30],
      start: "13:00",
      end: "14:00",
      color: "success"
    }
  ]

  @legend [
    {"Reunião", "info"},
    {"Prazo", "error"},
    {"Entrega", "success"},
    {"Atenção", "warning"},
    {"Planejamento", "primary"},
    {"Evento", "secondary"},
    {"Interno", "neutral"}
  ]

  def render(assigns) do
    assigns = assign(assigns, events: @events, week: @week, legend: @legend)

    ~H"""
    <.example title="Visão mensal" text="Semana começa no domingo, hoje 28 out 2026" class="mt-5">
      <.calendar
        id="cal-month"
        locale="pt_BR"
        date={~D[2026-10-28]}
        today={~D[2026-10-28]}
        selected={~D[2026-10-22]}
        events={@events}
        legend={@legend}
        on_navigate="noop"
        on_view="noop"
        on_select="noop"
        on_event="noop"
      />
    </.example>
    <.example title="Visão semanal" text="day_start 8, day_end 14" class="mt-5">
      <.calendar
        id="cal-week"
        view="week"
        locale="pt_BR"
        date={~D[2026-10-28]}
        today={~D[2026-10-28]}
        events={@week}
        day_start={8}
        day_end={14}
        on_navigate="noop"
        on_view="noop"
        on_select="noop"
        on_event="noop"
      />
    </.example>
    """
  end
end
