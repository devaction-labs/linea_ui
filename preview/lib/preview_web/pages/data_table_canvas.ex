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
          row_class={&(&1.id == "#2479" && "[&>td]:bg-slate-200/90! dark:[&>td]:bg-navy-600!")}
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
            <.button color="primary" size="sm">
              <.glyph name={:plus} class="size-3.5" stroke_width="2" /> Novo pedido
            </.button>
          </:actions>
          <:filters :let={toggle}>
            <p class="text-sm" phx-click={toggle}>Filtros</p>
          </:filters>
          <:summary><b>1</b> - <b>5</b> de <b>15</b> registros</:summary>
          <:col
            :let={r}
            label="Pedido"
            sort_key="number"
            class="font-mono text-[12.5px] font-medium text-slate-700 dark:text-navy-100"
          >
            {r.id}
          </:col>
          <:col
            :let={r}
            label="Cliente"
            sort_key="name"
            head_class="[&_button]:outline-2 [&_button]:outline-offset-1 [&_button]:outline-solid [&_button]:outline-primary/55"
          >
            <.who r={r} />
          </:col>
          <:col :let={r} label="Responsável" priority={3}>{r.owner}</:col>
          <:col :let={r} label="Status" priority={2}><.status r={r} /></:col>
          <:col
            :let={r}
            label="Total"
            sort_key="total"
            align="right"
            class="font-medium text-slate-700 tabular-nums dark:text-navy-100"
          >
            {r.total}
          </:col>
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
          wrapper_class="max-h-[236px]"
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
          <:col
            :let={r}
            label="Pedido"
            sort_key="number"
            class="font-mono text-[12.5px] font-medium text-slate-700 dark:text-navy-100"
          >
            {r.id}
          </:col>
          <:col :let={r} label="Cliente" sort_key="name"><.who r={r} /></:col>
          <:col :let={r} label="Responsável" priority={3}>{r.owner}</:col>
          <:col :let={r} label="Status" priority={2}><.status r={r} /></:col>
          <:col
            :let={r}
            label="Total"
            sort_key="total"
            align="right"
            class="font-medium text-slate-700 tabular-nums dark:text-navy-100"
          >
            {r.total}
          </:col>
        </.data_table>
      </div>
    </.example>

    <div class="mt-5 grid gap-x-7 gap-y-5 lg:grid-cols-2">
      <.example title="Carregando" text="table_skeleton, aria-busy" class="">
        <div class="w-full overflow-hidden rounded-xl shadow-soft ring-1 ring-slate-150 dark:ring-navy-500">
          <.table_skeleton
            id="dt-skel"
            rows={4}
            variant="data"
            columns={["Pedido", "Cliente", "Responsável", "Status", "Total"]}
            shapes={["text", "avatar", "text", "pill", "number"]}
            label="Carregando pedidos"
          />
        </div>
      </.example>
      <.example title="Vazio" text="slot :empty" class="">
        <div class="w-full">
          <.data_table id="dt-empty" rows={[]} footer={false}>
            <:col label="Pedido">{nil}</:col>
            <:col label="Cliente">{nil}</:col>
            <:col label="Responsável" priority={3}>{nil}</:col>
            <:col label="Status" priority={2}>{nil}</:col>
            <:col label="Total" align="right">{nil}</:col>
            <:empty>
              <.empty_state variant="table" icon="huge-inbox" title="Nenhum pedido encontrado">
                Nada corresponde a "Souza". Ajuste a busca ou limpe os filtros.
                <:action>
                  <a href="#" class="text-primary hover:underline dark:text-accent-light">
                    Limpar busca
                  </a>
                </:action>
              </.empty_state>
            </:empty>
          </.data_table>
        </div>
      </.example>
    </div>

    <.example title="Cabeçalho ordenável" text="sort_key, sort_by, sort_dir" class="mt-5">
      <div class="grid w-full gap-2.5 sm:grid-cols-2 lg:grid-cols-5">
        <.sort_cell
          :for={
            {label, key, by, dir, force, caption} <- [
              {"Cliente", "name", nil, "asc", nil, "Sem ordenação"},
              {"Cliente", "name", nil, "asc", :hover, "Hover"},
              {"Cliente", "name", nil, "asc", :focus, "Foco do teclado"},
              {"Pedido", "number", "number", "asc", nil, "Crescente (asc)"},
              {"Total", "total", "total", "desc", nil, "Decrescente (desc)"}
            ]
          }
          label={label}
          key={key}
          by={by}
          dir={dir}
          force={force}
          caption={caption}
        />
      </div>
    </.example>
    """
  end

  attr :label, :string, required: true
  attr :key, :string, required: true
  attr :by, :string, default: nil
  attr :dir, :string, required: true
  attr :force, :atom, default: nil
  attr :caption, :string, required: true

  defp sort_cell(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <.table
        id={"sort-" <> Base.encode16(@caption, case: :lower)}
        variant="data"
        class={[
          "rounded-lg",
          @force == :hover && "[&_button]:bg-slate-300/40 dark:[&_button]:bg-navy-450/40",
          @force == :focus &&
            "[&_button]:outline-2 [&_button]:outline-offset-1 [&_button]:outline-solid [&_button]:outline-primary/55"
        ]}
      >
        <.table_head on_sort="noop" sort_by={@by} sort_dir={@dir}>
          <:col sort_key={@key} label={@label} />
        </.table_head>
      </.table>
      <small class="text-[11.5px] font-medium text-slate-400 dark:text-navy-300">{@caption}</small>
    </div>
    """
  end

  attr :r, :map, required: true

  defp who(assigns) do
    ~H"""
    <div class="flex items-center gap-2.5">
      <.avatar name={@r.name} color="auto" size="2xs" />
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
