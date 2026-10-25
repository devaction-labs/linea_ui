defmodule LineaShowcaseWeb.Templates.Pages.SignetumKanban do
  @moduledoc """
  The Signetum sales funnel of the design canvas (board `AppKanban`): the orders by situation as a kanban,
  built only from LineaUI components and a handful of utility classes.

  The recipe, for an app that needs the same board:

    * the page is a column of header (title, seller avatars as a filter, search, board/list switch, the primary
      action), four KPI cards and the board;
    * the board is `kanban/1`, a column `kanban_column/1` (the tinted well with the icon tile in the stage color,
      the name, the count pill, the win chance and the total, the 4px probability bar, the cards, the empty state
      and the dashed add button), a card `kanban_card/1` (a number in mono, the customer as a link, the value in
      bold, tags and a dashed footer with the seller and a move-on button; a card idle for more than seven days
      gets the warning ring and a flag line) and the aside `kanban_lost/1`;
    * dragging a card over a column outlines it and shows a line where it lands; dropping pushes `move` with
      `%{"id", "from", "to", "index"}` (the `LineaUI.Sortable` hook of the board, native drag and drop). The arrow
      in the card's footer pushes `advance`, for touch and keyboard.
  """

  use LineaShowcaseWeb.Template,
    title: "Signetum · Funil de vendas",
    section: :signetum,
    group: "App",
    order: 2

  @sellers [
    {"ma", "Marina Costa", "MC", "primary"},
    {"jo", "João Silva", "JS", "warning"},
    {"ca", "Carla Mendes", "CM", "secondary"},
    {"ra", "Rafael Souza", "RS", "info"}
  ]

  @columns [
    %{
      id: :draft,
      name: "Prospecção",
      chance: 20,
      icon: "pencil-edit-02",
      color: "neutral",
      empty: "Rascunhos de pedido aparecem aqui."
    },
    %{
      id: :confirmed,
      name: "Qualificado",
      chance: 60,
      icon: "checkmark-circle-02",
      color: "info",
      empty: "Pedidos confirmados esperando aprovação."
    },
    %{
      id: :pending,
      name: "Pendente",
      chance: 60,
      icon: "clock-01",
      color: "warning",
      empty: "Arraste um pedido para cá quando ele travar."
    },
    %{
      id: :approved,
      name: "Aprovado",
      chance: 80,
      icon: "security-check",
      color: "primary",
      empty: "Pedidos aprovados prontos para despachar."
    },
    %{
      id: :shipped,
      name: "Em trânsito",
      chance: 90,
      icon: "truck-delivery",
      color: "teal",
      empty: "Pedidos despachados a caminho do cliente."
    },
    %{
      id: :delivered,
      name: "Ganho",
      chance: 100,
      icon: "award-01",
      color: "success",
      empty: "Pedidos entregues no período."
    }
  ]

  @cards [
    %{
      n: 2486,
      customer: "Ótica Visão",
      value: 980.0,
      date: "23 out",
      pay: "PIX",
      items: "3 itens",
      seller: "jo",
      st: :draft
    },
    %{
      n: 2485,
      customer: "Drogaria São Bento",
      value: 4320.0,
      date: "22 out",
      pay: "Boleto 3x",
      items: "8 itens",
      seller: "ma",
      st: :draft
    },
    %{
      n: 2483,
      customer: "Clínica Vida Plena",
      value: 980.0,
      date: "23 out",
      pay: "Cartão",
      items: "2 itens",
      seller: "jo",
      st: :confirmed
    },
    %{
      n: 2482,
      customer: "Pet Shop Amigo Fiel",
      value: 1105.3,
      date: "23 out",
      pay: "Boleto 2x",
      items: "4 itens",
      seller: "ca",
      st: :confirmed
    },
    %{
      n: 2477,
      customer: "Mercado Central",
      value: 2640.0,
      date: "20 out",
      pay: "Boleto",
      items: "6 itens",
      seller: "ma",
      st: :confirmed
    },
    %{
      n: 2481,
      customer: "Farmácia Bom Preço",
      value: 2158.8,
      date: "23 out",
      pay: "Boleto 2x",
      items: "2 itens",
      seller: "ma",
      st: :approved
    },
    %{
      n: 2462,
      customer: "Hospital Santa Clara",
      value: 18_420.0,
      date: "14 out",
      pay: "Boleto 4x",
      items: "12 itens",
      seller: "jo",
      st: :approved,
      age: 9
    },
    %{
      n: 2458,
      customer: "Clínica Vida Plena",
      value: 3180.0,
      date: "12 out",
      pay: "PIX",
      items: "5 itens",
      seller: "ca",
      st: :approved,
      age: 11
    },
    %{
      n: 2480,
      customer: "Hospital Santa Clara",
      value: 18_420.0,
      date: "22 out",
      pay: "Boleto 4x",
      items: "12 itens",
      seller: "jo",
      st: :shipped
    },
    %{
      n: 2479,
      customer: "Mercado Central",
      value: 214.5,
      date: "22 out",
      pay: "Dinheiro",
      items: "1 item",
      seller: "ra",
      st: :delivered
    },
    %{
      n: 2470,
      customer: "Ótica Visão",
      value: 1290.0,
      date: "18 out",
      pay: "PIX",
      items: "2 itens",
      seller: "ma",
      st: :delivered
    }
  ]

  @order Enum.map(@columns, & &1.id)

  def mount(socket), do: assign(socket, cards: @cards, query: "", seller: nil)

  def handle_event("search", %{"query" => query}, socket),
    do: {:noreply, assign(socket, :query, query)}

  def handle_event("seller", %{"id" => id}, %{assigns: %{seller: id}} = socket),
    do: {:noreply, assign(socket, :seller, nil)}

  def handle_event("seller", %{"id" => id}, socket), do: {:noreply, assign(socket, :seller, id)}

  def handle_event("move", %{"id" => id, "to" => to, "index" => index}, socket),
    do: {:noreply, move(socket, String.to_integer(id), String.to_existing_atom(to), index)}

  def handle_event("advance", %{"id" => id}, socket) do
    n = String.to_integer(id)
    card = Enum.find(socket.assigns.cards, &(&1.n == n))
    {:noreply, move(socket, n, next(card.st), 0)}
  end

  def render(assigns) do
    visible = visible(assigns.cards, assigns.query, assigns.seller)
    open = Enum.reject(visible, &(&1.st == :delivered))

    assigns =
      assign(assigns,
        sellers: @sellers,
        columns: columns(visible),
        open_total: Enum.sum(Enum.map(open, & &1.value)),
        weighted: Enum.sum(Enum.map(open, &(&1.value * chance(&1.st) / 100))),
        risk: Enum.count(visible, &Map.has_key?(&1, :age))
      )

    ~H"""
    <div class="mt-5 grid grid-cols-1 gap-[18px] lg:mt-6">
      <div class="flex flex-wrap items-center gap-3">
        <div class="min-w-[260px] flex-[1_1_320px]">
          <h1 class="text-xl font-medium text-slate-800 dark:text-navy-50 lg:text-2xl">
            Funil de vendas
          </h1>
          <p class="mt-1 text-slate-400 dark:text-navy-300">
            Os pedidos de venda por situação. Arraste um cartão para a próxima etapa.
          </p>
        </div>

        <div class="flex" role="group" aria-label="Filtrar por vendedor">
          <button
            :for={{id, name, initials, color} <- @sellers}
            type="button"
            phx-click="seller"
            phx-value-id={id}
            aria-pressed={to_string(@seller == id)}
            aria-label={name}
            class="-ml-1.5 rounded-full first:ml-0 focus-visible:outline-2 focus-visible:outline-primary aria-pressed:ring-2 aria-pressed:ring-primary aria-pressed:ring-offset-2 aria-pressed:ring-offset-white dark:aria-pressed:ring-offset-navy-900"
          >
            <.avatar size="sm" initials={initials} color={color} variant="soft" />
          </button>
        </div>

        <form phx-change="search" class="w-[220px] max-w-full">
          <.input
            type="search"
            name="query"
            value={@query}
            placeholder="Pedido ou cliente"
            aria-label="Buscar no quadro"
            phx-debounce="150"
          >
            <:prefix><.icon name="huge-search-01" class="size-4" /></:prefix>
          </.input>
        </form>

        <.segmented id="kanban-view" name="view" size="sm" value="board">
          <:option value="board" label="Quadro" icon="huge-kanban" />
          <:option value="list" label="Lista" icon="huge-list-view" />
        </.segmented>

        <.button color="primary">
          <.icon name="huge-plus-sign" class="mr-2 size-4" />Novo pedido
        </.button>
      </div>

      <div class="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <.kpi label="Em aberto no funil" value={brl(@open_total)} />
        <.kpi label="Previsão ponderada" value={brl(@weighted)} />
        <.kpi label="Taxa de ganho (90 dias)" value="78%" />
        <.kpi label="Pedidos parados há mais de 7 dias" value={to_string(@risk)} warn />
      </div>

      <.kanban id="kanban" event="move" group="funnel" class="min-h-[600px]">
        <.kanban_column
          :for={{stage, cards} <- @columns}
          id={"col-#{stage.id}"}
          list={Atom.to_string(stage.id)}
          label={stage.name}
          color={stage.color}
          count={length(cards)}
          meta={"#{stage.chance}% de chance"}
          total={brl(sum(cards))}
          progress={stage.chance}
        >
          <:icon><.icon name={"huge-" <> stage.icon} class="size-3.5" /></:icon>
          <:actions>
            <.button
              size="sm"
              variant="flat"
              icon
              class="size-[26px]"
              aria-label={"Opções de " <> stage.name}
            >
              <.icon name="huge-more-horizontal" class="size-4" />
            </.button>
          </:actions>
          <.board_card
            :for={card <- cards}
            card={card}
            sellers={@sellers}
            last={stage.id == :delivered}
          />
          <:empty title="Nenhum pedido aqui">{stage.empty}</:empty>
          <:footer :if={stage.id == :draft}>
            <.button variant="outline" size="sm" class="h-[34px] w-full border-dashed">
              <.icon name="huge-plus-sign" class="mr-1.5 size-4" />Novo pedido
            </.button>
          </:footer>
        </.kanban_column>
        <.kanban_lost label="Perdidos" count={3} meta="R$ 6.410,00" />
      </.kanban>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :warn, :boolean, default: false

  defp kpi(assigns) do
    ~H"""
    <div class="rounded-xl bg-white px-4 py-3.5 shadow-soft ring-1 ring-slate-150 dark:bg-navy-700 dark:shadow-none dark:ring-navy-500">
      <div class="text-xs text-slate-400 dark:text-navy-300">{@label}</div>
      <div class={[
        "mt-1 text-xl font-bold tracking-tight tabular-nums",
        (@warn && "text-warning-focus dark:text-warning") || "text-slate-800 dark:text-navy-50"
      ]}>
        {@value}
      </div>
    </div>
    """
  end

  attr :card, :map, required: true
  attr :sellers, :list, required: true
  attr :last, :boolean, default: false

  defp board_card(assigns) do
    {_, name, initials, color} = List.keyfind(assigns.sellers, assigns.card.seller, 0)
    assigns = assign(assigns, name: name, initials: initials, color: color)

    ~H"""
    <.kanban_card id={"kc-#{@card.n}"} item={@card.n} risk={Map.has_key?(@card, :age)}>
      <div class="flex items-center gap-1.5">
        <span class="font-mono text-xs font-medium text-slate-400 dark:text-navy-300">#{@card.n}</span>
        <span
          :if={Map.has_key?(@card, :age)}
          class="inline-flex items-center gap-[5px] text-xs font-semibold text-warning-focus dark:text-warning"
        >
          <.icon name="huge-flag-01" class="size-[13px]" />Parado há {@card.age} dias
        </span>
      </div>
      <a href="#" class="font-semibold leading-[19px] text-slate-800 dark:text-navy-50">{@card.customer}</a>
      <div class="text-base font-bold text-slate-800 tabular-nums dark:text-navy-50">
        {brl(@card.value)}
      </div>
      <div class="flex flex-wrap gap-1">
        <span class="inline-flex h-5 items-center gap-1 rounded-md bg-slate-50 px-[7px] text-[11px] font-medium text-slate-500 ring-1 ring-slate-150 ring-inset dark:bg-navy-800 dark:text-navy-200 dark:ring-navy-500">
          <.icon name="huge-calendar-03" class="size-3" />{@card.date}
        </span>
        <span class="inline-flex h-5 items-center rounded-md bg-slate-150 px-[7px] text-[11px] font-medium text-slate-500 dark:bg-navy-600 dark:text-navy-100">{@card.pay}</span>
        <span class="inline-flex h-5 items-center rounded-md bg-slate-150 px-[7px] text-[11px] font-medium text-slate-500 dark:bg-navy-600 dark:text-navy-100">{@card.items}</span>
      </div>
      <div class="flex items-center gap-2 border-t border-dashed border-slate-200 pt-2 text-xs text-slate-400 dark:border-navy-500 dark:text-navy-300">
        <.avatar size="2xs" initials={@initials} color={@color} variant="soft" />
        {hd(String.split(@name))}
        <.button
          :if={not @last}
          size="sm"
          variant="flat"
          icon
          class="ml-auto size-[26px]"
          aria-label="Mover para a próxima etapa"
          phx-click="advance"
          phx-value-id={@card.n}
        >
          <.icon name="huge-arrow-right-02" class="size-4" />
        </.button>
      </div>
    </.kanban_card>
    """
  end

  defp columns(visible) do
    Enum.map(@columns, fn column ->
      {column, Enum.filter(visible, &(&1.st == column.id))}
    end)
  end

  defp sum(cards), do: Enum.reduce(cards, 0.0, &(&1.value + &2))

  defp visible(cards, query, seller) do
    needle = query |> String.trim() |> String.downcase()

    Enum.filter(cards, fn card ->
      (needle == "" or String.contains?(to_string(card.n), needle) or
         String.contains?(String.downcase(card.customer), needle)) and
        (is_nil(seller) or card.seller == seller)
    end)
  end

  defp move(socket, n, to, index) do
    %{cards: cards, query: query, seller: seller} = socket.assigns
    {[card], rest} = Enum.split_with(cards, &(&1.n == n))
    moved = card |> Map.delete(:age) |> Map.put(:st, to)
    column = rest |> visible(query, seller) |> Enum.filter(&(&1.st == to))
    assign(socket, :cards, insert(rest, moved, Enum.at(column, index)))
  end

  defp insert(cards, moved, nil), do: cards ++ [moved]

  defp insert(cards, moved, anchor) do
    {before, from_anchor} = Enum.split_while(cards, &(&1.n != anchor.n))
    before ++ [moved | from_anchor]
  end

  defp next(state) do
    index = Enum.find_index(@order, &(&1 == state))
    Enum.at(@order, min(index + 1, length(@order) - 1))
  end

  defp chance(state) do
    @columns |> Enum.find(&(&1.id == state)) |> Map.fetch!(:chance)
  end

  defp brl(value) do
    [int, frac] = value |> :erlang.float_to_binary(decimals: 2) |> String.split(".")

    grouped =
      int
      |> String.reverse()
      |> String.replace(~r/(\d{3})(?=\d)/, "\\1.")
      |> String.reverse()

    "R$ #{grouped},#{frac}"
  end
end
