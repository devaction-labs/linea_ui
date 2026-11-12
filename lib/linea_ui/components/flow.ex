defmodule LineaUI.Components.Flow do
  @moduledoc """
  A workflow editor: steps (a trigger, an agent, an action, a human approval) on a dotted board, joined by
  connections that carry the condition of each branch, with a bar of actions at the bottom and the
  configuration panel of a step on the right. It is the canvas's `Flow`.

      <.flow id="triage" edges={@edges} on_add="add_node" aria-label="Exception triage">
        <:node id="in" kind="Trigger" kind_icon="huge-flash" icon="huge-mail-01" title="Invoice received"
               metrics={[%{label: "runs", value: "1,284/wk", href: ~p"/runs/in"}]}>
          <.flow_section label="Event">An invoice arrives at the inbox or by the ERP webhook.</.flow_section>
        </:node>
        <:node id="match" kind="Agent" kind_icon="huge-sparkles" icon="huge-sparkles" title="Check and match">
          <.flow_section label="Tools">
            <.flow_chips><.flow_chip>erp.lookup</.flow_chip><.flow_chip>ocr.extract</.flow_chip></.flow_chips>
          </.flow_section>
        </:node>
        <:node id="post" kind="Action" kind_icon="huge-sent" icon="huge-file-01" title="Post to finance" />
        <:node id="gate" kind="Approval" kind_icon="huge-user" icon="huge-security-check" title="Approval" selected />

        <:actions :let={id}>
          <.button icon size="sm" aria-label="Delete" phx-click="delete" phx-value-id={id}>
            <.icon name="huge-delete-02" />
          </.button>
        </:actions>

        <:toolbar>
          <.button color="primary" variant="solid"><.icon name="huge-add-01" /> Add node</.button>
          <.button><.icon name="huge-shield-01" /> Guardrails</.button>
        </:toolbar>

        <:panel label="Approval">
          <.flow_panel_head icon="huge-security-check" title="Approval" on_close="close_panel" />
          <.flow_panel_tabs><.tabs ...>...</.tabs></.flow_panel_tabs>
          <.flow_panel_body>...fields...</.flow_panel_body>
          <.flow_panel_foot>
            <span>Edited 4 min ago</span><span class="sp"></span>
            <.button>Discard</.button> <.button color="primary" variant="solid">Save node</.button>
          </.flow_panel_foot>
        </:panel>
      </.flow>

  ## Layout

  The server lays the steps out (no JavaScript, no measuring): `edges` is a list of maps with `from` and `to`
  (node ids) and, optionally, `label` and `status`. A node's row is its depth along the edges; a parent is
  centred over its children, the children stand side by side and every connection is an SVG path drawn in
  the gap above its target, with the `label` on it. A gap with a branch or a label is taller than a plain one.
  Edges are expected to join one row to the next; an edge that skips rows is drawn in the gap above its
  target, from the column of its source. A flow with no `edges` is a free grid: the nodes in the order given, four to a row.

  `status: "done"` paints a traversed edge green and `"error"` red; an edge into the `selected` node takes the
  accent colour. An edge with no status is the neutral line, which is how the branch not taken of a run reads.

  ## Nodes

  A `:node` has a `kind` tab (text in `kind`, glyph in `kind_icon`) joined to a card with the `title`, the
  `icon`, the sections (`flow_section/1`, the content of the slot) and a footer of `metrics`. `status` is
  `running`, `done`, `waiting`, `error` or `skipped` and the tab gets its dot; `selected` takes the accent
  colour and renders the `:actions` slot beside the card (with the node id as the slot argument). With
  `on_add` set, the nodes with no outgoing edge get the + button under them; it pushes `on_add` (an event
  name or a `%JS{}`) with `phx-value-id` of the node.

  The `:hint` slot is a floating note on the board (`<:hint title="Comece pelo gatilho">Depois use o +…</:hint>`):
  the title in bold above the text, placed at `left`/`top` (372 and 92 px of the stage, to the right of a
  first node) and `width` (240).

  The `:toolbar` slot is the bar at the bottom of the board. The `:panel` slot is the aside on the right,
  composed with `flow_panel_head/1`, `flow_panel_tabs/1`, `flow_panel_body/1` and `flow_panel_foot/1` and the
  rest of the kit (`tabs`, `input`, `select`, `button`...); without it the board takes the whole width.
  Give the board a height (`class="h-[640px]"`) and an `aria-label`.
  """

  use LineaUI.Component

  import LineaUI.Components.Button, only: [button: 1]
  import LineaUI.Components.Icon, only: [icon: 1]

  @statuses ~w(running done waiting error skipped)
  @edge_statuses ~w(done error)

  # the gap between two rows with a plain connection, with a branch or a label, the height of a kind tab
  # that a connection crosses to reach its card, and where the horizontal rail of a branch runs
  @gap 14
  @gap_branch 97
  @tab 29
  @rail 28
  @radius 10
  @pitch_gap 76
  @free_gap 16
  @free_per_row 4

  @doc """
  Renders the board: the nodes, the connections, the toolbar and the panel.
  """
  attr :id, :string, required: true

  attr :edges, :list,
    default: [],
    doc:
      "Connections: maps with `from` and `to` (node ids) and optionally `label` and `status` (`done` or `error`)."

  attr :on_add, :any,
    default: nil,
    doc:
      "An event name or a `%JS{}`; draws the + button under the nodes with no outgoing edge and pushes with `phx-value-id`."

  attr :add_label, :string, default: "Add step after", doc: "The accessible name of the + button."
  attr :node_width, :integer, default: 300, doc: "The width of a node card in px."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :node, required: true, doc: "A step; its content is the sections of the card." do
    attr :id, :string, required: true, doc: "The DOM id of the node and the key of the edges."
    attr :title, :string, required: true
    attr :icon, :string, doc: "The icon in front of the title (`huge-mail-01`)."
    attr :kind, :string, doc: "The text of the tab (`Trigger`, `Agent`); no tab when missing."
    attr :kind_icon, :string, doc: "The icon of the tab (`huge-flash`)."
    attr :status, :string, values: @statuses
    attr :selected, :boolean
    attr :class, :any

    attr :metrics, :list,
      doc: "The footer: maps with `label`, `value` and optionally `href` (a link with a chevron)."
  end

  slot :actions,
    doc: "Buttons shown beside the selected node; the node id is the slot argument (`:let={id}`)."

  slot :hint,
    doc:
      "A floating note on the board, for an empty or new flow: a title in bold, then the text. Free-positioned in the stage." do
    attr :title, :string, doc: "The bold first line."
    attr :left, :integer, doc: "Distance from the left of the stage in px. Defaults to 372."
    attr :top, :integer, doc: "Distance from the top of the stage in px. Defaults to 92."
    attr :width, :integer, doc: "Width in px. Defaults to 240."
    attr :class, :any
  end

  slot :toolbar, doc: "The bar at the bottom of the board, centred."

  slot :panel, doc: "The aside on the right, for the selected node." do
    attr :label, :string, doc: "Its `aria-label`."
  end

  def flow(assigns) do
    assigns =
      assign_derived(assigns, :layers, [:node, :edges, :node_width], fn ->
        layers(assigns.node, assigns.edges, assigns.node_width)
      end)

    ~H"""
    <div id={@id} class={merge(["linea-flow", @class])} role="group" {@rest}>
      <div class="linea-flow-main">
        <div class="linea-flow-scroll">
          <div class="linea-flow-stage" data-free={@edges == []}>
            <%= for layer <- @layers do %>
              <div :if={layer.band} class="linea-flow-band" style={"height:#{layer.band.height}px"}>
                <svg class="linea-flow-edges" aria-hidden="true">
                  <path
                    :for={edge <- layer.band.edges}
                    d={edge.d}
                    data-status={edge.status}
                    data-active={edge.active}
                  />
                  <rect
                    :for={dot <- layer.band.dots}
                    x={dot.x}
                    y={dot.y}
                    width="8"
                    height="8"
                    rx="2"
                    data-status={dot.status}
                    data-active={dot.active}
                  />
                </svg>
                <span
                  :for={edge <- layer.band.edges}
                  class="linea-flow-edge"
                  data-from={edge.from}
                  data-to={edge.to}
                  data-status={edge.status}
                  data-active={edge.active}
                  style={"left:#{edge.label_x}px;top:#{edge.label_y}px"}
                >{edge.label}</span>
              </div>
              <div class="linea-flow-row">
                <article
                  :for={item <- layer.nodes}
                  id={item.node.id}
                  class={merge(["linea-flow-node", item.node[:class]])}
                  style={item.style}
                  data-status={item.node[:status]}
                  data-selected={item.node[:selected] == true}
                >
                  <span :if={item.node[:kind]} class="linea-flow-kind">
                    <i :if={item.node[:status]} class="st"></i>
                    <.icon :if={item.node[:kind_icon]} name={item.node.kind_icon} />{item.node.kind}
                  </span>
                  <div class="linea-flow-card" tabindex="0" role="group" aria-label={item.node.title}>
                    <header class="linea-flow-head">
                      <.icon :if={item.node[:icon]} name={item.node.icon} />
                      <h3>{item.node.title}</h3>
                    </header>
                    {item.node[:inner_block] && render_slot(item.node)}
                    <footer :if={item.node[:metrics] not in [nil, []]} class="linea-flow-metrics">
                      <.metric :for={metric <- item.node.metrics} metric={metric} />
                    </footer>
                  </div>
                  <div
                    :if={item.node[:selected] == true and @actions != []}
                    class="linea-flow-actions"
                  >
                    {render_slot(@actions, item.node.id)}
                  </div>
                  <button
                    :if={@on_add && item.leaf}
                    type="button"
                    class="linea-flow-add"
                    aria-label={@add_label}
                    phx-click={@on_add}
                    phx-value-id={item.node.id}
                  >
                    <.icon name="huge-add-01" />
                  </button>
                </article>
              </div>
            <% end %>
            <div
              :for={hint <- @hint}
              class={merge(["linea-flow-hint", hint[:class]])}
              style={hint_style(hint)}
            >
              <b :if={hint[:title]}>{hint.title}</b>{render_slot(hint)}
            </div>
          </div>
        </div>
        <div :if={@toolbar != []} class="linea-flow-toolbar" role="toolbar">
          {render_slot(@toolbar)}
        </div>
      </div>
      <aside :for={panel <- @panel} class="linea-flow-panel" aria-label={panel[:label]}>
        {render_slot(panel)}
      </aside>
    </div>
    """
  end

  attr :metric, :map, required: true

  defp metric(%{metric: %{href: href}} = assigns) when is_binary(href) do
    ~H"""
    <a href={@metric.href}>{@metric.label}: <b>{@metric.value}</b><.icon name="huge-arrow-right-01" /></a>
    """
  end

  defp metric(assigns) do
    ~H"""
    <span>{@metric.label}: <b>{@metric.value}</b></span>
    """
  end

  @doc """
  A tinted section of a node's card, with a label in mono capitals.

      <.flow_section label="Instructions">Extract the items and match them to the order.</.flow_section>
  """
  attr :label, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_section(assigns) do
    ~H"""
    <div class={merge(["linea-flow-sec", @class])} {@rest}>
      <span class="l">{@label}</span>{render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The row of chips of a section (the tools of an agent).
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_chips(assigns) do
    ~H"""
    <div class={merge(["linea-flow-chips", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc """
  A chip of `flow_chips/1`, in mono type.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_chip(assigns) do
    ~H"""
    <code class={merge(["linea-flow-chip", @class])} {@rest}>{render_slot(@inner_block)}</code>
    """
  end

  @doc """
  The head of the panel: the icon in its box, the title and, with `on_close`, a close button.
  """
  attr :title, :string, required: true
  attr :icon, :string, default: nil, doc: "The icon of the box (`huge-security-check`)."
  attr :on_close, :any, default: nil, doc: "An event name or a `%JS{}`; draws the close button."
  attr :close_label, :string, default: "Close"
  attr :class, :any, default: nil
  attr :rest, :global

  def flow_panel_head(assigns) do
    ~H"""
    <header class={merge(["linea-flow-panel-head", @class])} {@rest}>
      <span :if={@icon} class="ic"><.icon name={@icon} /></span>
      <h2>{@title}</h2>
      <.button
        :if={@on_close}
        icon
        size="sm"
        variant="flat"
        aria-label={@close_label}
        phx-click={@on_close}
      >
        <.icon name="huge-cancel-01" />
      </.button>
    </header>
    """
  end

  @doc """
  The strip under the head that holds the `tabs` of the panel.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_panel_tabs(assigns) do
    ~H"""
    <div class={merge(["linea-flow-panel-tabs", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc """
  The scrolling body of the panel, where the fields go.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_panel_body(assigns) do
    ~H"""
    <div class={merge(["linea-flow-panel-body", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc """
  The foot of the panel: a note on the left and the buttons on the right.

  A `<span class="sp"></span>` between them pushes the buttons to the end.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def flow_panel_foot(assigns) do
    ~H"""
    <footer class={merge(["linea-flow-panel-foot", @class])} {@rest}>
      {render_slot(@inner_block)}
    </footer>
    """
  end

  defp hint_style(hint) do
    [left: hint[:left], top: hint[:top], width: hint[:width]]
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Enum.map_join(";", fn {name, px} -> "#{name}:#{px}px" end)
  end

  # The layout. Returns a list of layers: %{band: nil | band, nodes: [%{node, style, leaf}]}.

  @doc false
  def layers(nodes, [], width) do
    nodes
    |> Enum.map(fn node -> %{node: node, style: "width:#{width}px", leaf: true} end)
    |> Enum.chunk_every(@free_per_row)
    |> Enum.map(&%{band: nil, nodes: &1})
  end

  def layers(nodes, edges, width) do
    ids = Enum.map(nodes, & &1.id)
    valid = valid_edges(edges, ids)
    layer_of = depths(ids, valid)
    xs = columns(ids, valid, layer_of)
    pitch = width + @pitch_gap
    sources = valid |> Enum.map(& &1.from) |> MapSet.new()
    selected = for node <- nodes, node[:selected] == true, into: MapSet.new(), do: node.id
    tabs = Map.new(nodes, &{&1.id, tab_height(&1)})

    nodes
    |> Enum.group_by(&Map.fetch!(layer_of, &1.id))
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {depth, row} ->
      %{
        band: band(depth, valid, layer_of, xs, pitch, width, selected, tabs),
        nodes: row_items(row, xs, pitch, width, sources)
      }
    end)
  end

  defp tab_height(%{kind: kind}) when is_binary(kind), do: @tab
  defp tab_height(_node), do: 0

  defp valid_edges(edges, ids) do
    edges
    |> Enum.filter(fn edge -> edge.from in ids and edge.to in ids and edge.from != edge.to end)
    |> Enum.uniq_by(&{&1.from, &1.to})
  end

  # the depth of a node: the longest path to it; cycles stop after one pass per node
  defp depths(ids, edges) do
    start = Map.new(ids, &{&1, 0})

    Enum.reduce_while(ids, start, fn _, depth ->
      next =
        Enum.reduce(edges, depth, fn edge, acc ->
          Map.update!(acc, edge.to, &max(&1, Map.fetch!(acc, edge.from) + 1))
        end)

      case next == depth do
        true -> {:halt, next}
        false -> {:cont, next}
      end
    end)
  end

  # the x of every node in pitches: leaves side by side, a parent centred over its children
  defp columns(ids, edges, layer_of) do
    parents =
      Enum.reduce(edges, %{}, fn edge, acc ->
        case Map.fetch!(layer_of, edge.from) < Map.fetch!(layer_of, edge.to) do
          true -> Map.put_new(acc, edge.to, edge.from)
          false -> acc
        end
      end)

    kids =
      Enum.reduce(ids, %{}, fn id, acc ->
        Map.put(
          acc,
          id,
          for(e <- edges, Map.get(parents, e.to) == e.from and e.from == id, do: e.to)
        )
      end)

    roots = Enum.reject(ids, &Map.has_key?(parents, &1))

    {xs, _next} = Enum.reduce(roots ++ ids, {%{}, 0}, &place(&1, &2, kids))
    xs
  end

  defp place(id, {xs, _next} = state, _kids) when is_map_key(xs, id), do: state

  defp place(id, {xs, next}, kids) do
    case Map.fetch!(kids, id) do
      [] ->
        {Map.put(xs, id, next * 1.0), next + 1}

      children ->
        {xs, next} = Enum.reduce(children, {xs, next}, &place(&1, &2, kids))
        placed = Enum.filter(children, &is_map_key(xs, &1))
        centre = (Map.fetch!(xs, List.first(placed)) + Map.fetch!(xs, List.last(placed))) / 2
        {Map.put(xs, id, centre), next}
    end
  end

  defp row_items(row, xs, pitch, width, sources) do
    row
    |> Enum.sort_by(&Map.fetch!(xs, &1.id))
    |> Enum.map_reduce(nil, fn node, previous_end ->
      left = Map.fetch!(xs, node.id) * pitch

      {%{
         node: node,
         style: "width:#{width}px;margin-left:#{num(margin(left, previous_end))}px",
         leaf: not MapSet.member?(sources, node.id)
       }, left + width}
    end)
    |> elem(0)
  end

  defp margin(left, nil), do: left
  defp margin(left, previous_end), do: max(left - previous_end, @free_gap)

  defp band(0, _edges, _layer_of, _xs, _pitch, _width, _selected, _tabs), do: nil

  defp band(depth, edges, layer_of, xs, pitch, width, selected, tabs) do
    into = Enum.filter(edges, &(Map.fetch!(layer_of, &1.to) == depth))

    case into do
      [] -> nil
      _ -> build_band(into, xs, pitch, width, selected, tabs)
    end
  end

  defp build_band(into, xs, pitch, width, selected, tabs) do
    centre = fn id -> Map.fetch!(xs, id) * pitch + width / 2 end

    branching =
      Enum.any?(into, fn edge ->
        centre.(edge.from) != centre.(edge.to) or label(edge) != nil
      end)

    height = band_height(branching)

    edges =
      Enum.map(into, fn edge ->
        sx = centre.(edge.from)
        tx = centre.(edge.to)
        stop = height + Map.fetch!(tabs, edge.to)

        %{
          from: edge.from,
          to: edge.to,
          d: path(sx, tx, stop),
          sx: sx,
          tx: tx,
          stop: stop,
          label: label(edge),
          status: status(edge),
          active: MapSet.member?(selected, edge.to),
          label_x: num(tx),
          label_y: num(label_y(sx, tx, stop))
        }
      end)

    dots =
      Enum.flat_map(edges, fn edge ->
        [
          %{x: num(edge.sx - 4), y: -4, status: edge.status, active: edge.active},
          %{x: num(edge.tx - 4), y: num(edge.stop - 4), status: edge.status, active: edge.active}
        ]
      end)

    %{height: height, edges: edges, dots: dots}
  end

  defp band_height(true), do: @gap_branch
  defp band_height(false), do: @gap

  defp label(edge) do
    case Map.get(edge, :label) do
      nil -> nil
      "" -> nil
      text -> text
    end
  end

  defp status(edge) do
    case Map.get(edge, :status) do
      status when status in @edge_statuses -> status
      _ -> nil
    end
  end

  defp label_y(sx, tx, stop) when sx == tx, do: stop / 2
  defp label_y(_sx, _tx, stop), do: (@rail + stop) / 2

  defp path(sx, tx, stop) when sx == tx, do: "M#{num(sx)} 0V#{num(stop)}"

  defp path(sx, tx, stop) do
    dir = direction(sx, tx)
    r = min(@radius * 1.0, abs(tx - sx) / 2)

    "M#{num(sx)} 0V#{num(@rail - r)}Q#{num(sx)} #{@rail} #{num(sx + dir * r)} #{@rail}" <>
      "H#{num(tx - dir * r)}Q#{num(tx)} #{@rail} #{num(tx)} #{num(@rail + r)}V#{num(stop)}"
  end

  defp direction(sx, tx) when tx > sx, do: 1
  defp direction(_sx, _tx), do: -1

  defp num(value) when is_integer(value), do: Integer.to_string(value)
  defp num(value), do: value |> Float.round(2) |> to_string()
end
