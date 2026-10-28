defmodule LineaUI.Components.DataTable do
  @moduledoc """
  A table with a search box, sortable headers, a pagination footer and row selection, in the
  two looks LineOne shows: `advanced` (the Table Advanced page: a title bar with a search
  that slides open, the table as a card, "Show 10 entries" and a pager underneath) and `grid`
  (the Grid Table page: a search box on the right, sort arrows, "Showing 1 to 10 of 15
  results" and Previous/Next).

  The LiveView owns the state: it filters, sorts and slices the rows and gives the component
  the current page; the component only renders it and sends events back.

      <.data_table
        id="users"
        rows={@users}
        search={@search}
        on_search="search"
        sort_by={@sort_by}
        sort_dir={@sort_dir}
        on_sort="sort"
        page={@page}
        page_size={10}
        total={@total}
        on_page="paginate"
      >
        <:title>Users Table</:title>
        <:col :let={user} label="Name" sort_key="name">{user.name}</:col>
        <:col :let={user} label="Email">{user.email}</:col>
      </.data_table>

      def handle_event("search", %{"search" => q}, socket), do: ...
      def handle_event("sort", %{"column" => col, "direction" => dir}, socket), do: ...
      def handle_event("paginate", %{"page" => page}, socket), do: ...

  Rows may be a stream (`rows={@streams.users}`); the body then renders with
  `phx-update="stream"` and `total` drives the footer. `:col`, `:action`, `:expand`,
  `:empty`, `row_id`, `row_key`, `row_item`, `row_click` and selection work as in
  `LineaUI.Components.Table.table/1`, and so do the columns that leave by `priority` when the
  box gets narrow, and `peek` to read them in a panel.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  alias LineaUI.Components.Table

  @pager_list %{
    "rounded" => "pagination",
    "pill" => "pagination",
    "circle" => "pagination space-x-1.5"
  }

  @pager_li %{
    "rounded" =>
      {"rounded-l-lg bg-slate-150 dark:bg-navy-500", "bg-slate-150 dark:bg-navy-500",
       "rounded-r-lg bg-slate-150 dark:bg-navy-500"},
    "pill" =>
      {"rounded-l-full bg-slate-150 dark:bg-navy-500", "bg-slate-150 dark:bg-navy-500",
       "rounded-r-full bg-slate-150 dark:bg-navy-500"},
    "circle" => {"", "", ""}
  }

  @pager_arrow %{
    "rounded" =>
      "flex size-8 items-center justify-center rounded-lg text-slate-500 transition-colors hover:bg-slate-300 focus:bg-slate-300 active:bg-slate-300/80 disabled:pointer-events-none disabled:opacity-60 aria-disabled:pointer-events-none aria-disabled:opacity-60 dark:text-navy-200 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90",
    "pill" =>
      "flex size-8 items-center justify-center rounded-full text-slate-500 transition-colors hover:bg-slate-300 focus:bg-slate-300 active:bg-slate-300/80 disabled:pointer-events-none disabled:opacity-60 aria-disabled:pointer-events-none aria-disabled:opacity-60 dark:text-navy-200 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90",
    "circle" =>
      "flex size-8 items-center justify-center rounded-full bg-slate-150 text-slate-500 transition-colors hover:bg-slate-300 focus:bg-slate-300 active:bg-slate-300/80 disabled:pointer-events-none disabled:opacity-60 aria-disabled:pointer-events-none aria-disabled:opacity-60 dark:bg-navy-500 dark:text-navy-200 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90"
  }

  @pager_page %{
    "rounded" =>
      "flex h-8 min-w-[2rem] items-center justify-center rounded-lg px-3 leading-tight transition-colors hover:bg-slate-300 focus:bg-slate-300 active:bg-slate-300/80 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90",
    "pill" =>
      "flex h-8 min-w-[2rem] items-center justify-center rounded-full px-3 leading-tight transition-colors hover:bg-slate-300 focus:bg-slate-300 active:bg-slate-300/80 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90",
    "circle" =>
      "flex h-8 min-w-[2rem] items-center justify-center rounded-full bg-slate-150 px-3 leading-tight transition-colors hover:bg-slate-300 focus:bg-slate-300 active:bg-slate-300/80 dark:bg-navy-500 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90"
  }

  @pager_current %{
    "rounded" =>
      "flex h-8 min-w-[2rem] items-center justify-center rounded-lg bg-primary px-3 leading-tight text-white transition-colors hover:bg-primary-focus focus:bg-primary-focus active:bg-primary-focus/90 dark:bg-accent dark:hover:bg-accent-focus dark:focus:bg-accent-focus dark:active:bg-accent/90",
    "pill" =>
      "flex h-8 min-w-[2rem] items-center justify-center rounded-full bg-primary px-3 leading-tight text-white transition-colors hover:bg-primary-focus focus:bg-primary-focus active:bg-primary-focus/90 dark:bg-accent dark:hover:bg-accent-focus dark:focus:bg-accent-focus dark:active:bg-accent/90",
    "circle" =>
      "flex h-8 min-w-[2rem] items-center justify-center rounded-full bg-primary px-3 leading-tight text-white transition-colors hover:bg-primary-focus focus:bg-primary-focus active:bg-primary-focus/90 dark:bg-accent dark:hover:bg-accent-focus dark:focus:bg-accent-focus dark:active:bg-accent/90"
  }

  @grid_button "flex h-8 min-w-[2rem] items-center justify-center rounded-full bg-slate-150 px-3 leading-tight transition-colors hover:bg-slate-300 focus:bg-slate-300 disabled:pointer-events-none disabled:opacity-60 aria-disabled:pointer-events-none aria-disabled:opacity-60 dark:bg-navy-500 dark:hover:bg-navy-450 dark:focus:bg-navy-450"

  @grid_current "flex h-8 min-w-[2rem] items-center justify-center rounded-full bg-primary px-3 leading-tight text-white transition-colors dark:bg-accent"

  @icon_button "btn size-8 rounded-full p-0 hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25"

  @doc """
  Renders a data table. The LiveView passes the rows of the current page and handles the
  events below.

      <.data_table
        id="contacts"
        variant="grid"
        rows={@rows}
        total={@total}
        page={@page}
        on_page="paginate"
        search={@search}
        on_search="search"
        sort_by={@sort_by}
        sort_dir={@sort_dir}
        on_sort="sort"
        row_key={& &1.id}
        selected={@selected}
        on_select="select"
        on_select_all="select_all"
      >
        <:col :let={c} label="Name" sort_key="name">{c.name}</:col>
        <:col :let={c} label="Email" sort_key="email">{c.email}</:col>
      </.data_table>

  Events, each an event name or a `%JS{}` (sent to `target` when given):

  * `on_search` — the search input changed or was submitted: `%{"search" => query}`.
  * `on_sort` — a sortable header was clicked: `%{"column" => sort_key, "direction" => "asc" | "desc"}`,
    the direction to sort by next.
  * `on_page` — a page was chosen: `%{"page" => "3"}` (a string, as every `phx-value-*`).
    With `page_path` (a function of the page number) the pager renders `patch` links instead.
  * `on_page_size` — the "Show N entries" select changed: `%{"page_size" => "30"}`.
  * `on_select` — a row checkbox: `%{"id" => key, "selected" => "true" | "false"}`.
  * `on_select_all` — the header checkbox: `%{"selected" => "true" | "false"}`.

  The footer shows when `on_page` or `page_path` is given (unless `footer={false}`); the search
  when `on_search` is.
  """
  attr(:id, :string, required: true)
  attr(:rows, :any, required: true, doc: "The rows of the current page, a list or a stream.")
  attr(:variant, :string, default: "advanced", values: ~w(advanced grid))

  attr(:row_id, :any,
    default: nil,
    doc: "A function giving each row's DOM id; streams default to the stream id."
  )

  attr(:row_key, :any,
    default: nil,
    doc: "A function giving a row's selection key; defaults to its DOM id."
  )

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "Maps each row before the slots get it."
  )

  attr(:row_click, :any,
    default: nil,
    doc: "A function of the row returning a `JS` or an event name."
  )

  attr(:hoverable, :boolean,
    default: nil,
    doc: "Highlights the hovered row; on by default, off for expandable rows."
  )

  attr(:search, :string, default: "", doc: "The current query.")
  attr(:search_placeholder, :string, default: nil, doc: "Placeholder of the search input.")
  attr(:on_search, :any, default: nil, doc: "See the events above.")
  attr(:sort_by, :string, default: nil, doc: "The `sort_key` of the sorted column.")
  attr(:sort_dir, :string, default: "asc", values: ~w(asc desc), doc: "Direction of `sort_by`.")
  attr(:on_sort, :any, default: nil, doc: "See the events above.")
  attr(:page, :integer, default: 1, doc: "The current page, from 1.")
  attr(:page_size, :integer, default: 10, doc: "Rows per page.")
  attr(:total, :integer, default: nil, doc: "Rows across every page. Defaults to the row count.")
  attr(:on_page, :any, default: nil, doc: "See the events above.")
  attr(:page_path, :any, default: nil, doc: "A function of the page number returning a path.")

  attr(:footer, :boolean,
    default: true,
    doc:
      "`false` leaves out the footer (pager, summary and page-size select) even when `on_page` is given, for a table with only a search."
  )

  attr(:compact, :boolean, default: false, doc: "Tighter cells, see `table/1`.")
  attr(:row_class, :any, default: nil, doc: "Extra classes of a row's `<tr>`, see `table/1`.")
  attr(:row_attrs, :any, default: nil, doc: "Extra attributes of a row's `<tr>`, see `table/1`.")
  attr(:sticky_header, :boolean, default: false, doc: "Sticky header row, see `table/1`.")
  attr(:scroll_label, :string, default: nil, doc: "Names the scrolling wrapper, see `table/1`.")

  attr(:peek, :boolean,
    default: false,
    doc:
      "Rows show the columns hidden by `priority` in a panel on hover and focus, see `table/1`."
  )

  attr(:peek_label, :string, default: "Hidden columns", doc: "`aria-label` of the panel.")

  attr(:sort_label, :string,
    default: nil,
    doc: "`aria-label` of the sort buttons, a prefix or a `%{label}` template, see `table/1`."
  )

  attr(:row_label, :any, default: nil, doc: "Label of a row's checkbox, see `table/1`.")
  attr(:headless, :boolean, default: false, doc: "No `<thead>`, see `table/1`.")
  attr(:borderless, :boolean, default: false, doc: "No row rules, see `table/1`.")
  attr(:page_sizes, :list, default: [], doc: "Options of the \"Show N entries\" select.")
  attr(:on_page_size, :any, default: nil, doc: "See the events above.")

  attr(:pager, :string,
    default: "rounded",
    values: ~w(rounded pill circle),
    doc: "The pager look of the `advanced` variant."
  )

  attr(:show_label, :string, default: "Show", doc: "Text before the page-size select.")
  attr(:entries_label, :string, default: "entries", doc: "Text after the page-size select.")
  attr(:prev_label, :string, default: "Previous", doc: "Text of the `grid` pager's first button.")
  attr(:next_label, :string, default: "Next", doc: "Text of the `grid` pager's last button.")

  attr(:page_label, :string,
    default: "Page %{page}",
    doc: "`aria-label` of each page button; `%{page}` is replaced."
  )

  attr(:summary_label, :string,
    default: nil,
    doc:
      "The summary text, `%{from}`, `%{to}` and `%{total}` being replaced (the `grid` variant shows them in bold): \"Showing 1 to 10 of 15 results\" in `grid`, \"1 - 10 of 15 entries\" in `advanced`. The `:summary` slot replaces it."
  )

  attr(:select_all_label, :string,
    default: "Select all rows",
    doc: "`aria-label` of the header checkbox."
  )

  attr(:select_label, :string, default: "Select row", doc: "`aria-label` of each row checkbox.")

  attr(:selected, :list, default: [], doc: "Keys of the selected rows.")

  attr(:all_selected, :boolean,
    default: nil,
    doc: "Whether the header checkbox is checked; computed for lists."
  )

  attr(:on_select, :any, default: nil, doc: "See the events above.")
  attr(:on_select_all, :any, default: nil, doc: "See the events above.")
  attr(:expand_label, :string, default: nil, doc: "Header of the expand column.")
  attr(:target, :any, default: nil, doc: "`phx-target` of every event.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :col, required: true, doc: "A column; receives the row (after `row_item`)." do
    attr(:label, :string, doc: "Header text.")

    attr(:class, :any,
      doc: "Extra classes of the column's cells (the header takes `head_class`)."
    )

    attr(:head_class, :any, doc: "Extra classes of the column's header.")

    attr(:align, :string,
      values: ~w(left center right),
      doc: "Text alignment of the column's header and cells."
    )

    attr(:sort_key, :string, doc: "Makes the header sortable; sent as `\"column\"` in `on_sort`.")

    attr(:priority, :integer,
      doc: "0 (default) stays; 1, 2 and 3 leave when the table's box is under 720, 560 and 420px."
    )
  end

  slot(:title, doc: "The `advanced` variant's heading.")
  slot(:actions, doc: "Buttons at the right of the `advanced` title bar.")

  slot(:filters,
    doc:
      "A filter panel the `advanced` title bar's filter button opens. Receives the `JS` that toggles it."
  )

  slot(:summary,
    doc: "Replaces the \"1 - 10 of 15 entries\" text; receives `%{first: n, last: n, total: n}`."
  )

  slot(:action, doc: "Cells appended to every row.")
  slot(:expand, doc: "Detail under each row, see `LineaUI.Components.Table.table/1`.")
  slot(:empty, doc: "Shown when `rows` is an empty list.")

  slot :foot, doc: "A cell of the totals row, see `table/1`." do
    attr(:class, :any, doc: "Extra classes of the cell.")
    attr(:align, :string, values: ~w(left center right), doc: "Text alignment of the cell.")
    attr(:colspan, :any, doc: "Columns the cell spans.")
    attr(:priority, :integer, doc: "Leaves with the columns of that priority.")
  end

  def data_table(assigns) do
    assigns
    |> assign(:total, total(assigns))
    |> assign_pages()
    |> assign(:paginated, assigns.footer and (assigns.on_page != nil or assigns.page_path != nil))
    |> assign(:icon_button, @icon_button)
    |> render_data_table()
  end

  defp total(%{total: nil, rows: rows}) when is_list(rows), do: length(rows)
  defp total(%{total: nil}), do: 0
  defp total(%{total: total}), do: total

  defp assign_pages(%{total: total, page_size: size, page: page} = assigns) do
    pages = max(div(total + size - 1, size), 1)
    current = page |> max(1) |> min(pages)

    assign(assigns,
      page: current,
      pages: pages,
      window: window(current, pages),
      range: %{first: first(total, current, size), last: min(current * size, total), total: total}
    )
  end

  defp first(0, _page, _size), do: 0
  defp first(_total, page, size), do: (page - 1) * size + 1

  defp window(page, pages), do: LineaUI.Components.Pagination.window(page, pages, 1, 1)

  @grid_summary "Showing %{from} to %{to} of %{total} results"
  @advanced_summary "%{from} - %{to} of %{total} entries"

  defp grid_summary(template, range) do
    (template || @grid_summary)
    |> String.split(~r/%\{(?:from|to|total)\}/, include_captures: true)
    |> Enum.map(fn
      "%{from}" -> bold(range.first)
      "%{to}" -> bold(range.last)
      "%{total}" -> bold(range.total)
      text -> text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    end)
    |> Phoenix.HTML.raw()
  end

  defp bold(number), do: "<b>#{number}</b>"

  defp advanced_summary_text(template, range) do
    (template || @advanced_summary)
    |> String.replace("%{from}", to_string(range.first))
    |> String.replace("%{to}", to_string(range.last))
    |> String.replace("%{total}", to_string(range.total))
  end

  defp render_data_table(%{variant: "grid"} = assigns) do
    ~H"""
    <div id={@id} class={merge(["w-full", @class])} {@rest}>
      <form
        :if={@on_search}
        id={@id <> "-search-form"}
        class="flex justify-end px-4 pb-5 sm:px-5"
        phx-change={@on_search}
        phx-submit={@on_search}
        phx-target={@target}
      >
        <label class="flex h-9 w-full max-w-55 items-center gap-2 rounded-lg border border-slate-300 bg-transparent px-3 text-slate-400 focus-within:border-primary dark:border-navy-450 dark:bg-navy-700 dark:focus-within:border-accent">
          <.glyph name={:search} class="size-4 shrink-0" stroke_width="1.5" />
          <input
            type="search"
            name="search"
            value={@search}
            placeholder={@search_placeholder || "Type a keyword..."}
            aria-label={@search_placeholder || "Type a keyword..."}
            autocomplete="off"
            phx-debounce="300"
            class="min-w-0 flex-1 appearance-none border-0 bg-transparent p-0 font-medium text-slate-700 outline-hidden placeholder:font-normal placeholder:text-slate-400/70 focus:ring-0 dark:text-navy-100"
          />
        </label>
      </form>
      <.data_table_body {assigns} table_variant="grid" rounded="none" />
      <div
        :if={@paginated}
        class="flex flex-col justify-between space-y-4 px-4 py-4 sm:flex-row sm:items-center sm:space-y-0 sm:px-5"
      >
        <div role="status" aria-live="polite">
          <span :if={@summary == []}>{grid_summary(@summary_label, @range)}</span>
          {render_slot(@summary, @range)}
        </div>
        <div class="flex flex-wrap space-x-1 text-slate-600 dark:text-slate-300">
          <.pager_link
            {pager_link_assigns(assigns)}
            to={@page - 1}
            disabled={@page == 1}
            class={grid_button()}
            label={@prev_label}
          >
            {@prev_label}
          </.pager_link>
          <%= for n <- @window do %>
            <span
              :if={n == :gap}
              aria-hidden="true"
              class="flex h-8 items-center justify-center px-2"
            >…</span>
            <.pager_link
              :if={n != :gap}
              {pager_link_assigns(assigns)}
              to={n}
              current={n == @page}
              class={grid_page_class(n == @page)}
              label={page_label(@page_label, n)}
            >
              {n}
            </.pager_link>
          <% end %>
          <.pager_link
            {pager_link_assigns(assigns)}
            to={@page + 1}
            disabled={@page == @pages}
            class={grid_button()}
            label={@next_label}
          >
            {@next_label}
          </.pager_link>
        </div>
      </div>
    </div>
    """
  end

  defp render_data_table(assigns) do
    ~H"""
    <div id={@id} class={@class} {@rest}>
      <div class="flex items-center justify-between">
        <h2 class="text-base font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100">
          {render_slot(@title)}
        </h2>
        <div class="flex">
          <.table_search
            :if={@on_search}
            id={@id}
            value={@search}
            on_search={@on_search}
            target={@target}
            placeholder={@search_placeholder}
          />
          <button
            :if={@filters != []}
            type="button"
            class={@icon_button}
            aria-controls={@id <> "-filters"}
            aria-expanded="false"
            phx-click={data_table_toggle_filters(@id)}
          >
            <.glyph name={:filter} class="size-4.5" />
          </button>
          {render_slot(@actions)}
        </div>
      </div>
      <div :if={@filters != []} id={@id <> "-filters"} class="hidden">
        <div class="max-w-2xl py-3">
          {render_slot(@filters, data_table_toggle_filters(@id))}
        </div>
      </div>
      <div class="card mt-3">
        <.data_table_body {assigns} table_variant="hoverable" rounded="top" />
        <div
          :if={@paginated}
          class="flex flex-col justify-between space-y-4 px-4 py-4 sm:flex-row sm:items-center sm:space-y-0 sm:px-5"
        >
          <form
            :if={@page_sizes != []}
            id={@id <> "-page-size-form"}
            class="flex items-center space-x-2 text-xs-plus"
            phx-change={@on_page_size}
            phx-target={@target}
          >
            <span>{@show_label}</span>
            <label class="block">
              <select
                name="page_size"
                aria-label={@show_label <> " " <> @entries_label}
                class="form-select rounded-full border border-slate-300 bg-white px-2 py-1 pr-6 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:bg-navy-700 dark:hover:border-navy-400 dark:focus:border-accent"
              >
                <option :for={size <- @page_sizes} value={size} selected={size == @page_size}>
                  {size}
                </option>
              </select>
            </label>
            <span>{@entries_label}</span>
          </form>
          <.advanced_summary
            :if={@page_sizes == []}
            range={@range}
            summary={@summary}
            summary_label={@summary_label}
          />
          <.advanced_pager {assigns} />
          <.advanced_summary
            :if={@page_sizes != []}
            range={@range}
            summary={@summary}
            summary_label={@summary_label}
          />
        </div>
      </div>
    </div>
    """
  end

  @table_keys ~w(row_id row_key row_item row_click sort_by sort_dir on_sort on_select on_select_all
                 selected all_selected expand_label target col action expand empty compact headless
                 borderless row_class row_attrs sticky_header foot scroll_label sort_label row_label select_all_label select_label peek peek_label)a

  defp data_table_body(assigns) do
    assigns =
      assign(
        assigns,
        :table,
        assigns
        |> Map.take(@table_keys)
        |> Map.merge(%{
          id: assigns.id <> "-table",
          rows: assigns.rows,
          variant: assigns.table_variant,
          rounded: assigns.rounded,
          hoverable: hoverable(assigns.hoverable, assigns.expand),
          rest: %{},
          class: nil,
          wrapper_class: nil,
          __changed__: nil
        })
      )

    ~H"""
    {Table.table(@table)}
    """
  end

  defp hoverable(nil, [_ | _]), do: false
  defp hoverable(value, _expand), do: value

  defp advanced_summary(assigns) do
    ~H"""
    <div class="text-xs-plus" role="status" aria-live="polite">
      <span :if={@summary == []}>{advanced_summary_text(@summary_label, @range)}</span>
      {render_slot(@summary, @range)}
    </div>
    """
  end

  defp advanced_pager(assigns) do
    assigns =
      assign(assigns,
        list_class: @pager_list[assigns.pager],
        li: @pager_li[assigns.pager],
        arrow: @pager_arrow[assigns.pager],
        page_class: @pager_page[assigns.pager],
        current_class: @pager_current[assigns.pager]
      )

    ~H"""
    <ol class={@list_class}>
      <li class={elem(@li, 0)}>
        <.pager_link
          {pager_link_assigns(assigns)}
          to={@page - 1}
          disabled={@page == 1}
          class={@arrow}
          label={@prev_label}
        >
          <.glyph name={:chevron_left} class="size-4" />
        </.pager_link>
      </li>
      <li :for={n <- @window} class={elem(@li, 1)}>
        <span
          :if={n == :gap}
          aria-hidden="true"
          class={[@page_class, "pointer-events-none"]}
        >…</span>
        <.pager_link
          :if={n != :gap}
          {pager_link_assigns(assigns)}
          to={n}
          current={n == @page}
          class={page_class(n == @page, @page_class, @current_class)}
          label={page_label(@page_label, n)}
        >
          {n}
        </.pager_link>
      </li>
      <li class={elem(@li, 2)}>
        <.pager_link
          {pager_link_assigns(assigns)}
          to={@page + 1}
          disabled={@page == @pages}
          class={@arrow}
          label={@next_label}
        >
          <.glyph name={:chevron_right} class="size-4" />
        </.pager_link>
      </li>
    </ol>
    """
  end

  defp pager_link_assigns(assigns),
    do:
      assigns
      |> Map.take([:on_page, :page_path, :target])
      |> Map.merge(%{current: false, disabled: false})

  defp page_class(true, _page, current), do: current
  defp page_class(false, page, _current), do: page

  defp page_label(template, page), do: String.replace(template, "%{page}", to_string(page))

  defp grid_button, do: @grid_button
  defp grid_page_class(true), do: @grid_current
  defp grid_page_class(false), do: @grid_button

  defp pager_link(%{page_path: nil} = assigns) do
    ~H"""
    <button
      type="button"
      class={@class}
      disabled={@disabled}
      aria-label={@label}
      aria-current={@current && "page"}
      phx-click={@on_page}
      phx-value-page={@to}
      phx-target={@target}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp pager_link(%{disabled: true} = assigns) do
    ~H"""
    <span class={@class} aria-disabled="true" aria-label={@label}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp pager_link(assigns) do
    ~H"""
    <.link
      patch={@page_path.(@to)}
      class={@class}
      aria-label={@label}
      aria-current={@current && "page"}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  LineOne's collapsing search: a magnifier button that slides a borderless input open, as in the
  title bar of the Table Advanced page. `data_table/1` uses it, and it works on its own next to
  any title.

      <div class="flex items-center justify-between">
        <h2>Users</h2>
        <.table_search id="users" value={@search} on_search="search" />
      </div>

  Events: `on_search` (an event name or `%JS{}`, sent to `target` when given) receives
  `%{"search" => query}` on every change (debounced 300ms) and on submit. The input has the
  DOM id `\#{id}-search` and the form `\#{id}-search-form`. The input starts open when `value`
  is not empty.
  """
  attr(:id, :string, required: true)
  attr(:value, :string, default: "", doc: "The current query.")
  attr(:on_search, :any, default: nil, doc: "Event name or `%JS{}` for the query changes.")
  attr(:target, :any, default: nil, doc: "`phx-target` of `on_search`.")

  attr(:placeholder, :string,
    default: nil,
    doc: "Placeholder and label; \"Search here...\" by default."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def table_search(assigns) do
    assigns
    |> assign(:icon_button, @icon_button)
    |> assign(:label, assigns.placeholder || "Search here...")
    |> render_table_search()
  end

  defp render_table_search(assigns) do
    ~H"""
    <form
      id={@id <> "-search-form"}
      class={merge(["flex items-center", @class])}
      phx-change={@on_search}
      phx-submit={@on_search}
      phx-target={@target}
      {@rest}
    >
      <label class="block">
        <input
          id={@id <> "-search"}
          type="text"
          name="search"
          value={@value}
          placeholder={@label}
          aria-label={@label}
          autocomplete="off"
          phx-debounce="300"
          class={search_input_class(@value)}
        />
      </label>
      <button
        type="button"
        class={@icon_button}
        aria-label={@label}
        aria-controls={@id <> "-search"}
        phx-click={toggle_search(@id)}
      >
        <.glyph name={:search} class="size-4.5" stroke_width="1.5" />
      </button>
    </form>
    """
  end

  defp search_input_class("") do
    "form-input w-0 bg-transparent px-1 text-right transition-all duration-100 placeholder:text-slate-500 dark:placeholder:text-navy-200"
  end

  defp search_input_class(_search) do
    "form-input w-32 bg-transparent px-1 text-right transition-all duration-100 placeholder:text-slate-500 lg:w-48 dark:placeholder:text-navy-200"
  end

  defp toggle_search(id) do
    ("#" <> id <> "-search")
    |> then(&JS.toggle_class("w-0 w-32 lg:w-48", to: &1))
    |> JS.focus(to: "#" <> id <> "-search")
  end

  @doc """
  The `JS` that opens and closes the filter panel of the data table with `id` (the `:filters`
  slot also receives it).

      <.button phx-click={data_table_toggle_filters("projects")}>Filters</.button>
  """
  @spec data_table_toggle_filters(JS.t(), String.t()) :: JS.t()
  def data_table_toggle_filters(js \\ %JS{}, id) do
    js
    |> JS.toggle(to: "#" <> id <> "-filters")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"},
      to: "#" <> id <> " [aria-controls='" <> id <> "-filters']"
    )
  end
end
