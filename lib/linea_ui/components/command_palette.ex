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

  Choosing an item closes the palette and runs `on_select`. An item with `navigate`, `patch` or `href` is a real link
  (so Ctrl Enter opens its address in a new window) and the navigation happens as for any link.
  """

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [glyph: 1, icon: 1]
  import LineaUI.Components.Modal, only: [modal: 1]
  import LineaUI.Components.Typography, only: [kbd: 1]

  alias LineaUI.Components.Overlay
  alias LineaUI.Components.Select.Options

  @item_row "group/item flex w-full cursor-pointer items-center gap-3 px-4.5 py-2 text-left no-underline outline-hidden aria-selected:bg-primary/10 dark:aria-selected:bg-accent/15"

  @item_icon "flex size-8 shrink-0 items-center justify-center rounded-lg bg-slate-150 text-slate-500 group-aria-selected/item:bg-primary group-aria-selected/item:text-white dark:bg-navy-600 dark:text-navy-200 dark:group-aria-selected/item:bg-accent"

  @assistant_icon "flex size-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-indigo-600 to-purple-500 text-white"

  @doc """
  Renders the palette, closed unless `open`.

  Each of `items` is a map with `label` (required) and optionally `value` (what `on_select` receives, the label by
  default), `sub` (the line under the label), `icon` (a `LineaUI.Components.Icon.icon/1` name), `keys` (a list of key
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

  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil, doc: "The `phx-target` of every event."

  attr :shortcut, :any,
    default: "Mod+k",
    doc:
      "The key that toggles the palette from anywhere: `Mod` is Ctrl or ⌘. `nil` leaves it to `LineaUI.open/1`."

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
      class={merge(["mt-[10vh] max-w-160 rounded-xl", @class])}
      {@rest}
    >
      <div
        id={@id <> "-palette"}
        phx-hook="LineaUI.CommandPalette"
        phx-target={@target}
        data-shortcut={@shortcut}
        data-on-search={@on_search}
        data-debounce={@debounce}
        data-on-select={@on_select_js}
        data-on-assistant={@on_assistant_js}
        data-assistant-mode={@assistant_mode}
      >
        <div class="flex h-14 items-center gap-3 border-b border-slate-150 px-4.5 dark:border-navy-500">
          <.glyph name={:search} class="size-4.5 shrink-0 text-slate-400 dark:text-navy-300" />
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
            class="h-full min-w-0 flex-1 bg-transparent text-sm-plus text-slate-700 outline-hidden placeholder:font-light placeholder:text-slate-400 dark:text-navy-50 dark:placeholder:text-navy-300"
            data-query
          />
          <.kbd>Esc</.kbd>
        </div>
        <div
          :if={@chips != []}
          class="flex flex-wrap gap-1.5 border-b border-slate-150 px-3.5 py-2.5 dark:border-navy-500"
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
          class="scrollbar-sm max-h-95 overflow-y-auto py-1.5"
        >
          <div
            :for={group <- @groups}
            role={group.label && "group"}
            aria-labelledby={group.label && group.id}
            data-group
          >
            <div
              :if={group.label}
              id={group.id}
              class="px-4.5 pb-1 pt-2.5 text-tiny-plus font-semibold uppercase tracking-wider text-slate-400 dark:text-navy-300"
            >
              {group.label}
            </div>
            <.palette_item :for={item <- group.items} item={item} />
          </div>
          <button
            :if={@assistant_row}
            id={@id <> "-assistant"}
            type="button"
            role="option"
            aria-selected="false"
            class={item_row()}
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
                class="block truncate text-sm text-slate-700 dark:text-navy-50"
                data-assistant-text
              ></span>
              <span
                :if={@assistant_row.sub}
                class="block truncate text-xs text-slate-400 dark:text-navy-300"
              >
                {@assistant_row.sub}
              </span>
            </span>
            <span class="ml-auto flex gap-1"><.kbd>↵</.kbd></span>
          </button>
          <div
            data-empty
            class="px-4.5 py-7 text-center text-xs-plus text-slate-400 dark:text-navy-300"
            hidden
          >
            {@empty}
          </div>
        </div>
        <div class="flex items-center gap-4 border-t border-slate-150 bg-slate-50 px-4.5 py-2.5 text-xs text-slate-400 dark:border-navy-500 dark:bg-navy-800 dark:text-navy-300">
          <span class="inline-flex items-center gap-1.5"><.kbd>↑↓</.kbd>{@hint_navigate}</span>
          <span class="inline-flex items-center gap-1.5"><.kbd>↵</.kbd>{@hint_open}</span>
          <span class="inline-flex items-center gap-1.5"><.kbd>Ctrl ↵</.kbd>{@hint_new_tab}</span>
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

  defp palette_item(%{item: %{link: nil}} = assigns) do
    ~H"""
    <button
      id={@item.id}
      type="button"
      role="option"
      aria-selected="false"
      class={item_row()}
      data-item
      data-value={@item.value}
      data-scope={@item.scope}
      data-text={@item.text}
    >
      <.palette_item_body item={@item} />
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
      class={item_row()}
      data-item
      data-value={@item.value}
      data-scope={@item.scope}
      data-text={@item.text}
      {@link}
    >
      <.palette_item_body item={@item} />
    </.link>
    """
  end

  attr :item, :map, required: true

  defp palette_item_body(assigns) do
    ~H"""
    <span class={item_icon()}>
      <.icon :if={@item.icon} name={@item.icon} class="size-4.5" />
    </span>
    <span class="min-w-0">
      <span class="block truncate text-sm text-slate-700 dark:text-navy-50">{@item.label}</span>
      <span :if={@item.sub} class="block truncate text-xs text-slate-400 dark:text-navy-300">{@item.sub}</span>
    </span>
    <span :if={@item.keys != []} class="ml-auto flex gap-1">
      <.kbd :for={key <- @item.keys}>{key}</.kbd>
    </span>
    """
  end

  defp item_row, do: @item_row
  defp item_icon, do: @item_icon
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
      keys: Map.get(entry, :keys, []),
      group: Map.get(entry, :group),
      scope: to_string(Map.get(entry, :scope, "")),
      text: [label, sub, Map.get(entry, :keywords)] |> Enum.reject(&is_nil/1) |> Enum.join(" "),
      link: link_attrs(entry)
    }
  end

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
