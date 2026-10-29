defmodule PreviewWeb.Pages.PopoverCanvas do
  use PreviewWeb.Page, title: "Popover (canvas)", category: :components

  def render(assigns) do
    ~H"""
    <div class="grid gap-5 lg:grid-cols-2">
      <.example
        title="trigger_on click · right-start"
        text="Fecha com clique fora ou Esc. Sem espaço à direita, tenta embaixo e depois em cima."
      >
        <div class="min-h-72 w-full pt-2">
          <.popover id="pc-lesson" open>
            <:trigger>
              <.button color="primary">
                Aulas <.icon name="huge-arrow-right-01" class="size-4" />
              </.button>
            </:trigger>
            <:title>Aula em grupo</:title>
            <p class="mt-2 text-[13px]/[1.55]">
              Quinta, 14h às 15h30. Até 12 pessoas por turma, com material enviado na véspera.
            </p>
            <div class="mt-3 flex flex-wrap gap-1.5">
              <.badge color="primary" variant="soft">Presencial</.badge>
              <.badge color="success" variant="soft">3 vagas</.badge>
              <.badge color="warning" variant="soft">Lista de espera</.badge>
            </div>
          </.popover>
        </div>
      </.example>

      <.example
        title="trigger_on hover · top, cartão de pessoa"
        text="Aparece no foco de teclado também; o gatilho mostra o anel de foco."
      >
        <div class="flex min-h-72 w-full items-end justify-center pt-2">
          <.popover
            id="pc-person"
            open
            trigger_on="hover"
            placement="top"
            fallbacks={[]}
            class="w-52 px-4 py-5 text-center"
          >
            <:trigger>
              <button
                type="button"
                class="rounded-full ring-2 ring-primary/50 ring-offset-2 ring-offset-white dark:ring-accent/60 dark:ring-offset-navy-800"
                aria-label="Ana Souza"
              >
                <.avatar initials="AS" color="primary" size="xs-plus" />
              </button>
            </:trigger>
            <.avatar initials="AS" color="primary" size="md" class="mx-auto" />
            <p class="mt-2.5 text-sm font-medium text-slate-700 dark:text-navy-50">Ana Souza</p>
            <p class="text-xs text-slate-400 dark:text-navy-300">Gerente de projetos</p>
            <div class="mt-3 flex justify-center gap-4.5 border-t border-slate-150 pt-3 dark:border-navy-500">
              <div>
                <b class="block text-sm font-semibold text-slate-700 dark:text-navy-50">24</b>
                <span class="text-[11px] text-slate-400 dark:text-navy-300">projetos</span>
              </div>
              <div>
                <b class="block text-sm font-semibold text-slate-700 dark:text-navy-50">8</b>
                <span class="text-[11px] text-slate-400 dark:text-navy-300">equipes</span>
              </div>
            </div>
          </.popover>
        </div>
      </.example>

      <.example title="Formulário curto · bottom-start">
        <div class="min-h-72 w-full pt-2">
          <.popover id="pc-form" open placement="bottom-start" fallbacks={["top"]}>
            <:trigger>
              <.button variant="soft">
                <.icon name="huge-edit-02" class="size-4" /> Renomear projeto
              </.button>
            </:trigger>
            <:title>Renomear projeto</:title>
            <div class="mt-2.5">
              <.input
                id="pc-form-name"
                name="name"
                label="Nome"
                class="!border-primary ring-[3px] ring-primary/10 dark:ring-accent/20"
                value="Projeto Aurora"
                help="Visível para todas as pessoas da equipe."
              />
            </div>
            <div class="mt-3.5 flex justify-end gap-2">
              <.button size="sm" variant="soft">Cancelar</.button>
              <.button size="sm" color="primary">Salvar</.button>
            </div>
          </.popover>
        </div>
      </.example>
    </div>

    <.example title="arrow=false · lista de notificações" class="mt-5">
      <div class="min-h-80 w-full pt-2">
        <.popover id="pc-notifs" open placement="bottom-start" arrow={false} class="w-[300px]">
          <:trigger>
            <.button variant="soft">
              <.icon name="huge-notification-03" class="size-4" /> Notificações
            </.button>
          </:trigger>
          <:title>Notificações</:title>
          <ul class="-mx-2 mt-2.5">
            <li
              :for={
                {dot, title, text, time} <- [
                  {true, "Carlos Lima comentou", "Revisão do pedido 1042", "2 min"},
                  {true, "Novo cliente", "Marina Rocha entrou", "1 h"},
                  {false, "Entrega confirmada", "Pedido 1038", "ontem"}
                ]
              }
              class="flex items-center gap-2.5 rounded-md p-2 text-[13px]/[1.35] hover:bg-slate-100 dark:hover:bg-navy-600"
            >
              <span class={[
                "size-2 flex-none rounded-full",
                if(dot, do: "bg-primary dark:bg-accent", else: "bg-slate-300 dark:bg-navy-400")
              ]}>
              </span>
              <span>
                <b class="block font-medium text-slate-700 dark:text-navy-50">{title}</b>{text}
              </span>
              <span class="ml-auto text-[11px] whitespace-nowrap text-slate-400 dark:text-navy-300">
                {time}
              </span>
            </li>
          </ul>
        </.popover>
      </div>
    </.example>
    """
  end
end
