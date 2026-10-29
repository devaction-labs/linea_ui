defmodule PreviewWeb.Pages.DateTimeCanvas do
  use PreviewWeb.Page, title: "Date and time canvas", category: :components

  @today ~D[2026-10-28]
  @hint "text-xs text-slate-400 dark:text-navy-300"

  def render(assigns) do
    assigns = assign(assigns, today: @today, hint: @hint)

    ~H"""
    <.example title="Campo: tamanhos, variantes e estados" class="block">
      <div class="grid grid-cols-1 gap-x-6 gap-y-4 md:grid-cols-2 xl:grid-cols-4">
        <.datetime_picker
          id="dt-i1"
          name="i1"
          locale="pt_BR"
          size="sm"
          label="Pequeno (sm)"
          value="2026-10-28T10:30"
          today={@today}
        />
        <.datetime_picker
          id="dt-i2"
          name="i2"
          locale="pt_BR"
          label="Médio (md, padrão)"
          placeholder="Selecionar data e hora"
        />
        <.datetime_picker
          id="dt-i3"
          name="i3"
          locale="pt_BR"
          size="lg"
          label="Grande (lg)"
          value="2026-10-28T10:30"
          today={@today}
        />
        <.datetime_picker
          id="dt-i4"
          name="i4"
          locale="pt_BR"
          label="Outlined, hover"
          placeholder="Selecionar data e hora"
          class="!border-slate-400 dark:!border-navy-400"
        />
        <.datetime_picker
          id="dt-i5"
          name="i5"
          locale="pt_BR"
          label="Outlined, foco"
          placeholder="Selecionar data e hora"
          class="!border-primary dark:!border-accent"
        />
        <.datetime_picker
          id="dt-i6"
          name="i6"
          locale="pt_BR"
          variant="filled"
          label="Filled"
          value="2026-10-28T10:30"
          today={@today}
        />
        <.datetime_picker
          id="dt-i7"
          name="i7"
          locale="pt_BR"
          variant="filled"
          label="Filled, foco"
          placeholder="Selecionar data e hora"
          class="ring-3"
        />
        <.datetime_picker
          id="dt-i8"
          name="i8"
          locale="pt_BR"
          label="Desabilitado"
          value="2026-10-28T10:30"
          today={@today}
          disabled
        />
        <.datetime_picker
          id="dt-i9"
          name="i9"
          locale="pt_BR"
          label="Com erro"
          placeholder="Selecionar data e hora"
          errors={["Escolha um horário a partir de agora."]}
        />
        <.datetime_picker
          id="dt-i10"
          name="i10"
          locale="pt_BR"
          mode="range"
          label="Intervalo"
          value={{~N[2026-10-26 09:00:00], ~N[2026-11-03 17:00:00]}}
          help={~s(mode="range")}
        />
      </div>
    </.example>

    <.example title="Data e hora e período" class="block">
      <div class="flex flex-wrap items-start gap-x-8 gap-y-7">
        <div class="w-[400px] max-w-full">
          <p class="mb-2.5 text-[11px] font-semibold uppercase tracking-widest">
            Data e hora · aberto
          </p>
          <.datetime_picker
            id="dt-open"
            name="open"
            locale="pt_BR"
            label="Início da reunião"
            value="2026-10-28T10:30"
            today={@today}
            interval={30}
            min_time="09:00"
            max_time="13:00"
            unavailable="12:00-13:00"
          />
          <p class={["mt-2", @hint]}>
            interval 30 · min_time 09:00 · max_time 13:00 · unavailable "12:00-13:00". Em tela estreita a lista vira um campo com "Selecionar".
          </p>
        </div>
        <div class="w-[640px] max-w-full">
          <p class="mb-2.5 text-[11px] font-semibold uppercase tracking-widest">Período · aberto</p>
          <.datetime_picker
            id="dt-range"
            name="range"
            locale="pt_BR"
            mode="range"
            label="Janela de entrega"
            value={{~N[2026-10-26 09:00:00], ~N[2026-11-03 17:00:00]}}
            today={@today}
          />
        </div>
      </div>
    </.example>
    """
  end
end
