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
            label="Vencimento"
            placeholder="Selecione a data"
            help="Padrão, com ícone"
          />
          <.date_picker
            id="dp-b"
            name="b"
            locale="pt_BR"
            today={@today}
            label="Hover"
            placeholder="Selecione a data"
          />
          <.date_picker
            id="dp-c"
            name="c"
            locale="pt_BR"
            today={@today}
            label="Foco"
            placeholder="Selecione a data"
          />
          <.date_picker
            id="dp-d"
            name="d"
            locale="pt_BR"
            today={@today}
            label="Preenchido"
            value={~D[2026-10-15]}
          />
          <.date_picker
            id="dp-e"
            name="e"
            locale="pt_BR"
            today={@today}
            label="Desabilitado"
            value={~D[2026-10-15]}
            disabled
          />
          <.date_picker
            id="dp-f"
            name="f"
            locale="pt_BR"
            today={@today}
            label="Entrega"
            placeholder="Selecione a data"
            errors={["Informe a data de entrega."]}
          />
          <.date_picker
            id="dp-g"
            name="g"
            locale="pt_BR"
            today={@today}
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
          presets={[
            {"Hoje", "today"},
            {"Últimos 7 dias", "last_7_days"},
            {"Este mês", "this_month"},
            {"Mês passado", "last_month"}
          ]}
        />
      </.example>
    </div>
    """
  end
end
