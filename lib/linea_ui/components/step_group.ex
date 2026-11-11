defmodule LineaUI.Components.StepGroup do
  @moduledoc """
  A framed card for processes in steps (a build, a deploy, issuing an invoice, an import).

  The header sits on the frame with the overall status, the title, the duration and a button that
  collapses the card; inside, a raised panel lists the steps, each with a status, a result in mono
  type and a chevron that opens its log.

      <.step_group id="deploy" title="Deploy logs" status={:running} duration="1m 04s">
        <:step title="Preparing environment" status={:ok} result="12s" />
        <:step title="Updating the stack" status={:running} result="Running…" open>
          <.step_group_line n={1} at="09:41:02" tone="dim">Connecting</.step_group_line>
          <.step_group_line n={2} at="09:41:04" tone="err">Rejected</.step_group_line>
        </:step>
        <:step title="Routing traffic" status={:waiting} result="Waiting" />
      </.step_group>

  `status` is one of `:ok`, `:running`, `:waiting`, `:failed`, `:skipped` and `:canceled`.

  The content of a `:step` is its log (`step_group_line/1` lines). A step with a log is a
  `<button>` that opens and closes the log; a step without one is a plain row, with no chevron.
  A `canceled` step has no status icon, as in the canvas.

  Collapsing the card and opening a log happen in the browser (`Phoenix.LiveView.JS`), with no
  round trip. The browser owns that state: `collapsed` and `open` set where it starts, and a
  patch does not undo what the user toggled.
  """

  use LineaUI.Component

  @classes %{
    ok: "ok",
    running: "run",
    waiting: "wait",
    failed: "fail",
    skipped: "skip",
    canceled: "cancel"
  }

  @statuses Map.keys(@classes)

  # the canvas draws ok, failed, canceled and skipped; running and waiting are drawn by the CSS
  @icons %{
    ok: "M8 12.5l2.6 2.6L16 9.5",
    failed: "M9 9l6 6M15 9l-6 6",
    canceled: "M9 9l6 6M15 9l-6 6",
    skipped: "M8 12h8"
  }

  @up_down "M8 9.5l4-4 4 4M8 14.5l4 4 4-4"
  @right "M9.5 6l6 6-6 6"

  @doc """
  Renders the card: the header, and the steps in the panel under it.
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :status, :atom, default: :waiting, values: @statuses, doc: "The overall status."
  attr :duration, :string, default: nil, doc: "Shown at the end of the header, e.g. `1m 04s`."

  attr :collapsed, :boolean,
    default: false,
    doc: "Starts with the panel hidden. The user's toggling wins afterwards."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :step, doc: "One step; its content is its log." do
    attr :title, :string, required: true
    attr :status, :atom, values: @statuses
    attr :result, :string, doc: "The result at the end of the row (`12s`, `Running…`)."
    attr :open, :boolean, doc: "Starts with the log open."
    attr :id, :string, doc: "The row's id; `<id>-step-<n>` when missing."
    attr :class, :any
  end

  def step_group(assigns) do
    assigns =
      assigns
      |> assign_derived(:rows, [:step, :id], fn -> rows(assigns.step, assigns.id) end)
      |> assign_derived(:status_class, [:status], fn -> Map.fetch!(@classes, assigns.status) end)

    ~H"""
    <section
      id={@id}
      class={merge(["sg-sgp", @collapsed && "is-collapsed", @class])}
      phx-mounted={JS.ignore_attributes(["class"])}
      {@rest}
    >
      <button
        type="button"
        class="sg-sgp-h"
        aria-expanded={bool(!@collapsed)}
        aria-controls={"#{@id}-body"}
        phx-click={toggle_group(@id)}
        phx-mounted={JS.ignore_attributes(["aria-expanded"])}
      >
        <.status_icon status={@status} class={@status_class} />
        <span class="t">{@title}</span>
        <span :if={@duration} class="m">{@duration}</span>
        <span class="c"><.chevron path={up_down()} /></span>
      </button>
      <div
        id={"#{@id}-body"}
        class="sg-sgp-b"
        hidden={@collapsed}
        phx-mounted={JS.ignore_attributes(["hidden"])}
      >
        <%= for row <- @rows do %>
          <button
            :if={row.log}
            type="button"
            id={row.id}
            class={row_class(row)}
            aria-expanded={bool(row.open)}
            aria-controls={row.log_id}
            phx-click={toggle_row(row.id, row.log_id)}
            phx-mounted={JS.ignore_attributes(["class", "aria-expanded"])}
          >
            <.row_content row={row} />
          </button>
          <div :if={!row.log} id={row.id} class={row_class(row)}>
            <.row_content row={row} />
          </div>
          <div
            :if={row.log}
            id={row.log_id}
            class="sg-sgp-log"
            role="log"
            hidden={!row.open}
            phx-mounted={JS.ignore_attributes(["hidden"])}
          >
            {render_slot(row.step)}
          </div>
        <% end %>
      </div>
    </section>
    """
  end

  attr :row, :map, required: true

  defp row_content(assigns) do
    ~H"""
    <.status_icon :if={@row.lead} status={@row.status} class={@row.class} />
    <span class="t">{@row.title}</span>
    <span class="s">{@row.result}</span>
    <span class="c"><.chevron :if={@row.log} path={right()} /></span>
    """
  end

  attr :status, :atom, required: true
  attr :class, :string, required: true

  defp status_icon(assigns) do
    assigns = assign_derived(assigns, :path, [:status], fn -> Map.get(@icons, assigns.status) end)

    ~H"""
    <span class={["sg-sgs", @class]} aria-hidden="true">
      <svg viewBox="0 0 24 24"><path :if={@path} d={@path} /></svg>
    </span>
    """
  end

  attr :path, :string, required: true

  defp chevron(assigns) do
    ~H"""
    <svg class="i sm" viewBox="0 0 24 24" aria-hidden="true"><path d={@path} /></svg>
    """
  end

  @doc """
  A line of a step's log: its number, the time and the text.

      <.step_group_line n={3} at="09:41:04" tone="err">cStat 539: duplicate invoice</.step_group_line>
  """
  attr :n, :integer, required: true, doc: "The line number."
  attr :at, :string, default: nil, doc: "The time of the line, e.g. `09:41:02`."

  attr :tone, :string,
    default: nil,
    values: [nil, "dim", "err", "ok"],
    doc: "`dim` for a quiet line, `err` for an error, `ok` for a success."

  slot :inner_block, required: true

  def step_group_line(assigns) do
    ~H"""
    <div>
      <span class="n">{@n}</span><span class="ts">{@at}</span><span class={@tone}>{render_slot(
        @inner_block
      )}</span>
    </div>
    """
  end

  defp up_down, do: @up_down
  defp right, do: @right

  defp rows(steps, id) do
    steps
    |> Enum.with_index(1)
    |> Enum.map(fn {step, index} ->
      row_id = Map.get(step, :id) || "#{id}-step-#{index}"
      status = Map.get(step, :status) || :waiting

      %{
        step: step,
        id: row_id,
        log_id: "#{row_id}-log",
        log: step.inner_block != nil,
        title: step.title,
        result: Map.get(step, :result),
        status: status,
        class: Map.fetch!(@classes, status),
        lead: status != :canceled,
        open: Map.get(step, :open, false) == true,
        extra: Map.get(step, :class)
      }
    end)
  end

  defp row_class(row) do
    merge(["sg-sgp-r", row.class, row.open && "open", row.lead && "lead", row.extra])
  end

  # collapse the card: the class, the header's aria-expanded and the panel, all in the browser
  defp toggle_group(id) do
    JS.toggle_class("is-collapsed", to: "##{id}")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"})
    |> JS.toggle_attribute({"hidden", "hidden"}, to: "##{id}-body")
  end

  defp toggle_row(row_id, log_id) do
    JS.toggle_class("open", to: "##{row_id}")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"})
    |> JS.toggle_attribute({"hidden", "hidden"}, to: "##{log_id}")
  end
end
