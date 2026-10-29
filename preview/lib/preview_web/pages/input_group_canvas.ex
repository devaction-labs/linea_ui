defmodule PreviewWeb.Pages.InputGroupCanvas do
  use PreviewWeb.Page, title: "Grupo de input (canvas)", category: :components

  @select "form-select border border-slate-300 bg-slate-150 px-3 py-2 pr-9 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:bg-navy-500 dark:hover:border-navy-400 dark:focus:border-accent"

  def render(assigns) do
    assigns = assign(assigns, select: @select)

    ~H"""
    <.example
      title="Grupo de input"
      class="mt-5 grid grid-cols-1 gap-x-6 gap-y-5 sm:grid-cols-2 lg:grid-cols-4"
    >
      <.input_group label="Usuário · prefixo">
        <.input_group_addon>@</.input_group_addon>
        <.input name="u" placeholder="usuario" aria-label="Usuário" />
      </.input_group>
      <.input_group label="Preço · addons preenchidos">
        <.input_group_addon variant="filled">R$</.input_group_addon>
        <.input name="p" placeholder="0" inputmode="decimal" aria-label="Preço" />
        <.input_group_addon variant="filled">,00</.input_group_addon>
      </.input_group>
      <.input_group label="E-mail · ícone">
        <.input_group_addon><.icon name="huge-mail-01" class="size-4" /></.input_group_addon>
        <.input name="e" type="email" placeholder="ana@exemplo.com" aria-label="E-mail" />
      </.input_group>
      <.input_group label="Site · foco">
        <.input_group_addon>https://</.input_group_addon>
        <.input id="ig-focus" name="s" value="devaction.com.br" aria-label="Site" />
        <.input_group_addon variant="filled">.br</.input_group_addon>
      </.input_group>
      <.input_group label="Link · botão unido">
        <.input_group_addon><.icon name="huge-link-02" class="size-4" /></.input_group_addon>
        <.input name="l" value="app.exemplo.com/p/8f3k2" readonly aria-label="Link" />
        <.button variant="outline" class="gap-1.5">
          <.icon name="huge-copy-01" class="size-4" /> Copiar
        </.button>
      </.input_group>
      <.input_group label="Busca · select e botão">
        <select class={@select} aria-label="Campo">
          <option>Pedido</option>
          <option>Cliente</option>
        </select>
        <.input name="b" placeholder="Buscar…" aria-label="Busca" />
        <.button color="primary" aria-label="Buscar">
          <.icon name="huge-search-01" class="size-4" />
        </.button>
      </.input_group>
      <.input_group label="Valor · erro" errors={["O valor deve ser positivo."]}>
        <.input_group_addon variant="filled">R$</.input_group_addon>
        <.input name="v" value="-20" state="error" aria-label="Valor" />
      </.input_group>
      <.input_group label="Desconto · desabilitado">
        <.input name="d" value="15" disabled aria-label="Desconto" />
        <.input_group_addon variant="filled" class="opacity-60">%</.input_group_addon>
      </.input_group>
    </.example>

    <.example
      title="Forma pílula e tamanhos"
      class="mt-5 grid grid-cols-1 gap-x-6 gap-y-5 sm:grid-cols-2 lg:grid-cols-3"
    >
      <.input_group label="pill" shape="pill">
        <select class={@select} aria-label="Plano">
          <option>Pro</option>
        </select>
        <.input name="c" placeholder="Cupom" aria-label="Cupom" />
        <.button color="primary">Aplicar</.button>
      </.input_group>
      <.input_group label="sm" size="sm">
        <.input_group_addon size="sm">@</.input_group_addon>
        <.input name="sm" size="sm" placeholder="usuario" aria-label="sm" />
        <.button color="primary" size="sm">Seguir</.button>
      </.input_group>
      <.input_group label="lg" size="lg">
        <.input_group_addon size="lg">@</.input_group_addon>
        <.input name="lg" size="lg" placeholder="usuario" aria-label="lg" />
        <.button color="primary" size="lg">Seguir</.button>
      </.input_group>
    </.example>
    """
  end
end
