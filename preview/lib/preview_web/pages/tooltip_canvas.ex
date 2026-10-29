defmodule PreviewWeb.Pages.TooltipCanvas do
  use PreviewWeb.Page, title: "Tooltip (canvas)", category: :components

  @colors [
    {"neutral", "Neutro"},
    {"light", "Claro"},
    {"primary", "Primary"},
    {"secondary", "Secondary"},
    {"info", "Info"},
    {"success", "Success"},
    {"warning", "Warning"},
    {"error", "Error"}
  ]

  @placements ~w(top-start top top-end right-start right right-end bottom-start bottom bottom-end left-start left left-end)

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, placements: @placements)

    ~H"""
    <.example
      title="color: oito temas"
      text="Sempre texto curto, uma linha. Neutral e light seguem a superfície; as demais ficam sólidas com texto branco, nos dois temas."
    >
      <div id="tc-colors" class="grid w-full grid-cols-2 justify-items-center gap-x-3 gap-y-20 pt-14 pb-4 sm:grid-cols-4">
        <.tooltip
          :for={{color, label} <- @colors}
          id={"tc-color-#{color}"}
          text="Salvar rascunho"
          color={color}
          open
        >
          <.button variant="outline" size="sm">{label}</.button>
        </.tooltip>
      </div>
    </.example>

    <.example
      title="placement: doze posições"
      text="A posição se inverte sozinha quando falta espaço; a seta acompanha o gatilho. O padrão é top."
      class="mt-5"
    >
      <div id="tc-places" class="grid w-full grid-cols-2 gap-3 lg:grid-cols-4">
        <div
          :for={placement <- @placements}
          class="relative flex min-h-40 items-center justify-center rounded-lg bg-slate-50 px-3 py-12 ring-1 ring-slate-150 dark:bg-navy-800 dark:ring-navy-600"
        >
          <span class="absolute top-2 left-2.5 font-mono text-[11px] text-slate-400 dark:text-navy-300">
            {placement}
          </span>
          <.tooltip id={"tc-place-#{placement}"} text="Salvar rascunho" placement={placement} open>
            <.button variant="outline" size="sm">Salvar</.button>
          </.tooltip>
        </div>
      </div>
    </.example>

    <div class="mt-5 grid gap-5 lg:grid-cols-2">
      <.example
        title="slot content: trigger click, interativo"
        text="Com conteúdo o tema content remove o padding e a dica fica interativa: o ponteiro pode entrar nela."
      >
        <div class="flex min-h-72 w-full items-end justify-center pt-4">
          <.tooltip id="tc-rich" trigger="click" open>
            <.button
              variant="outline"
              size="sm"
              aria-expanded="true"
              class="ring-2 ring-primary/50 ring-offset-2 ring-offset-white dark:ring-accent/60 dark:ring-offset-navy-800"
            >
              Carlos Lima
            </.button>
            <:content>
              <div class="w-60 p-3.5">
                <div class="flex items-center gap-2.5">
                  <.avatar initials="CL" color="primary" size="xs-plus" />
                  <div>
                    <b class="block text-[13px] font-medium">Carlos Lima</b>
                    <span class="block text-xs opacity-70">Engenharia · Salvador</span>
                  </div>
                </div>
                <p class="mt-2.5 text-xs/[1.5] opacity-85">
                  Responsável pela revisão do pedido 1042, que vence amanhã.
                </p>
                <div class="mt-3 flex gap-2">
                  <.button size="xs" color="primary">Ver perfil</.button>
                  <.button size="xs" variant="outline">Mensagem</.button>
                </div>
              </div>
            </:content>
          </.tooltip>
        </div>
      </.example>

      <.example
        title="arrow: sem seta e com seta, botões de ícone"
        text="Ícone sem texto sempre leva aria-label; a dica complementa, não substitui. O foco de teclado também abre a dica."
      >
        <div class="flex min-h-72 w-full flex-col gap-24 pt-16">
          <div>
            <.tooltip
              id="tc-delete"
              text="Excluir definitivamente"
              color="error"
              placement="top"
              arrow={false}
              open
            >
              <.button
                color="error"
                variant="outline"
                size="sm"
                icon
                aria-label="Excluir pedido"
                class="ring-2 ring-primary/50 ring-offset-2 ring-offset-white dark:ring-accent/60 dark:ring-offset-navy-800"
              >
                <.icon name="huge-delete-02" class="size-4" />
              </.button>
            </.tooltip>
          </div>
          <div>
            <.tooltip id="tc-help" text="Com seta, padrão" placement="bottom" open>
              <.button variant="outline" size="sm" icon aria-label="Ajuda">
                <.icon name="huge-help-circle" class="size-4" />
              </.button>
            </.tooltip>
          </div>
        </div>
      </.example>
    </div>
    """
  end
end
