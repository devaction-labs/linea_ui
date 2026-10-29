defmodule LineaUI.Components.NotificationCenter do
  @moduledoc """
  A notification center: a bell with a dot when something is unread, and, under it, a panel with a
  title and the count of unread, tabs, the notifications grouped by day, a footer and an empty state.

      <.notification_center
        id="notifications"
        items={@notifications}
        tabs={[
          %{id: "all", label: "Todas"},
          %{id: "unread", label: "Não lidas"},
          %{id: "orders", label: "Pedidos", empty: "Nenhum pedido novo"}
        ]}
        on_read_all="read_all"
        on_read="read"
        all_href={~p"/notifications"}
        preferences_href={~p"/settings/notifications"}
      />

  Each item is a map:

      %{
        id: 41,
        title: "Pedido aguardando aprovação",
        body: "Pedido 2483, Clínica Vida Plena",
        at: "há 4 min",
        group: "Hoje",
        type: "warning",
        category: "orders",
        read: false,
        navigate: "/orders/2483"
      }

  `title` is the only required key. `group` is the heading of the day (items with the same `group` in a
  row share it, so keep the list in order); `type` is one of `info success warning error primary` and
  gives the icon and the tone (`icon`, a Hugeicons name, replaces the icon); `category` is the `id` of a
  tab and is shown after `at`; `navigate`, `patch` or `href` turn the item into a link.

  The tabs are filtered in the browser, without a round trip: `all` shows everything, `unread` the items
  that are not `read`, and any other id the items with that `category`. The number beside a tab is how
  many unread items it holds. Without `tabs` the panel has no tab bar.

  The panel is a `LineaUI.Components.Popover`: it closes on a click outside and on Esc, and opens from
  the server with `LineaUI.open(socket, "notifications")`. Marking as read is up to the server: change
  `read` and the dot, the count and the bell follow.
  """

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [glyph: 1, icon: 1]
  import LineaUI.Components.Popover, only: [popover: 1]
  import LineaUI.Components.Tabs, only: [tabs: 1]

  import LineaUI.Components.Illustration, only: [empty_box: 1]

  alias LineaUI.Components.Overlay

  @default_tabs [%{id: "all", label: "Todas"}, %{id: "unread", label: "Não lidas"}]

  @tones %{
    "info" => "bg-info/10 text-info dark:bg-info/15",
    "success" => "bg-success/10 text-success dark:bg-success/15",
    "warning" => "bg-warning/10 text-warning dark:bg-warning/15",
    "error" => "bg-error/10 text-error dark:bg-error/15",
    "primary" => "bg-primary/10 text-primary dark:bg-accent-light/15 dark:text-accent-light"
  }

  @icons %{
    "info" => "huge-information-circle",
    "success" => "huge-checkmark-circle-02",
    "warning" => "huge-alert-02",
    "error" => "huge-cancel-circle",
    "primary" => "huge-megaphone-01"
  }

  @doc """
  Renders the bell and its panel.

  Events: `on_read_all` pushes `%{"id" => id}`; `on_read` pushes `%{"id" => id, "item" => item_id}`
  when an item is clicked. Both take an event name (sent to `target` when given) or a `%JS{}`.
  """
  attr :id, :string, required: true, doc: "Needed by the popover and the tabs."

  attr :items, :list,
    default: [],
    doc: "The notifications, newest first, see the module doc."

  attr :tabs, :list,
    default: @default_tabs,
    doc:
      "`%{id, label}` maps, with an optional `empty` (the text of the empty state of that tab). `all` and `unread` filter by read; any other id by `category`. `[]` hides the tab bar."

  attr :unread, :integer,
    default: nil,
    doc:
      "How many are unread. Defaults to the items that are not `read`; pass it when `items` is a page."

  attr :title, :string, default: "Notificações"
  attr :bell_label, :string, default: "Notificações", doc: "The accessible name of the bell."
  attr :read_all_label, :string, default: "Marcar todas como lidas"
  attr :preferences_label, :string, default: "Preferências de notificação"
  attr :all_label, :string, default: "Ver todas as notificações"

  attr :unread_label, :string,
    default: "não lidas",
    doc: "The word after the count in the footer."

  attr :empty, :string,
    default: "Nenhuma notificação",
    doc: "The empty state of a tab without an `empty`."

  attr :empty_text, :string, default: "Quando houver novidades, elas aparecem aqui."

  attr :all_href, :string,
    default: nil,
    doc: "Where \"see all\" goes (a regular link). Without it the footer link is not drawn."

  attr :preferences_href, :string,
    default: nil,
    doc: "Where the preferences button goes. Without it the button is not drawn."

  attr :on_read_all, :any,
    default: nil,
    doc:
      "An event name or a `%JS{}` for \"mark all as read\". Without it the button is not drawn."

  attr :on_read, :any,
    default: nil,
    doc: "An event name or a `%JS{}`, run when an item is clicked."

  attr :on_change, :any,
    default: nil,
    doc: "An event name or a `%JS{}`, run when another tab is chosen."

  attr :target, :any, default: nil, doc: "The `phx-target` of the events."
  attr :open, :boolean, default: false
  attr :placement, :string, default: "bottom-end"
  attr :arrow, :boolean, default: false
  attr :class, :any, default: nil, doc: "Merged into the panel."
  attr :rest, :global

  slot :empty_action, doc: "A next step under the text of the empty state."

  def notification_center(assigns) do
    unread = assigns.unread || Enum.count(assigns.items, &unread?/1)

    assigns =
      assigns
      |> assign(:unread_count, unread)
      |> assign(:read_all_js, Overlay.callback(assigns.on_read_all, assigns.id, assigns.target))
      |> assign(:categories, Map.new(assigns.tabs, &{&1.id, &1.label}))

    ~H"""
    <.popover
      id={@id}
      open={@open}
      placement={@placement}
      arrow={@arrow}
      offset={8}
      class={
        merge([
          "w-[25rem] max-w-[calc(100vw-1.5rem)] overflow-hidden rounded-2xl border-slate-150 p-0 shadow-soft dark:border-navy-600",
          @class
        ])
      }
      {@rest}
    >
      <:trigger>
        <button
          type="button"
          aria-label={bell_label(@bell_label, @unread_count, @unread_label)}
          aria-haspopup="dialog"
          class="relative flex size-9 items-center justify-center rounded-full bg-white text-slate-500 ring-1 ring-slate-200 transition-colors hover:bg-slate-100 hover:text-slate-800 aria-expanded:text-primary aria-expanded:ring-primary dark:bg-navy-700 dark:text-navy-200 dark:ring-navy-500 dark:hover:bg-navy-600 dark:hover:text-navy-50 dark:aria-expanded:text-accent-light dark:aria-expanded:ring-accent-light"
        >
          <.icon name="huge-notification-01" class="size-4.5" />
          <span
            :if={@unread_count > 0}
            class="absolute right-1.5 top-1.5 size-2 rounded-full bg-error ring-2 ring-white dark:ring-navy-700"
          ></span>
        </button>
      </:trigger>

      <div class="flex items-center gap-2 bg-slate-50 py-3.5 pl-4.5 pr-3 dark:bg-navy-800">
        <h3 class="text-base font-bold text-slate-800 dark:text-navy-50">{@title}</h3>
        <span
          :if={@unread_count > 0}
          aria-label={"#{@unread_count} #{@unread_label}"}
          class="rounded-full bg-primary/15 px-2 py-1 font-mono text-xs font-semibold leading-none text-primary dark:bg-accent-light/15 dark:text-accent-light"
        >
          {@unread_count}
        </span>
        <span class="ml-auto flex gap-0.5">
          <button
            :if={@on_read_all}
            type="button"
            aria-label={@read_all_label}
            title={@read_all_label}
            disabled={@unread_count == 0}
            phx-click={@read_all_js}
            class="flex size-8 items-center justify-center rounded-lg text-slate-500 hover:bg-slate-200/70 hover:text-slate-800 disabled:pointer-events-none disabled:opacity-40 dark:text-navy-200 dark:hover:bg-navy-600 dark:hover:text-navy-50"
          >
            <.icon name="huge-tick-double-02" class="size-4" />
          </button>
          <.link
            :if={@preferences_href}
            navigate={@preferences_href}
            aria-label={@preferences_label}
            title={@preferences_label}
            class="flex size-8 items-center justify-center rounded-lg text-slate-500 hover:bg-slate-200/70 hover:text-slate-800 dark:text-navy-200 dark:hover:bg-navy-600 dark:hover:text-navy-50"
          >
            <.icon name="huge-settings-02" class="size-4" />
          </.link>
        </span>
      </div>

      <.tabs
        :if={@tabs != []}
        id={"#{@id}-tabs"}
        variant="line"
        bordered
        overlap
        on_change={@on_change}
        target={@target}
        list_class="bg-slate-50 px-3 dark:bg-navy-800"
        panels_class="p-1.5"
        class="block"
      >
        <:tab :for={tab <- @tabs} name={tab.id}>
          {tab.label}
          <span
            :if={tab_unread(@items, tab) > 0}
            class="font-mono text-[11px] font-semibold text-slate-400 dark:text-navy-300"
          >
            {tab_unread(@items, tab)}
          </span>
        </:tab>
        <:panel :for={tab <- @tabs} name={tab.id}>
          <.list
            id={"#{@id}-#{tab.id}"}
            items={filter(@items, tab)}
            tab={tab}
            categories={@categories}
            on_read={@on_read}
            target={@target}
            panel_id={@id}
            empty={tab[:empty] || @empty}
            empty_text={@empty_text}
            empty_action={@empty_action}
          />
        </:panel>
      </.tabs>

      <div :if={@tabs == []} class="p-1.5">
        <.list
          id={"#{@id}-all"}
          items={@items}
          tab={%{id: "all"}}
          categories={@categories}
          on_read={@on_read}
          target={@target}
          panel_id={@id}
          empty={@empty}
          empty_text={@empty_text}
          empty_action={@empty_action}
        />
      </div>

      <div
        :if={@items != [] and (@all_href || @unread_count > 0)}
        class="flex items-center justify-between gap-2 border-t border-slate-150 bg-slate-50 py-2 pl-3 pr-4 dark:border-navy-600 dark:bg-navy-800"
      >
        <.link
          :if={@all_href}
          navigate={@all_href}
          class="inline-flex h-8 items-center gap-1.5 rounded-lg px-2.5 text-sm font-semibold text-primary hover:bg-primary/10 dark:text-accent-light dark:hover:bg-accent-light/10"
        >
          {@all_label}
          <.glyph name={:chevron_right} class="size-3.5" />
        </.link>
        <span
          :if={@unread_count > 0}
          class="ml-auto text-xs-plus text-slate-400 dark:text-navy-300"
        >
          {@unread_count} {@unread_label}
        </span>
      </div>
    </.popover>
    """
  end

  attr :id, :string, required: true
  attr :items, :list, required: true
  attr :tab, :map, required: true
  attr :categories, :map, required: true
  attr :on_read, :any, required: true
  attr :target, :any, required: true
  attr :panel_id, :string, required: true
  attr :empty, :string, required: true
  attr :empty_text, :string, required: true
  attr :empty_action, :list, required: true

  defp list(%{items: []} = assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-1.5 px-7 pb-7 pt-6 text-center">
      <.empty_box />
      <h4 class="mt-3 text-[15px] font-semibold text-slate-800 dark:text-navy-50">{@empty}</h4>
      <p class="max-w-60 text-xs-plus leading-5 text-slate-500 dark:text-navy-200">{@empty_text}</p>
      <div :if={@empty_action != []} class="mt-2 flex flex-wrap justify-center gap-2">
        {render_slot(@empty_action)}
      </div>
    </div>
    """
  end

  defp list(assigns) do
    assigns = assign(assigns, :groups, groups(assigns.items))

    ~H"""
    <div class="max-h-[26rem] overflow-y-auto">
      <section :for={{group, items} <- @groups} aria-label={group}>
        <h4
          :if={group}
          class="px-3 pb-1 pt-2.5 font-mono text-[11px] font-medium uppercase leading-none tracking-wider text-slate-400 dark:text-navy-300"
        >
          {group}
        </h4>
        <.item
          :for={item <- items}
          item={item}
          category={@categories[item[:category]] || item[:category]}
          on_read={@on_read}
          target={@target}
          panel_id={@panel_id}
        />
      </section>
    </div>
    """
  end

  attr :item, :map, required: true
  attr :category, :string, default: nil
  attr :on_read, :any, required: true
  attr :target, :any, required: true
  attr :panel_id, :string, required: true

  defp item(assigns) do
    item = assigns.item
    type = Map.get(item, :type, "primary")

    assigns =
      assign(assigns,
        tone: Map.fetch!(@tones, type),
        icon_name: item[:icon] || Map.fetch!(@icons, type),
        unread: unread?(item),
        click: item_js(assigns.on_read, assigns.panel_id, item[:id], assigns.target),
        link: Map.take(item, [:navigate, :patch, :href])
      )

    ~H"""
    <.link
      {@link}
      phx-click={@click}
      class="flex items-start gap-3 rounded-xl px-3 py-2.5 text-inherit no-underline outline-hidden hover:bg-slate-50 focus-visible:ring-2 focus-visible:ring-primary/50 dark:hover:bg-navy-800 dark:focus-visible:ring-accent-light/50"
    >
      <span class={["flex size-10 flex-none items-center justify-center rounded-[11px]", @tone]}>
        <.icon name={@icon_name} class="size-5" />
      </span>
      <span class="block min-w-0 flex-1">
        <span class={[
          "block text-sm+",
          @unread && "font-semibold text-slate-800 dark:text-navy-50",
          !@unread && "font-medium text-slate-600 dark:text-navy-100"
        ]}>
          {@item.title}
        </span>
        <span
          :if={@item[:body]}
          class="mt-0.5 block truncate text-[13px] leading-[18px] text-slate-500 dark:text-navy-200"
        >
          {@item[:body]}
        </span>
        <span
          :if={@item[:at] || @category}
          class="mt-1 flex items-center gap-1.5 text-xs-plus text-slate-400 dark:text-navy-300"
        >
          <span :if={@item[:at]}>{@item[:at]}</span>
          <span
            :if={@item[:at] && @category}
            class="h-2.5 w-px bg-slate-300 dark:bg-navy-500"
            aria-hidden="true"
          ></span>
          <span :if={@category}>{@category}</span>
        </span>
      </span>
      <span :if={@unread} class="mt-1.5 size-2 flex-none rounded-full bg-primary dark:bg-accent">
        <span class="sr-only">Não lida</span>
      </span>
    </.link>
    """
  end

  defp unread?(item), do: !Map.get(item, :read, false)

  defp bell_label(label, 0, _unread_label), do: label
  defp bell_label(label, n, unread_label), do: "#{label}, #{n} #{unread_label}"

  defp filter(items, %{id: "all"}), do: items
  defp filter(items, %{id: "unread"}), do: Enum.filter(items, &unread?/1)
  defp filter(items, %{id: id}), do: Enum.filter(items, &(&1[:category] == id))

  defp tab_unread(_items, %{id: "unread"}), do: 0
  defp tab_unread(items, tab), do: items |> filter(tab) |> Enum.count(&unread?/1)

  defp groups(items) do
    items
    |> Enum.chunk_by(& &1[:group])
    |> Enum.map(fn [first | _] = chunk -> {first[:group], chunk} end)
  end

  defp item_js(nil, _panel_id, _item_id, _target), do: nil
  defp item_js(%JS{} = js, _panel_id, _item_id, _target), do: js

  defp item_js(event, panel_id, item_id, target) when is_binary(event),
    do: JS.push(event, value: %{id: panel_id, item: item_id}, target: target)
end
