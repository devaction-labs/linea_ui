defmodule PreviewWeb.Pages.AccordionCanvas do
  use PreviewWeb.Page, title: "Accordion and collapse (canvas)", category: :components

  @q1 "Como acompanho o status de um pedido?"
  @a1 "Abra o pedido na lista e veja a linha do tempo: cada mudança de status aparece com data, hora e responsável."
  @q2 "Posso alterar o endereço depois do pagamento?"
  @a2 "Sim, enquanto o pedido estiver em separação. Depois que sai para entrega, só o atendimento consegue alterar."
  @q3 "Quando o reembolso cai na conta?"
  @a3 "Em até 5 dias úteis após a aprovação, no mesmo meio de pagamento usado na compra."

  @grid "grid grid-cols-1 items-start gap-x-7 gap-y-5 lg:grid-cols-3"

  def render(assigns) do
    assigns = assign(assigns, q1: @q1, a1: @a1, q2: @q2, a2: @a2, q3: @q3, a3: @a3, grid: @grid)

    ~H"""
    <.example
      title="Accordion"
      text="um aberto por vez (name no details); com multiple, independentes"
    >
      <div class={["w-full", @grid]}>
        <.cell title={~s(variant="basic")} id="ac-basic" variant="basic" open={0} {assigns} />
        <.cell
          title={~s(variant="border-bottom")}
          id="ac-bb"
          variant="border-bottom"
          open={1}
          {assigns}
        />
        <.cell title={~s(variant="bordered")} id="ac-bd" variant="bordered" open={0} {assigns} />
        <.cell title={~s(variant="divided")} id="ac-dv" variant="divided" open={1} {assigns} />
        <.cell
          title={~s(variant="primary" · color="primary")}
          id="ac-pr"
          variant="primary"
          open={0}
          {assigns}
        />
        <.cell
          title={~s(variant="primary" · color="warning")}
          id="ac-pw"
          variant="primary"
          color="warning"
          open={1}
          {assigns}
        />

        <div class="rounded-xl p-5 ring-1 ring-slate-150 dark:ring-navy-500">
          <h3 class="mb-3 text-xs font-semibold text-slate-400">As seis cores de color</h3>
          <div class="grid grid-cols-2 gap-2.5">
            <.accordion
              :for={c <- ~w(primary secondary info success warning error)}
              id={"ac-c-#{c}"}
              variant="primary"
              color={c}
            >
              <.accordion_item id={"ac-c-#{c}-1"} title={c} trigger_class="!px-3 !py-2.5 !text-[13px]">
                x
              </.accordion_item>
            </.accordion>
          </div>
        </div>

        <div class="rounded-xl p-5 ring-1 ring-slate-150 dark:ring-navy-500">
          <h3 class="mb-3 text-xs font-semibold text-slate-400">variant="advanced" · slot :header</h3>
          <.accordion id="ac-adv" variant="advanced">
            <.accordion_item
              :for={
                {n, name, role, color, o} <- [
                  {1, "Ana Souza", "Gerente de projetos", "primary", true},
                  {2, "Carlos Lima", "Desenvolvedor", "info", false}
                ]
              }
              id={"ac-adv-#{n}"}
              open={o}
            >
              <:header>
                <.avatar name={name} color={color} size="xs-plus" />
                <div>
                  <p class="text-sm font-medium text-slate-700 dark:text-navy-100">{name}</p>
                  <p class="text-xs text-slate-500 dark:text-navy-300">{role}</p>
                </div>
              </:header>
              <p>Responsável por 12 projetos ativos neste trimestre. Último acesso hoje às 09:41.</p>
            </.accordion_item>
          </.accordion>
        </div>
      </div>
    </.example>

    <.example title="Collapse avulso" text="native details, sem JavaScript para abrir e fechar">
      <div class="grid w-full grid-cols-1 gap-x-7 gap-y-5 lg:grid-cols-2">
        <div class="rounded-xl p-5 ring-1 ring-slate-150 dark:ring-navy-500">
          <h3 class="mb-3 text-xs font-semibold text-slate-400">Collapse · chevron="down"</h3>
          <div class="divide-y divide-slate-150 rounded-xl px-5 py-1.5 ring-1 ring-slate-150 dark:divide-navy-500 dark:ring-navy-500">
            <.collapse id="co-1" open chevron="down" variant="section">
              <:trigger class="-mx-2 rounded-lg px-2 py-3.5 text-xs! tracking-[.06em] text-slate-700! dark:text-navy-100!">
                Meus arquivos
              </:trigger>
              <ul class="flex flex-col gap-1.5 pb-3 text-sm">
                <li :for={{f, i} <- [{"Contratos", "huge-folder-01"}, {"Propostas", "huge-folder-01"}, {"briefing.pdf", "huge-file-01"}]} class="flex items-center gap-2 text-[13.5px] text-slate-600 dark:text-navy-100"><.icon name={i} class="size-4 text-slate-400" />{f}</li>
              </ul>
            </.collapse>
            <.collapse id="co-2" chevron="down" variant="section">
              <:trigger class="-mx-2 rounded-lg px-2 py-3.5 text-xs! tracking-[.06em] text-slate-700! outline-2 outline-offset-2 outline-primary/55 outline-solid dark:text-navy-100!">
                Compartilhados
              </:trigger>
              <p class="pb-3 text-sm">Contratos</p>
            </.collapse>
          </div>
        </div>
        <div class="rounded-xl p-5 ring-1 ring-slate-150 dark:ring-navy-500">
          <h3 class="mb-3 text-xs font-semibold text-slate-400">
            Collapse · chevron="right" · abre independente
          </h3>
          <div class="divide-y divide-slate-150 rounded-xl px-5 py-1.5 ring-1 ring-slate-150 dark:divide-navy-500 dark:ring-navy-500">
            <.collapse
              :for={
                {n, t, b, o} <- [
                  {1, "Entrega", "Rápido Sul, previsão para quinta-feira.", true},
                  {2, "Pagamento", "Pix confirmado em 24 out às 17:30.", true},
                  {3, "Notas internas", "Sem observações.", false}
                ]
              }
              id={"co-r-#{n}"}
              open={o}
              chevron="right"
              variant="section"
            >
              <:trigger class="-mx-2 rounded-lg px-2 py-3.5 text-xs! tracking-[.06em] text-slate-700! dark:text-navy-100!">
                {t}
              </:trigger>
              <p class="pb-3 text-sm">{b}</p>
            </.collapse>
          </div>
        </div>
      </div>
    </.example>
    """
  end

  attr :title, :string, required: true
  attr :id, :string, required: true
  attr :variant, :string, required: true
  attr :color, :string, default: "primary"
  attr :open, :integer, required: true
  attr :q1, :string
  attr :a1, :string
  attr :q2, :string
  attr :a2, :string
  attr :q3, :string
  attr :a3, :string
  attr :rest, :global

  defp cell(assigns) do
    ~H"""
    <div class="rounded-xl px-5 py-1.5 ring-1 ring-slate-150 dark:ring-navy-500">
      <h3 class="mt-2 mb-1 text-xs font-semibold text-slate-400">{@title}</h3>
      <.accordion id={@id} variant={@variant} color={@color}>
        <.accordion_item
          :for={{n, q, a} <- [{0, @q1, @a1}, {1, @q2, @a2}, {2, @q3, @a3}]}
          id={"#{@id}-#{n}"}
          title={q}
          open={n == @open}
          trigger_class={@variant == "border-bottom" && n == 2 && "outline-2 outline-offset-2 outline-primary/55 outline-solid"}
        >
          <p>{a}</p>
        </.accordion_item>
      </.accordion>
    </div>
    """
  end
end
