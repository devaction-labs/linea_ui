defmodule PreviewWeb.Pages.CardTable do
  use PreviewWeb.Page, title: "Card table", category: :components

  @rows [
    %{id: 1, number: "PED-1004100", client: "Secretaria Municipal de Saúde de Vila Nova", issuer: "Matriz", bid: "PE312/2025 - PE", agent: "Lueide Souza", total: "R$ 95,60", state: :success, label: "Autorizado", balance: "—", at: "27/10/2026", afm: "245/2026", due: "Entrega 26/11/2026"},
    %{id: 2, number: "PED-1004099", client: "Hospital Regional do Alto Tietê", issuer: "Matriz", bid: "19.180-PE303/2025", agent: "Lueide Souza", total: "R$ 408,00", state: :success, label: "Autorizado", balance: "—", at: "27/10/2026", afm: "43.060.00262/2026", due: "Entrega 26/11/2026"},
    %{id: 3, number: "PED-1004098", client: "Prefeitura Municipal de Santa Rita", issuer: "Filial SP", bid: "PE118/2026 - SP", agent: "Ellen Santos", total: "R$ 35.360,00", state: :info, label: "Em separação", balance: "R$ 1.200,00", at: "26/10/2026", afm: "150010002", due: "Entrega 25/11/2026"},
    %{id: 4, number: "PED-1004097", client: "Fundo Municipal de Saúde", issuer: "Matriz", bid: "—", agent: "Ellen Santos", total: "R$ 0,00", state: :error, label: "Cancelado", balance: "—", at: "26/10/2026", afm: "58044-9", due: "—"}
  ]

  def mount(socket), do: assign(socket, selected: [2], sort_by: "number", sort_dir: "asc")

  def handle_event("select", %{"id" => id, "selected" => "true"}, socket),
    do: {:noreply, update(socket, :selected, &[String.to_integer(id) | &1])}

  def handle_event("select", %{"id" => id}, socket),
    do: {:noreply, update(socket, :selected, &List.delete(&1, String.to_integer(id)))}

  def handle_event("select_all", %{"selected" => "true"}, socket),
    do: {:noreply, assign(socket, selected: Enum.map(@rows, & &1.id))}

  def handle_event("select_all", _params, socket), do: {:noreply, assign(socket, selected: [])}

  def handle_event("sort", %{"column" => column, "direction" => dir}, socket),
    do: {:noreply, assign(socket, sort_by: column, sort_dir: dir)}

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  def render(assigns) do
    assigns = assign(assigns, rows: @rows)

    ~H"""
    <.example title="Columns leave by priority" text="The table answers to its own width: below 1180, 960 and 720px the columns of priority 1, 2 and 3 leave. Click a row to open the panel with its details (the detail slots), where each line can be copied; the copy button of the order number has a tooltip. Below 520px each row is a card." class="mt-5">
      <div class="flex flex-col gap-8">
        <div :for={{width, id} <- [{"w-full", "ct-full"}, {"max-w-[1000px]", "ct-1000"}, {"max-w-[800px]", "ct-800"}, {"max-w-[600px]", "ct-600"}, {"max-w-[400px]", "ct-400"}]} class={width}>
          <.card_table
            id={id}
            rows={@rows}
            selected={@selected}
            on_select="select"
            on_select_all="select_all"
            on_sort="sort"
            sort_by={@sort_by}
            sort_dir={@sort_dir}
            row_key={& &1.id}
            row_id={&"#{id}-#{&1.id}"}
            status={& &1.state}
          >
            <:col :let={o} label="Pedido" role="head" sort_key="number" copy={& &1.number} copy_label="Copiar pedido" copied_label="Pedido copiado"><span class="font-mono text-[12.5px] font-semibold">{o.number}</span></:col>
            <:col :let={o} label="Cliente" role="title" width="minmax(120px,1.3fr)">{o.client}</:col>
            <:col :let={o} label="Emissor" priority={2}><.badge variant="soft" color="primary" size="sm">{o.issuer}</.badge></:col>
            <:col :let={o} label="Licitação / AFM" role="meta" width="minmax(150px,1.5fr)" priority={3}><span class="font-mono text-[11px] text-slate-400">LIC:</span> {o.bid} <span class="mx-2 inline-block size-[3px] rounded-full bg-slate-400 align-middle"></span><span class="font-mono text-[11px] text-slate-400">AFM:</span> {o.afm}</:col>
            <:col :let={o} label="Atendente" priority={1}>{o.agent}</:col>
            <:col :let={o} label="Valor" role="value" align="end" sort_key="total"><span class="tabular-nums">{o.total}</span></:col>
            <:col :let={o} label="Status" role="status"><.badge variant="soft" color={to_string(o.state)} size="sm" dot>{o.label}</.badge></:col>
            <:col :let={o} label="Saldo" priority={1}>{o.balance}</:col>
            <:col :let={o} label="Inserido em" priority={2}><span class="inline-flex items-center gap-1.5 text-xs text-slate-500 dark:text-navy-200"><.icon name="huge-clock-01" class="size-3 text-success" />{o.at}</span></:col>
            <:detail :let={o} label="Pedido">{o.number}</:detail>
            <:detail :let={o} label="Prazo">{o.due}</:detail>
            <:detail :let={o} label="Inserido em">{o.at}</:detail>
            <:detail :let={o} label="Atendente">{o.agent}</:detail>
            <:detail :let={o} label="Emissor">{o.issuer}</:detail>
            <:detail :let={o} label="Licitação">{o.bid}</:detail>
            <:detail :let={o} label="AFM">{o.afm}</:detail>
            <:detail :let={o} label="Saldo">{o.balance}</:detail>
            <:action :let={o}>
              <.button variant="flat" size="sm" aria-label={"Ações de #{o.number}"}><.icon name="huge-more-horizontal" class="size-4" /></.button>
            </:action>
          </.card_table>
        </div>
      </div>
    </.example>
    <.example title="Heading, actions and empty list" text="title, description and the actions slot draw a heading above the table. With no rows the column titles are hidden and the empty slot sits in a dashed box." class="mt-5">
      <div class="flex max-w-[1000px] flex-col gap-8">
        <.card_table id="ct-head" rows={Enum.take(@rows, 2)} row_key={& &1.id} row_id={&"ct-head-#{&1.id}"} status={& &1.state} title="Acesso ao portal" description="Quem tem estes acessos enxerga os pedidos, documentos e saldos deste cliente.">
          <:actions><.button size="sm">Convidar comprador</.button></:actions>
          <:col :let={o} label="Pedido" role="head"><span class="font-mono text-[12.5px] font-semibold">{o.number}</span></:col>
          <:col :let={o} label="Cliente" role="title" width="minmax(120px,1.3fr)">{o.client}</:col>
          <:col :let={o} label="Status" role="status"><.badge variant="soft" color={to_string(o.state)} size="sm" dot>{o.label}</.badge></:col>
        </.card_table>
        <.card_table id="ct-head-empty" rows={[]} title="Acesso ao portal" description="Quem tem estes acessos enxerga os pedidos, documentos e saldos deste cliente.">
          <:actions><.button size="sm">Convidar comprador</.button></:actions>
          <:col :let={o} label="Acesso" role="head">{o.number}</:col>
          <:col :let={o} label="Situação" role="status">{o.label}</:col>
          <:empty>Nenhum acesso ao portal ainda.</:empty>
        </.card_table>
      </div>
    </.example>
    """
  end
end
