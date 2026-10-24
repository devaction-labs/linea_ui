defmodule PreviewWeb.Pages.FilterMenu do
  use PreviewWeb.Page, title: "Filter menu", category: :components, lineone: "elements-badge"

  @orders [
    {"PV-1284", "Drogaria Feira Saúde", "Balcão", "Ana Souza", "Faturado", 4280.0},
    {"PV-1283", "Clínica Santa Mônica", "Representante", "Carlos Lima", "Aprovado", 12_850.4},
    {"PV-1282", "Ótica Visão Feira", "Loja online", "Ana Souza", "Rascunho", 2460.0},
    {"PV-1281", "Hospital Dom Pedro", "Representante", "Carlos Lima", "Faturado", 9744.0},
    {"PV-1280", "Mercado Bom Preço", "Balcão", "Juliana Moraes", "Cancelado", 1890.0},
    {"PV-1279", "Farmácia Popular do Tomba", "Loja online", "Juliana Moraes", "Aprovado", 3120.0},
    {"PV-1278", "Padaria Pão de Mel", "Balcão", "Ana Souza", "Faturado", 680.0},
    {"PV-1277", "Restaurante Sabor da Bahia", "Representante", "Carlos Lima", "Rascunho", 1450.0}
  ]

  @columns %{"status" => 4, "channel" => 2, "seller" => 3}

  def mount(socket) do
    assign(socket,
      filter: %{
        "status" => ["Faturado", "Aprovado"],
        "channel" => [],
        "seller" => [],
        "sort" => "recent"
      },
      single: "Paid",
      last: nil,
      live: %{"tags" => ["b"]},
      tags: [{"Priority", "a"}, {"Backlog", "b"}, {"Blocked", "c"}]
    )
  end

  def handle_event("apply", %{"filter" => params}, socket) do
    filter = Map.merge(%{"status" => [], "channel" => [], "seller" => []}, params)
    {:noreply, assign(socket, filter: filter)}
  end

  def handle_event("apply", _params, socket), do: {:noreply, socket}

  def handle_event("set_single", %{"values" => %{"status" => status}} = payload, socket),
    do: {:noreply, assign(socket, single: List.first(status, ""), last: payload)}

  def handle_event("live", %{"tags" => tags}, socket),
    do: {:noreply, assign(socket, live: %{"tags" => tags})}

  def handle_event("live", _params, socket), do: {:noreply, assign(socket, live: %{"tags" => []})}

  defp orders(filter) do
    @orders
    |> Enum.filter(fn order ->
      Enum.all?(@columns, fn {name, column} ->
        filter[name] == [] or elem(order, column) in filter[name]
      end)
    end)
    |> sort(filter["sort"])
  end

  defp sort(orders, "recent"), do: Enum.sort_by(orders, &elem(&1, 0), :desc)
  defp sort(orders, "value"), do: Enum.sort_by(orders, &elem(&1, 5), :desc)
  defp sort(orders, "client"), do: Enum.sort_by(orders, &elem(&1, 1))

  defp count(column, label), do: Enum.count(@orders, &(elem(&1, column) == label))

  defp options(column), do: for(label <- unique(column), do: {label, label, count(column, label)})

  defp unique(column), do: @orders |> Enum.map(&elem(&1, column)) |> Enum.uniq()

  defp groups(filter) do
    [
      %{
        name: "filter[status]",
        label: "Status",
        icon: "huge-checkmark-circle-02",
        value: filter["status"],
        options: options(4)
      },
      %{
        name: "filter[channel]",
        label: "Canal de venda",
        icon: "huge-store-01",
        value: filter["channel"],
        options: options(2)
      },
      %{
        name: "filter[seller]",
        label: "Vendedor",
        icon: "huge-user",
        value: filter["seller"],
        options: options(3)
      },
      %{
        name: "filter[sort]",
        label: "Ordenar por",
        caption: "Ordenar por",
        display: :section,
        type: :single,
        value: filter["sort"],
        options: [
          {"Mais recentes", "recent"},
          {"Maior valor", "value"},
          {"Cliente A-Z", "client"}
        ]
      }
    ]
  end

  defp money(value), do: "R$ " <> :erlang.float_to_binary(value, decimals: 2)

  def render(assigns) do
    assigns = assign(assigns, :shown, orders(assigns.filter))

    ~H"""
    <.example
      title="Menu de filtros com submenus"
      text="One filter button instead of a row of chips: a row per group opens its options, a flat Ordenar por group, Clear and Apply (n). Nothing is applied until Apply."
      class="block"
    >
      <div class="rounded-lg bg-white p-4 dark:bg-navy-700">
        <form id="orders" phx-submit="apply" class="mb-3 flex items-center gap-3">
          <label class="relative flex w-70">
            <input
              type="search"
              placeholder="Buscar pedidos…"
              class="form-input h-9 w-full rounded-lg border border-slate-300 bg-transparent px-3 text-sm dark:border-navy-450"
            />
          </label>
          <.filter_menu
            id="orders-filter"
            label="Filtrar"
            locale="pt_BR"
            icon="huge-filter"
            groups={groups(@filter)}
          />
          <span class="ml-auto text-xs text-slate-400">{length(@shown)} de 8 pedidos</span>
        </form>
        <table class="w-full text-left text-sm">
          <thead>
            <tr class="border-y border-slate-150 text-xs uppercase text-slate-400 dark:border-navy-500">
              <th class="px-3 py-2 font-semibold">Pedido</th>
              <th class="px-3 py-2 font-semibold">Cliente</th>
              <th class="px-3 py-2 font-semibold">Canal</th>
              <th class="px-3 py-2 font-semibold">Vendedor</th>
              <th class="px-3 py-2 font-semibold">Status</th>
              <th class="px-3 py-2 text-right font-semibold">Total</th>
            </tr>
          </thead>
          <tbody>
            <tr
              :for={{id, client, channel, seller, status, total} <- @shown}
              class="border-b border-slate-150 dark:border-navy-500"
            >
              <td class="px-3 py-2.5 font-mono">{id}</td>
              <td class="px-3 py-2.5">{client}</td>
              <td class="px-3 py-2.5">{channel}</td>
              <td class="px-3 py-2.5">{seller}</td>
              <td class="px-3 py-2.5">{status}</td>
              <td class="px-3 py-2.5 text-right font-mono">{money(total)}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </.example>

    <.example
      title="Toolbar button"
      text="One group, the dashed small outline button of a list toolbar; Apply pushes on_apply with the staged values instead of submitting a form."
    >
      <.filter_menu
        id="single-filter"
        label="Status"
        variant="outline"
        size="sm"
        dashed
        on_apply="set_single"
        groups={[
          %{
            name: "status",
            label: "Status",
            value: [@single],
            options: [{"Paid", "Paid", 12}, {"Open", "Open", 5}, {"Late", "Late", 2}]
          }
        ]}
      />
      <span class="text-sm text-slate-500">Applied: {@single}</span>
      <pre :if={@last} class="w-full text-xs text-slate-500">{inspect(@last)}</pre>
    </.example>

    <.example
      title="Live mode"
      text="No Apply: every tick reaches the form's phx-change at once."
    >
      <form id="live-form" phx-change="live" class="flex items-center gap-3">
        <.filter_menu
          id="live-filter"
          mode="live"
          label="Tags"
          groups={[
            %{
              name: "tags",
              label: "Tags",
              value: @live["tags"],
              options: Enum.map(@tags, fn {label, value} -> {label, value} end)
            }
          ]}
        />
        <span class="text-sm text-slate-500">Server has: {Enum.join(@live["tags"], ", ")}</span>
      </form>
    </.example>

    <.example
      title="Custom option content"
      text="A :group slot with your own dropdown_checkbox items."
    >
      <.filter_menu id="slot-filter" label="Filters">
        <:group name="tags[]" label="Tags" value={["b"]} icon="huge-filter">
          <.dropdown_checkbox
            :for={{label, value} <- @tags}
            name="tags[]"
            value={value}
            checked={value == "b"}
            data-count={3}
            count={3}
          >
            {label}
          </.dropdown_checkbox>
        </:group>
      </.filter_menu>
    </.example>
    """
  end
end
