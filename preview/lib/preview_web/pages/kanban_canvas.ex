defmodule PreviewWeb.Pages.KanbanCanvas do
  use PreviewWeb.Page, title: "Kanban (canvas)", category: :components

  @people %{
    "AS" => "primary",
    "CL" => "info",
    "MA" => "success",
    "RC" => "warning",
    "BN" => "secondary"
  }

  @tag_colors %{"p" => "primary", "o" => "success", "w" => "warning", "i" => "info", "n" => "neutral"}

  @lifted "shadow-[0_0_0_1px_var(--color-slate-300),0_8px_20px_-10px_rgb(16_24_64/0.3)] dark:shadow-[0_0_0_1px_var(--color-navy-450)]"

  def render(assigns) do
    assigns = assign(assigns, lifted: @lifted)

    ~H"""
    <.example
      title="Quadro"
      text="colunas de 272px, cartões com avatar e etiquetas, coluna Perdidos"
      class="mt-2"
    >
      <.kanban id="kc-board" aria-label="Quadro de pedidos" class="mt-3">
        <.kanban_column
          id="kc-novo"
          label="Novo"
          count={3}
          meta="33% do funil"
          total="R$ 5.047,40"
          progress={33}
        >
          <:icon><.icon name="huge-inbox" class="size-3.5" /></:icon>
          <:actions><.menu_button label="Opções de Novo" /></:actions>
          <.order
            id="2490"
            name="Ana Souza"
            value="R$ 1.284,90"
            tags={[{"p", "Pix"}, {"n", "3 itens"}]}
            due="29 out"
            who={["AS"]}
          />
          <.order
            id="2489"
            name="Carlos Lima"
            value="R$ 642,00"
            tags={[{"i", "Atacado"}]}
            due="30 out"
            who={["CL", "MA"]}
            hover
          />
          <.order
            id="2488"
            name="Marina Alves"
            value="R$ 3.120,50"
            tags={[{"w", "Atrasado"}]}
            due="22 out"
            who={["MA"]}
            late
          />
          <:footer><.new_order /></:footer>
        </.kanban_column>
        <.kanban_column
          id="kc-andamento"
          label="Em andamento"
          color="info"
          count={2}
          meta="60% de chance"
          total="R$ 2.158,80"
          progress={60}
        >
          <:icon><.icon name="huge-truck-delivery" class="size-3.5" /></:icon>
          <:actions><.menu_button label="Opções de Em andamento" /></:actions>
          <.order
            id="2487"
            name="Rafael Costa"
            value="R$ 89,90"
            tags={[{"p", "Cartão"}]}
            due="31 out"
            who={["RC"]}
          />
          <div class="linea-drop-slot h-[78px] rounded-xl" aria-hidden="true"></div>
          <:footer><.new_order /></:footer>
        </.kanban_column>
        <.kanban_column
          id="kc-concluido"
          label="Concluído"
          color="success"
          count={2}
          meta="100% concluído"
          total="R$ 2.317,30"
          progress={100}
        >
          <:icon><.icon name="huge-checkmark-circle-02" class="size-3.5" /></:icon>
          <:actions><.menu_button label="Opções de Concluído" /></:actions>
          <.order
            id="2486"
            name="Beatriz Nunes"
            value="R$ 1.905,00"
            tags={[{"p", "Pix"}, {"o", "Entregue"}]}
            due="24 out"
            who={["BN", "AS"]}
          />
          <.order
            id="2485"
            name="Paulo Dias"
            value="R$ 412,30"
            tags={[{"o", "Entregue"}]}
            due="23 out"
            who={["CL"]}
          />
          <:footer><.new_order /></:footer>
        </.kanban_column>
        <.kanban_lost label="Perdidos" count={3} meta="R$ 640,00" />
      </.kanban>
      <p class="mt-2 text-xs">
        O cartão do meio está em <b>hover</b>
        (sombra maior e alça de arrasto visível); o cartão com anel âmbar é <b>risk</b>; o tracejado em Em andamento é o espaço reservado do cartão em arraste.
      </p>
    </.example>

    <.example
      title="Estados"
      text="arrasto, coluna alvo, vazia, limite WIP, desativada"
      class="mt-2"
    >
      <.kanban id="kc-states" aria-label="Estados do quadro" class="mt-3">
        <.kanban_column
          id="kc-s-drag"
          label="Em andamento"
          color="info"
          count={2}
          meta="Arrastando"
          data-over="true"
        >
          <:icon><.icon name="huge-truck-delivery" class="size-3.5" /></:icon>
          <:actions><.menu_button label="Opções de Em andamento" /></:actions>
          <div class="linea-drop-slot h-[78px] rounded-xl" aria-hidden="true"></div>
          <.order
            id="2487b"
            name="Rafael Costa"
            value="R$ 89,90"
            tags={[{"p", "Cartão"}]}
            due="31 out"
            who={["RC"]}
          />
          <.order
            id="2484"
            name="Julia Rocha"
            value="R$ 758,00"
            tags={[{"p", "Pix"}]}
            due="01 nov"
            who={["MA"]}
            ghost
          />
        </.kanban_column>
        <.kanban_column
          id="kc-s-empty"
          label="Em análise"
          color="primary"
          count={0}
          meta="0% de chance"
          total="R$ 0,00"
          progress={0}
        >
          <:icon><.icon name="huge-search-01" class="size-3.5" /></:icon>
          <:actions><.menu_button label="Opções de Em análise" /></:actions>
          <:empty title="Nenhum pedido aqui">
            Arraste um pedido para cá quando ele precisar de revisão.
          </:empty>
          <:footer><.new_order /></:footer>
        </.kanban_column>
        <.kanban_column
          id="kc-s-wip"
          label="Aprovado"
          color="primary"
          count={4}
          limit={3}
          meta="limite de 3 em andamento"
          total="4 de 3"
          progress={100}
        >
          <:icon><.icon name="huge-security-check" class="size-3.5" /></:icon>
          <:actions><.menu_button label="Opções de Aprovado" /></:actions>
          <.order
            id="2470"
            name="Felipe Reis"
            value="R$ 980,00"
            tags={[{"p", "Pix"}]}
            due="28 out"
            who={["RC"]}
          />
          <.order
            id="2469"
            name="Ana Souza"
            value="R$ 1.240,00"
            tags={[{"i", "Atacado"}]}
            due="28 out"
            who={["AS"]}
          />
        </.kanban_column>
        <.kanban_column
          id="kc-s-off"
          label="Arquivado"
          count={12}
          meta="coluna desativada"
          disabled
        >
          <:icon><.icon name="huge-archive-02" class="size-3.5" /></:icon>
          <:actions><.menu_button label="Opções de Arquivado" /></:actions>
          <.order
            id="2201"
            name="Carlos Lima"
            value="R$ 301,00"
            tags={[{"o", "Entregue"}]}
            due="02 set"
            who={["CL"]}
          />
        </.kanban_column>
      </.kanban>
      <p class="mt-2 text-xs">
        Coluna 1: cartão levantado seguindo o ponteiro e coluna alvo com <b>data-over</b>. Coluna 3: limite WIP com <b>limit</b>. Coluna 4: <b>disabled</b>.
      </p>
    </.example>
    """
  end

  attr :label, :string, required: true

  defp menu_button(assigns) do
    ~H"""
    <.button size="sm" variant="flat" icon class="size-[26px]" aria-label={@label}>
      <.icon name="huge-more-horizontal" class="size-4" />
    </.button>
    """
  end

  defp new_order(assigns) do
    ~H"""
    <.button
      variant="outline"
      size="sm"
      class="font-inter h-[34px] w-full border-dashed text-[13px] text-slate-500 dark:text-navy-200"
    >
      <.icon name="huge-add-01" class="size-3.5" /> Novo pedido
    </.button>
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :value, :string, required: true
  attr :tags, :list, default: []
  attr :due, :string, required: true
  attr :who, :list, default: []
  attr :hover, :boolean, default: false
  attr :late, :boolean, default: false
  attr :ghost, :boolean, default: false

  defp order(assigns) do
    assigns =
      assigns
      |> assign(:people, @people)
      |> assign(:tag_colors, @tag_colors)
      |> assign(:lifted, @lifted)

    ~H"""
    <.kanban_card
      id={"kc-order-#{@id}"}
      item={@id}
      risk={@late}
      grip
      class={[
        @hover && [@lifted, "[&_[data-grip]]:opacity-90"],
        @ghost && "linea-drag-lift linea-drag-lifted z-10 translate-x-2 -translate-y-1"
      ]}
    >
      <div class="flex h-[19px] items-center gap-2">
        <span class="font-mono text-[11.5px]/none font-medium text-slate-400 dark:text-navy-300">
          #{String.replace(@id, ~r/\D/, "")}
        </span>
      </div>
      <div class="font-inter text-[13.5px]/[1.35] font-semibold text-slate-800 dark:text-navy-50">{@name}</div>
      <div class="font-inter text-[13px]/[1.3] font-semibold text-slate-800 tabular-nums dark:text-navy-50">
        {@value}
      </div>
      <div class="flex flex-wrap gap-[5px]">
        <.badge
          :for={{key, text} <- @tags}
          color={@tag_colors[key]}
          variant="soft"
          shape="pill"
          size="sm"
          class={[
            "font-inter text-[11px] font-medium",
            key == "n" && "bg-slate-500/[.13] text-slate-500 dark:bg-navy-200/[.13] dark:text-navy-200"
          ]}
        >
          {text}
        </.badge>
      </div>
      <div class="flex items-center justify-between gap-2 border-t border-dashed border-slate-200 pt-[9px] dark:border-navy-500">
        <span class={[
          "font-inter inline-flex items-center gap-[5px] text-[11.5px] font-medium",
          if(@late,
            do: "text-warning-focus dark:text-warning",
            else: "text-slate-500 dark:text-navy-200"
          )
        ]}>
          <.icon name="huge-calendar-03" class="size-[13px]" />{@due}
        </span>
        <.avatar_group aria-label="Responsáveis" size="3xs" overlap="auto">
          <.avatar :for={who <- @who} initials={who} color={@people[who]} size="3xs" ring />
        </.avatar_group>
        <.button
          size="sm"
          variant="flat"
          icon
          class="size-6 text-slate-500 dark:text-navy-200"
          aria-label={"Mover ##{String.replace(@id, ~r/\D/, "")} para a próxima coluna"}
        >
          <.icon name="huge-arrow-right-02" class="size-[15px]" />
        </.button>
      </div>
    </.kanban_card>
    """
  end
end
