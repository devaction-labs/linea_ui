defmodule LineaUI.Components.CardTable do
  @moduledoc """
  A compact table: one row per record, in a card with a header row and a thin status bar at the left of each row. It is for long lists (orders, invoices, clients)
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

  ## Heading

  `title`, `description` and `<:actions>` draw a heading above the table, so a list needs no card around it to
  say what it is and how to add to it:

      <.card_table id="portal" rows={@users} title="Portal access" description="Who can see the orders." ...>
        <:actions><.button size="sm">Invite</.button></:actions>
        ...
      </.card_table>

      <.card_table id="orders" title="Pedidos" meta="128 no período" rows={@orders} ...>
        <:actions><.link navigate={~p"/orders"}>Ver todos</.link></:actions>
        ...
      </.card_table>

  `meta` is a small muted text on the same line as the title, right after it. A plain link (or any `<a>`
  with no class) in `<:actions>` is drawn quiet, in the same muted style, pushed to the right: the line reads
  `Pedidos  128 no período ........................ Ver todos`. A `<.button>` keeps its own look.

  ## Footer

  `<:foot>` is a line inside the card, under the rows, set off by a hairline: the place for the pager or a
  total. Its content is laid out in a wrapping row with the parts spread to the two ends:

      <.card_table id="orders" rows={@orders} ...>
        <:col ...>...</:col>
        <:foot>
          <span>Mostrando 1–6 de 128 · 25 / página</span>
          <.pagination ... />
        </:foot>
      </.card_table>

  ## Columns leave by priority

  The table answers to the width of its own box, not of the window (a container query), so it behaves the same
  in a narrow column or beside a sidebar. A column has a `priority`: `0` (default) always stays; `1`, `2` and `3`
  leave, in this order, when the box gets narrower than 1180px, 960px and 720px. What left is not lost: hovering a row (or
  tabbing to it) opens a panel under it with the label and the value of every column that is hidden.

  `breakpoints` changes those widths: one integer (px) per priority level, in descending order, and the width of
  the card layout last. The default is `[1180, 960, 720, 520]`. A table with four priority levels, whose
  card layout starts under 560px:

      <.card_table id="orders" breakpoints={[1180, 980, 760, 640, 560]} ...>
        <:col :let={o} label="Issuer" priority={4}>{o.issuer}</:col>

  gives 1 under 1180px, 2 under 980px, 3 under 760px, 4 under 640px and the cards under 560px. Between 2 and 5 integers
  (1 to 4 priority levels), strictly descending; anything else raises `ArgumentError`. Container queries cannot read
  CSS variables, so a table with other widths than the default renders a small `<style>` scoped to its own id (the same
  every render, so nothing is sent again over the socket). A priority above the levels of the list never leaves.

  Below 520px (the last of `breakpoints`) the table is one card with a compact two-line grid per row, a hairline
  between rows, and the `role` of a column says where it goes: `head` (first line, left; drawn in mono), `status`
  (first line, right), `title` (second line, left, up to two lines: a name and a sub line) and `value` (second
  line, right). The checkbox, if any, sits at the left of both lines. A column with no `role`, `meta` and the
  action column are not drawn in the card (the board has no third line). The header row and the panel are not
  drawn; "select all" is kept for screen readers and the keyboard only (a visually hidden checkbox that shows when
  it has focus).

  ## The details panel

  Clicking a row (or tapping it) opens a panel under it with more than the row shows: a list of label and value, one
  line each. Hovering never opens it. The panel's left edge sits at the click (16px to its left), kept 8px inside
  both sides of the row, and it does not follow the pointer afterwards. The text of the panel can be selected and
  copied, and a click inside it keeps it open. It closes on a second click on the row, on `Esc` (the focus goes back to the
  row), on a click outside the table, and on a click on any control of the row (link, button, check box, copy button,
  action menu), which does its own thing. A click on another row moves the panel there. From the keyboard, `Enter` or
  `Space` on a focused row toggles it, at a fixed anchor (96px from the left of the row, 72px under 720px) since there is no pointer.
  The row carries `aria-expanded` and `data-open` (which the CSS uses). The last two rows open it upwards. The
  `CardTable` hook (`LineaUI.CardTable`, on the rows' list) does this; without it the panel never opens.
  Give `detail` slots (`<:detail :let={o} label="Due date">{o.due}</:detail>`) and the panel lists them first, in
  the order given, at every width above 520px, then the columns that left at the current width (each shows only
  once its priority has left; a column with the same label as a `detail` is not listed again). With no `detail`, the panel only has the columns that left. Below 520px there is no panel: the card shows what the roles place.

  A column may have an empty `label` (a number or copy column with no header text), and `<:action priority={3}>`
  makes the action column leave like a column of that priority.

  ## Copy button

  `copy` on a column (a function of the row that returns the text) turns its cell into a copy button, as in the
  order number of the design. Its tooltip shows the text it copies and, for two seconds after a copy, `copied_label`
  (`copy_label` is the button's accessible name). The column's own content stays visible only in the card, where
  there is no tooltip. The button shows a check while it says `copied_label` (two seconds).

  `copy_show="inline"` keeps the column's own content visible before the button at every width, 8px apart
  (`ORD-2041 [copy]`), instead of only in the card:

      <:col :let={o} label="Pedido" role="head" copy={& &1.number} copy_show="inline"
        copy_label="Copiar número">{o.number}</:col>

  `copy_tip="value_label"` changes the tooltip to the value in bold mono, a dot, and the label in the text font:
  `ORD-2041 · Copiar número`, and after the copy `ORD-2041 · Número copiado`:

      <:col :let={o} label="Pedido" role="head" copy={& &1.number} copy_tip="value_label"
        copy_label="Copiar número" copied_label="Número copiado">{o.number}</:col>

  ## Sub lines

  `<.ctable_sub>` is a second line inside a cell (12px, faint) that leaves by its own `priority`, with the same
  widths as the columns (default or custom `breakpoints`), while the cell stays. No priority: always shown. The
  panel of a row lists whole columns, so a sub line inside a column that left is shown there.

      <:col :let={o} label="Cliente" role="title" width="minmax(120px,1.3fr)">
        {o.client}
        <.ctable_sub priority={2}>{o.issuer}</.ctable_sub>
      </:col>
      <:col :let={o} label="Valor" role="value" align="end">
        {o.total}
        <.ctable_sub priority={1}>saldo {o.balance} · {o.pending} pend.</.ctable_sub>
      </:col>

  ## Columns

  `width` is the CSS track of the column (`max-content` by default; `minmax(120px,1.3fr)` to let it take what is
  left). `align` is `start` (default) or `end` (numbers). Text is cut with an ellipsis; `truncate={false}` lets
  it wrap. `sort_key` with the table's `on_sort` makes the header a button, as in `table/1`.

  ## Rows

  `rows` is a list or a stream. `status` is a function of the row that returns a color (`success`, `info`,
  `warning`, `error`, `primary`...) for the thin bar at the left of the row, or `nil` for the neutral (input border) bar. `on_select`
  adds a checkbox column (the events and keys work as in `table/1`: `selected`, `row_key`, `on_select_all`).
  `row_attrs` gives extra attributes of a row (`phx-click`, `data-*`).

  ## Flat

  `variant="flat"` is the canvas card table: a plain table in a card (`sg-card flush` and `sg-table`), for
  short lists on a dashboard ("Últimos pedidos", "Maiores clientes"). The `title` and `<:actions>` (a "Ver
  todos" link, drawn quiet) head the card; `<:top>` takes the place of the heading (tabs that filter the
  table). Columns keep `label`, `align` and `class`; the priorities, the panel, the selection and the cards
  below 520px belong to the default variant. `description` goes under the title and `<:foot>` under the table
  (a "Total" line), as in the default variant.

      <.card_table id="last" variant="flat" title="Últimos pedidos" rows={@orders}>
        <:actions><.link navigate={~p"/orders"}>Ver todos</.link></:actions>
        <:col :let={o} label="Pedido">{o.number}</:col>
        <:col :let={o} label="Total" align="end">{o.total}</:col>
      </.card_table>

  The filters above the table and the pager under it are not part of it: build them with `input`, `select`,
  `button` and `pagination`, inside the same `card`.
  """

  use LineaUI.Component

  import LineaUI.Components.Clipboard, only: [clipboard: 1]

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
  attr :panel_label, :string, default: "Details", doc: "The accessible name of the details panel."
  attr :on_sort, :any, default: nil, doc: "Event sent when a sortable header is clicked."
  attr :sort_by, :string, default: nil
  attr :sort_dir, :string, default: "asc", values: ~w(asc desc)
  attr :target, :any, default: nil, doc: "`phx-target` of the events."

  attr :title, :string,
    default: nil,
    doc: "A heading drawn above the table, with `description` and `<:actions>`."

  attr :description, :string, default: nil, doc: "A line under the `title`."

  attr :meta, :string,
    default: nil,
    doc:
      "A small muted text on the same line as the `title`, right after it (\"128 no período\"). Default variant only."

  attr :breakpoints, :list,
    default: [1180, 960, 720, 520],
    doc:
      "The widths (px) at which each priority level leaves, descending, and the width of the card layout last. 2 to 5 integers; `[1180, 980, 760, 640, 560]` gives priorities 1 to 4 and cards under 560px. Default variant only."

  attr :variant, :string,
    default: "rows",
    values: ~w(rows flat),
    doc:
      "`rows` (default) draws one row per record in a card; `flat` a plain table in a card, as the canvas."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions, doc: "Buttons at the right of the heading (`title`, `description`)."

  slot :foot,
    doc:
      "A line inside the card, under the rows, set off by a hairline (pagination, a total). Wraps, with its parts spread to both ends."

  slot :top, doc: "With `variant=\"flat\"`, what heads the card instead of the title (tabs)."

  slot :col, required: true, doc: "A column; receives the row (after `row_item`)." do
    attr :label, :string,
      doc: "Header text, and the label in the hidden panel. May be empty (a copy/number column)."

    attr :width, :string, doc: "The CSS grid track of the column. Default `max-content`."

    attr :priority, :integer,
      doc:
        "0 (default) stays; 1, 2 and 3 leave at 1180, 960 and 720px (4 too, with a 5-value `breakpoints`)."

    attr :role, :string, values: @roles, doc: "Where the column goes in the card below 520px."
    attr :align, :string, values: ~w(start end)
    attr :truncate, :boolean, doc: "Cut the text with an ellipsis (default) or let it wrap."
    attr :class, :any, doc: "Extra classes of the column's cells."
    attr :sort_key, :string, doc: "Makes the header sortable; sent as `\"column\"` in `on_sort`."

    attr :copy, :any,
      doc:
        "A function of the row returning the text to copy; the cell becomes a copy button with a tooltip."

    attr :copy_label, :string, doc: "The accessible name of the copy button. Default `Copy`."

    attr :copied_label, :string,
      doc: "What the tooltip says for two seconds after a copy. Default `Copied`."

    attr :copy_show, :string,
      values: ~w(card inline),
      doc:
        "`card` (default): the column's own content shows only in the card layout. `inline`: it shows before the button at every width (`ORD-2041 [copy]`)."

    attr :copy_tip, :string,
      values: ~w(value value_label),
      doc:
        "`value` (default): the tooltip shows the value, then `copied_label`. `value_label`: `VALUE · copy_label`, then `VALUE · copied_label`."
  end

  slot :detail,
    doc:
      "A line of the panel that opens when a row is clicked; receives the row. When given, the panel lists these and not the hidden columns." do
    attr :label, :string, required: true
  end

  slot :action, doc: "The last cell of every row (a menu button); receives the row." do
    attr :priority, :integer,
      doc: "Like a column's: the action column leaves at that level (e.g. 3). Default 0."
  end

  slot :empty, doc: "Shown when there are no rows."

  def card_table(%{variant: "flat"} = assigns) do
    assigns = assign_row_id(assigns)

    ~H"""
    <div class={merge(["sg-card flush linea-ctable-flat", @class])} id={@id <> "-box"}>
      <div :if={@top != []} class="linea-ctable-flat-top">{render_slot(@top)}</div>
      <div
        :if={@top == [] and (@title || @actions != [])}
        class="sg-card-h linea-ctable-flat-h"
      >
        <h3 :if={@title && !@description}>{@title}</h3>
        <div :if={@title && @description} class="linea-ctable-flat-text">
          <h3>{@title}</h3>
          <p>{@description}</p>
        </div>
        <div :if={@actions != []} class="meta ml-auto flex items-center gap-2">
          {render_slot(@actions)}
        </div>
      </div>
      <table class="sg-table">
        <thead>
          <tr>
            <th :for={col <- @col} class={col[:align] == "end" && "r"}>{col[:label]}</th>
            <th :if={@action != []}><span class="sr-only">{@panel_label}</span></th>
          </tr>
        </thead>
        <tbody id={@id} phx-update={match?(%LiveStream{}, @rows) && "stream"} {@rest}>
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            {row_attrs(@row_attrs, @row_item, row)}
          >
            <td :for={col <- @col} class={merge([col[:align] == "end" && "r", col[:class]])}>
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="r">{render_slot(@action, @row_item.(row))}</td>
          </tr>
          <tr :if={@empty != [] and @rows == []} id={@id <> "-empty"}>
            <td colspan={length(@col) + if(@action != [], do: 1, else: 0)}>{render_slot(@empty)}</td>
          </tr>
        </tbody>
      </table>
      <div :if={@foot != []} class="linea-ctable-foot">{render_slot(@foot)}</div>
    </div>
    """
  end

  def card_table(assigns) do
    assigns =
      assigns
      |> assign_row_id()
      |> assign_derived(:selectable, [:on_select], fn -> assigns.on_select != nil end)
      |> assign_derived(:hidable, [:col], fn -> Enum.any?(assigns.col, &(priority(&1) > 0)) end)
      |> assign_derived(:tracks, [:on_select, :action, :col], fn -> tracks(assigns) end)
      |> assign_derived(:checkbox, [], fn -> @checkbox end)
      |> assign_derived(:bp_css, [:breakpoints, :id], fn ->
        breakpoints_css(assigns.id, assigns.breakpoints)
      end)

    assigns =
      assign_derived(
        assigns,
        :all_checked,
        [:all_selected, :rows, :on_select, :selected, :row_key, :row_id, :row_item, :id],
        fn -> all_selected(assigns) end
      )

    ~H"""
    <div
      id={@id <> "-box"}
      class={merge(["linea-ctable", @class])}
      style={@tracks}
    >
      <style :if={@bp_css}>
        <%= Phoenix.HTML.raw(@bp_css) %>
      </style>
      <div :if={@title || @meta || @description || @actions != []} class="linea-ctable-top">
        <div class="linea-ctable-top-text">
          <div :if={@meta} class="linea-ctable-title-row">
            <h3 :if={@title} class="linea-ctable-title">{@title}</h3>
            <span class="linea-ctable-meta">{@meta}</span>
          </div>
          <h3 :if={@title && !@meta} class="linea-ctable-title">{@title}</h3>
          <p :if={@description} class="linea-ctable-desc">{@description}</p>
        </div>
        <div :if={@actions != []} class="linea-ctable-top-act">{render_slot(@actions)}</div>
      </div>
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
              {col[:label]}
              <span
                class="table-sort-icon"
                data-sort={sort_state(col.sort_key, @sort_by, @sort_dir)}
                aria-hidden="true"
              ></span>
            </button>
            <span :if={!(col[:sort_key] && @on_sort)}>{col[:label]}</span>
          </span>
          <span
            :if={@action != []}
            class="linea-ctable-act"
            data-p={action_priority(@action)}
          ></span>
        </div>
        <ul
          id={@id}
          phx-hook="LineaUI.CardTable"
          phx-update={match?(%LiveStream{}, @rows) && "stream"}
          {@rest}
        >
          <%= if stream?(@rows) do %>
            <.card_row
              :for={row <- @rows}
              row={row}
              key={@selectable && key(@row_key, @row_id, @row_item, row)}
              selected={@selectable && key(@row_key, @row_id, @row_item, row) in @selected}
              row_id={@row_id}
              hidable={@hidable}
              detail={@detail}
              status={@status}
              row_item={@row_item}
              row_attrs={@row_attrs}
              selectable={@selectable}
              checkbox={@checkbox}
              select_label={@select_label}
              on_select={@on_select}
              target={@target}
              col={@col}
              action={@action}
              panel_label={@panel_label}
            />
          <% else %>
            <.card_row
              :for={
                {row, key, selected} <-
                  list_rows(@rows, @row_id, {@selectable, @selected, @row_key, @row_item})
              }
              row={row}
              key={key}
              selected={selected}
              row_id={@row_id}
              hidable={@hidable}
              detail={@detail}
              status={@status}
              row_item={@row_item}
              row_attrs={@row_attrs}
              selectable={@selectable}
              checkbox={@checkbox}
              select_label={@select_label}
              on_select={@on_select}
              target={@target}
              col={@col}
              action={@action}
              panel_label={@panel_label}
            />
          <% end %>
          <li
            :if={@empty != [] and (@rows == [] or stream?(@rows))}
            id={@id <> "-empty"}
            class={["linea-ctable-empty", stream?(@rows) && "hidden only:block"]}
          >
            {render_slot(@empty)}
          </li>
        </ul>
      </div>
      <div :if={@foot != []} class="linea-ctable-foot">{render_slot(@foot)}</div>
    </div>
    """
  end

  attr :priority, :integer,
    default: nil,
    doc: "1 to 4: the sub line leaves at the width where the columns of that priority leave."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A second line inside a `card_table` cell that leaves by `priority`. See the moduledoc."
  def ctable_sub(assigns) do
    ~H"""
    <span class={merge(["linea-ctable-sub", @class])} data-p={@priority} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  # One row of the card table; its selection and key come in as comprehension variables, so
  # toggling a row re-renders that row only.
  defp card_row(assigns) do
    ~H"""
    <li
      id={@row_id && @row_id.(@row)}
      class="linea-ctable-row"
      tabindex="0"
      aria-expanded={(@hidable or @detail != []) && "false"}
      phx-mounted={
        (@hidable or @detail != []) && JS.ignore_attributes(["style", "data-open", "aria-expanded"])
      }
      data-status={status_of(@status, @row_item, @row)}
      data-selected={@selectable && bool(@selected)}
      {row_attrs(@row_attrs, @row_item, @row)}
    >
      <span :if={@selectable} class="linea-ctable-sel">
        <input
          type="checkbox"
          class={@checkbox}
          checked={@selected}
          aria-label={@select_label}
          phx-click={@on_select}
          phx-value-id={@key}
          phx-value-selected={bool(not @selected)}
          phx-target={@target}
        />
      </span>
      <div
        :for={col <- @col}
        class={cell_class(col, "linea-ctable-cell")}
        data-p={priority(col)}
        data-role={col[:role]}
      >
        <%= if col[:copy] do %>
          <span class="linea-ctable-nn" data-show={col[:copy_show] == "inline" && "inline"}>{render_slot(
            col,
            @row_item.(@row)
          )}</span>
          <span class="linea-ctable-cpw">
            <.clipboard
              id={"#{@row_id.(@row)}-copy"}
              value={col.copy.(@row_item.(@row))}
              icon_only
              size="xs"
              variant="outline"
              toast={nil}
              class="linea-ctable-cp"
              aria-label={col[:copy_label] || "Copy"}
            />
            <span
              class="linea-ctable-ctip"
              role="tooltip"
              data-tip={col[:copy_tip] == "value_label" && "value_label"}
            >
              <%= if col[:copy_tip] == "value_label" do %>
                <span class="l1">
                  <b>{col.copy.(@row_item.(@row))}</b> · {col[:copy_label] || "Copy"}
                </span>
                <span class="l2">
                  <b>{col.copy.(@row_item.(@row))}</b> · {col[:copied_label] || "Copied"}
                </span>
              <% else %>
                <span class="l1">{col.copy.(@row_item.(@row))}</span>
                <span class="l2">{col[:copied_label] || "Copied"}</span>
              <% end %>
            </span>
          </span>
        <% else %>
          {render_slot(col, @row_item.(@row))}
        <% end %>
      </div>
      <div :if={@action != []} class="linea-ctable-act" data-p={action_priority(@action)}>
        {render_slot(@action, @row_item.(@row))}
      </div>
      <dl
        :if={@hidable or @detail != []}
        class="linea-ctable-pop"
        data-detail={@detail != [] && ""}
        aria-label={@panel_label}
      >
        <div :for={detail <- @detail} data-d>
          <dt>{detail.label}</dt>
          <dd>{render_slot(detail, @row_item.(@row))}</dd>
        </div>
        <div :for={col <- hidden(@col, @detail)} data-p={priority(col)}>
          <dt>{col[:label]}</dt>
          <dd>{render_slot(col, @row_item.(@row))}</dd>
        </div>
      </dl>
    </li>
    """
  end

  defp priority(col), do: col[:priority] || 0

  defp action_priority([action | _]), do: priority(action)

  # A hidden column whose label a `detail` slot already uses is not listed twice.
  defp hidden(cols, details) do
    labels = MapSet.new(details, & &1.label)
    Enum.filter(cols, &(priority(&1) > 0 and not MapSet.member?(labels, &1[:label])))
  end

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
    levels = max(length(assigns.breakpoints) - 1, 3)
    sel = if assigns.on_select, do: ["2.75rem"], else: []
    act = if assigns.action != [], do: ["2.75rem"], else: []
    act_priority = if assigns.action != [], do: action_priority(assigns.action), else: 0

    regimes =
      Enum.map(0..levels, fn regime ->
        act = if act_priority == 0 or act_priority > regime, do: act, else: []

        cols =
          assigns.col
          |> Enum.filter(&(priority(&1) == 0 or priority(&1) > regime))
          |> Enum.map(&(&1[:width] || "max-content"))

        "--ct-c#{regime}:" <> Enum.join(sel ++ cols ++ act, " ")
      end)

    ends = Enum.map(sel, &"--ct-sel:#{&1}") ++ Enum.map(act, &"--ct-act:#{&1}")
    Enum.join(regimes ++ ends, ";")
  end

  @default_breakpoints [1180, 960, 720, 520]

  # The CSS of a table with other widths than the default: the same blocks as the container queries of data.css,
  # under a container name of its own, keyed to the box's id. The box keeps `ctable` (for an app's own container
  # variants) but loses `ctable-d`, the name only the default queries of data.css ask for. `&` stands for the box's selector.
  defp breakpoints_css(_id, @default_breakpoints), do: nil

  defp breakpoints_css(id, breakpoints) do
    valid? =
      is_list(breakpoints) and length(breakpoints) in 2..5 and
        Enum.all?(breakpoints, &(is_integer(&1) and &1 > 0)) and
        breakpoints == Enum.sort(Enum.uniq(breakpoints), :desc)

    unless valid? do
      raise ArgumentError,
            "card_table: breakpoints must be 2 to 5 positive integers in descending order " <>
              "(one per priority level, then the card width), got: #{inspect(breakpoints)}"
    end

    box = ~s([id="#{css_escape(id <> "-box")}"])
    name = "ct-" <> css_escape(id)
    {widths, [card]} = Enum.split(breakpoints, -1)
    levels = length(widths)

    levels_css =
      widths
      |> Enum.with_index(1)
      |> Enum.map_join("\n", fn {width, k} ->
        pop_left =
          if k == min(levels, 3),
            do:
              "& .linea-ctable-pop { left: var(--ct-pop-x, 72px); max-width: calc(100% - 88px); }\n",
            else: ""

        """
        @container #{name} (max-width: #{width - 0.02}px) {
        & .linea-ctable-grid { grid-template-columns: var(--ct-c#{k}); }
        & [data-p="#{k}"].linea-ctable-cell, & [data-p="#{k}"].linea-ctable-h, & [data-p="#{k}"].linea-ctable-act, & .linea-ctable-cell [data-p="#{k}"].linea-ctable-sub { display: none; }
        & .linea-ctable-pop:has(> [data-p="#{k}"]) { display: flex; }
        & .linea-ctable-pop > [data-p="#{k}"] { display: flex; }
        & .linea-ctable-row:has(> .linea-ctable-pop > [data-p="#{k}"]) { cursor: pointer; }
        #{pop_left}}
        """
      end)

    card_css = """
    @container #{name} (max-width: #{card - 0.02}px) {
    & .linea-ctable-all { position: absolute; display: flex; width: 1px; height: 1px; padding: 0; border: 0; overflow: hidden; clip-path: inset(50%); }
    & .linea-ctable-all:focus-within { position: static; width: auto; height: auto; padding: 10px 14px 10px 16px; border-bottom: 1px solid var(--line); clip-path: none; }
    & .linea-ctable-head { display: none; }
    & .linea-ctable-top { border-bottom: 1px solid var(--line); }
    & .linea-ctable-top-text { flex-basis: 100%; }
    & .linea-ctable-top-act { flex: 1 1 100%; justify-content: stretch; }
    & .linea-ctable-top-act > :not(.sg-btn):not(a) { flex: 1 1 100%; width: auto !important; max-width: 100%; }
    & .linea-ctable-top-act > .sg-btn { flex: 1 1 auto !important; }
    & .linea-ctable-grid { grid-template-columns: auto minmax(0, 1fr) max-content; column-gap: 0; }
    & .linea-ctable-row { grid-template-areas: "sel head status" "sel title value"; row-gap: 4px; min-height: 0; padding: 12px 14px 12px 16px; }
    & .linea-ctable-row > .linea-ctable-cell { display: none; }
    & .linea-ctable-row > .linea-ctable-act { display: none; }
    & .linea-ctable-row > .linea-ctable-sel { grid-area: sel; align-self: start; margin: 2px 10px 0 0; }
    & .linea-ctable-row > .linea-ctable-cell[data-role="head"] { display: block; grid-area: head; font: 500 12.5px var(--mono); color: var(--ink); }
    & .linea-ctable-row > .linea-ctable-cell[data-role="status"] { display: block; grid-area: status; justify-self: end; padding-left: 10px; }
    & .linea-ctable-row > .linea-ctable-cell[data-role="value"] { display: block; grid-area: value; justify-self: end; align-self: end; padding-left: 10px; }
    & .linea-ctable-row > .linea-ctable-cell[data-role="title"] { display: -webkit-box; grid-area: title; white-space: normal; -webkit-line-clamp: 2; -webkit-box-orient: vertical; }
    & .linea-ctable-pop { display: none !important; }
    & .linea-ctable-row { cursor: auto !important; }
    & .linea-ctable-nn { display: inline; }
    & .linea-ctable-cpw { display: none; }
    }
    """

    css = (levels_css <> "\n" <> card_css) |> String.replace("&", box)
    "#{box}.linea-ctable { container-name: ctable #{name}; }\n" <> css
  end

  defp css_escape(string) do
    for <<c::utf8 <- string>>, into: "" do
      if c in ?a..?z or c in ?A..?Z or c in ?0..?9 or c in [?-, ?_],
        do: <<c>>,
        else: "\\" <> Integer.to_string(c, 16) <> " "
    end
  end

  defp assign_row_id(%{rows: %LiveStream{}, row_id: nil} = assigns),
    do: assign_derived(assigns, :row_id, [:row_id], fn -> &stream_dom_id/1 end)

  defp assign_row_id(%{row_id: nil, id: id} = assigns),
    do:
      assign_derived(assigns, :row_id, [:row_id, :id], fn ->
        fn row -> id <> "-" <> to_string(:erlang.phash2(row)) end
      end)

  defp assign_row_id(assigns), do: assigns

  defp stream_dom_id({id, _item}), do: id

  # `{row, key, selected}` of each row of a list.
  defp list_rows(rows, row_id, selection) do
    Enum.map(rows, fn row ->
      {key, selected} = selection(selection, row_id, row)
      {row, key, selected}
    end)
  end

  defp selection({false, _selected, _row_key, _row_item}, _row_id, _row), do: {nil, false}

  defp selection({true, selected, row_key, row_item}, row_id, row) do
    key = key(row_key, row_id, row_item, row)
    {key, key in selected}
  end

  defp stream?(%LiveStream{}), do: true
  defp stream?(_rows), do: false

  defp all_selected(%{all_selected: value}) when is_boolean(value), do: value
  defp all_selected(%{rows: %LiveStream{}}), do: false
  defp all_selected(%{on_select: nil}), do: false

  defp all_selected(%{rows: rows, selected: selected} = assigns) do
    keys = Enum.map(rows, &key(assigns.row_key, assigns.row_id, assigns.row_item, &1))
    keys != [] and Enum.all?(keys, &(&1 in selected))
  end

  defp key(nil, row_id, _row_item, row), do: row_id.(row)
  defp key(row_key, _row_id, row_item, row), do: row_key.(row_item.(row))

  defp status_of(nil, _row_item, _row), do: nil

  defp status_of(fun, row_item, row) do
    case fun.(row_item.(row)) do
      color when is_atom(color) and not is_nil(color) -> valid_color(Atom.to_string(color))
      color when is_binary(color) -> valid_color(color)
      _none -> nil
    end
  end

  defp valid_color(color) when color in @colors, do: color
  defp valid_color(_color), do: nil

  defp row_attrs(nil, _row_item, _row), do: %{}
  defp row_attrs(fun, row_item, row), do: fun.(row_item.(row))

  defp aria_sort(nil, _sort_by, _dir), do: nil
  defp aria_sort(key, key, "asc"), do: "ascending"
  defp aria_sort(key, key, "desc"), do: "descending"
  defp aria_sort(_key, _sort_by, _dir), do: "none"

  defp sort_state(key, key, dir), do: dir
  defp sort_state(_key, _sort_by, _dir), do: "none"

  defp next_dir("asc"), do: "desc"
  defp next_dir(_dir), do: "asc"
end
