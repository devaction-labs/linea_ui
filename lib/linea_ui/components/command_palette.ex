defmodule LineaUI.Components.CommandPalette do
  @moduledoc """
  A command palette: a dialog opened with Ctrl K (or `LineaUI.open/1`) where the person types, narrows the
  results by scope and jumps to a page or runs an action from the keyboard.

      <.command_palette
        id="palette"
        scopes={[{"All", "all"}, {"Pages", "pages"}, {"Actions", "actions"}, {"Recent", "recent"}]}
        items={[
          %{group: "Go to", scope: "pages", label: "Orders", sub: "Sales", icon: "huge-shopping-cart-01",
            navigate: ~p"/orders", keys: ["G", "O"]},
          %{group: "Actions", scope: "actions", label: "New order", sub: "Opens the order form",
            icon: "huge-add-01", value: "new-order", keys: ["N"]}
        ]}
        assistant={%{label: "Ask the assistant: “%{query}”", sub: "Answers with your company's data"}}
        on_select="palette-select"
        on_assistant="ask"
      />

      <.button phx-click={LineaUI.open("palette")}>Search</.button>

  Item and assistant `icon`s are Hugeicons names (`huge-*`), which need the Tailwind plugin of the Icons
  section of the README; without `icon`, the item shows no icon and the assistant row a sparkle.

  The palette is a modal, so `LineaUI.open/close/toggle` (in the browser or from the server) and the `open`,
  `on_open` and `on_close` attrs work as they do for `modal`. `shortcut` (Ctrl K / ⌘ K by default) toggles it from
  anywhere in the page.

  The input is a `role="combobox"` over a `role="listbox"`; the arrows move the active row (`aria-activedescendant`),
  Enter presses it, Ctrl Enter opens it in a new tab and Esc closes the palette. The scope chips are toggle buttons
  (`aria-pressed`): the first scope starts selected, the scope `"all"` keeps every item and any other keeps the items
  whose `scope` is the same. Every time the palette opens it starts empty on its first scope.

  The items are filtered in the browser, by label, `sub` and `keywords` ignoring case and accents. With `on_search`
  the server filters instead: the query is pushed (debounced) and the palette shows the `items` it renders, still
  narrowed by scope.

  `variant="canvas"` is the design canvas look (the canvas menu: a 14px panel, 34px rows with muted icons, small
  faint group headings, mono keys); `hints={false}` drops the keys footer and `highlight="typed"` leaves the rows
  unmarked until something is typed (or an arrow or the mouse picks one), as the canvas shows its "recent" list.
  An item's `avatar` (the attrs of `LineaUI.Components.Avatar.avatar/1`) takes the place of its icon:

      <.command_palette
        id="search"
        variant="canvas"
        hints={false}
        highlight="typed"
        items={[%{group: "Clientes", label: "Casa das Tintas", avatar: %{initials: "CD", tint: "#d97a1e"}}]}
      />

  Choosing an item closes the palette and runs `on_select`. An item with `navigate`, `patch` or `href` is a real link
  (so Ctrl Enter opens its address in a new window) and the navigation happens as for any link.
  """

  use LineaUI.Component

  import LineaUI.Components.Avatar, only: [avatar: 1]
  import LineaUI.Components.Icon, only: [glyph: 1, icon: 1]
  import LineaUI.Components.Modal, only: [modal: 1]
  import LineaUI.Components.Typography, only: [kbd: 1]

  alias LineaUI.Components.Overlay
  alias LineaUI.Components.Select.Options

  @item_row "group/item flex w-full cursor-pointer items-center gap-2.5 px-2.5 py-2 text-left no-underline outline-hidden rounded-md aria-selected:bg-slate-100 dark:aria-selected:bg-navy-600"

  @item_icon "flex size-4.5 shrink-0 items-center justify-center text-slate-950 dark:text-navy-50"

  @key "rounded-[4px] border-0 bg-slate-100 px-1.5 text-slate-950 shadow-none dark:bg-navy-600 dark:text-navy-50"

  @assistant_icon "flex size-6 shrink-0 items-center justify-center rounded-md bg-gradient-to-br from-blue-600 to-purple-500 text-white"

  # the canvas menu (`sg-menu`): the classes that differ from the default look
  @looks %{
    "default" => %{
      card: "rounded-xl",
      head: "h-[67px] gap-2.5 border-b border-slate-200 px-5 dark:border-navy-450",
      search: "size-4 shrink-0 text-slate-950 dark:text-navy-50",
      input:
        "h-full text-sm text-slate-950 placeholder:text-slate-500 dark:text-navy-50 dark:placeholder:text-navy-300",
      key: @key,
      heading:
        "px-2.5 pb-1 pt-2.5 text-xs font-medium uppercase text-slate-500 dark:text-navy-300",
      row: @item_row,
      icon: @item_icon,
      label: "text-[13px] text-slate-950 dark:text-navy-50"
    },
    "canvas" => %{
      card: "palette-canvas rounded-[14px]",
      head: "gap-4 border-b border-[var(--line)] px-3.5 py-3",
      search: "size-4 shrink-0 text-[var(--fg)]",
      input: "h-6 text-sm text-[var(--ink)] placeholder:text-[var(--faint)]",
      key: "sg-kbd",
      heading: "px-2.5 pb-1 pt-2 text-[11px] tracking-[.06em] uppercase text-[var(--faint)]",
      row:
        "group/item flex min-h-[34px] w-full cursor-pointer items-center gap-2.5 rounded-[9px] px-2.5 py-[5px] text-left text-[13.5px] text-[var(--fg)] no-underline outline-hidden aria-selected:bg-[var(--hover)] aria-selected:text-[var(--ink)]",
      icon: "flex size-4 shrink-0 items-center justify-center text-[var(--muted)]",
      label: "text-[13.5px] text-inherit"
    }
  }

  @doc """
  Renders the palette, closed unless `open`.

  Each of `items` is a map with `label` (required) and optionally `value` (what `on_select` receives, the label by
  default), `sub` (the line under the label), `icon` (a `LineaUI.Components.Icon.icon/1` name), `avatar` (a map of
  `LineaUI.Components.Avatar.avatar/1` attrs, drawn 24px and square in place of the icon), `keys` (a list of key
  names shown on the right), `group` (the heading it is listed under; items without one are listed first, without a
  heading), `scope`, `keywords` (more text the query matches) and one of `navigate`, `patch` or `href`.

  `assistant` is a map with `label` (`%{query}` is replaced by what was typed), `sub` and `icon`: the row that offers
  to ask the assistant. It shows when the query has no match, or whenever something is typed with
  `assistant_mode="always"`.

  Events (an event name or a `%JS{}`; a `%JS{}` push receives the same payload):

    * `on_select` - `%{"id" => palette id, "value" => item value, "new_tab" => boolean}`; `new_tab` is true after
      Ctrl Enter or a Ctrl/⌘ click.
    * `on_assistant` - `%{"id" => palette id, "query" => text typed}`.
    * `on_search` - an event name only; `%{"id" => palette id, "query" => text typed, "scope" => scope value}`, after
      `debounce` milliseconds.
    * `on_open` / `on_close` - `%{"id" => palette id}`, as for `modal`.

  All go to `target` when given.
  """
  attr :id, :string, required: true

  attr :open, :boolean,
    default: false,
    doc: "The server's state; the browser can still open and close it."

  attr :label, :string,
    default: "Command palette",
    doc: "The accessible name of the dialog and of the list."

  attr :placeholder, :string, default: "Search or type a command"

  attr :scopes, :list,
    default: [],
    doc:
      "The scope chips: strings, `{label, value}` tuples or maps with `:label` and `:value`. The first starts selected."

  attr :scopes_label, :string,
    default: "Where to search",
    doc: "The accessible name of the chips."

  attr :items, :list, default: [], doc: "The rows, see the function doc."

  attr :empty, :string,
    default: "Nothing found",
    doc: "Shown when no item matches and there is no assistant row."

  attr :assistant, :map,
    default: nil,
    doc: "The assistant row: `label` (with `%{query}`), `sub` and `icon`."

  attr :assistant_mode, :string,
    default: "no_match",
    values: ~w(no_match always),
    doc:
      "`no_match` offers the assistant only when nothing matched; `always` whenever something is typed."

  attr :on_select, :any,
    default: nil,
    doc: "An event name or a `%JS{}`, run when an item is chosen."

  attr :on_assistant, :any,
    default: nil,
    doc: "An event name or a `%JS{}`, run when the assistant row is chosen."

  attr :on_search, :string, default: nil, doc: "An event name: the server filters the items."

  attr :debounce, :integer,
    default: 200,
    doc: "Milliseconds between the last keystroke and the `on_search` push."

  attr :query, :string,
    default: "",
    doc: "The text the input holds every time the palette opens, narrowing the items."

  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil, doc: "The `phx-target` of every event."

  attr :shortcut, :any,
    default: "Mod+k",
    doc:
      "The key that toggles the palette from anywhere: `Mod` is Ctrl or ⌘. `nil` leaves it to `LineaUI.open/1`."

  attr :variant, :string,
    default: "default",
    values: ~w(default canvas),
    doc:
      "`canvas`: the design canvas menu look (34px rows, muted icons, faint headings, mono keys)."

  attr :hints, :boolean, default: true, doc: "Shows the footer with the keys hints."

  attr :highlight, :string,
    default: "always",
    values: ~w(always typed),
    doc:
      "`always` marks the first row as active; `typed` only once something is typed or an arrow or the mouse picks a row."

  attr :hint_navigate, :string, default: "Navigate"
  attr :hint_open, :string, default: "Open"
  attr :hint_new_tab, :string, default: "Open in new tab"
  attr :class, :any, default: nil, doc: "Merged into the dialog card."
  attr :rest, :global

  slot :footer, doc: "Content at the right end of the footer, e.g. a status line."

  def command_palette(assigns) do
    items = assigns.items |> Enum.with_index() |> Enum.map(&item(&1, assigns.id))

    assigns =
      assigns
      |> assign(:groups, groups(items, assigns.id))
      |> assign(:chips, Options.normalize(assigns.scopes))
      |> assign(:assistant_row, assistant(assigns.assistant))
      |> assign(:look, Map.fetch!(@looks, assigns.variant))
      |> assign(:on_select_js, Overlay.callback(assigns.on_select, assigns.id, assigns.target))
      |> assign(
        :on_assistant_js,
        Overlay.callback(assigns.on_assistant, assigns.id, assigns.target)
      )

    ~H"""
    <.modal
      id={@id}
      open={@open}
      size="xl"
      placement="top"
      animation="scale"
      origin="top"
      close_button={false}
      on_open={@on_open}
      on_close={@on_close}
      target={@target}
      aria-label={@label}
      class={merge(["mt-[10vh] max-w-130", @look.card, @class])}
      {@rest}
    >
      <div
        id={@id <> "-palette"}
        phx-hook="LineaUI.CommandPalette"
        phx-target={@target}
        data-shortcut={@shortcut}
        data-initial-query={@query}
        data-on-search={@on_search}
        data-debounce={@debounce}
        data-on-select={@on_select_js}
        data-on-assistant={@on_assistant_js}
        data-assistant-mode={@assistant_mode}
        data-highlight={@highlight}
      >
        <div class={["flex items-center", @look.head]}>
          <.glyph name={:search} class={@look.search} />
          <input
            type="text"
            role="combobox"
            aria-expanded="false"
            aria-controls={@id <> "-list"}
            aria-autocomplete="list"
            aria-label={@label}
            autocomplete="off"
            autofocus
            placeholder={@placeholder}
            phx-mounted={JS.ignore_attributes(["value"])}
            class={["min-w-0 flex-1 bg-transparent outline-hidden", @look.input]}
            data-query
          />
          <.kbd class={@look.key}>Esc</.kbd>
        </div>
        <div
          :if={@chips != []}
          class="flex flex-wrap gap-1.5 border-b border-slate-200 px-3.5 py-2.5 dark:border-navy-450"
          role="group"
          aria-label={@scopes_label}
        >
          <button
            :for={chip <- @chips}
            type="button"
            aria-pressed="false"
            class="h-6.5 rounded-full px-2.5 text-xs font-medium text-slate-500 outline-hidden ring-1 ring-inset ring-slate-300 transition-colors hover:text-slate-700 focus-visible:outline-2 focus-visible:outline-primary/50 aria-pressed:bg-primary aria-pressed:text-white aria-pressed:ring-0 dark:text-navy-200 dark:ring-navy-450 dark:hover:text-navy-50 dark:focus-visible:outline-accent/50 dark:aria-pressed:bg-accent"
            phx-mounted={JS.ignore_attributes(["aria-pressed"])}
            data-scope-chip
            data-scope={chip.value}
          >
            {chip.label}
          </button>
        </div>
        <div
          id={@id <> "-list"}
          role="listbox"
          aria-label={@label}
          class="scrollbar-sm max-h-95 overflow-y-auto p-1.5"
        >
          <div
            :for={group <- @groups}
            role={group.label && "group"}
            aria-labelledby={group.label && group.id}
            data-group
          >
            <div :if={group.label} id={group.id} class={@look.heading}>
              {group.label}
            </div>
            <.palette_item :for={item <- group.items} item={item} look={@look} />
          </div>
          <button
            :if={@assistant_row}
            id={@id <> "-assistant"}
            type="button"
            role="option"
            aria-selected="false"
            class={@look.row}
            data-assistant
            data-template={@assistant_row.label}
            hidden
          >
            <span class={assistant_icon()}>
              <.icon :if={@assistant_row.icon} name={@assistant_row.icon} class="size-4.5" />
              <svg
                :if={!@assistant_row.icon}
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="1.6"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="size-4.5"
                aria-hidden="true"
              >
                <path d="M12 3l1.8 4.2L18 9l-4.2 1.8L12 15l-1.8-4.2L6 9l4.2-1.8z" />
              </svg>
            </span>
            <span class="min-w-0">
              <span
                class="block truncate text-sm text-slate-800 dark:text-navy-50"
                data-assistant-text
              ></span>
              <span
                :if={@assistant_row.sub}
                class="block truncate text-xs text-slate-400 dark:text-navy-300"
              >
                {@assistant_row.sub}
              </span>
            </span>
            <span class="ml-auto flex gap-1"><.kbd class={@look.key}>↵</.kbd></span>
          </button>
          <div
            data-empty
            class="px-4.5 py-7 text-center text-xs-plus text-slate-400 dark:text-navy-300"
            hidden
          >
            {@empty}
          </div>
        </div>
        <div
          :if={@hints or @footer != []}
          class="flex items-center gap-4 border-t border-slate-200 bg-slate-50 px-5 py-2.5 text-xs text-slate-500 dark:border-navy-450 dark:bg-navy-800 dark:text-navy-300"
        >
          <span :if={@hints} class="inline-flex items-center gap-1.5">
            <.kbd class={@look.key}>↑↓</.kbd>{@hint_navigate}
          </span>
          <span :if={@hints} class="inline-flex items-center gap-1.5">
            <.kbd class={@look.key}>↵</.kbd>{@hint_open}
          </span>
          <span :if={@hints} class="inline-flex items-center gap-1.5">
            <.kbd class={@look.key}>Ctrl ↵</.kbd>{@hint_new_tab}
          </span>
          <span
            :if={@footer != []}
            class="ml-auto text-primary dark:text-accent-light"
            aria-live="polite"
          >
            {render_slot(@footer)}
          </span>
        </div>
      </div>
    </.modal>
    """
  end

  attr :item, :map, required: true
  attr :look, :map, required: true

  defp palette_item(%{item: %{link: nil}} = assigns) do
    ~H"""
    <button
      id={@item.id}
      type="button"
      role="option"
      aria-selected="false"
      class={@look.row}
      data-item
      data-value={@item.value}
      data-scope={@item.scope}
      data-text={@item.text}
    >
      <.palette_item_body item={@item} look={@look} />
    </button>
    """
  end

  defp palette_item(%{item: %{link: link}} = assigns) do
    assigns = assign(assigns, :link, link)

    ~H"""
    <.link
      id={@item.id}
      role="option"
      aria-selected="false"
      class={@look.row}
      data-item
      data-value={@item.value}
      data-scope={@item.scope}
      data-text={@item.text}
      {@link}
    >
      <.palette_item_body item={@item} look={@look} />
    </.link>
    """
  end

  attr :item, :map, required: true
  attr :look, :map, required: true

  defp palette_item_body(assigns) do
    ~H"""
    <.avatar :if={@item.avatar} size="24" shape="square" {@item.avatar} />
    <span :if={!@item.avatar} class={@look.icon}>
      <.icon :if={@item.icon} name={@item.icon} class="size-4" />
    </span>
    <span class="min-w-0">
      <span class={["block truncate", @look.label]}>{@item.label}</span>
      <span :if={@item.sub} class="block truncate text-xs text-slate-400 dark:text-navy-300">{@item.sub}</span>
    </span>
    <span :if={@item.keys != []} class="ml-auto flex gap-1">
      <.kbd :for={name <- @item.keys} class={@look.key}>{name}</.kbd>
    </span>
    """
  end

  defp assistant_icon, do: @assistant_icon

  defp item({entry, index}, id) do
    entry = Map.new(entry)
    label = Map.fetch!(entry, :label)
    sub = Map.get(entry, :sub)

    %{
      id: "#{id}-item-#{index}",
      label: label,
      sub: sub,
      value: to_string(Map.get(entry, :value, label)),
      icon: Map.get(entry, :icon),
      avatar: avatar_attrs(Map.get(entry, :avatar)),
      keys: Map.get(entry, :keys, []),
      group: Map.get(entry, :group),
      scope: to_string(Map.get(entry, :scope, "")),
      text: [label, sub, Map.get(entry, :keywords)] |> Enum.reject(&is_nil/1) |> Enum.join(" "),
      link: link_attrs(entry)
    }
  end

  defp avatar_attrs(nil), do: nil
  defp avatar_attrs(attrs), do: Map.new(attrs)

  defp link_attrs(%{navigate: path}), do: %{navigate: path}
  defp link_attrs(%{patch: path}), do: %{patch: path}
  defp link_attrs(%{href: url}), do: %{href: url}
  defp link_attrs(_entry), do: nil

  defp groups(items, id) do
    items
    |> Enum.map(& &1.group)
    |> Enum.uniq()
    |> Enum.with_index()
    |> Enum.map(fn {label, index} ->
      %{
        label: label,
        id: "#{id}-group-#{index}",
        items: Enum.filter(items, &(&1.group == label))
      }
    end)
  end

  defp assistant(nil), do: nil

  defp assistant(row) do
    row = Map.new(row)

    %{
      label: Map.fetch!(row, :label),
      sub: Map.get(row, :sub),
      icon: Map.get(row, :icon)
    }
  end
end
