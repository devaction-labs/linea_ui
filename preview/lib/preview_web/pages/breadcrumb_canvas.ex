defmodule PreviewWeb.Pages.BreadcrumbCanvas do
  use PreviewWeb.Page, title: "Breadcrumb (canvas)", category: :components

  @hover "!text-primary-focus underline underline-offset-3 dark:!text-indigo-300"
  @focus "outline-solid outline-2 outline-offset-2 outline-primary/55 dark:outline-accent/55"
  @bd_hover "[box-shadow:inset_0_0_0_1px_color-mix(in_oklab,var(--color-primary)_40%,transparent)]!"

  @home "M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"

  def render(assigns) do
    assigns = assign(assigns, hover: @hover, focus: @focus, bd_hover: @bd_hover, home: @home)

    ~H"""
    <.example title="Variantes" text="plain e bordered, separador padrão e customizado">
      <div class="grid w-full grid-cols-1 gap-[18px] xl:grid-cols-3">
        <.panel>
          <.line label="plain · separador chevron (padrão)"><.trail /></.line>
          <.line label="Hover no segundo item"><.trail hover={1} hover_class={@hover} /></.line>
          <.line label="Foco do teclado"><.trail focus={1} focus_class={@focus} /></.line>
          <.line label="Só a página atual (sem ancestrais)">
            <.breadcrumb>
              <:item>Pedido #2481</:item>
            </.breadcrumb>
          </.line>
        </.panel>

        <.panel>
          <.line label={~s(variant="bordered")}><.trail variant="bordered" /></.line>
          <.line label="bordered · hover e foco">
            <.trail variant="bordered" hover={0} focus={1} focus_class={@focus} />
          </.line>
          <.line label="bordered · ícone no primeiro item">
            <.breadcrumb variant="bordered">
              <:item href="#" aria-label="Início"><.home_icon d={@home} /></:item>
              <:item href="#">Projetos</:item>
              <:item>Pedido #2481</:item>
            </.breadcrumb>
          </.line>
        </.panel>

        <.panel>
          <.line label=":separator com barra">
            <.breadcrumb>
              <:separator>
                <span class="text-xs leading-none font-light text-slate-300">/</span>
              </:separator>
              <:item href="#">Início</:item>
              <:item href="#">Projetos</:item>
              <:item href="#">Loja online</:item>
              <:item>Pedido #2481</:item>
            </.breadcrumb>
          </.line>
          <.line label="Com ícone Heroicons no início">
            <.breadcrumb>
              <:item href="#"><.home_icon d={@home} />Início</:item>
              <:item href="#">Clientes</:item>
              <:item>Ana Souza</:item>
            </.breadcrumb>
          </.line>
          <.line label="Itens com phx-click (botão que parece link)">
            <.breadcrumb>
              <:item phx-click="noop">Documentos</:item>
              <:item phx-click="noop">Contratos</:item>
              <:item phx-click="noop">2026</:item>
              <:item>Proposta final.pdf</:item>
            </.breadcrumb>
          </.line>
        </.panel>

        <.panel>
          <.line label="Trilha longa: quebra de linha (flex-wrap), sem rolagem">
            <.breadcrumb>
              <:item href="#">Início</:item>
              <:item href="#">Projetos</:item>
              <:item href="#">Loja online</:item>
              <:item href="#">Pedidos</:item>
              <:item href="#">Outubro de 2026</:item>
              <:item href="#">Entregas pendentes</:item>
              <:item>Pedido #2481 de Ana Souza</:item>
            </.breadcrumb>
          </.line>
          <.line label="Em um cabeçalho de página">
            <div class="flex flex-wrap items-center justify-between gap-3.5 rounded-xl px-[18px] py-3.5 ring-1 ring-slate-150 dark:ring-navy-500">
              <div>
                <.breadcrumb>
                  <:item href="#">Início</:item>
                  <:item href="#">Clientes</:item>
                  <:item>Ana Souza</:item>
                </.breadcrumb>
                <h1 class="mt-1.5 text-xl font-medium tracking-wide text-slate-700 dark:text-navy-50">
                  Ana Souza
                </h1>
              </div>
              <.button href="#" color="primary" size="sm">Editar cliente</.button>
            </div>
          </.line>
        </.panel>
      </div>
    </.example>
    """
  end

  slot :inner_block, required: true

  defp panel(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 rounded-xl px-5 py-[18px] ring-1 ring-slate-150 dark:ring-navy-500">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :label, :string, required: true
  slot :inner_block, required: true

  defp line(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <small class="text-[11.5px] font-medium text-slate-400 dark:text-navy-300">{@label}</small>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :d, :string, required: true

  defp home_icon(assigns) do
    ~H"""
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      class="size-4 shrink-0"
      aria-hidden="true"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d={@d} />
    </svg>
    """
  end

  attr :variant, :string, default: "plain"
  attr :hover, :integer, default: nil
  attr :focus, :integer, default: nil
  attr :hover_class, :string, default: nil
  attr :focus_class, :string, default: nil
  attr :bd_hover, :string, default: nil
  attr :rest, :global

  defp trail(assigns) do
    ~H"""
    <.breadcrumb variant={@variant}>
      <:item
        :for={{label, i} <- Enum.with_index(["Início", "Projetos", "Loja online"])}
        href="#"
        class={[
          @hover == i && [@hover_class, @variant == "bordered" && @bd_hover],
          @focus == i && @focus_class
        ]}
      >
        {label}
      </:item>
      <:item>Pedido #2481</:item>
    </.breadcrumb>
    """
  end
end
