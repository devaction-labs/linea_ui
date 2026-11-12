defmodule LineaUI.Components.Flow do
  @moduledoc """
  A workflow editor: steps (a trigger, an agent, an action, a human approval) placed on a dotted stage and
  joined by connections, with a toolbar at the bottom and an inspector on the right.

      <.flow
        id="triage"
        aria-label="AP exception triage"
        edges={[
          %{from: "received", to: "match"},
          %{from: "match", to: "post", label: "variance ≤ 2%"},
          %{from: "match", to: "gate", label: "variance > 2%", active: true}
        ]}
      >
        <.flow_node id="received" x={320} y={32} kind="Trigger" title="Invoice received" phx-click="select" phx-value-id="received">
          <:kind_icon><.icon name="huge-play" /></:kind_icon>
          <:icon><.icon name="huge-mail-01" /></:icon>
          <:section label="Event">An invoice lands in ap@meridian.co.</:section>
          <:metric label="runs" value="1,284/wk" navigate={~p"/runs"} />
          <:metric label="p95" value="0.3s" />
        </.flow_node>

        <.flow_node id="gate" x={500} y={700} kind="Human step" title="Approval gate" selected on_add="add_after">
          <:section label="Tools"><.flow_chip :for={tool <- @tools}>{tool}</.flow_chip></:section>
          <:actions>
            <.button icon size="sm" aria-label="Delete"><.icon name="huge-delete-02" /></.button>
          </:actions>
        </.flow_node>

        <:toolbar>
          <.button color="primary"><.icon name="huge-add-01" /> Add node</.button>
          <.button>Variables</.button>
        </:toolbar>

        <:panel>
          <.flow_panel title="Approval gate" on_close="close_panel">
            <:icon><.icon name="huge-user-check-01" /></:icon>
            <.input field={@form[:message]} label="Request message" />
            <:footer>
              <span>Edited 4m ago</span>
              <.button>Discard</.button>
              <.button color="primary" type="submit">Save node</.button>
            </:footer>
          </.flow_panel>
        </:panel>
      </.flow>

  ## Nodes

  A node is placed by `x` and `y` (pixels from the top left of the stage); the stage grows to hold every
  node and scrolls. `kind` is the tab over the card (with `:kind_icon`), `title` and `:icon` the header,
  each `:section` a tinted block with a mono caps `label`, and each `:metric` an entry of the footer
  (`label: value`, a link with a chevron when it has `href`, `navigate` or `patch`). The inner block goes
  between the sections and the footer.

  `selected` draws the node in the accent color and shows the `:actions` beside it. `status` marks a run:
  `running` (a pulsing dot in the tab), `done`, `waiting`, `error` (a red border) and `skipped` (faded).
  `on_add` puts a `+` button under the node; it pushes that event with the node id as `id`.
  A click on the node is yours (`phx-click`); the card is a `tabindex="0"` group so it takes the keyboard.

  ## Edges

  `edges` is a list of maps with `:from` and `:to` (node ids) and optionally `:label`, `:active` (the accent
  color, for the branch of the selected node) and `:status` (`done`, `error`). The `LineaUI.Flow` hook
  measures the nodes and draws each edge from the bottom of the `from` card to the top of the `to` card,
  with a port at each end and the label on the way; it redraws when the flow is patched or a node changes
  size. Without JavaScript the nodes still render, with no lines.

  Styles: `canvas-flow.css` (`linea-flow`).
  """

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [icon: 1]

  @doc """
  Renders the stage of a flow, with its edges, toolbar and panel.
  """
  attr :id, :string, required: true
  attr :edges, :list, default: [], doc: "Maps with `:from` and `:to`, and optionally `:label`, `:active`, `:status`."
  attr :padding, :integer, default: 96, doc: "The room after the last node, in pixels."

  attr :height, :string,
    default: nil,
    doc: "A CSS height for the editor (`\"640px\"`, `\"calc(100dvh - 8rem)\"`). The default is `clamp(420px, 72vh, 880px)`; the stage scrolls inside it."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, doc: "The nodes."
  slot :toolbar, doc: "Buttons centered at the bottom of the stage."
  slot :panel, doc: "The inspector on the right (`flow_panel/1`)."

  def flow(assigns) do
    ~H"""
    <div id={@id} class={merge(["linea-flow", @class])} role="group" phx-hook="LineaUI.Flow" data-padding={@padding} style={@height && "--linea-flow-height:#{@height}"} {@rest}>
      <div class="linea-flow-main">
        <div class="linea-flow-scroll">
          <div class="linea-flow-stage">
            <svg id={"#{@id}-edges"} class="linea-flow-edges" aria-hidden="true" phx-update="ignore"></svg>
            <span
              :for={edge <- @edges}
              class="linea-flow-edge"
              data-from={edge[:from]}
              data-to={edge[:to]}
              data-active={edge[:active]}
              data-status={edge[:status]}
            >{edge[:label]}</span>
            {render_slot(@inner_block)}
          </div>
        </div>
        <div :if={@toolbar != []} class="linea-flow-toolbar" role="toolbar">{render_slot(@toolbar)}</div>
      </div>
      {render_slot(@panel)}
    </div>
    """
  end

  @doc """
  Renders a step of the flow.
  """
  attr :id, :string, required: true
  attr :x, :integer, default: 0
  attr :y, :integer, default: 0
  attr :width, :integer, default: 320
  attr :kind, :string, default: nil, doc: "The tab over the card (`Trigger`, `Agent`, `Action`...)."
  attr :title, :string, required: true
  attr :selected, :boolean, default: false

  attr :status, :string,
    default: nil,
    values: [nil, "running", "done", "waiting", "error", "skipped"],
    doc: "The state of the step in a run."

  attr :on_add, :string, default: nil, doc: "The event of the `+` button under the node; it gets the node id as `id`."
  attr :add_label, :string, default: "Add a step after"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :kind_icon
  slot :icon, doc: "The icon before the title."

  slot :section, doc: "A tinted block of the card." do
    attr :label, :string
  end

  slot :inner_block
  slot :actions, doc: "Buttons beside the node, shown when it is selected."

  slot :metric, doc: "An entry of the footer, `label: value`." do
    attr :label, :string
    attr :value, :string
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
  end

  def flow_node(assigns) do
    ~H"""
    <article
      id={@id}
      class={merge(["linea-flow-node", @class])}
      style={"left:#{@x}px;top:#{@y}px;width:#{@width}px"}
      data-selected={@selected}
      data-status={@status}
      aria-current={@selected && "true"}
      {@rest}
    >
      <span :if={@kind} class="linea-flow-kind">
        <i :if={@status} class="st" aria-hidden="true"></i>{render_slot(@kind_icon)}{@kind}
      </span>
      <div class="linea-flow-card" tabindex="0" role="group" aria-label={@title}>
        <header class="linea-flow-head">
          {render_slot(@icon)}
          <h3>{@title}</h3>
        </header>
        <div :for={section <- @section} class="linea-flow-sec">
          <span :if={section[:label]} class="l">{section.label}</span>{render_slot(section)}
        </div>
        {render_slot(@inner_block)}
        <footer :if={@metric != []} class="linea-flow-metrics">
          <.metric :for={metric <- @metric} metric={metric} />
        </footer>
      </div>
      <div :if={@selected and @actions != []} class="linea-flow-actions">{render_slot(@actions)}</div>
      <button
        :if={@on_add}
        type="button"
        class="linea-flow-add"
        phx-click={@on_add}
        phx-value-id={@id}
        aria-label={@add_label}
      >
        <.icon name="huge-add-01" />
      </button>
    </article>
    """
  end

  attr :metric, :map, required: true

  defp metric(%{metric: metric} = assigns) do
    assigns = assign(assigns, :link?, !!(metric[:href] || metric[:navigate] || metric[:patch]))

    ~H"""
    <.link :if={@link?} href={@metric[:href]} navigate={@metric[:navigate]} patch={@metric[:patch]}>
      {@metric[:label]}: <b>{@metric[:value]}</b><.icon name="huge-arrow-right-01" />
    </.link>
    <span :if={!@link?}>{@metric[:label]}: <b>{@metric[:value]}</b></span>
    """
  end

  @doc """
  A mono chip inside a section of a node (a tool, a variable). Wrap several in a `class="linea-flow-chips"`
  element, or let them flow in the section.
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
  The inspector of the selected node: a header with an icon, the title and a close button, optional tabs,
  the body (your fields) and a footer.
  """
  attr :title, :string, required: true
  attr :on_close, :any, default: nil, doc: "The event (or `JS` command) of the close button."
  attr :close_label, :string, default: "Close"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon
  slot :tabs, doc: "Under the header, over a line (a `tabs` component)."
  slot :inner_block
  slot :footer

  def flow_panel(assigns) do
    ~H"""
    <aside class={merge(["linea-flow-panel", @class])} aria-label={@title} {@rest}>
      <header class="linea-flow-panel-head">
        <span :if={@icon != []} class="ic">{render_slot(@icon)}</span>
        <h2>{@title}</h2>
        <button :if={@on_close} type="button" class="sg-ib plain sm" phx-click={@on_close} aria-label={@close_label}>
          <.icon name="huge-cancel-01" />
        </button>
      </header>
      <div :if={@tabs != []} class="linea-flow-panel-tabs">{render_slot(@tabs)}</div>
      <div class="linea-flow-panel-body">{render_slot(@inner_block)}</div>
      <footer :if={@footer != []} class="linea-flow-panel-foot">{render_slot(@footer)}</footer>
    </aside>
    """
  end
end
