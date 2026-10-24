defmodule LineaUI.Components.MenuList do
  @moduledoc """
  LineOne's menu lists: a vertical list of links with one active entry.

      <.menu_list variant="solid">
        <:item navigate={~p"/start"} active>Getting start</:item>
        <:item navigate={~p"/shipping"}>Shipping</:item>
      </.menu_list>

  An icon is the first child of an item; LineOne's icon colors (muted, darker on hover, current
  color when active) come with it:

      <:item href="#"><svg class="size-5">…</svg><span>Payments</span></:item>

  A trailing count (a badge, a number) goes in the `:count` slot of a `menu_item`, or in the
  `count` attr of an `:item`; it is pushed to the end of the row:

      <.menu_item navigate="/inbox" variant="solid">
        <:icon><svg class="size-5">…</svg></:icon>
        Inbox
        <:count><.badge size="sm" shape="pill">12</.badge></:count>
      </.menu_item>

  `variant` follows LineOne's examples: `link` (text only), `solid` (filled; `color` picks
  primary or neutral), `pill` (rounded-full with a tinted hover), `gradient` and `bordered`.

  Items that are not links take `on_select` (an event name or `%JS{}`), pushed with
  `%{"value" => item_value}`:

      <.menu_list on_select="pick">
        <:item value="shipping">Shipping</:item>
      </.menu_list>

  Streams render one `menu_item` per row:

      <.menu_list id="pages" rows={@streams.pages}>
        <:row :let={{_id, page}}>
          <.menu_item navigate={page.path} active={page.id == @current}>{page.title}</.menu_item>
        </:row>
      </.menu_list>
  """

  use LineaUI.Component

  @spacing %{
    "link" => "space-y-3.5",
    "solid" => "space-y-1.5",
    "pill" => "space-y-1.5",
    "gradient" => "space-y-1.5",
    "bordered" => "space-y-1.5"
  }

  @base "group flex items-center space-x-2 tracking-wide outline-hidden"

  @shape %{
    "link" => "inline-flex transition-colors",
    "solid" => "rounded-lg px-4 py-2.5 transition-all",
    "pill" => "rounded-full px-5 py-2.5 transition-all",
    "gradient" => "rounded-lg px-4 py-2.5 transition-all",
    "bordered" => "rounded-lg px-4 py-2.5 transition-all"
  }

  @active %{
    {"link", "primary"} => "font-medium text-primary dark:text-accent-light",
    {"link", "neutral"} => "font-medium text-slate-800 dark:text-navy-50",
    {"solid", "primary"} => "bg-primary text-white dark:bg-accent",
    {"solid", "neutral"} => "bg-slate-150 text-slate-800 dark:bg-navy-500 dark:text-navy-50",
    {"pill", "primary"} => "bg-primary text-white dark:bg-accent",
    {"pill", "neutral"} => "bg-slate-150 text-slate-800 dark:bg-navy-500 dark:text-navy-50",
    {"gradient", "primary"} => "bg-gradient-to-r from-purple-500 to-purple-600 text-white",
    {"gradient", "neutral"} => "bg-gradient-to-r from-purple-500 to-purple-600 text-white",
    {"bordered", "primary"} =>
      "border border-slate-150 text-primary shadow-xs dark:border-navy-500 dark:text-accent-light",
    {"bordered", "neutral"} =>
      "border border-slate-150 text-slate-800 shadow-xs dark:border-navy-500 dark:text-navy-50"
  }

  @neutral_hover "hover:bg-slate-100 hover:text-slate-800 focus:bg-slate-100 focus:text-slate-800 dark:hover:bg-navy-600 dark:hover:text-navy-100 dark:focus:bg-navy-600 dark:focus:text-navy-100"

  @inactive %{
    "link" =>
      "hover:text-slate-800 focus:text-slate-800 dark:hover:text-navy-100 dark:focus:text-navy-100",
    "solid" => @neutral_hover,
    "pill" =>
      "hover:bg-primary/10 hover:text-primary focus:bg-primary/10 focus:text-primary dark:hover:bg-accent-light/15 dark:hover:text-accent-light dark:focus:bg-accent-light/15 dark:focus:text-accent-light",
    "gradient" => @neutral_hover,
    "bordered" => @neutral_hover
  }

  @icon_active "[&>svg]:size-5 [&>svg]:shrink-0"

  @icon_inactive %{
    "pill" =>
      "[&>svg]:size-5 [&>svg]:shrink-0 [&>svg]:text-slate-400 [&>svg]:transition-colors group-hover:[&>svg]:text-primary group-focus:[&>svg]:text-primary dark:[&>svg]:text-navy-300 dark:group-hover:[&>svg]:text-accent dark:group-focus:[&>svg]:text-accent"
  }

  @icon_muted "[&>svg]:size-5 [&>svg]:shrink-0 [&>svg]:text-slate-400 [&>svg]:transition-colors group-hover:[&>svg]:text-slate-500 group-focus:[&>svg]:text-slate-500 dark:[&>svg]:text-navy-300 dark:group-hover:[&>svg]:text-navy-200 dark:group-focus:[&>svg]:text-navy-200"

  @doc """
  Renders the list. Items come from `:item` slots (each takes `href`/`navigate`/`patch`,
  `active`, `value`, and any HTML attribute), or from `rows` with a `:row` slot.

  `on_select` is pushed with `%{"value" => value}` when an item that has a `value` is clicked;
  it goes to `target` when given; a `%JS{}` is executed instead.

      <.menu_list variant="pill" on_select="pick">
        <:item value="shipping" active={@tab == "shipping"}>Shipping</:item>
        <:item navigate={~p"/payments"}><svg class="size-5">…</svg><span>Payments</span></:item>
      </.menu_list>

      def handle_event("pick", %{"value" => value}, socket), do: {:noreply, assign(socket, tab: value)}
  """
  attr(:id, :string, default: nil)

  attr(:variant, :string,
    default: "link",
    values: ~w(link solid pill gradient bordered),
    doc:
      "LineOne's menu list examples 1–2 (`link`), 3–4/7–8 (`solid`), 5–6 (`pill`), 9–10 (`gradient`), 11–12 (`bordered`)."
  )

  attr(:color, :string,
    default: "primary",
    values: ~w(primary neutral),
    doc: "The active item's color (LineOne's examples 7–8 are `neutral`)."
  )

  attr(:on_select, :any,
    default: nil,
    doc: "Event name or `%JS{}`; pushed with `%{\"value\" => value}` by items with a `value`."
  )

  attr(:target, :any, default: nil, doc: "The `phx-target` `on_select` goes to.")
  attr(:rows, :list, default: nil, doc: "A list or a stream (`@streams.x`) rendered by `:row`.")
  attr(:row_id, :any, default: nil, doc: "A function giving each row's DOM id (streams give it).")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :item do
    attr(:href, :string)
    attr(:navigate, :string)
    attr(:patch, :string)
    attr(:active, :boolean)
    attr(:value, :string)
    attr(:count, :string, doc: "Text pushed to the end of the row.")
  end

  slot(:row, doc: "Renders one row; takes the row (`{dom_id, item}` for a stream).")

  def menu_list(assigns) do
    assigns
    |> assign(:stream?, match?(%Phoenix.LiveView.LiveStream{}, assigns.rows))
    |> assign(:row_id, row_id(assigns))
    |> assign(
      :list_class,
      merge(["font-inter font-medium", @spacing[assigns.variant], assigns.class])
    )
    |> render_list()
  end

  defp row_id(%{row_id: nil, rows: %Phoenix.LiveView.LiveStream{}}), do: fn {id, _row} -> id end
  defp row_id(%{row_id: row_id}), do: row_id

  defp render_list(assigns) do
    ~H"""
    <ul
      id={@id}
      class={@list_class}
      phx-update={@stream? && "stream"}
      {@rest}
    >
      <li :for={item <- @item}>
        <.menu_item
          variant={@variant}
          color={@color}
          active={Map.get(item, :active, false)}
          value={Map.get(item, :value)}
          on_select={@on_select}
          target={@target}
          {Map.drop(item, [:__slot__, :inner_block, :active, :value, :count])}
        >
          {render_slot(item)}
          <:count :if={Map.get(item, :count)}>{Map.get(item, :count)}</:count>
        </.menu_item>
      </li>
      <li :for={row <- @rows || []} id={@row_id && @row_id.(row)}>
        {render_slot(@row, row)}
      </li>
    </ul>
    """
  end

  @doc """
  Renders one entry of a menu list as a link (`href`, `navigate`, `patch`) or, without one,
  a link-styled button that pushes `on_select` with `%{"value" => value}`. Used alone or in
  a `menu_list` `:row`.

      <.menu_item variant="solid" navigate={~p"/start"} active>Getting start</.menu_item>
      <.menu_item value="b" on_select="pick">Beta</.menu_item>
  """
  attr(:variant, :string, default: "link", values: ~w(link solid pill gradient bordered))
  attr(:color, :string, default: "primary", values: ~w(primary neutral))
  attr(:active, :boolean, default: false)
  attr(:value, :string, default: nil)
  attr(:on_select, :any, default: nil, doc: "An event name or `%JS{}` run on click.")
  attr(:target, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(href navigate patch method download replace))
  slot(:icon, doc: "Drawn before the text; an `<svg>` gets LineOne's icon size and colors.")
  slot(:count, doc: "Pushed to the end of the row (a number, a badge).")
  slot(:inner_block, required: true)

  def menu_item(assigns) do
    assigns
    |> assign(:classes, item_classes(assigns))
    |> render_item()
  end

  defp item_classes(assigns) do
    merge([
      @base,
      @shape[assigns.variant],
      state_classes(assigns),
      assigns.class
    ])
  end

  defp state_classes(%{active: true} = assigns),
    do: [@active[{assigns.variant, assigns.color}], @icon_active]

  defp state_classes(assigns),
    do: [@inactive[assigns.variant], Map.get(@icon_inactive, assigns.variant, @icon_muted)]

  defp render_item(%{rest: rest} = assigns)
       when is_map_key(rest, :href) or is_map_key(rest, :navigate) or is_map_key(rest, :patch) do
    ~H"""
    <.link
      class={@classes}
      aria-current={@active && "page"}
      phx-click={@value && @on_select}
      phx-value-value={@value}
      phx-target={@value && @target}
      {@rest}
    >
      {render_slot(@icon)}{render_slot(@inner_block)}<span
        :for={count <- @count}
        class="ml-auto shrink-0 pl-2 text-xs"
      >{render_slot(count)}</span>
    </.link>
    """
  end

  defp render_item(assigns) do
    ~H"""
    <a
      href="#"
      role="button"
      class={@classes}
      aria-current={@active && "true"}
      phx-click={@on_select}
      phx-value-value={@value}
      phx-target={@target}
      {@rest}
    >
      {render_slot(@icon)}{render_slot(@inner_block)}<span
        :for={count <- @count}
        class="ml-auto shrink-0 pl-2 text-xs"
      >{render_slot(count)}</span>
    </a>
    """
  end
end
