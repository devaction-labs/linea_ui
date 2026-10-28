defmodule LineaUI.Components.Table do
  @moduledoc """
  LineOne's tables: basic, bordered, hoverable, zebra and the grid look, with `:col` slots
  the way Phoenix's generated `CoreComponents.table/1` takes them.

      <.table id="users" rows={@users}>
        <:col :let={user} label="Name">{user.name}</:col>
        <:col :let={user} label="Job">{user.job}</:col>
      </.table>

      <.table id="users" rows={@streams.users} variant="hoverable" row_click={&JS.navigate(~p"/users/\#{elem(&1, 1)}")}>
        <:col :let={{_id, user}} label="Name">{user.name}</:col>
        <:action :let={{_id, user}}><.button size="xs">Edit</.button></:action>
      </.table>

  `variant="hoverable"` and `"zebra"` draw the filled header; `rounded` picks its corners:
  `row` rounds both ends of the header row (a table inside a padded card), `top` only the
  top corners (a table that is the top of a card) and `none` keeps it square (full width).

  Sortable headers: give a column `sort_key` and the table `on_sort`; the header becomes a
  button that sends `on_sort` with `%{"column" => sort_key, "direction" => "asc" | "desc"}`,
  the direction being the one to sort by next. `sort_by` and `sort_dir` mark the current order.

      <.table id="t" rows={@rows} on_sort="sort" sort_by={@sort_by} sort_dir={@sort_dir}>
        <:col :let={row} label="Name" sort_key="name">{row.name}</:col>
      </.table>

  Row selection: `on_select` adds a checkbox column. Each checkbox sends `on_select` with
  `%{"id" => key, "selected" => "true" | "false"}` (the new state of that row); the header one
  sends `on_select_all` with `%{"selected" => "true" | "false"}`. `selected` is the list of keys
  checked. The key is `row_key.(row)`, or the row's DOM id when `row_key` is not given; keys
  are compared as given, so pass strings or convert the `"id"` back.

  Density and chrome: `compact` tightens the cell padding, `borderless` drops the row rules (and
  the cell borders of `bordered`), `headless` leaves out the `<thead>` altogether. A column's
  `align` (`left`, `center`, `right`) aligns its header and cells.

      <.table id="stats" rows={@rows} compact borderless headless>
        <:col :let={row}>{row.label}</:col>
        <:col :let={row} align="right">{row.count}</:col>
      </.table>

  Every event attr takes an event name or a `%JS{}`; `target` sets `phx-target`.

  Expandable rows: an `:expand` slot adds a last column with a chevron that shows a detail
  row under each row (`expand_label` names that column). The slot receives
  `%{row: row, toggle: js}`, `toggle` being the `JS` that opens and closes it. Expandable
  rows render one `<tbody>` per row, so they take a list, not a stream.

  Per-row markup: `row_class` and `row_attrs` are functions of the row giving extra classes
  and attributes (`phx-click`, `data-*`) of its `<tr>`; `:foot` cells make a totals row in a
  `<tfoot>`; `sticky_header` pins the header inside a height-bound wrapper.

  ## Hand-written tables

  Without `rows`, the table renders its inner block and its cells take the look of `variant`,
  `rounded`, `compact`, `borderless` and `sticky_header` from it, so rows can carry any markup:
  per-row attributes, colspans, detail rows, a totals footer.

      <.table id="orders" variant="hoverable" rounded="top" class="min-w-[760px]">
        <.table_head on_sort="sort" sort_by={@sort_by} sort_dir={@sort_dir}
          on_select_all="select_all" all_selected={@all?} some_selected={@some?}>
          <:col sort_key="number">Number</:col>
          <:col align="right">Total</:col>
        </.table_head>
        <.table_body id="orders-body" phx-update="stream">
          <.table_row :for={{id, o} <- @streams.orders} id={id} on_click="open" phx-value-id={o.id}
            selected={o.id in @selected} on_select="select" select_value={o.id}>
            <:cell>{o.number}</:cell>
            <:cell align="right">{o.total}</:cell>
          </.table_row>
          <.table_empty id="orders-empty">No orders.</.table_empty>
        </.table_body>
        <.table_foot><:cell>Total</:cell><:cell align="right">{@sum}</:cell></.table_foot>
      </.table>

  `table_cell/1`, `table_checkbox/1`, `table_expand_toggle/1` and `table_detail_row/1` cover
  free cells, custom checkboxes and expandable rows; `table_skeleton/1` is the loading state.
  A class given to a cell always wins over the table's look (the look lives in the CSS
  `components` layer).

  Inside a card, `bleed` runs the table edge to edge: the wrapper cancels the padding of the
  card's body (or of the card) as a negative margin and the first and last cells get it back as
  their own padding, so the rows (hover, zebra, rules) reach the card's sides while the content
  stays aligned with the rest of the card. As the only thing in a body it also reaches the
  body's top and bottom and follows its rounded corners. The `bordered` frame is dropped.

      <.card>
        <.card_header><.card_heading>Team</.card_heading></.card_header>
        <.table id="team" rows={@team} bleed>
          <:col :let={person} label="Name">{person.name}</:col>
        </.table>
      </.card>
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]
  import LineaUI.Components.Skeleton, only: [skeleton: 1]

  alias Phoenix.LiveView.LiveStream

  # `relative` so an absolute child of the table (an `sr-only` label) is clipped by the scroller instead of
  # widening the page around it.
  @wrapper %{
    "basic" => "is-scrollbar-hidden relative min-w-full overflow-x-auto",
    "bordered" =>
      "is-scrollbar-hidden relative min-w-full overflow-x-auto rounded-lg border border-slate-200 dark:border-navy-500",
    "hoverable" => "is-scrollbar-hidden relative min-w-full overflow-x-auto",
    "zebra" => "is-scrollbar-hidden relative min-w-full overflow-x-auto",
    "grid" => "is-scrollbar-hidden relative min-w-full overflow-x-auto"
  }

  @table %{
    "basic" => "w-full text-left",
    "bordered" => "w-full text-left",
    "hoverable" => "is-hoverable w-full text-left",
    "zebra" => "is-zebra w-full text-left",
    "grid" => "is-hoverable w-full text-left"
  }

  @head_row %{
    "basic" => "border-y border-transparent border-b-slate-200 dark:border-b-navy-500",
    "bordered" => "",
    "hoverable" => "",
    "zebra" => "",
    "grid" => "border border-transparent border-b-slate-200 dark:border-b-navy-500"
  }

  @body_row %{
    "basic" => "border-y border-transparent border-b-slate-200 dark:border-b-navy-500",
    "bordered" => "[&:last-child>td]:border-b-0",
    "hoverable" => "border-y border-transparent border-b-slate-200 dark:border-b-navy-500",
    "zebra" => "",
    "grid" => "border border-transparent border-b-slate-200 dark:border-b-navy-500"
  }

  @th %{
    "basic" =>
      "whitespace-nowrap px-3 py-3 font-semibold uppercase text-slate-800 dark:text-navy-100 lg:px-5",
    "bordered" =>
      "whitespace-nowrap border border-t-0 border-slate-200 px-3 py-3 font-semibold uppercase text-slate-800 first:border-l-0 last:border-r-0 dark:border-navy-500 dark:text-navy-100 lg:px-5",
    "hoverable" =>
      "whitespace-nowrap bg-slate-200 px-4 py-3 font-semibold uppercase text-slate-800 dark:bg-navy-800 dark:text-navy-100 lg:px-5",
    "zebra" =>
      "whitespace-nowrap bg-slate-200 px-4 py-3 font-semibold uppercase text-slate-800 dark:bg-navy-800 dark:text-navy-100 lg:px-5",
    "grid" =>
      "whitespace-nowrap bg-slate-200 px-3 py-3 font-semibold uppercase text-slate-800 dark:bg-navy-800 dark:text-navy-100 lg:px-4"
  }

  @td %{
    "basic" => "whitespace-nowrap px-4 py-3 sm:px-5",
    "bordered" =>
      "whitespace-nowrap border border-slate-200 px-3 py-3 first:border-l-0 last:border-r-0 dark:border-navy-500 lg:px-5",
    "hoverable" => "whitespace-nowrap px-4 py-3 sm:px-5",
    "zebra" => "whitespace-nowrap px-4 py-3 sm:px-5",
    "grid" => "whitespace-nowrap px-4 py-3"
  }

  @th_rounded %{
    "row" => "first:rounded-l-lg first:px-3 last:rounded-r-lg last:px-3",
    "top" => "first:rounded-tl-lg last:rounded-tr-lg",
    "none" => ""
  }

  @td_rounded %{
    "row" => "first:rounded-l-lg last:rounded-r-lg",
    "top" => "",
    "none" => ""
  }

  @filled ~w(hoverable zebra)

  @sticky %{
    "basic" => "sticky top-0 z-10 bg-white dark:bg-navy-700",
    "bordered" => "sticky top-0 z-10 bg-white dark:bg-navy-700",
    "hoverable" => "sticky top-0 z-10",
    "zebra" => "sticky top-0 z-10",
    "grid" => "sticky top-0 z-10"
  }

  @bleed "min-w-[calc(100%+var(--card-bleed-x,1rem)*2)] mx-[calc(var(--card-bleed-x,1rem)*-1)] rounded-none border-0 first:mt-[calc(var(--card-bleed-t,0px)*-1)] last:mb-[calc(var(--card-bleed-b,0px)*-1)] first:rounded-t-[var(--card-bleed-rt,0px)] last:rounded-b-[var(--card-bleed-rb,0px)] [&_tbody>tr:last-child]:border-b-transparent [&_tr>:first-child]:pl-[var(--card-bleed-x,1rem)] [&_tr>:last-child]:pr-[var(--card-bleed-x,1rem)]"

  @slot_defaults %{row_class: nil, row_attrs: nil, sticky_header: false, foot: []}

  @foot_td "whitespace-nowrap border-t border-slate-200 px-4 py-3 font-semibold text-slate-700 dark:border-navy-500 dark:text-navy-100 sm:px-5"

  @compact "px-3 py-2 sm:px-3 lg:px-3"

  @aligns %{"left" => "text-left", "center" => "text-center", "right" => "text-right"}

  @head_col_keys ~w(__slot__ inner_block label class align colspan sort_key)a

  @cell_keys ~w(__slot__ inner_block class align colspan rowspan)a

  @checkbox "form-checkbox is-basic size-5 rounded-sm border-slate-400/70 checked:border-primary checked:bg-primary hover:border-primary focus:border-primary dark:border-navy-400 dark:checked:border-accent dark:checked:bg-accent dark:hover:border-accent dark:focus:border-accent"

  @expand_button "btn size-8 rounded-full p-0 hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25"

  @doc """
  Renders a table of `rows` (a list or a stream), one column per `:col` slot.

      <.table id="people" rows={@streams.people} variant="zebra">
        <:col :let={{_id, person}} label="Name">{person.name}</:col>
        <:col :let={{_id, person}} label="Job">{person.job}</:col>
        <:action :let={{_id, person}}>
          <.button size="xs" phx-click="edit" phx-value-id={person.id}>Edit</.button>
        </:action>
      </.table>

  Events (each an event name or a `%JS{}`, sent to `target` when given):

  * `on_sort` — a sortable header was clicked:
    `%{"column" => sort_key, "direction" => "asc" | "desc"}` (the direction to sort by next).
  * `on_select` — a row checkbox: `%{"id" => key, "selected" => "true" | "false"}`.
  * `on_select_all` — the header checkbox: `%{"selected" => "true" | "false"}`.

  With a stream, `selected` only reaches the rows the server re-renders: `stream_insert` the
  rows whose selection changed, and give `all_selected` for the header checkbox.
  """
  attr(:id, :string, required: true)

  attr(:rows, :any,
    default: nil,
    doc:
      "A list or a `@streams.x` stream. Leave it out to write the table by hand with `table_head/1`, `table_body/1` and `table_row/1`."
  )

  attr(:row_id, :any,
    default: nil,
    doc: "A function giving each row's DOM id. Streams default to the stream id."
  )

  attr(:row_click, :any, default: nil, doc: "A function of the row returning a `JS` or an event.")

  attr(:row_class, :any,
    default: nil,
    doc: "A function of the row returning extra classes of its `<tr>`."
  )

  attr(:row_attrs, :any,
    default: nil,
    doc:
      "A function of the row returning a map of extra attributes of its `<tr>` (`phx-click`, `data-*`...)."
  )

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "Maps each row before it is given to the slots."
  )

  attr(:row_key, :any,
    default: nil,
    doc: "A function giving the selection key of a row. Defaults to the row's DOM id."
  )

  attr(:variant, :string,
    default: "basic",
    values: ~w(basic bordered hoverable zebra grid),
    doc: "`grid` is the gridjs look of LineOne's Grid Table page."
  )

  attr(:rounded, :string,
    default: "row",
    values: ~w(row top none),
    doc: "Corners of the filled header of `hoverable` and `zebra`."
  )

  attr(:sort_by, :string, default: nil, doc: "The `sort_key` of the sorted column.")
  attr(:sort_dir, :string, default: "asc", values: ~w(asc desc), doc: "Direction of `sort_by`.")
  attr(:on_sort, :any, default: nil, doc: "Event sent when a sortable header is clicked.")
  attr(:on_select, :any, default: nil, doc: "Event sent when a row checkbox is clicked.")
  attr(:on_select_all, :any, default: nil, doc: "Event sent by the header checkbox.")
  attr(:selected, :list, default: [], doc: "The keys of the selected rows.")

  attr(:all_selected, :boolean,
    default: nil,
    doc: "Whether the header checkbox is checked. Computed for lists; give it for streams."
  )

  attr(:hoverable, :boolean,
    default: nil,
    doc: "Highlights the hovered row. Defaults to the variant's own behavior."
  )

  attr(:compact, :boolean,
    default: false,
    doc: "Tighter cells: `px-3 py-2` instead of the variant's padding."
  )

  attr(:headless, :boolean,
    default: false,
    doc: "Renders no `<thead>` at all (not hidden columns), for list-like tables."
  )

  attr(:sticky_header, :boolean,
    default: false,
    doc:
      "Keeps the header row at the top while the body scrolls. The wrapper is the scroll container, so bound its height with `wrapper_class` (`max-h-96`)."
  )

  attr(:borderless, :boolean,
    default: false,
    doc: "Removes the rules between rows, and the cell borders of the `bordered` variant."
  )

  attr(:bleed, :boolean,
    default: false,
    doc:
      "Runs the table edge to edge of the card it sits in (the body's padding as a negative margin, given back to the first and last cells), and to the top and bottom of the body when it is the only thing in it."
  )

  attr(:target, :any, default: nil, doc: "`phx-target` of the events.")
  attr(:expand_label, :string, default: nil, doc: "Header of the expand column.")

  attr(:scroll_label, :string,
    default: nil,
    doc:
      "Names the scrolling wrapper (`role=\"region\"` and `aria-label`) and makes it focusable, so a keyboard can scroll a height-bound or wide table."
  )

  attr(:sort_label, :string,
    default: nil,
    doc:
      "Prefix of the `aria-label` of the sort buttons (\"Sort by\" gives \"Sort by Order\"); without it the button is named by its text."
  )

  attr(:row_label, :any,
    default: nil,
    doc:
      "A function of the row (after `row_item`) returning the `aria-label` of its selection checkbox (\"Select order #2481\"); \"Select row\" when not given."
  )

  attr(:wrapper_class, :any, default: nil, doc: "Classes of the scrolling wrapper.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :col, doc: "A column; receives the row (after `row_item`)." do
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
  end

  slot(:action, doc: "Cells appended to every row, after the columns.")
  slot(:expand, doc: "Detail shown under a row; receives `%{row: row, toggle: js}`.")

  slot(:empty,
    doc:
      "Shown in a full-width row when there are no rows (a stream shows it whenever its body is empty)."
  )

  slot :foot, doc: "A cell of the `<tfoot>` row, for totals; one entry per cell." do
    attr(:class, :any, doc: "Extra classes of the cell.")
    attr(:align, :string, values: ~w(left center right), doc: "Text alignment of the cell.")
    attr(:colspan, :any, doc: "Columns the cell spans.")
  end

  slot(:inner_block,
    doc:
      "The hand-written table (`table_head/1`, `table_body/1`, `table_foot/1`) when `rows` is not given."
  )

  def table(%{rows: nil} = assigns) do
    assigns
    |> assign(:wrapper, merge([@wrapper[assigns.variant], bleed(assigns), assigns.wrapper_class]))
    |> assign(:table_class, merge(["linea-table", table_class(assigns), assigns.class]))
    |> render_composable()
  end

  def table(assigns) do
    assigns
    |> Map.merge(Map.drop(@slot_defaults, Map.keys(assigns)))
    |> assign_row_id()
    |> assign_selection()
    |> assign(
      :th_class,
      merge([
        @th[assigns.variant],
        th_rounded(assigns),
        compact(assigns),
        no_border(assigns),
        sticky(assigns)
      ])
    )
    |> assign(
      :td_class,
      merge([@td[assigns.variant], td_rounded(assigns), compact(assigns), no_border(assigns)])
    )
    |> assign(:head_row_class, merge([@head_row[assigns.variant], no_border(assigns)]))
    |> assign(:body_row_class, merge([@body_row[assigns.variant], no_border(assigns)]))
    |> assign(
      :wrapper,
      merge([
        @wrapper[assigns.variant],
        no_border(assigns),
        bleed(assigns),
        assigns.wrapper_class
      ])
    )
    |> assign(:table_class, merge([table_class(assigns), assigns.class]))
    |> assign(:checkbox, @checkbox)
    |> assign(:expand_button, @expand_button)
    |> render_table()
  end

  defp sticky(%{sticky_header: true, variant: variant}), do: @sticky[variant]
  defp sticky(_assigns), do: nil

  defp row_class(%{row_class: nil}, _row), do: nil
  defp row_class(%{row_class: fun, row_item: row_item}, row), do: fun.(row_item.(row))

  defp row_attrs(%{row_attrs: nil}, _row), do: %{}
  defp row_attrs(%{row_attrs: fun, row_item: row_item}, row), do: fun.(row_item.(row))

  defp stream?(%LiveStream{}), do: true
  defp stream?(_rows), do: false

  defp empty_row_class(%LiveStream{}), do: "hidden only:table-row"
  defp empty_row_class(_rows), do: nil

  defp compact(%{compact: true}), do: @compact
  defp compact(%{compact: false}), do: nil

  defp bleed(%{bleed: true}), do: @bleed
  defp bleed(%{bleed: false}), do: nil

  defp no_border(%{borderless: true}), do: "border-0"
  defp no_border(%{borderless: false}), do: nil

  defp align(nil), do: nil
  defp align(align), do: @aligns[align]

  defp table_class(%{hoverable: nil, variant: variant}), do: @table[variant]
  defp table_class(%{hoverable: true}), do: "is-hoverable w-full text-left"
  defp table_class(%{variant: "zebra"}), do: "is-zebra w-full text-left"
  defp table_class(_assigns), do: "w-full text-left"

  defp th_rounded(%{variant: variant, rounded: rounded}) when variant in @filled,
    do: @th_rounded[rounded]

  defp th_rounded(_assigns), do: ""

  defp td_rounded(%{variant: variant, rounded: rounded}) when variant in @filled,
    do: @td_rounded[rounded]

  defp td_rounded(_assigns), do: ""

  defp assign_row_id(%{rows: %LiveStream{}, row_id: nil} = assigns),
    do: assign(assigns, :row_id, fn {id, _item} -> id end)

  defp assign_row_id(assigns), do: assigns

  defp expand_rows(%{row_id: nil, id: id, rows: rows}) do
    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, index} -> {id <> "-row-" <> Integer.to_string(index), row} end)
  end

  defp expand_rows(%{row_id: row_id, rows: rows}), do: Enum.map(rows, &{row_id.(&1), &1})

  defp assign_selection(%{on_select: nil} = assigns), do: assign(assigns, :selectable, false)

  defp assign_selection(assigns) do
    assigns
    |> assign(:selectable, true)
    |> assign(:all_selected, all_selected(assigns))
    |> assign(:some_selected, assigns.selected != [])
  end

  defp all_selected(%{all_selected: value}) when is_boolean(value), do: value
  defp all_selected(%{rows: %LiveStream{}}), do: false

  defp all_selected(%{rows: rows, selected: selected} = assigns) do
    keys = Enum.map(rows, &key(assigns, &1))
    keys != [] and Enum.all?(keys, &(&1 in selected))
  end

  defp row_label(%{row_label: nil}, _row), do: "Select row"
  defp row_label(%{row_label: row_label, row_item: row_item}, row), do: row_label.(row_item.(row))

  defp key(%{row_key: nil, row_id: row_id}, row), do: row_id.(row)
  defp key(%{row_key: row_key, row_item: row_item}, row), do: row_key.(row_item.(row))

  defp render_table(%{expand: [_ | _]} = assigns) do
    ~H"""
    <div
      class={@wrapper}
      role={@scroll_label && "region"}
      tabindex={@scroll_label && "0"}
      aria-label={@scroll_label}
    >
      <table id={@id} class={@table_class} {@rest}>
        <.slot_head :if={!@headless} {assigns} />
        <tbody :for={{dom_id, row} <- expand_rows(assigns)} id={dom_id}>
          <tr
            class={merge(["border-y border-transparent", row_class(assigns, row)])}
            {row_attrs(assigns, row)}
          >
            <.slot_cells {assigns} row={row} />
            <td class={@td_class}>
              <button
                type="button"
                class={@expand_button}
                aria-expanded="false"
                aria-controls={dom_id <> "-detail"}
                phx-click={table_toggle_row(dom_id)}
              >
                <.glyph
                  name={:chevron_down}
                  class="size-3.5 transition-transform"
                  stroke_width="2.5"
                  data-expand-icon
                />
              </button>
            </td>
          </tr>
          <tr class="border-y border-transparent border-b-slate-200 dark:border-b-navy-500">
            <td colspan="100" class="p-0">
              <div id={dom_id <> "-detail"} class="hidden px-4 pb-4 sm:px-5">
                {render_slot(@expand, %{row: @row_item.(row), toggle: table_toggle_row(dom_id)})}
              </div>
            </td>
          </tr>
        </tbody>
        <.slot_foot foot={@foot} td_class={@td_class} />
      </table>
    </div>
    """
  end

  defp render_table(assigns) do
    ~H"""
    <div
      class={@wrapper}
      role={@scroll_label && "region"}
      tabindex={@scroll_label && "0"}
      aria-label={@scroll_label}
    >
      <table id={@id} class={@table_class} {@rest}>
        <.slot_head :if={!@headless} {assigns} />
        <tbody
          id={@id <> "-body"}
          phx-update={match?(%LiveStream{}, @rows) && "stream"}
        >
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class={merge([@body_row_class, row_class(assigns, row)])}
            data-selected={@selectable && bool(key(assigns, row) in @selected)}
            {row_attrs(assigns, row)}
          >
            <.slot_cells {assigns} row={row} />
          </tr>
          <tr
            :if={(@rows == [] or stream?(@rows)) and @empty != []}
            id={@id <> "-empty"}
            class={empty_row_class(@rows)}
          >
            <td colspan="100" class={@td_class}>{render_slot(@empty)}</td>
          </tr>
        </tbody>
        <.slot_foot foot={@foot} td_class={@td_class} />
      </table>
    </div>
    """
  end

  defp slot_head(assigns) do
    ~H"""
    <thead>
      <tr class={@head_row_class}>
        <th :if={@selectable} class={[@th_class, "w-px"]}>
          <label class="flex">
            <input
              id={@id <> "-select-all"}
              type="checkbox"
              class={[@checkbox, "table-select-all"]}
              checked={@all_selected}
              aria-label="Select all rows"
              phx-hook="LineaUI.TableSelectAll"
              data-indeterminate={bool(@some_selected and not @all_selected)}
              phx-click={@on_select_all}
              phx-value-selected={bool(!@all_selected)}
              phx-target={@target}
            />
          </label>
        </th>
        <th
          :for={col <- @col}
          class={merge([@th_class, align(col[:align]), col[:head_class]])}
          aria-sort={aria_sort(col[:sort_key], @sort_by, @sort_dir)}
        >
          <.sort_header
            :if={col[:sort_key] && @on_sort}
            col={col}
            on_sort={@on_sort}
            target={@target}
            dir={sort_state(col[:sort_key], @sort_by, @sort_dir)}
            sort_label={@sort_label}
          />
          <span :if={!(col[:sort_key] && @on_sort)}>{col[:label]}</span>
        </th>
        <th :if={@action != []} class={@th_class}></th>
        <th :if={@expand != []} class={@th_class}>{@expand_label}</th>
      </tr>
    </thead>
    """
  end

  defp sort_header(assigns) do
    ~H"""
    <button
      type="button"
      class="flex w-full cursor-pointer items-center justify-between space-x-2 text-left font-semibold uppercase outline-hidden"
      phx-click={@on_sort}
      aria-label={@sort_label && "#{@sort_label} #{@col[:label]}"}
      phx-value-column={@col.sort_key}
      phx-value-direction={next_dir(@dir)}
      phx-target={@target}
    >
      <span class="overflow-hidden text-ellipsis">{@col[:label]}</span>
      <span class="table-sort-icon" data-sort={@dir} aria-hidden="true"></span>
    </button>
    """
  end

  defp slot_foot(%{foot: []} = assigns), do: ~H""

  defp slot_foot(assigns) do
    assigns = assign(assigns, :foot_td, @foot_td)

    ~H"""
    <tfoot>
      <tr>
        <td
          :for={cell <- @foot}
          colspan={cell[:colspan]}
          class={merge([@td_class, @foot_td, align(cell[:align]), cell[:class]])}
        >
          {render_slot(cell)}
        </td>
      </tr>
    </tfoot>
    """
  end

  defp slot_cells(assigns) do
    ~H"""
    <td :if={@selectable} class={@td_class}>
      <label class="flex">
        <input
          type="checkbox"
          class={@checkbox}
          checked={key(assigns, @row) in @selected}
          aria-label={row_label(assigns, @row)}
          phx-click={@on_select}
          phx-value-id={key(assigns, @row)}
          phx-value-selected={bool(key(assigns, @row) not in @selected)}
          phx-target={@target}
        />
      </label>
    </td>
    <td
      :for={col <- @col}
      class={merge([@td_class, align(col[:align]), @row_click && "cursor-pointer", col[:class]])}
      phx-click={@row_click && @row_click.(@row)}
    >
      {render_slot(col, @row_item.(@row))}
    </td>
    <td :if={@action != []} class={@td_class}>
      {render_slot(@action, @row_item.(@row))}
    </td>
    """
  end

  defp next_dir("asc"), do: "desc"
  defp next_dir(_dir), do: "asc"

  defp sort_state(key, key, dir), do: dir
  defp sort_state(_key, _sort_by, _dir), do: "none"

  defp aria_sort(nil, _sort_by, _dir), do: nil
  defp aria_sort(key, key, "asc"), do: "ascending"
  defp aria_sort(key, key, "desc"), do: "descending"
  defp aria_sort(_key, _sort_by, _dir), do: "none"

  defp render_composable(assigns) do
    ~H"""
    <div
      class={@wrapper}
      role={@scroll_label && "region"}
      tabindex={@scroll_label && "0"}
      aria-label={@scroll_label}
    >
      <table
        id={@id}
        class={@table_class}
        data-variant={@variant}
        data-rounded={@rounded}
        data-compact={@compact}
        data-borderless={@borderless}
        data-sticky={@sticky_header}
        {@rest}
      >
        {render_slot(@inner_block)}
      </table>
    </div>
    """
  end

  @doc """
  The `<thead>` of a hand-written table: one header cell per `:col`, after an optional
  select-all checkbox. Takes the look (`variant`, `compact`, `sticky_header`) from the
  `table/1` around it.

      <.table id="orders" variant="hoverable" rounded="top">
        <.table_head on_sort="sort" sort_by={@sort_by} sort_dir={@sort_dir}>
          <:col sort_key="number">Number</:col>
          <:col>Customer</:col>
          <:col align="right" class="w-32">Total</:col>
        </.table_head>
        <.table_body id="orders-body" phx-update="stream">
          ...
        </.table_body>
      </.table>

  Events (each an event name or a `%JS{}`, sent to `target` when given):

  * `on_sort` — a header with `sort_key` was clicked:
    `%{"column" => sort_key, "direction" => "asc" | "desc"}` (the direction to sort by next).
    The header cell carries `aria-sort` (`ascending`, `descending` or `none`).
  * `on_select_all` — the header checkbox: `%{"selected" => "true" | "false"}`, the state to
    move every row to. `all_selected` checks it and `some_selected` draws it indeterminate.
  """
  attr(:sort_by, :string, default: nil, doc: "The `sort_key` of the sorted column.")
  attr(:sort_dir, :string, default: "asc", values: ~w(asc desc), doc: "Direction of `sort_by`.")
  attr(:on_sort, :any, default: nil, doc: "Event sent when a sortable header is clicked.")

  attr(:on_select_all, :any,
    default: nil,
    doc: "Adds a select-all checkbox cell first; the event it sends."
  )

  attr(:all_selected, :boolean, default: false, doc: "Whether every row is selected.")

  attr(:some_selected, :boolean,
    default: false,
    doc: "Whether some rows are selected; with `all_selected` false the box is indeterminate."
  )

  attr(:select_all_id, :string,
    default: nil,
    doc: "Id of the select-all checkbox (its hook needs one). Generated when not given."
  )

  attr(:select_all_label, :string, default: "Select all rows")
  attr(:target, :any, default: nil, doc: "`phx-target` of the events.")
  attr(:class, :any, default: nil, doc: "Classes of the `<tr>`.")
  attr(:rest, :global)

  slot(:col,
    validate_attrs: false,
    doc:
      "A header cell; its content is the label (or give `label`). Takes `label` (text when the slot has no content), `class`, `align` (`left center right`), `colspan` and `sort_key` (makes it sortable; sent as `\"column\"` in `on_sort`). Any other attribute (`id`, `data-*`, `phx-*`, `title`, `aria-*`) lands on the `<th>`."
  )

  slot(:inner_block, doc: "Extra `<th>` cells after the columns, or further header rows.")

  def table_head(assigns) do
    assigns =
      assigns
      |> assign(:select_all_id, assigns.select_all_id || gen_id("table-select-all"))
      |> assign(:head_col_keys, @head_col_keys)

    ~H"""
    <thead {@rest}>
      <tr class={@class}>
        <th :if={@on_select_all} class="w-px">
          <.table_checkbox
            id={@select_all_id}
            checked={@all_selected}
            indeterminate={@some_selected and not @all_selected}
            label={@select_all_label}
            on_click={@on_select_all}
            values={%{"selected" => bool(!@all_selected)}}
            target={@target}
          />
        </th>
        <th
          :for={col <- @col}
          colspan={col[:colspan]}
          class={merge([align(col[:align]), col[:class]])}
          aria-sort={aria_sort(col[:sort_key], @sort_by, @sort_dir)}
          {slot_rest(col, @head_col_keys)}
        >
          <button
            :if={col[:sort_key] && @on_sort}
            type="button"
            class="flex w-full cursor-pointer items-center justify-between space-x-2 text-left font-semibold uppercase outline-hidden"
            phx-click={@on_sort}
            phx-value-column={col.sort_key}
            phx-value-direction={next_dir(sort_state(col.sort_key, @sort_by, @sort_dir))}
            phx-target={@target}
          >
            <span class="overflow-hidden text-ellipsis">
              <.col_label col={col} />
            </span>
            <span
              class="table-sort-icon"
              data-sort={sort_state(col.sort_key, @sort_by, @sort_dir)}
              aria-hidden="true"
            ></span>
          </button>
          <.col_label :if={!(col[:sort_key] && @on_sort)} col={col} />
        </th>
        {render_slot(@inner_block)}
      </tr>
    </thead>
    """
  end

  defp slot_rest(entry, consumed), do: Map.drop(entry, consumed)

  defp col_label(%{col: %{inner_block: nil}} = assigns), do: ~H"{@col[:label]}"
  defp col_label(assigns), do: ~H"{render_slot(@col)}"

  @doc """
  The `<tbody>` of a hand-written table. Attributes pass through, so a stream is
  `id` plus `phx-update="stream"`, each row taking its stream DOM id.

      <.table_body id="orders-body" phx-update="stream">
        <.table_row :for={{dom_id, order} <- @streams.orders} id={dom_id}>
          <:cell>{order.number}</:cell>
        </.table_row>
        <.table_empty id="orders-empty">No orders yet.</.table_empty>
      </.table_body>
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def table_body(assigns) do
    ~H"""
    <tbody class={@class} {@rest}>{render_slot(@inner_block)}</tbody>
    """
  end

  @doc """
  A row of a hand-written table: one `<td>` per `:cell`, then the inner content (free `<td>`s
  or `table_cell/1`). Any attribute (`id`, `phx-click`, `phx-value-*`, `data-*`) lands on the
  `<tr>`.

      <.table_row
        :for={{dom_id, order} <- @streams.orders}
        id={dom_id}
        selected={order.id in @selected}
        on_select="select"
        select_value={order.id}
        on_click={JS.patch(~p"/orders/\#{order.id}")}
        class={order.canceled && "opacity-60"}
      >
        <:cell class="font-medium">{order.number}</:cell>
        <:cell colspan="2">{order.customer}</:cell>
        <:cell align="right">{order.total}</:cell>
      </.table_row>

  Events (each an event name or a `%JS{}`, sent to `target` when given):

  * `on_click` — the row was clicked; `phx-value-*` attributes ride along.
  * `on_select` — adds a checkbox cell first; clicking it sends
    `%{"id" => select_value, "selected" => "true" | "false"}` (the row's new state).

  `selected` checks the box and marks the row (`data-selected`, a tinted background with a
  primary bar on its first cell).
  """
  attr(:selected, :boolean,
    default: nil,
    doc: "Whether the row is selected. `nil` leaves the row unmarked."
  )

  attr(:on_click, :any, default: nil, doc: "Event or `%JS{}` run when the row is clicked.")

  attr(:on_select, :any,
    default: nil,
    doc: "Adds a selection checkbox cell first; the event it sends."
  )

  attr(:select_value, :any, default: nil, doc: "Sent as `\"id\"` by the checkbox.")
  attr(:select_label, :string, default: "Select row")
  attr(:target, :any, default: nil, doc: "`phx-target` of the events.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:cell,
    validate_attrs: false,
    doc:
      "A `<td>` of the row. Takes `class`, `align` (`left center right`), `colspan` and `rowspan`; any other attribute (`id`, `data-*`, `phx-*`, `title`, `aria-*`) lands on the `<td>`."
  )

  slot(:inner_block, doc: "Free cells after the `:cell` ones.")

  def table_row(assigns) do
    assigns = assign(assigns, :cell_keys, @cell_keys)

    ~H"""
    <tr
      class={merge([@on_click && "cursor-pointer", @class])}
      data-selected={is_boolean(@selected) && bool(@selected)}
      aria-selected={is_boolean(@selected) && bool(@selected)}
      phx-click={@on_click}
      phx-target={@on_click && @target}
      {@rest}
    >
      <td :if={@on_select} class="w-px">
        <.table_checkbox
          checked={@selected == true}
          label={@select_label}
          on_click={@on_select}
          values={%{"id" => @select_value, "selected" => bool(@selected != true)}}
          target={@target}
        />
      </td>
      <td
        :for={cell <- @cell}
        colspan={cell[:colspan]}
        rowspan={cell[:rowspan]}
        class={merge([align(cell[:align]), cell[:class]])}
        {slot_rest(cell, @cell_keys)}
      >
        {render_slot(cell)}
      </td>
      {render_slot(@inner_block)}
    </tr>
    """
  end

  @doc """
  A cell of a hand-written table, for rows written with free markup: `<td>`, or `<th>` with
  `header` (a row header, `scope="row"`).

      <.table_row id="total">
        <.table_cell colspan="3" align="right">Total</.table_cell>
        <.table_cell align="right">{@total}</.table_cell>
      </.table_row>
  """
  attr(:header, :boolean, default: false, doc: "Renders a `<th scope=\"row\">`.")
  attr(:align, :string, default: nil, values: [nil | ~w(left center right)])
  attr(:colspan, :any, default: nil)
  attr(:rowspan, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def table_cell(%{header: true} = assigns) do
    ~H"""
    <th
      scope="row"
      colspan={@colspan}
      rowspan={@rowspan}
      class={merge([align(@align), @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </th>
    """
  end

  def table_cell(assigns) do
    ~H"""
    <td colspan={@colspan} rowspan={@rowspan} class={merge([align(@align), @class])} {@rest}>
      {render_slot(@inner_block)}
    </td>
    """
  end

  @doc """
  The `<tfoot>` of a hand-written table, for totals: one row of `:cell`s in bold over a rule,
  then any free rows.

      <.table_foot>
        <:cell colspan="3">Total</:cell>
        <:cell align="right">{@total}</:cell>
      </.table_foot>
  """
  attr(:class, :any, default: nil, doc: "Classes of the `:cell` row.")
  attr(:rest, :global)

  slot(:cell,
    validate_attrs: false,
    doc:
      "A `<td>` of the totals row. Takes `class`, `align` (`left center right`) and `colspan`; any other attribute (`id`, `data-*`, `phx-*`, `title`, `aria-*`) lands on the `<td>`."
  )

  slot(:inner_block, doc: "Free `<tr>` rows after the `:cell` row.")

  def table_foot(assigns) do
    assigns = assign(assigns, :cell_keys, @cell_keys)

    ~H"""
    <tfoot {@rest}>
      <tr :if={@cell != []} class={@class}>
        <td
          :for={cell <- @cell}
          colspan={cell[:colspan]}
          class={merge([align(cell[:align]), cell[:class]])}
          {slot_rest(cell, @cell_keys)}
        >
          {render_slot(cell)}
        </td>
      </tr>
      {render_slot(@inner_block)}
    </tfoot>
    """
  end

  @doc """
  The empty state of a hand-written table: a full-width row shown only when it is the only
  row of its `<tbody>`, so it works for lists and streams alike (put it last in the body;
  a stream needs its `id`).

      <.table_body id="orders-body" phx-update="stream">
        <.table_row :for={{id, order} <- @streams.orders} id={id}>...</.table_row>
        <.table_empty id="orders-empty">No orders in this filter.</.table_empty>
      </.table_body>
  """
  attr(:id, :string, required: true)
  attr(:class, :any, default: nil, doc: "Classes of the cell.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def table_empty(assigns) do
    ~H"""
    <tr id={@id} class="hidden only:table-row" {@rest}>
      <td
        colspan="100"
        class={merge(["px-4 py-12 text-center text-slate-400 dark:text-navy-300", @class])}
      >
        {render_slot(@inner_block)}
      </td>
    </tr>
    """
  end

  @doc """
  The selection checkbox the table draws, for a header or row written by hand.
  `indeterminate` draws the dash of a partial selection (it needs an `id`, for its hook).

      <.table_checkbox
        checked={row.id in @selected}
        on_click="select"
        values={%{"id" => row.id, "selected" => to_string(row.id not in @selected)}}
      />

  `on_click` (an event name or a `%JS{}`) is sent with `values` as `phx-value-*`, to
  `target` when given.
  """
  attr(:id, :string, default: nil)
  attr(:checked, :boolean, default: false)
  attr(:indeterminate, :boolean, default: false)
  attr(:label, :string, required: true, doc: "The `aria-label` of the box.")
  attr(:on_click, :any, default: nil)
  attr(:values, :map, default: %{}, doc: "Sent as `phx-value-*` with `on_click`.")
  attr(:target, :any, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def table_checkbox(assigns) do
    assigns =
      assigns
      |> assign(:value_attrs, Map.new(assigns.values, fn {k, v} -> {"phx-value-#{k}", v} end))
      |> assign(:checkbox, @checkbox)

    ~H"""
    <label class="flex">
      <input
        id={@id}
        type="checkbox"
        class={merge([@checkbox, "table-select-all", @class])}
        checked={@checked}
        aria-label={@label}
        phx-hook={@id && "LineaUI.TableSelectAll"}
        data-indeterminate={bool(@indeterminate)}
        phx-click={@on_click}
        phx-target={@target}
        {@value_attrs}
        {@rest}
      />
    </label>
    """
  end

  @doc """
  The chevron button that opens and closes the detail row of the row with DOM id `row_id`,
  for hand-written expandable rows (pair it with `table_detail_row/1`).

      <.table_row id={"order-\#{order.id}"}>
        <:cell>{order.number}</:cell>
        <:cell><.table_expand_toggle row_id={"order-\#{order.id}"} /></:cell>
      </.table_row>
      <.table_detail_row row_id={"order-\#{order.id}"}>{order.notes}</.table_detail_row>

  The toggle runs on the client (`table_toggle_row/2`); `open` sets the starting state.
  Rows that come in pairs need a list, not a stream.
  """
  attr(:row_id, :string, required: true)
  attr(:open, :boolean, default: false)
  attr(:label, :string, default: "Toggle details")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def table_expand_toggle(assigns) do
    assigns = assign(assigns, :expand_button, @expand_button)

    ~H"""
    <button
      type="button"
      class={merge([@expand_button, @class])}
      aria-label={@label}
      aria-expanded={bool(@open)}
      aria-controls={@row_id <> "-detail"}
      phx-click={table_toggle_row(@row_id)}
      {@rest}
    >
      <.glyph
        name={:chevron_down}
        class={["size-3.5 transition-transform", @open && "rotate-180"]}
        stroke_width="2.5"
        data-expand-icon
      />
    </button>
    """
  end

  @doc """
  The detail row under the row with DOM id `row_id`: one cell spanning every column,
  hidden until `table_expand_toggle/1` (or `table_toggle_row/2`) opens it.

      <.table_detail_row row_id="order-1" class="bg-slate-50">Notes...</.table_detail_row>
  """
  attr(:row_id, :string, required: true)
  attr(:open, :boolean, default: false)
  attr(:class, :any, default: nil, doc: "Classes of the detail panel.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def table_detail_row(assigns) do
    ~H"""
    <tr id={@row_id <> "-detail-row"} {@rest}>
      <td colspan="100" class="p-0">
        <div
          id={@row_id <> "-detail"}
          class={merge([!@open && "hidden", "px-4 pb-4 sm:px-5", @class])}
        >
          {render_slot(@inner_block)}
        </div>
      </td>
    </tr>
    """
  end

  @skeleton_widths ~w(w-8/12 w-5/12 w-10/12 w-6/12 w-9/12 w-4/12 w-7/12)

  @doc """
  A table of placeholder rows shown while the real one loads, in the same look.

      <.table_skeleton id="orders-loading" columns={["Number", "Customer", "Total"]} rows={8} variant="hoverable" />
      <.table_skeleton id="loading" cols={4} compact />

  `columns` gives the header labels; without them `cols` header cells are placeholders too.
  """
  attr(:id, :string, required: true)
  attr(:rows, :integer, default: 5, doc: "How many placeholder rows.")
  attr(:columns, :list, default: [], doc: "Header labels; one column each.")
  attr(:cols, :integer, default: 4, doc: "How many columns when `columns` is empty.")

  attr(:variant, :string,
    default: "basic",
    values: ~w(basic bordered hoverable zebra grid)
  )

  attr(:rounded, :string, default: "row", values: ~w(row top none))
  attr(:compact, :boolean, default: false)
  attr(:headless, :boolean, default: false)
  attr(:label, :string, default: "Loading", doc: "The table's `aria-label`.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def table_skeleton(assigns) do
    count = skeleton_columns(assigns)

    assigns =
      assigns
      |> assign(:column_indexes, Enum.to_list(0..(count - 1)//1))
      |> assign(:row_indexes, Enum.to_list(0..(assigns.rows - 1)//1))

    ~H"""
    <.table
      id={@id}
      variant={@variant}
      rounded={@rounded}
      compact={@compact}
      class={@class}
      aria-busy="true"
      aria-label={@label}
      {@rest}
    >
      <thead :if={!@headless}>
        <tr>
          <th :for={index <- @column_indexes}>
            <span :if={@columns != []}>{Enum.at(@columns, index)}</span>
            <.skeleton :if={@columns == []} class="h-3 w-16" />
          </th>
        </tr>
      </thead>
      <tbody>
        <tr :for={row <- @row_indexes}>
          <td :for={column <- @column_indexes}>
            <.skeleton class={["h-3", skeleton_width(row, column)]} />
          </td>
        </tr>
      </tbody>
    </.table>
    """
  end

  defp skeleton_columns(%{columns: [], cols: cols}), do: max(cols, 1)
  defp skeleton_columns(%{columns: columns}), do: length(columns)

  defp skeleton_width(row, column),
    do: Enum.at(@skeleton_widths, rem(row * 3 + column, length(@skeleton_widths)))

  @doc """
  The `JS` that shows or hides the detail panel of the expandable row with DOM id `row_id`
  (the `toggle` the `:expand` slot receives is this, already bound to its row).

      <.button phx-click={table_toggle_row("devs-row-0")}>Details</.button>
  """
  @spec table_toggle_row(JS.t(), String.t()) :: JS.t()
  def table_toggle_row(js \\ %JS{}, row_id) do
    js
    |> JS.toggle(to: "#" <> row_id <> "-detail")
    |> JS.toggle_class("rotate-180", to: "#" <> row_id <> " [data-expand-icon]")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"},
      to: "#" <> row_id <> " [aria-controls]"
    )
  end
end
