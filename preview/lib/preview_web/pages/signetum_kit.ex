defmodule PreviewWeb.Pages.SignetumKit do
  use PreviewWeb.Page, title: "Signetum kit", category: :components, lineone: "elements-badge"

  @today ~D[2026-10-24]

  @events [
    %{id: 1, title: "Drogaria Feira 1/3", date: ~D[2026-10-02], color: "success"},
    %{id: 2, title: "PC-0398 3/3", date: ~D[2026-10-05], color: "error"},
    %{id: 3, title: "Visita Hospital Dom Pedro", date: ~D[2026-10-08], color: "primary"},
    %{id: 4, title: "Manifestar NF 88.412", date: ~D[2026-10-12], color: "warning"},
    %{id: 5, title: "Coelba", date: ~D[2026-10-15], color: "error"},
    %{id: 6, title: "Ótica Visão 1/2", date: ~D[2026-10-15], color: "success"},
    %{
      id: 7,
      title: "Proposta Clínica",
      subtitle: "Santa Mônica · 1h",
      date: ~D[2026-10-21],
      start: "10:00",
      end: "11:00",
      color: "primary"
    },
    %{
      id: 8,
      title: "Manifestar NF",
      subtitle: "88.530 · prazo final",
      date: ~D[2026-10-19],
      start: "08:00",
      end: "09:00",
      color: "warning"
    },
    %{
      id: 9,
      title: "Ligar p/ Mercado",
      subtitle: "Bom Preço · Carlos",
      date: ~D[2026-10-22],
      start: "11:00",
      end: "12:00",
      color: "primary"
    },
    %{id: 10, title: "Reunião de equipe", date: ~D[2026-10-23]}
  ]

  def mount(socket) do
    assign(socket,
      color: "#4C3FE0",
      today: @today,
      cal_date: @today,
      cal_view: "month",
      cal_events: @events,
      cal_last: nil,
      signature: ""
    )
  end

  def handle_event("color", %{"stage" => %{"color" => color}}, socket),
    do: {:noreply, assign(socket, color: color)}

  def handle_event("sign", %{"receipt" => %{"signature" => svg}}, socket),
    do: {:noreply, assign(socket, signature: svg)}

  def handle_event("cal_navigate", %{"date" => date, "view" => view}, socket),
    do: {:noreply, assign(socket, cal_date: Date.from_iso8601!(date), cal_view: view)}

  def handle_event("cal_view", %{"date" => date, "view" => view}, socket),
    do: {:noreply, assign(socket, cal_date: Date.from_iso8601!(date), cal_view: view)}

  def handle_event("cal_select", %{"date" => date}, socket),
    do: {:noreply, assign(socket, cal_last: "day #{date}")}

  def handle_event("cal_event", %{"event" => id, "date" => date}, socket),
    do: {:noreply, assign(socket, cal_last: "event #{id} on #{date}")}

  def render(assigns) do
    ~H"""
    <.example title="Color picker" text="Drag the area, pick a preset or type a hex." class="mt-5">
      <form id="stage-form" phx-change="color" class="w-72">
        <.color_picker id="stage-color" name="stage[color]" value={@color} label="Stage color" />
      </form>
      <.color_picker
        id="overlay-color"
        name="overlay"
        value="#EB3B2F80"
        alpha
        locale="pt_BR"
        label="Com opacidade"
        class="w-72"
      />
      <p class="text-xs-plus">Color: <span id="color-value">{@color}</span></p>
    </.example>
    <.example title="Calendar" text="Month and week grids with events." class="mt-5 block">
      <.calendar
        id="due"
        view={@cal_view}
        date={@cal_date}
        today={@today}
        events={@cal_events}
        locale="pt_BR"
        on_navigate="cal_navigate"
        on_view="cal_view"
        on_select="cal_select"
        on_event="cal_event"
        legend={[
          {"Conta a pagar", "error"},
          {"Conta a receber", "success"},
          {"Prazo de manifestação", "warning"},
          {"Compromisso do CRM", "primary"}
        ]}
      />
      <p class="mt-2 text-xs-plus">Last: <span id="cal-last">{@cal_last}</span></p>
    </.example>
    <.example
      title="Signature pad"
      text="Draw with the pointer or type a name; it exports SVG."
      class="mt-5 block"
    >
      <form id="receipt-form" phx-change="sign" class="max-w-xl">
        <.signature_pad
          id="receipt-signature"
          name="receipt[signature]"
          label="Comprovante"
          locale="pt_BR"
          text="Marcos Oliveira"
        />
      </form>
      <p class="mt-2 text-xs-plus">SVG: <span id="sign-size">{byte_size(@signature)}</span> bytes</p>
    </.example>
    """
  end
end
