defmodule PreviewWeb.Pages.SignetumKitInputs do
  use PreviewWeb.Page, title: "Signetum inputs", category: :components, lineone: "elements-badge"

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

  @orders [
    {"PV-1284", "Drogaria Feira Saúde", "Balcão", "Faturado", 4280.0},
    {"PV-1283", "Clínica Santa Mônica", "Representante", "Aprovado", 12_850.4},
    {"PV-1282", "Ótica Visão Feira", "Loja online", "Rascunho", 2460.0},
    {"PV-1281", "Hospital Dom Pedro", "Representante", "Faturado", 9744.0},
    {"PV-1280", "Mercado Bom Preço", "Balcão", "Cancelado", 1890.0},
    {"PV-1279", "Farmácia Popular do Tomba", "Loja online", "Aprovado", 3120.0}
  ]

  def mount(socket) do
    assign(socket,
      color: "#4C3FE0",
      today: @today,
      cal_date: @today,
      cal_view: "month",
      cal_events: @events,
      cal_last: nil,
      signature: "",
      markup: 60,
      orders: @orders,
      pending: %{"status" => ["Aprovado", "Faturado"], "channel" => [], "sort" => "recent"},
      applied: %{"status" => ["Aprovado", "Faturado"], "channel" => [], "sort" => "recent"}
    )
  end

  def handle_event("color", %{"stage" => %{"color" => color}}, socket),
    do: {:noreply, assign(socket, color: color)}

  def handle_event("sign", %{"receipt" => %{"signature" => svg}}, socket),
    do: {:noreply, assign(socket, signature: svg)}

  def handle_event("draft", %{"filter" => params}, socket),
    do: {:noreply, assign(socket, pending: Map.merge(%{"status" => [], "channel" => []}, params))}

  def handle_event("apply", %{"filter" => params}, socket) do
    params = Map.merge(%{"status" => [], "channel" => []}, params)
    {:noreply, assign(socket, pending: params, applied: params)}
  end

  def handle_event("range", %{"markup" => markup}, socket),
    do: {:noreply, assign(socket, markup: String.to_integer(markup))}

  def handle_event("range", _params, socket), do: {:noreply, socket}

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
    <.example title="Number input" text="Steppers, min, max, step and a unit." class="mt-5 block">
      <div id="numbers" class="grid max-w-sm gap-4">
        <.number_input
          name="qty"
          value={12}
          label="Quantidade"
          steppers
          min={1}
          max={999}
          align="center"
          suffix="un"
          help="Em estoque: 148 un no Depósito central."
        />
        <.number_input
          name="discount"
          value={5}
          label="Desconto"
          steppers
          min={0}
          max={15}
          step={0.5}
          decimals={1}
          align="center"
          suffix="%"
        />
        <.number_input name="price" value={1486.9} label="Valor" prefix="R$" decimals={2} min={0} />
      </div>
    </.example>
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
    <.example
      title="Filter menu"
      text="Checkboxes and radios keep the menu open; submenus stay open; Clear and Apply."
      class="mt-5 block"
    >
      <form
        id="orders-filter"
        phx-change="draft"
        phx-submit="apply"
        class="mb-3 flex items-center gap-3"
      >
        <.dropdown
          id="orders-menu"
          label="Filtrar"
          keep_submenus
          close_on_select={false}
          class="min-w-56"
        >
          <.dropdown_submenu id="orders-status" label="Status" count={length(@pending["status"])}>
            <.dropdown_checkbox
              :for={status <- ~w(Aprovado Faturado Rascunho Cancelado)}
              name="filter[status][]"
              value={status}
              checked={status in @pending["status"]}
              count={Enum.count(@orders, &(elem(&1, 3) == status))}
            >
              {status}
            </.dropdown_checkbox>
          </.dropdown_submenu>
          <.dropdown_submenu
            id="orders-channel"
            label="Canal de venda"
            count={length(@pending["channel"])}
          >
            <.dropdown_checkbox
              :for={channel <- ~w(Balcão Representante)}
              name="filter[channel][]"
              value={channel}
              checked={channel in @pending["channel"]}
            >
              {channel}
            </.dropdown_checkbox>
          </.dropdown_submenu>
          <.dropdown_separator />
          <.dropdown_label>Ordenar por</.dropdown_label>
          <.dropdown_radio name="filter[sort]" value="recent" checked={@pending["sort"] == "recent"}>
            Mais recentes
          </.dropdown_radio>
          <.dropdown_radio name="filter[sort]" value="value" checked={@pending["sort"] == "value"}>
            Maior valor
          </.dropdown_radio>
          <.dropdown_footer
            locale="pt_BR"
            apply_count={length(@pending["status"]) + length(@pending["channel"])}
          />
        </.dropdown>
        <span class="text-xs-plus">Aplicado: <span id="applied">{inspect(@applied)}</span></span>
      </form>
    </.example>
    <.example title="Range" text="Value, marks, two thumbs, steps and vertical." class="mt-5 block">
      <form id="range-form" phx-change="range" class="grid max-w-lg gap-8">
        <.range
          name="markup"
          value={@markup}
          label="Markup padrão"
          min={0}
          max={200}
          step={5}
          color="primary"
          show_value
          value_format="%{value}%"
          filled
          marks={[{0, "0%"}, {50, "50%"}, {100, "100%"}, {150, "150%"}, {200, "200%"}]}
          help="Preço de venda sugerido = custo × (1 + markup)."
        />
        <.range
          start_name="from"
          end_name="to"
          value={{40, 280}}
          label="Faixa de preço"
          min={0}
          max={500}
          step={10}
          color="primary"
          show_value
          value_format="R$ %{value}"
          help="Dois polegares para filtrar por valor."
        />
        <.range
          name="tolerance"
          value={1}
          label="Tolerância da conciliação"
          min={0}
          max={3}
          color="primary"
          filled
          marks={[{0, "R$ 0,00"}, {1, "R$ 0,01"}, {2, "R$ 0,10"}, {3, "R$ 1,00"}]}
        />
        <div class="flex gap-8">
          <.range
            :for={{name, value} <- [{"price", 40}, {"term", 30}, {"quality", 20}]}
            name={name}
            value={value}
            label={String.capitalize(name)}
            orientation="vertical"
            color="primary"
            filled
            show_value
            value_format="%{value}%"
            steppers
            step={5}
          />
        </div>
      </form>
    </.example>
    """
  end
end
