defmodule PreviewWeb.Pages.DatePickerCanvas do
  use PreviewWeb.Page, title: "Date picker (artboard)", category: :components

  @today ~D[2026-10-28]

  def mount(socket), do: assign(socket, today: @today)

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 gap-6 lg:grid-cols-3" id="dp-canvas">
      <.example title="Campo, estados" class="mt-5 flex-col gap-4">
        <div class="flex w-full flex-col gap-4">
          <.date_picker
            id="dp-a"
            name="a"
            locale="pt_BR"
            today={@today}
            skin="linea"
            label="Vencimento"
            placeholder="Selecione a data"
            help="Padrão, com ícone"
          />
          <.date_picker
            id="dp-b"
            name="b"
            locale="pt_BR"
            today={@today}
            skin="linea"
            label="Hover"
            placeholder="Selecione a data"
          />
          <.date_picker
            id="dp-c"
            name="c"
            locale="pt_BR"
            today={@today}
            skin="linea"
            label="Foco"
            placeholder="Selecione a data"
          />
          <.date_picker
            id="dp-d"
            name="d"
            locale="pt_BR"
            today={@today}
            skin="linea"
            label="Preenchido"
            value={~D[2026-10-15]}
          />
          <.date_picker
            id="dp-e"
            name="e"
            locale="pt_BR"
            today={@today}
            skin="linea"
            label="Desabilitado"
            value={~D[2026-10-15]}
            disabled
          />
          <.date_picker
            id="dp-f"
            name="f"
            locale="pt_BR"
            today={@today}
            skin="linea"
            label="Entrega"
            placeholder="Selecione a data"
            errors={["Informe a data de entrega."]}
          />
          <.date_picker
            id="dp-g"
            name="g"
            locale="pt_BR"
            today={@today}
            skin="linea"
            label="Sem ícone (show_icon=false)"
            placeholder="dd/mm/aaaa"
            show_icon={false}
          />
        </div>
      </.example>

      <.example title="Data única, aberto" class="mt-5 flex-col">
        <.date_picker
          id="dp-s"
          name="s"
          locale="pt_BR"
          today={@today}
          label="Entrega"
          value={~D[2026-10-30]}
          min={~D[2026-10-05]}
          disabled_weekdays={[0, 6]}
          disabled_dates={[~D[2026-10-12]]}
          inline
          skin="linea"
          help="min 05/10 · fins de semana e 12/10 desabilitados"
        />
      </.example>

      <.example title="Intervalo com atalhos, aberto" class="mt-5 flex-col">
        <.date_picker
          id="dp-r"
          name="r"
          locale="pt_BR"
          today={@today}
          label="Período"
          mode="range"
          value={{~D[2026-10-22], ~D[2026-10-28]}}
          inline
          skin="linea"
          presets={[
            {"Hoje", "today"},
            {"Últimos 7 dias", "last_7_days"},
            {"Este mês", "this_month"},
            {"Mês passado", "last_month"}
          ]}
        />
      </.example>
    </div>

    <style>#dp-states .flatpickr-day { width: 36px; flex: none; }</style>
    <.example title="Estados do dia" text="The day cells with the picker's own classes." class="mt-5">
      <div
        id="dp-states"
        data-skin="linea"
        class="flatpickr-calendar"
        style="position: static; display: block; visibility: visible; opacity: 1; width: auto; padding: 0; box-shadow: none; background: transparent"
      >
        <div class="flex flex-wrap items-start gap-x-6 gap-y-3">
          <.state label="Normal">
            <span class="flatpickr-day">14</span>
          </.state>
          <.state label="Hover">
            <span class="flatpickr-day" style="background: var(--lp-hover); color: var(--lp-ink)">
              15
            </span>
          </.state>
          <.state label="Hoje"><span class="flatpickr-day today">28</span></.state>
          <.state label="Selecionado"><span class="flatpickr-day selected">30</span></.state>
          <.state label="Intervalo">
            <div class="flex">
              <span class="flatpickr-day selected startRange">22</span>
              <span class="flatpickr-day inRange">23</span>
              <span class="flatpickr-day selected endRange">24</span>
            </div>
          </.state>
          <.state label="Desabilitado">
            <span class="flatpickr-day flatpickr-disabled">12</span>
          </.state>
          <.state label="Fora do mês"><span class="flatpickr-day nextMonthDay">2</span></.state>
          <.state label="Foco por teclado">
            <span class="flatpickr-day" style="box-shadow: inset 0 0 0 2px var(--lp-main)">30</span>
          </.state>
        </div>
      </div>
    </.example>
    """
  end

  attr :label, :string, required: true
  slot :inner_block, required: true

  defp state(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-1.5 text-tiny-plus text-slate-500 dark:text-navy-200">
      <div>{render_slot(@inner_block)}</div>
      {@label}
    </div>
    """
  end
end
