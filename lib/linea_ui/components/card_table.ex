defmodule LineaUI.Components.CardTable do
  @moduledoc """
  A compact table: one row per record, each row a small card. It is for long lists (orders, invoices, clients)
  that must stay readable from a wide screen down to a phone, without a horizontal scroll.

      <.card_table id="orders" rows={@streams.orders} on_select="select" on_select_all="select_all" selected={@selected}
        status={&order_status/1}>
        <:col :let={o} label="Order" role="head" width="max-content">{o.number}</:col>
        <:col :let={o} label="Client" role="title" width="minmax(120px,1.3fr)">{o.client}</:col>
        <:col :let={o} label="Issuer" priority={2}>{o.issuer}</:col>
        <:col :let={o} label="Value" role="value" align="end">{o.total}</:col>
        <:col :let={o} label="Status" role="status"><.badge variant="soft" dot>{o.status}</.badge></:col>
        <:col :let={o} label="Balance" priority={1}>{o.balance}</:col>
        <:action :let={o}><.dropdown id={"actions-" <> o.id}>...</.dropdown></:action>
        <:empty>No orders.</:empty>
      </.card_table>

  ## Columns leave by priority

  The table answers to the width of its own box, not of the window (a container query), so it behaves the same
  in a narrow column or beside a sidebar. A column has a `priority`: `0` (default) always stays; `1`, `2` and `3`
  leave, in this order, when the box gets narrower than 1180px, 960px and 720px. What left is not lost: pointing
  at a row (or focusing it) opens a panel under it with the label and the value of every column that is hidden.

  Below 520px the rows become cards of three lines, and the `role` of a column says where it goes: `head` (the
  first line, at the left), `status` (the first line, at the right), `title` (the second line, up to two lines of
  text), `meta` (the third line, at the left) and `value` (the third line, at the right). A column with no `role`
  is not drawn in the card (it is in the panel of the other widths only). The header row is not drawn either, and
  the select all checkbox goes on a line of its own above the list.

  ## Columns

  `width` is the CSS track of the column (`max-content` by default; `minmax(120px,1.3fr)` to let it take what is
  left). `align` is `start` (default) or `end` (numbers). Text is cut with an ellipsis; `truncate={false}` lets
  it wrap. `sort_key` with the table's `on_sort` makes the header a button, as in `table/1`.

  ## Rows

  `rows` is a list or a stream. `status` is a function of the row that returns a color (`success`, `info`,
  `warning`, `error`, `primary`...) for the thin bar at the left of the row, or `nil` for the neutral (input border) bar. `on_select`
  adds a checkbox column (the events and keys work as in `table/1`: `selected`, `row_key`, `on_select_all`).
  `row_attrs` gives extra attributes of a row (`phx-click`, `data-*`).

  The filters above the table and the pager under it are not part of it: build them with `input`, `select`,
  `button` and `pagination`, inside the same `card`.
  """

  use LineaUI.Component

  alias Phoenix.LiveView.LiveStream

  @checkbox "form-checkbox is-basic size-4 rounded-sm border-slate-400/70 checked:border-primary checked:bg-primary hover:border-primary focus:border-primary dark:border-navy-400 dark:checked:border-accent dark:checked:bg-accent dark:hover:border-accent dark:focus:border-accent"

  @roles ~w(head title status meta value)
  @colors ~w(neutral primary secondary accent info success warning error)

  attr :id, :string, required: true

  attr :rows, :any, required: true, doc: "A list or a `@streams.x` stream."

  attr :row_id, :any,
    default: nil,
    doc: "A function giving each row's DOM id. Streams default to the stream id."

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "Maps each row before it is given to the slots."

  attr :row_key, :any,
    default: nil,
    doc: "A function giving the selection key of a row. Defaults to the row's DOM id."

  attr :row_attrs, :any,
    default: nil,
    doc: "A function of the row returning a map of extra attributes of its `<li>`."

  attr :status, :any,
    default: nil,
    doc: "A function of the row returning a color for the bar at the row's left, or `nil`."

  attr :on_select, :any, default: nil, doc: "Event sent when a row checkbox is clicked."
  attr :on_select_all, :any, default: nil, doc: "Event sent by the header checkbox."
  attr :selected, :list, default: [], doc: "The keys of the selected rows."

  attr :all_selected, :boolean,
    default: nil,
    doc: "Whether the header checkbox is checked. Computed for lists; give it for streams."

  attr :select_all_label, :string, default: "Select all rows"
  attr :select_label, :string, default: "Select row"
  attr :on_sort, :any, default: nil, doc: "Event sent when a sortable header is clicked."
  attr :sort_by, :string, default: nil
  attr :sort_dir, :string, default: "asc", values: ~w(asc desc)
  attr :target, :any, default: nil, doc: "`phx-target` of the events."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :col, required: true, doc: "A column; receives the row (after `row_item`)." do
    attr :label, :string, required: true, doc: "Header text, and the label in the hidden panel."
    attr :width, :string, doc: "The CSS grid track of the column. Default `max-content`."
    attr :priority, :integer, doc: "0 (default) stays; 1, 2 and 3 leave at 1180, 960 and 720px."
    attr :role, :string, values: @roles, doc: "Where the column goes in the card below 520px."
    attr :align, :string, values: ~w(start end)
    attr :truncate, :boolean, doc: "Cut the text with an ellipsis (default) or let it wrap."
    attr :class, :any, doc: "Extra classes of the column's cells."
    attr :sort_key, :string, doc: "Makes the header sortable; sent as `\"column\"` in `on_sort`."
  end

  slot :action, doc: "The last cell of every row (a menu button); receives the row."
  slot :empty, doc: "Shown when there are no rows."

  def card_table(assigns) do
    assigns =
      assigns
      |> assign_row_id()
      |> assign(:selectable, assigns.on_select != nil)
      |> assign(:hidable, Enum.any?(assigns.col, &(priority(&1) > 0)))
      |> assign(:tracks, tracks(assigns))
      |> assign(:checkbox, @checkbox)

    assigns = assign(assigns, :all_checked, all_selected(assigns))

    ~H"""
    <div id={@id <> "-box"} class={merge(["linea-ctable", @class])} style={@tracks}>
      <label :if={@selectable} class="linea-ctable-all">
        <input
          type="checkbox"
          class={@checkbox}
          checked={@all_checked}
          phx-click={@on_select_all}
          phx-value-selected={bool(!@all_checked)}
          phx-target={@target}
        />
        <span>{@select_all_label}</span>
      </label>
      <div class="linea-ctable-grid">
        <div class="linea-ctable-head">
          <span :if={@selectable} class="linea-ctable-sel">
            <input
              id={@id <> "-select-all"}
              type="checkbox"
              class={@checkbox}
              checked={@all_checked}
              aria-label={@select_all_label}
              phx-hook="LineaUI.TableSelectAll"
              data-indeterminate={bool(@selected != [] and not @all_checked)}
              phx-click={@on_select_all}
              phx-value-selected={bool(!@all_checked)}
              phx-target={@target}
            />
          </span>
          <span
            :for={col <- @col}
            class={cell_class(col, "linea-ctable-h")}
            data-p={priority(col)}
            data-role={col[:role]}
            aria-sort={aria_sort(col[:sort_key], @sort_by, @sort_dir)}
          >
            <button
              :if={col[:sort_key] && @on_sort}
              type="button"
              class="linea-ctable-sort"
              phx-click={@on_sort}
              phx-value-column={col.sort_key}
              phx-value-direction={next_dir(sort_state(col.sort_key, @sort_by, @sort_dir))}
              phx-target={@target}
            >
              {col.label}
              <span
                class="table-sort-icon"
                data-sort={sort_state(col.sort_key, @sort_by, @sort_dir)}
                aria-hidden="true"
              ></span>
            </button>
            <span :if={!(col[:sort_key] && @on_sort)}>{col.label}</span>
          </span>
          <span :if={@action != []} class="linea-ctable-act"></span>
        </div>
        <ul id={@id} phx-update={match?(%LiveStream{}, @rows) && "stream"} {@rest}>
          <li
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class="linea-ctable-row"
            tabindex="0"
            data-status={status_of(assigns, row)}
            data-selected={@selectable && bool(key(assigns, row) in @selected)}
            {row_attrs(assigns, row)}
          >
            <span :if={@selectable} class="linea-ctable-sel">
              <input
                type="checkbox"
                class={@checkbox}
                checked={key(assigns, row) in @selected}
                aria-label={@select_label}
                phx-click={@on_select}
                phx-value-id={key(assigns, row)}
                phx-value-selected={bool(key(assigns, row) not in @selected)}
                phx-target={@target}
              />
            </span>
            <div
              :for={col <- @col}
              class={cell_class(col, "linea-ctable-cell")}
              data-p={priority(col)}
              data-role={col[:role]}
            >
              {render_slot(col, @row_item.(row))}
            </div>
            <div :if={@action != []} class="linea-ctable-act">
              {render_slot(@action, @row_item.(row))}
            </div>
            <dl :if={@hidable} class="linea-ctable-pop" role="tooltip">
              <div :for={col <- hidden(@col)} data-p={priority(col)}>
                <dt>{col.label}</dt>
                <dd>{render_slot(col, @row_item.(row))}</dd>
              </div>
            </dl>
          </li>
          <li
            :if={@empty != [] and (@rows == [] or stream?(@rows))}
            id={@id <> "-empty"}
            class={["linea-ctable-empty", stream?(@rows) && "hidden only:block"]}
          >
            {render_slot(@empty)}
          </li>
        </ul>
      </div>
    </div>
    """
  end

  defp priority(col), do: col[:priority] || 0

  defp hidden(cols), do: Enum.filter(cols, &(priority(&1) > 0))

  defp cell_class(col, base) do
    merge([
      base,
      col[:align] == "end" && "justify-self-end text-right",
      col[:truncate] == false && "is-wrap",
      col[:class]
    ])
  end

  # The four templates of the grid, one per width: the tracks of the columns still shown at that width. The CSS
  # picks one by container query; below 520px it has its own.
  defp tracks(assigns) do
    sel = if assigns.on_select, do: ["2.75rem"], else: []
    act = if assigns.action != [], do: ["2.75rem"], else: []

    regimes =
      Enum.map(0..3, fn regime ->
        cols =
          assigns.col
          |> Enum.filter(&(priority(&1) == 0 or priority(&1) > regime))
          |> Enum.map(&(&1[:width] || "max-content"))

        "--ct-c#{regime}:" <> Enum.join(sel ++ cols ++ act, " ")
      end)

    ends = Enum.map(sel, &"--ct-sel:#{&1}") ++ Enum.map(act, &"--ct-act:#{&1}")
    Enum.join(regimes ++ ends, ";")
  end

  defp assign_row_id(%{rows: %LiveStream{}, row_id: nil} = assigns),
    do: assign(assigns, :row_id, fn {id, _item} -> id end)

  defp assign_row_id(%{row_id: nil, id: id} = assigns),
    do: assign(assigns, :row_id, fn row -> id <> "-" <> to_string(:erlang.phash2(row)) end)

  defp assign_row_id(assigns), do: assigns

  defp stream?(%LiveStream{}), do: true
  defp stream?(_rows), do: false

  defp all_selected(%{all_selected: value}) when is_boolean(value), do: value
  defp all_selected(%{rows: %LiveStream{}}), do: false
  defp all_selected(%{on_select: nil}), do: false

  defp all_selected(%{rows: rows, selected: selected} = assigns) do
    keys = Enum.map(rows, &key(assigns, &1))
    keys != [] and Enum.all?(keys, &(&1 in selected))
  end

  defp key(%{row_key: nil, row_id: row_id}, row), do: row_id.(row)
  defp key(%{row_key: row_key, row_item: row_item}, row), do: row_key.(row_item.(row))

  defp status_of(%{status: nil}, _row), do: nil

  defp status_of(%{status: fun, row_item: row_item}, row) do
    case fun.(row_item.(row)) do
      color when is_atom(color) and not is_nil(color) -> valid_color(Atom.to_string(color))
      color when is_binary(color) -> valid_color(color)
      _none -> nil
    end
  end

  defp valid_color(color) when color in @colors, do: color
  defp valid_color(_color), do: nil

  defp row_attrs(%{row_attrs: nil}, _row), do: %{}
  defp row_attrs(%{row_attrs: fun, row_item: row_item}, row), do: fun.(row_item.(row))

  defp aria_sort(nil, _sort_by, _dir), do: nil
  defp aria_sort(key, key, "asc"), do: "ascending"
  defp aria_sort(key, key, "desc"), do: "descending"
  defp aria_sort(_key, _sort_by, _dir), do: "none"

  defp sort_state(key, key, dir), do: dir
  defp sort_state(_key, _sort_by, _dir), do: "none"

  defp next_dir("asc"), do: "desc"
  defp next_dir(_dir), do: "asc"
end
