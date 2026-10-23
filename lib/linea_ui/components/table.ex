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

  Every event attr takes an event name or a `%JS{}`; `target` sets `phx-target`.

  Expandable rows: an `:expand` slot adds a last column with a chevron that shows a detail
  row under each row (`expand_label` names that column). The slot receives
  `%{row: row, toggle: js}`, `toggle` being the `JS` that opens and closes it. Expandable
  rows render one `<tbody>` per row, so they take a list, not a stream.
  """

  use LineaUI.Component

  alias Phoenix.LiveView.LiveStream

  @wrapper %{
    "basic" => "is-scrollbar-hidden min-w-full overflow-x-auto",
    "bordered" =>
      "is-scrollbar-hidden min-w-full overflow-x-auto rounded-lg border border-slate-200 dark:border-navy-500",
    "hoverable" => "is-scrollbar-hidden min-w-full overflow-x-auto",
    "zebra" => "is-scrollbar-hidden min-w-full overflow-x-auto",
    "grid" => "is-scrollbar-hidden min-w-full overflow-x-auto"
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
  attr(:rows, :any, required: true, doc: "A list or a `@streams.x` stream.")

  attr(:row_id, :any,
    default: nil,
    doc: "A function giving each row's DOM id. Streams default to the stream id."
  )

  attr(:row_click, :any, default: nil, doc: "A function of the row returning a `JS` or an event.")

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

  attr(:target, :any, default: nil, doc: "`phx-target` of the events.")
  attr(:expand_label, :string, default: nil, doc: "Header of the expand column.")
  attr(:wrapper_class, :any, default: nil, doc: "Classes of the scrolling wrapper.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :col, required: true, doc: "A column; receives the row (after `row_item`)." do
    attr(:label, :string, doc: "Header text.")
    attr(:class, :any, doc: "Extra classes of the column's cells.")
    attr(:head_class, :any, doc: "Extra classes of the column's header.")
    attr(:sort_key, :string, doc: "Makes the header sortable; sent as `\"column\"` in `on_sort`.")
  end

  slot(:action, doc: "Cells appended to every row, after the columns.")
  slot(:expand, doc: "Detail shown under a row; receives `%{row: row, toggle: js}`.")
  slot(:empty, doc: "Shown in a full-width row when `rows` is an empty list.")

  def table(assigns) do
    assigns
    |> assign_row_id()
    |> assign_selection()
    |> assign(:th_class, merge([@th[assigns.variant], th_rounded(assigns)]))
    |> assign(:td_class, merge([@td[assigns.variant], td_rounded(assigns)]))
    |> assign(:head_row_class, @head_row[assigns.variant])
    |> assign(:body_row_class, @body_row[assigns.variant])
    |> assign(:wrapper, merge([@wrapper[assigns.variant], assigns.wrapper_class]))
    |> assign(:table_class, merge([table_class(assigns), assigns.class]))
    |> assign(:checkbox, @checkbox)
    |> assign(:expand_button, @expand_button)
    |> render_table()
  end

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

  defp key(%{row_key: nil, row_id: row_id}, row), do: row_id.(row)
  defp key(%{row_key: row_key, row_item: row_item}, row), do: row_key.(row_item.(row))

  defp render_table(%{expand: [_ | _]} = assigns) do
    ~H"""
    <div class={@wrapper}>
      <table id={@id} class={@table_class} {@rest}>
        <.table_head {assigns} />
        <tbody :for={{dom_id, row} <- expand_rows(assigns)} id={dom_id}>
          <tr class="border-y border-transparent">
            <.table_cells {assigns} row={row} />
            <td class={@td_class}>
              <button
                type="button"
                class={@expand_button}
                aria-expanded="false"
                aria-controls={dom_id <> "-detail"}
                phx-click={table_toggle_row(dom_id)}
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="size-3.5 transition-transform"
                  data-expand-icon
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  stroke-width="2.5"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
                </svg>
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
      </table>
    </div>
    """
  end

  defp render_table(assigns) do
    ~H"""
    <div class={@wrapper}>
      <table id={@id} class={@table_class} {@rest}>
        <.table_head {assigns} />
        <tbody
          id={@id <> "-body"}
          phx-update={match?(%LiveStream{}, @rows) && "stream"}
        >
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class={@body_row_class}
            data-selected={@selectable && bool(key(assigns, row) in @selected)}
          >
            <.table_cells {assigns} row={row} />
          </tr>
          <tr :if={@rows == [] and @empty != []} id={@id <> "-empty"}>
            <td colspan="100" class={@td_class}>{render_slot(@empty)}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp table_head(assigns) do
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
          class={merge([@th_class, col[:head_class]])}
          aria-sort={aria_sort(col[:sort_key], @sort_by, @sort_dir)}
        >
          <.sort_header
            :if={col[:sort_key] && @on_sort}
            col={col}
            on_sort={@on_sort}
            target={@target}
            dir={sort_state(col[:sort_key], @sort_by, @sort_dir)}
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
      phx-value-column={@col.sort_key}
      phx-value-direction={next_dir(@dir)}
      phx-target={@target}
    >
      <span class="overflow-hidden text-ellipsis">{@col[:label]}</span>
      <span class="table-sort-icon" data-sort={@dir} aria-hidden="true"></span>
    </button>
    """
  end

  defp table_cells(assigns) do
    ~H"""
    <td :if={@selectable} class={@td_class}>
      <label class="flex">
        <input
          type="checkbox"
          class={@checkbox}
          checked={key(assigns, @row) in @selected}
          aria-label="Select row"
          phx-click={@on_select}
          phx-value-id={key(assigns, @row)}
          phx-value-selected={bool(key(assigns, @row) not in @selected)}
          phx-target={@target}
        />
      </label>
    </td>
    <td
      :for={col <- @col}
      class={merge([@td_class, @row_click && "cursor-pointer", col[:class]])}
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
