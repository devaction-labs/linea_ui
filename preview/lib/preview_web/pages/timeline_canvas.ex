defmodule PreviewWeb.Pages.TimelineCanvas do
  use PreviewWeb.Page, title: "Timeline canvas", category: :components

  # Heroicons outline paths, as the design canvas draws them.
  @icons %{
    truck:
      "M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12",
    warning:
      "M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z",
    chat:
      "M8.625 9.75a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm0 0H8.25m4.125 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm0 0H12m4.125 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm0 0h-.375m-13.5 3.01c0 1.6 1.123 2.994 2.707 3.227 1.087.16 2.185.283 3.293.369V21l4.184-4.183a1.14 1.14 0 0 1 .778-.332 48.294 48.294 0 0 0 5.83-.498c1.585-.233 2.708-1.626 2.708-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0 0 12 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018Z",
    banknotes:
      "M2.25 18.75a60.07 60.07 0 0 1 15.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 0 1 3 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 0 0-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 0 1-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 0 0 3 15h-.75M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm3 0h.008v.008H18V10.5Zm-12 0h.008v.008H6V10.5Z",
    user_plus:
      "M18 7.5v3m0 0v3m0-3h3m-3 0h-3m-2.25-4.125a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0ZM3 19.235v-.11a6.375 6.375 0 0 1 12.75 0v.109A12.318 12.318 0 0 1 9.374 21c-2.331 0-4.512-.645-6.374-1.766Z",
    document_plus:
      "M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m3.75 9v6m3-3H9m1.5-12H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z",
    paperclip:
      "m18.375 12.739-7.693 7.693a4.5 4.5 0 0 1-6.364-6.364l10.94-10.94A3 3 0 1 1 19.5 7.372L8.552 18.32m.009-.01-.01.01m5.699-9.941-7.81 7.81a1.5 1.5 0 0 0 2.112 2.13"
  }

  @card "rounded-2xl bg-white px-6 pt-5 pb-3 shadow-[0_0_0_1px_var(--color-slate-200)] dark:bg-navy-700 dark:shadow-[0_0_0_1px_var(--color-navy-600)]"
  @caps "mb-2.5 text-[11px] font-semibold uppercase tracking-widest text-slate-400 dark:text-navy-300"
  @h3 "mb-4 text-sm font-semibold text-slate-700 dark:text-navy-50"
  @strong "font-semibold text-slate-700 dark:text-navy-50"

  def render(assigns) do
    assigns = assign(assigns, icons: @icons, card: @card, caps: @caps, h3: @h3, strong: @strong)

    ~H"""
    <.example
      title="Icons and variants"
      text="Composed from timeline, timeline_item, timeline_day, avatar, avatar_group and badge; the comment box and the file chip are plain markup."
      class="mt-5 grid gap-5 lg:grid-cols-2 lg:items-start"
    >
      <div>
        <div class={@caps}>Com ícones Heroicons · tamanho lg</div>
        <div class={@card}>
          <h3 class={@h3}>Atividade do pedido</h3>
          <.timeline size="xl" density="compact">
            <.timeline_day label="Hoje" />
            <.timeline_item variant="icon" color="info" title="Saiu para entrega" time="11:42">
              <:point><.hero d={@icons.truck} /></:point>
              <:details>
                Rápido Sul coletou <b>3 itens</b>. Previsão para quinta, 29 out.
              </:details>
            </.timeline_item>
            <.timeline_item
              variant="icon"
              color="warning"
              title="Atraso na separação"
              time="10:15"
              description="Item 2 sem estoque no endereço A-12. Reposição em andamento."
            >
              <:point><.hero d={@icons.warning} /></:point>
            </.timeline_item>
            <.timeline_item
              variant="icon"
              color="primary"
              title="Comentário de Ana Souza"
              time="09:58"
            >
              <:point><.hero d={@icons.chat} /></:point>
              <div class="mt-2 rounded-[10px] bg-slate-100 px-3 py-2.5 text-[13px] leading-normal text-slate-700 dark:bg-navy-800 dark:text-navy-50">
                Cliente pediu para entregar no período da tarde.
              </div>
            </.timeline_item>
            <.timeline_day label="Ontem" />
            <.timeline_item variant="icon" color="success" title="Pagamento confirmado" time="17:30">
              <:point><.hero d={@icons.banknotes} /></:point>
              <:details>Pix de <b>R$ 1.284,90</b> recebido.</:details>
              <span class="mt-2 inline-flex items-center gap-2 rounded-[9px] py-1.5 pr-2.5 pl-2 text-xs font-medium text-slate-700 shadow-[inset_0_0_0_1px_var(--color-slate-200)] dark:text-navy-50 dark:shadow-[inset_0_0_0_1px_var(--color-navy-500)]">
                <.hero d={@icons.paperclip} class="size-4 text-slate-400 dark:text-navy-300" />
                comprovante-pagamento.pdf
                <i class="font-normal not-italic text-slate-400 dark:text-navy-300">184 KB</i>
              </span>
            </.timeline_item>
            <.timeline_item
              variant="icon"
              color="primary"
              title="Atendimento atribuído"
              time="16:02"
              description="Lueide Souza assumiu o pedido."
            >
              <:point><.hero d={@icons.user_plus} /></:point>
              <.avatar_group size="3xs" overlap="auto" class="mt-2">
                <.avatar initials="as" color="primary" size="3xs" ring />
                <.avatar initials="cl" color="info" size="3xs" ring />
                <.avatar initials="mb" color="success" size="3xs" ring />
              </.avatar_group>
            </.timeline_item>
            <.timeline_item
              variant="icon"
              color="neutral"
              title="Pedido criado"
              time="15:48"
              description="Canal: loja online"
            >
              <:point><.hero d={@icons.document_plus} /></:point>
              <div class="mt-2 flex flex-wrap gap-1.5">
                <.badge variant="soft" shape="pill" color="primary">Pix</.badge>
                <.badge variant="soft" shape="pill" color="neutral">3 itens</.badge>
              </div>
            </.timeline_item>
          </.timeline>
        </div>
      </div>

      <div class="space-y-4">
        <div class={@caps}>Variantes do ponto</div>
        <div class={@card}>
          <h3 class={@h3}>Ponto sólido, com ping no ativo</h3>
          <.timeline density="compact">
            <.timeline_item color="success" title="Autorizado" time="24 out, 09:41" />
            <.timeline_item color="info" ping title="Em análise" time="24 out, 09:12" />
            <.timeline_item color="neutral" title="Criado" time="23 out, 17:40" />
          </.timeline>
        </div>
        <div class={@card}>
          <h3 class={@h3}>Ponto vazado</h3>
          <.timeline density="compact">
            <.timeline_item variant="outline" color="success" title="Autorizado" time="24 out, 09:41" />
            <.timeline_item variant="outline" color="info" title="Em análise" time="24 out, 09:12" />
            <.timeline_item variant="outline" color="neutral" title="Criado" time="23 out, 17:40" />
          </.timeline>
        </div>
        <div class={@card}>
          <h3 class={@h3}>Avatar</h3>
          <.timeline size="xl" density="compact">
            <.timeline_item variant="avatar" title="Autorizado" time="24 out, 09:41">
              <:point><.avatar size="xs" initials="mb" color="success" class="size-full" /></:point>
            </.timeline_item>
            <.timeline_item variant="avatar" title="Em análise" time="24 out, 09:12">
              <:point><.avatar size="xs" initials="as" color="info" class="size-full" /></:point>
            </.timeline_item>
            <.timeline_item variant="avatar" title="Criado" time="23 out, 17:40">
              <:point><.avatar size="xs" initials="ls" color="neutral" class="size-full" /></:point>
            </.timeline_item>
          </.timeline>
        </div>
      </div>
    </.example>
    """
  end

  attr :d, :string, required: true
  attr :class, :string, default: "size-4"

  defp hero(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.6"
      stroke-linecap="round"
      stroke-linejoin="round"
      class={@class}
      aria-hidden="true"
    >
      <path d={@d} />
    </svg>
    """
  end
end
