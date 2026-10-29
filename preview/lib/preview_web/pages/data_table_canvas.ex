defmodule PreviewWeb.Pages.DataTableCanvas do
  use PreviewWeb.Page, title: "Data table (canvas)", category: :components

  @rows [
    {"#2481", "Ana Souza", "Marcos Pinto", "Pago", "success", "R$ 1.284,90"},
    {"#2480", "Carlos Lima", "Lia Furtado", "Em separação", "info", "R$ 642,00"},
    {"#2479", "Marina Alves", "Marcos Pinto", "Pendente", "warning", "R$ 3.120,50"},
    {"#2478", "Rafael Costa", "Lia Furtado", "Cancelado", "error", "R$ 89,90"},
    {"#2477", "Beatriz Nunes", "Marcos Pinto", "Pago", "success", "R$ 1.905,00"},
    {"#2476", "Paulo Dias", "Lia Furtado", "Pago", "success", "R$ 412,30"},
    {"#2475", "Julia Rocha", "Marcos Pinto", "Pendente", "warning", "R$ 758,00"},
    {"#2474", "Felipe Reis", "Lia Furtado", "Pago", "success", "R$ 2.240,00"}
  ]

  def mount(socket), do: assign(socket, rows: Enum.map(@rows, &row/1))

  defp row({number, name, owner, status, tone, total}),
    do: %{id: number, name: name, owner: owner, status: status, tone: tone, total: total}

  def render(assigns) do
    assigns = assign(assigns, first5: Enum.take(assigns.rows, 5))

    ~H"""
    <.example
      title={~s(variant="advanced")}
      text="título, busca aberta, filtros, seleção, seletor de registros e pager"
    >
      <div class="w-full">
        <.data_table
          id="dt-adv"
          rows={@first5}
          row_id={&"dt-adv-#{&1.id}"}
          row_key={& &1.id}
          search="Souza"
          on_search="noop"
          search_placeholder="Buscar..."
          sort_by="number"
          sort_dir="asc"
          on_sort="noop"
          on_select="noop"
          on_select_all="noop"
          selected={["#2480", "#2478"]}
          page={1}
          page_size={10}
          total={50}
          page_sizes={[10, 25, 50]}
          on_page="noop"
          on_page_size="noop"
          show_label="Mostrar"
          entries_label="registros"
          page_label="Página %{page}"
          select_all_label="Selecionar todos"
          select_label="Selecionar pedido"
          sort_label="Ordenar por %{label}"
        >
          <:title>Pedidos</:title>
          <:actions>
            <.button color="primary" size="sm">Novo pedido</.button>
          </:actions>
          <:summary><b>1</b> - <b>5</b> de <b>15</b> registros</:summary>
          <:col :let={r} label="Pedido" sort_key="number">{r.id}</:col>
          <:col :let={r} label="Cliente" sort_key="name">
            <.who r={r} />
          </:col>
          <:col :let={r} label="Responsável" priority={3}>{r.owner}</:col>
          <:col :let={r} label="Status" priority={2}><.status r={r} /></:col>
          <:col :let={r} label="Total" sort_key="total" align="right">{r.total}</:col>
        </.data_table>
      </div>
    </.example>

    <.example
      title={~s(variant="grid" + sticky_header + compact)}
      text="as linhas rolam por baixo do cabeçalho fixo"
      class="mt-5"
    >
      <div class="w-full">
        <.data_table
          id="dt-grid"
          variant="grid"
          rows={@rows}
          row_id={&"dt-grid-#{&1.id}"}
          compact
          sticky_header
          scroll_label="Lista de pedidos"
          search_placeholder="Digite uma palavra-chave..."
          on_search="noop"
          sort_by="name"
          sort_dir="desc"
          on_sort="noop"
          page={1}
          page_size={8}
          total={15}
          on_page="noop"
          prev_label="Anterior"
          next_label="Próxima"
          summary_label="Mostrando %{from} a %{to} de %{total} resultados"
        >
          <:col :let={r} label="Pedido" sort_key="number">{r.id}</:col>
          <:col :let={r} label="Cliente" sort_key="name"><.who r={r} /></:col>
          <:col :let={r} label="Responsável" priority={3}>{r.owner}</:col>
          <:col :let={r} label="Status" priority={2}><.status r={r} /></:col>
          <:col :let={r} label="Total" sort_key="total" align="right">{r.total}</:col>
        </.data_table>
      </div>
    </.example>

    <div class="mt-5 grid gap-x-7 gap-y-5 lg:grid-cols-2">
      <.example title="Carregando" text="table_skeleton, aria-busy" class="">
        <div class="w-full">
          <.table_skeleton
            id="dt-skel"
            rows={4}
            variant="hoverable"
            rounded="top"
            columns={["Pedido", "Cliente", "Responsável", "Status", "Total"]}
            label="Carregando pedidos"
          />
        </div>
      </.example>
      <.example title="Vazio" text="slot :empty" class="">
        <div class="w-full">
          <.data_table id="dt-empty" rows={[]} search="Souza" on_search="noop" footer={false}>
            <:col label="Pedido">{nil}</:col>
            <:col label="Cliente">{nil}</:col>
            <:col label="Responsável">{nil}</:col>
            <:col label="Status">{nil}</:col>
            <:col label="Total" align="right">{nil}</:col>
            <:empty>
              <.empty_state variant="inline" icon="huge-inbox" title="Nenhum pedido encontrado">
                Nada corresponde a "Souza". Ajuste a busca ou limpe os filtros.
                <:action>
                  <.button variant="ghost" color="primary" size="sm">Limpar busca</.button>
                </:action>
              </.empty_state>
            </:empty>
          </.data_table>
        </div>
      </.example>
    </div>
    """
  end

  attr :r, :map, required: true

  defp who(assigns) do
    ~H"""
    <div class="flex items-center gap-2.5">
      <.avatar name={@r.name} color="auto" size="28" />
      <span class="font-medium text-slate-700 dark:text-navy-100">{@r.name}</span>
    </div>
    """
  end

  attr :r, :map, required: true

  defp status(assigns) do
    ~H"""
    <.badge color={@r.tone} variant="soft" shape="pill" dot>{@r.status}</.badge>
    """
  end
end
