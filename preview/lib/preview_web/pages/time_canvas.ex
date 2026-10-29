defmodule PreviewWeb.Pages.TimeCanvas do
  use PreviewWeb.Page, title: "Time canvas", category: :components

  @hint "text-xs text-slate-400 dark:text-navy-300"

  def render(assigns) do
    assigns =
      assign(assigns,
        hint: @hint,
        states: [
          {"Normal", :normal},
          {"Hover", :hover},
          {"Foco", :focus},
          {"Desabilitada (limite)", :disabled},
          {"Campo ativo", :field}
        ]
      )

    ~H"""
    <.example title="Seletor de hora" class="block">
      <div class="grid grid-cols-1 gap-x-6 gap-y-7 lg:grid-cols-3">
        <div class="space-y-4">
          <p class="text-[11px] font-semibold uppercase tracking-widest">Campo, estados</p>
          <.time_picker
            id="tp-a"
            name="a"
            label="Abertura"
            placeholder="Selecione a hora"
            help="Padrão, com ícone"
          />
          <.time_picker
            id="tp-b"
            name="b"
            label="Hover"
            placeholder="Selecione a hora"
            class="!border-slate-400 dark:!border-navy-400"
          />
          <.time_picker
            id="tp-c"
            name="c"
            label="Foco"
            placeholder="Selecione a hora"
            class="!border-primary ring-3 ring-primary/20 dark:!border-accent dark:ring-accent/20"
          />
          <.time_picker id="tp-d" name="d" label="Preenchido" value="09:30" time_24hr />
          <.time_picker id="tp-e" name="e" label="Desabilitado" value="09:30" time_24hr disabled />
          <.time_picker
            id="tp-f"
            name="f"
            label="Fechamento"
            placeholder="Selecione a hora"
            errors={["Escolha um horário entre 15:00 e 22:30."]}
          />
        </div>
        <div>
          <p class="mb-2.5 text-[11px] font-semibold uppercase tracking-widest">
            12 h com AM/PM · aberto
          </p>
          <.time_picker id="tp-s" name="s" label="Início" value="09:30" />
          <p class={["mt-2", @hint]}>minute_step 5 (padrão); AM/PM alterna com clique</p>
        </div>
        <div>
          <p class="mb-2.5 text-[11px] font-semibold uppercase tracking-widest">
            24 h, 15:00 a 22:30 · aberto
          </p>
          <.time_picker
            id="tp-t"
            name="t"
            label="Alarme"
            value="22:30"
            time_24hr
            min_time="15:00"
            max_time="22:30"
            minute_step={15}
          />
          <p class={["mt-2", @hint]}>
            min_time 15:00 · max_time 22:30 · minute_step 15: os limites desativam as setas
          </p>
        </div>
      </div>
    </.example>

    <.example title="Setas e campo numérico" class="block">
      <div class="flatpickr-calendar noCalendar open !static !flex !w-full !flex-wrap gap-x-7 gap-y-3.5">
        <.state :for={{label, kind} <- @states} label={label} kind={kind} />
      </div>
    </.example>
    """
  end

  defp state(%{kind: :field} = assigns) do
    ~H"""
    <div class="flatpickr-time stacked !flex-none !flex-col text-center text-[11px]">
      <div class="numInputWrapper !h-11 !flex-none">
        <input
          class="numInput flatpickr-hour !shadow-[inset_0_0_0_1px_var(--color-primary),0_0_0_3px_color-mix(in_oklab,var(--color-primary)_20%,transparent)]"
          type="text"
          value="09"
          readonly
          tabindex="-1"
          aria-hidden="true"
        />
      </div>
      <span class="mt-2 block">{@label}</span>
    </div>
    """
  end

  defp state(assigns) do
    ~H"""
    <div class="flatpickr-time stacked !flex-none !flex-col text-center text-[11px]">
      <div class="numInputWrapper !h-11 !flex-none !justify-center">
        <button
          type="button"
          class={["arrowUp", arrow_class(@kind)]}
          aria-hidden="true"
          tabindex="-1"
          aria-disabled={@kind == :disabled && "true"}
        >
        </button>
      </div>
      <span class="mt-2 block">{@label}</span>
    </div>
    """
  end

  defp arrow_class(:hover), do: "!bg-slate-150 !text-slate-800 dark:!bg-navy-500 dark:!text-navy-50"
  defp arrow_class(:focus), do: "outline-2 outline-offset-1 outline-primary/55"
  defp arrow_class(_kind), do: nil
end
