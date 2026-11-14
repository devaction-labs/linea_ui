defmodule LineaUI.Components.Trace do
  @moduledoc """
  What an agent did, one line per step: an icon, a title that truncates, an optional description (a count, a
  duration, a diff) and a status. A step can open to show its output, link somewhere, or group the steps under
  it. It is the canvas's `Trace`, in the spirit of the shadcn/ui Trace.

      <.trace>
        <.trace_line icon="huge-ai-idea" title="Thought for 5s" />
        <.trace_line icon="huge-command-line" description="0.4s">Ran <code>pnpm --version</code></.trace_line>
        <.trace_step icon="huge-command-line" title="Ran node --version" open>
          <pre class="linea-trace-code">v24.18.0</pre>
        </.trace_step>
        <.trace_line icon="huge-command-line" status="error">Failed to run <code>pnpm install</code></.trace_line>
      </.trace>

  ## Lines

  `trace_line/1` takes the title as `title` or as its block (so it can hold `<b>` and `<code>`). `status` is
  `nil` (done), `"running"` (the title shimmers, still for readers who prefer reduced motion), `"error"` (red,
  with an alert icon in place of `icon`) or `"pending"` (faded). With `href`, `navigate` or `patch` the line is a
  link, and `end_icon` puts an icon after it (an arrow, say).

  ## Steps that open

  `trace_step/1` is a native `<details>`: the line is its summary, with a chevron that turns when open, and the
  block is what shows under it, behind a thin line. Put a `<pre class="linea-trace-code">` there for output, or
  another `<.trace>` to group steps (sources, a chain of thought, the files of a commit). `open` starts it open.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [icon: 1]

  @statuses ~w(running error pending)

  @doc "The list of steps."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def trace(assigns) do
    ~H"""
    <div class={merge(["linea-trace", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "One step: icon, title, description and status; a link with `href`, `navigate` or `patch`."
  attr :icon, :string, default: nil, doc: "A `huge-*` icon name."
  attr :title, :string, default: nil, doc: "The title; or pass it as the block."
  attr :description, :any, default: nil, doc: "Secondary text after the title: a count, a duration, a diff."
  attr :status, :string, default: nil, values: [nil | @statuses]
  attr :end_icon, :string, default: nil, doc: "An icon after the line, such as an arrow on a link."
  attr :href, :string, default: nil
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(target rel)
  slot :inner_block

  def trace_line(%{href: nil, navigate: nil, patch: nil} = assigns) do
    ~H"""
    <div class={merge(["linea-trace-line", @class])} data-status={@status} {@rest}>
      <.line_body icon={@icon} title={@title} description={@description} status={@status} end_icon={@end_icon} body={@inner_block} />
    </div>
    """
  end

  def trace_line(assigns) do
    ~H"""
    <.link
      class={merge(["linea-trace-line", @class])}
      data-status={@status}
      href={@href}
      navigate={@navigate}
      patch={@patch}
      {@rest}
    >
      <.line_body icon={@icon} title={@title} description={@description} status={@status} end_icon={@end_icon} body={@inner_block} />
    </.link>
    """
  end

  @doc "A step that opens: the line is the summary and the block shows under it."
  attr :icon, :string, default: nil
  attr :title, :string, default: nil
  attr :description, :any, default: nil
  attr :status, :string, default: nil, values: [nil | @statuses]
  attr :open, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :summary, doc: "The title with markup, in place of `title`."
  slot :inner_block, required: true

  def trace_step(assigns) do
    ~H"""
    <details class={merge(["linea-trace-step", @class])} open={@open} {@rest}>
      <summary>
        <span class="linea-trace-line" data-status={@status}>
          <.line_body icon={@icon} title={@title} description={@description} status={@status} body={@summary} chevron />
        </span>
      </summary>
      <div class="linea-trace-body">{render_slot(@inner_block)}</div>
    </details>
    """
  end

  attr :icon, :string, default: nil
  attr :title, :string, default: nil
  attr :description, :any, default: nil
  attr :status, :string, default: nil
  attr :end_icon, :string, default: nil
  attr :chevron, :boolean, default: false
  attr :body, :list, default: []

  defp line_body(assigns) do
    ~H"""
    <span :if={@icon || @status == "error"} class="linea-trace-icon">
      <.icon name={if(@status == "error", do: "huge-alert-02", else: @icon)} class="size-4" />
    </span>
    <span class="linea-trace-title">{@title}{render_slot(@body)}</span>
    <span :if={@description} class="linea-trace-desc">{@description}</span>
    <.icon :if={@chevron} name="huge-arrow-right-01" class="linea-trace-chev" />
    <.icon :if={@end_icon} name={@end_icon} class="linea-trace-end" />
    """
  end
end
