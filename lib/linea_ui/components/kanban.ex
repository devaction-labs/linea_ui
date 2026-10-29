defmodule LineaUI.Components.Kanban do
  @moduledoc """
  A kanban board: a row of tinted columns (a stage of a sales funnel, a status of a task) holding cards that are
  dragged between them, with a native drag and drop on pointer events and no library. It is the Signetum canvas's
  `AppKanban`, and the same parts serve a plain task board.

      <.kanban id="funnel" event="move" group="orders" class="min-h-[600px]">
        <.kanban_column
          :for={stage <- @stages}
          id={"col-" <> stage.id}
          list={stage.id}
          label={stage.name}
          color={stage.color}
          count={length(stage.orders)}
          meta={"\#{stage.chance}% chance"}
          total={brl(stage.total)}
          progress={stage.chance}
        >
          <:icon><.icon name={stage.icon} class="size-3.5" /></:icon>
          <:actions>
            <.button size="sm" variant="flat" icon class="size-[26px]" aria-label={"Options of " <> stage.name}>
              <.icon name="huge-more-horizontal" class="size-4" />
            </.button>
          </:actions>
          <.kanban_card :for={order <- stage.orders} id={"order-\#{order.id}"} item={order.id} risk={order.idle > 7}>
            <b>{order.customer}</b>
          </.kanban_card>
          <:empty title="No orders here">Drag an order here when it stalls.</:empty>
          <:footer><.button variant="outline" size="sm" class="h-[34px] w-full border-dashed">New order</.button></:footer>
        </.kanban_column>
        <.kanban_lost label="Lost" count={3} meta="R$ 6.410,00" />
      </.kanban>

  The board is a `role="group"`; give it an `aria-label` (`aria-label="Sales funnel"`) so it is announced.
  A column with a `limit` (a work in progress limit) turns the pill and the bar red when the count goes over
  it (`data-wip="exceeded"`); the text of the stats line is yours (`meta="limit of 3 in progress" total="4 of 3"`).
  A `disabled` column is drawn at 60% opacity.

  The board is one `LineaUI.Sortable` hook: every column is a list (`data-list`), every card an item
  (`data-id`), and all the columns of the board are in one group, so a card can be dropped on any of them or
  reordered inside its own. Dropping pushes `event` (to `target` when given, else the LiveView) with the card's
  and the columns' ids and the index the card takes there:

      def handle_event("move", %{"id" => id, "from" => from, "to" => to, "index" => index}, socket),
        do: {:noreply, update(socket, :orders, &Orders.move(&1, id, from, to, index))}

  Nothing is moved in the browser, the server's render is the new order. While a card is dragged the original
  stays as a quiet dashed placeholder (`data-dragging`), a lifted copy of the card follows the pointer (tilting
  a little towards the movement, with a big soft shadow) and, on a drop, glides into its slot or flies back when
  the drop is cancelled. The cards of the column under the pointer (`data-over`, which only tints the
  column) slide out of the way as the copy crosses them, opening a gap with a dashed placeholder, and the board
  and the columns scroll when the pointer is near their edges. A drop where the card already was pushes nothing.
  A mouse, a pen and a finger share this: a mouse or a pen drags after moving a few pixels (a click on the card, a
  link or a button in it still works), a finger holds the card for a moment first. Escape cancels. A button in the
  card that pushes the same event with the next column (`phx-click`) is the alternative for the keyboard and for
  screens where dragging is awkward.

  ## Another board

  The old `kanban` of an admin template (columns that are reordered by a handle, free-form cards) needs no column:
  put `phx-hook="LineaUI.Sortable"` on your own list and the data attributes of the hook on it.

      <div id="columns" phx-hook="LineaUI.Sortable" data-event="move_column" data-list="columns" data-handle=".grip" data-axis="x">
        <div :for={col <- @columns} data-id={col.id}>...</div>
      </div>

  A list that holds the cards of a column in its own group does the same for the cards:

      <div id={"cards-\#{col.id}"} phx-hook="LineaUI.Sortable" data-group="cards" data-list={col.id} data-event="move_card">
        <.card :for={card <- col.cards} data-id={card.id}>...</.card>
      </div>

  A single list with no group is a sortable list, e.g. a to-do list:

      <div id="todos" phx-hook="LineaUI.Sortable" data-list="todos" data-event="reorder">
        <div :for={todo <- @todos} data-id={todo.id}>{todo.title}</div>
      </div>

  The attributes of the hook, on a list or on the element that holds the lists (a list's own wins):

    * `data-event` - the server event to push on a drop.
    * `data-target` - its `phx-target`; without it the LiveView of the hook gets the event.
    * `data-group` - lists with the same group exchange items; without one an item stays in its list.
    * `data-list` - the list's id, sent as `from` and `to`.
    * `data-handle` - a CSS selector inside the item; only a drag that starts on it moves the item.
    * `data-axis` - `x` for items laid in a row, `y` (default) for items stacked.
    * `data-disabled` - the list neither gives nor takes items (any value but `false`).

  Items carry `data-id`, the id the server gets as `id`. The default look comes from `parts/sortable.css`: a quiet
  `[data-dragging]` item, the lifted `.linea-drag-ghost` and the dashed `.linea-drop-slot`, all zero-specificity
  and easy to override with utilities.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [icon: 1]

  @board "flex items-start gap-3.5 overflow-x-auto px-0.5 pb-3"

  @column "flex w-[272px] flex-none flex-col gap-2.5 rounded-[14px] bg-slate-50 p-2.5 ring-1 ring-slate-150 ring-inset data-[over]:bg-primary/10 data-[disabled=true]:opacity-60 dark:bg-navy-900 dark:ring-navy-500 dark:data-[over]:bg-accent/[.18]"

  @colors %{
    "neutral" => %{
      tile: "bg-slate-500/[.13] text-slate-500 dark:bg-navy-200/[.13] dark:text-navy-200",
      bar: "bg-slate-500 dark:bg-navy-200"
    },
    "info" => %{
      tile: "bg-info-focus/[.13] text-info-focus dark:bg-info/[.13] dark:text-info",
      bar: "bg-info-focus dark:bg-info"
    },
    "warning" => %{
      tile: "bg-warning-focus/[.13] text-warning-focus dark:bg-warning/[.13] dark:text-warning",
      bar: "bg-warning-focus dark:bg-warning"
    },
    "primary" => %{
      tile: "bg-primary/[.13] text-primary dark:bg-accent-light/[.13] dark:text-accent-light",
      bar: "bg-primary dark:bg-accent-light"
    },
    "teal" => %{
      tile: "bg-teal-500/10 text-teal-600 dark:text-teal-300",
      bar: "bg-teal-500"
    },
    "success" => %{
      tile: "bg-success-focus/[.13] text-success-focus dark:bg-success/[.13] dark:text-success",
      bar: "bg-success-focus dark:bg-success"
    }
  }

  @card "group relative flex cursor-grab flex-col gap-[9px] rounded-xl bg-white p-3 shadow-[0_0_0_1px_var(--color-slate-200),0_1px_2px_rgb(0_0_0/0.05)] transition-shadow hover:shadow-[0_0_0_1px_var(--color-slate-300),0_8px_20px_-10px_rgb(16_24_64/0.3)] active:cursor-grabbing focus-within:outline-2 focus-within:outline-offset-1 focus-within:outline-primary/50 dark:focus-within:outline-accent/50 data-[dragging]:shadow-none dark:bg-navy-700 dark:shadow-[0_0_0_1px_var(--color-navy-500)] dark:hover:shadow-[0_0_0_1px_var(--color-navy-450)]"

  @risk "!shadow-[0_0_0_1px_color-mix(in_oklab,var(--color-warning)_55%,var(--color-slate-200)),0_1px_2px_rgb(0_0_0/0.05)] dark:!shadow-[0_0_0_1px_color-mix(in_oklab,var(--color-warning)_55%,var(--color-navy-500))]"

  @lost "flex w-[52px] flex-none flex-col items-center gap-2.5 self-stretch rounded-[14px] bg-slate-50 py-3 text-slate-500 ring-1 ring-slate-150 ring-inset data-[over]:bg-primary/10 dark:bg-navy-900 dark:text-navy-200 dark:ring-navy-500 dark:data-[over]:bg-accent/[.18]"

  @over_limit "bg-error-focus/10 text-error-focus ring-error-focus/50 dark:bg-error/10 dark:text-error dark:ring-error/50"

  @pill "inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-white px-1.5 font-mono text-[11px]/none font-semibold ring-1 ring-slate-200 dark:bg-navy-700 dark:ring-navy-500"

  @doc """
  Renders the board: a row of columns that scrolls sideways, and the drag and drop between them.

  Dropping a card pushes `event` with `%{"id" => card_item, "from" => column_list, "to" => column_list, "index" => position}`
  to `target`, or to the LiveView when there is none.

      <.kanban id="funnel" event="move" target={@myself} class="min-h-[600px]">
        <.kanban_column id="col-open" list="open" label="Open" count={length(@open)}>
          <.kanban_card :for={card <- @open} id={"card-\#{card.id}"} item={card.id}>{card.title}</.kanban_card>
        </.kanban_column>
      </.kanban>
  """
  attr :id, :string, required: true, doc: "Required by the hook."

  attr :event, :string,
    default: nil,
    doc: "The event pushed when a card is dropped; without one nothing is pushed."

  attr :target, :any,
    default: nil,
    doc:
      "The `phx-target` of the event (a selector or `@myself`); the LiveView gets it when `nil`."

  attr :group, :string,
    default: nil,
    doc:
      "The group whose columns exchange cards. The board's `id` by default, so two boards on a page do not exchange."

  attr :disabled, :boolean,
    default: false,
    doc: "`true` stops the cards from being dragged or dropped, e.g. for a read-only viewer."

  attr :class, :any,
    default: nil,
    doc: "Merged into the scrolling row, e.g. `min-h-[600px]` for a board that fills the screen."

  attr :rest, :global
  slot :inner_block, required: true, doc: "The `kanban_column`s, then a `kanban_lost`."

  def kanban(assigns) do
    assigns
    |> assign(:classes, merge([@board, assigns.class]))
    |> render_board()
  end

  defp render_board(assigns) do
    ~H"""
    <div
      id={@id}
      role="group"
      phx-hook="LineaUI.Sortable"
      data-group={@group || @id}
      data-event={@event}
      data-target={@target}
      data-disabled={@disabled && "true"}
      class={@classes}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a column: a tinted well, 272px wide, that is the drop list of its cards.

  The header has the `icon` tile in the color of the stage, the `label`, the number of cards and the `actions`
  (a menu button). Under it a line with `meta` on the left and `total` on the right, and a 4px bar filled to
  `progress`. The cards are the inner block; `empty` shows when `count` is `0`, and `footer` closes the column.

      <.kanban_column id="col-approved" list="approved" label="Approved" color="primary" count={2}
        meta="80% chance" total="R$ 2.158,80" progress={80}>
        <:icon><.icon name="huge-security-check" class="size-3.5" /></:icon>
        <.kanban_card id="order-2481" item="2481">...</.kanban_card>
        <.kanban_card id="order-2458" item="2458" risk>...</.kanban_card>
      </.kanban_column>

  The column is the `data-list` of the board's hook: a drop on it pushes `to` with `list`.
  """
  attr :id, :string, required: true, doc: "The DOM id of the column."

  attr :list, :string,
    default: nil,
    doc: "The id the server gets as `from` and `to` (the hook's `data-list`); defaults to `id`."

  attr :label, :string, required: true, doc: "The column's name, also its `aria-label`."

  attr :count, :integer,
    default: nil,
    doc:
      "The number of cards, in the pill by the label; `nil` shows no pill. `empty` needs it to be `0`."

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral info warning primary teal success),
    doc: "The color of the icon tile and of the progress bar."

  attr :limit, :integer,
    default: nil,
    doc:
      "A work in progress limit: with a `count` above it the pill and the bar turn red (`data-wip=\"exceeded\"`). The words of the limit go in `meta` and `total`."

  attr :meta, :string,
    default: nil,
    doc: "The text on the left of the stats line, e.g. `60% chance`."

  attr :total, :string,
    default: nil,
    doc: "The bold text on the right of the stats line, e.g. a sum."

  attr :progress, :integer,
    default: nil,
    doc: "0 to 100: the fill of the 4px bar under the stats; `nil` shows no bar."

  attr :disabled, :boolean,
    default: false,
    doc: "`true` makes this column neither give nor take cards."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, doc: "The `kanban_card`s."
  slot :icon, doc: "The glyph in the 26px tile of the header (`size-3.5`)."
  slot :actions, doc: "The header's menu button, at its right end."

  slot :empty, doc: "Shown instead of cards when `count` is `0`: `title` and the text." do
    attr :title, :string
    attr :icon, :string, doc: "A Hugeicons name; `huge-inbox` by default."
  end

  slot :footer, doc: "After the cards, e.g. the dashed add button."

  def kanban_column(assigns) do
    assigns
    |> assign(:look, Map.fetch!(@colors, assigns.color))
    |> assign(:width, bar_width(assigns.progress))
    |> assign(:exceeded, exceeded?(assigns.count, assigns.limit))
    |> assign(:classes, merge([@column, assigns.class]))
    |> assign(:pill, @pill)
    |> assign(:over_limit, @over_limit)
    |> render_column()
  end

  defp render_column(assigns) do
    ~H"""
    <section
      id={@id}
      data-list={@list || @id}
      data-disabled={@disabled && "true"}
      data-wip={@exceeded && "exceeded"}
      aria-label={@label}
      class={@classes}
      {@rest}
    >
      <div class="flex items-center gap-2 px-0.5 pt-0.5 pb-1">
        <span
          :if={@icon != []}
          class={["flex size-[26px] items-center justify-center rounded-lg", @look.tile]}
        >
          {render_slot(@icon)}
        </span>
        <span class="font-semibold text-slate-800 dark:text-navy-50">{@label}</span>
        <span
          :if={@count}
          class={
            merge([@pill, if(@exceeded, do: @over_limit, else: "text-slate-500 dark:text-navy-200")])
          }
        >
          {@count}
        </span>
        <span :if={@actions != []} class="ml-auto flex">{render_slot(@actions)}</span>
      </div>
      <div :if={@meta || @total} class="font-inter flex items-center justify-between px-0.5 text-xs">
        <span>{@meta}</span>
        <b class="font-semibold text-slate-800 tabular-nums dark:text-navy-50">{@total}</b>
      </div>
      <div
        :if={@width}
        class="mx-0.5 h-1 overflow-hidden rounded-full bg-slate-200 dark:bg-navy-500"
        aria-hidden="true"
      >
        <span
          class={[
            "block h-full rounded-full",
            if(@exceeded, do: "bg-error-focus dark:bg-error", else: @look.bar)
          ]}
          style={"width: #{@width}%"}
        ></span>
      </div>
      {render_slot(@inner_block)}
      <div
        :for={empty <- @empty}
        :if={@count == 0}
        data-empty
        class="flex flex-col items-center gap-1 px-2 pt-5 pb-6 text-center"
      >
        <.icon
          name={empty[:icon] || "huge-inbox"}
          class="mb-2 size-10 text-slate-300 dark:text-navy-450"
        />
        <b class="text-[14.5px] font-semibold text-slate-600 dark:text-navy-100">{empty[:title]}</b>
        <span class="font-inter text-[13px]/[18px] text-slate-500 dark:text-navy-200">
          {render_slot(empty)}
        </span>
      </div>
      {render_slot(@footer)}
    </section>
    """
  end

  defp exceeded?(count, limit) when is_integer(count) and is_integer(limit), do: count > limit
  defp exceeded?(_count, _limit), do: false

  defp bar_width(nil), do: nil
  defp bar_width(progress), do: progress |> max(0) |> min(100)

  @doc """
  Renders a card: a white rounded surface with a hairline ring that is dragged between columns.

  The content is yours, the inner block (the canvas's card is a number in mono, the customer, the value in bold,
  tags and a dashed footer with a button that advances it). `risk` gives it the warning ring and `grip` the
  drag handle that shows on hover.

      <.kanban_card id="order-2462" item="2462" risk>
        <span class="font-mono text-xs text-slate-400">#2462</span>
        <a href="#" class="font-semibold">Hospital Santa Clara</a>
        <.button size="sm" variant="flat" icon phx-click="advance" phx-value-id="2462" aria-label="Move on">
          <.icon name="huge-arrow-right-02" class="size-4" />
        </.button>
      </.kanban_card>

  A button inside is clickable as usual; the card is dragged by any other part of it, with a pointer that moves.
  """
  attr :id, :string, required: true, doc: "The DOM id of the card."

  attr :item, :any,
    default: nil,
    doc:
      "The id the server gets as `id` in the drop event (the hook's `data-id`); defaults to `id`."

  attr :risk, :boolean, default: false, doc: "The warning ring of a card that needs attention."

  attr :grip, :boolean,
    default: false,
    doc:
      "A six dot handle in the top right corner that shows while the card is hovered or has the focus, the cue that it can be dragged. Keep the first line of the content clear of it."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def kanban_card(assigns) do
    assigns
    |> assign(:classes, merge([@card, assigns.risk && @risk, assigns.class]))
    |> render_card()
  end

  defp render_card(assigns) do
    ~H"""
    <article
      id={@id}
      data-id={@item || @id}
      class={@classes}
      {@rest}
    >
      <span
        :if={@grip}
        data-grip
        aria-hidden="true"
        class="pointer-events-none absolute top-3 right-3 grid grid-cols-[repeat(2,3px)] gap-x-[3px] gap-y-0.5 p-[3px] text-slate-500 opacity-0 transition-opacity group-focus-within:opacity-90 group-hover:opacity-90 motion-reduce:transition-none dark:text-navy-200"
      >
        <i :for={_ <- 1..6} class="block size-[3px] rounded-full bg-current"></i>
      </span>
      {render_slot(@inner_block)}
    </article>
    """
  end

  @doc """
  Renders the 52px vertical aside that closes the board: the lost cards, with their count and a vertical label.

      <.kanban_lost label="Lost" count={3} meta="R$ 6.410,00" />

  With `list`, the aside is also a drop target: a card dropped on it pushes `to` with that id and index `0`.

      <.kanban_lost label="Lost" count={3} list="lost" />
  """
  attr :label, :string, required: true, doc: "The vertical text, also the `aria-label`."

  attr :count, :integer,
    default: nil,
    doc: "The number of lost cards, in the pill under the icon."

  attr :meta, :string, default: nil, doc: "Text after the label, separated by a dot (a sum)."

  attr :list, :string,
    default: nil,
    doc:
      "Makes the aside a drop list with this id for the `to` of the event; `nil` for a plain aside."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon, doc: "The glyph on top; a red crossed circle by default (`size-5`)."

  def kanban_lost(assigns) do
    assigns
    |> assign(:classes, merge([@lost, assigns.class]))
    |> assign(:pill, @pill)
    |> render_lost()
  end

  defp render_lost(assigns) do
    ~H"""
    <aside
      data-list={@list}
      aria-label={@label}
      class={@classes}
      {@rest}
    >
      {render_slot(@icon) || lost_icon(assigns)}
      <span :if={@count} class={@pill}>{@count}</span>
      <span class="rotate-180 text-[13px] font-semibold [writing-mode:vertical-rl]">
        {lost_text(@label, @meta)}
      </span>
    </aside>
    """
  end

  defp lost_icon(assigns) do
    ~H|<.icon name="huge-cancel-circle" class="size-5 text-error-focus dark:text-error" />|
  end

  defp lost_text(label, nil), do: label
  defp lost_text(label, meta), do: label <> " · " <> meta
end
