defmodule PreviewWeb.Pages.CardTable do
  use PreviewWeb.Page, title: "Card table", category: :components

  @rows [
    %{id: 1, number: "PED-1004100", client: "Secretaria Municipal de Saúde de Vila Nova", issuer: "Matriz", bid: "PE312/2025 - PE", agent: "Lueide Souza", total: "R$ 95,60", state: :success, label: "Autorizado", balance: "—", at: "27/10/2026"},
    %{id: 2, number: "PED-1004099", client: "Hospital Regional do Alto Tietê", issuer: "Matriz", bid: "19.180-PE303/2025", agent: "Lueide Souza", total: "R$ 408,00", state: :success, label: "Autorizado", balance: "—", at: "27/10/2026"},
    %{id: 3, number: "PED-1004098", client: "Prefeitura Municipal de Santa Rita", issuer: "Filial SP", bid: "PE118/2026 - SP", agent: "Ellen Santos", total: "R$ 35.360,00", state: :info, label: "Em separação", balance: "R$ 1.200,00", at: "26/10/2026"},
    %{id: 4, number: "PED-1004097", client: "Fundo Municipal de Saúde", issuer: "Matriz", bid: "—", agent: "Ellen Santos", total: "R$ 0,00", state: :error, label: "Cancelado", balance: "—", at: "26/10/2026"}
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
    <.example title="Columns leave by priority" text="The table answers to its own width: below 1180, 960 and 720px the columns of priority 1, 2 and 3 leave, and point at a row to read them. Below 520px each row is a card." class="mt-5">
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
            <:col :let={o} label="Pedido" role="head" sort_key="number"><span class="font-mono text-[12.5px] font-semibold">{o.number}</span></:col>
            <:col :let={o} label="Cliente" role="title" width="minmax(120px,1.3fr)">{o.client}</:col>
            <:col :let={o} label="Emissor" priority={2}><.badge variant="soft" color="primary" size="sm">{o.issuer}</.badge></:col>
            <:col :let={o} label="Licitação" role="meta" width="minmax(130px,1.2fr)" priority={3}>{o.bid}</:col>
            <:col :let={o} label="Atendente" priority={1}>{o.agent}</:col>
            <:col :let={o} label="Valor" role="value" align="end" sort_key="total"><span class="tabular-nums">{o.total}</span></:col>
            <:col :let={o} label="Status" role="status"><.badge variant="soft" color={to_string(o.state)} size="sm" dot>{o.label}</.badge></:col>
            <:col :let={o} label="Saldo" priority={1}>{o.balance}</:col>
            <:col :let={o} label="Inserido em" priority={2}>{o.at}</:col>
            <:action :let={o}>
              <.button variant="flat" size="sm" aria-label={"Ações de #{o.number}"}><.icon name="huge-more-horizontal" class="size-4" /></.button>
            </:action>
          </.card_table>
        </div>
      </div>
    </.example>
    """
  end
end
