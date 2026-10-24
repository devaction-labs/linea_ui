defmodule LineaUI.Components.Accordion do
  @moduledoc """
  LineOne's accordion and collapse: a list of sections that open under their titles, in LineOne's
  six styles (basic, border bottom, full bordered, divided items, primary, advanced).

      <.accordion id="faq" variant="bordered">
        <.accordion_item id="faq-1" title="Accordion Item 1" open>
          <p>Lorem ipsum dolor sit amet.</p>
        </.accordion_item>
        <.accordion_item id="faq-2" title="Accordion Item 2">…</.accordion_item>
      </.accordion>

      <.accordion id="help" variant="primary" color="warning">…</.accordion>

  One section is open at a time; `multiple` lets them open independently (LineOne's Collapse
  page). The `advanced` style puts a header of your own in each item, with the chevron button
  at its end:

      <.accordion id="people" variant="advanced">
        <.accordion_item id="simon">
          <:header><.avatar …/> Simon Tods</:header>
          …
        </.accordion_item>
      </.accordion>

  Each item is a `LineaUI.Components.Collapse`: the browser owns which sections are open, the
  server's `open` wins when it changes, `LineaUI.open/close/toggle("faq-1")` work, and
  `on_open` / `on_close` push `%{"id" => item_id}` when they are event names.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  alias LineaUI.Components.Collapse

  @variants %{
    "basic" => "flex flex-col",
    "border-bottom" => "flex flex-col divide-y divide-slate-150 dark:divide-navy-500",
    "bordered" =>
      "flex flex-col divide-y divide-slate-150 rounded-lg border border-slate-150 dark:divide-navy-500 dark:border-navy-500",
    "divided" => "flex flex-col space-y-4 rounded-lg sm:space-y-5 lg:space-y-6",
    "primary" => "flex flex-col divide-y overflow-hidden rounded-lg border",
    "advanced" => "flex flex-col space-y-4 sm:space-y-5 lg:space-y-6"
  }

  @frames %{
    "primary" => "divide-indigo-400 border-primary dark:border-accent",
    "secondary" => "divide-violet-400 border-secondary dark:border-secondary",
    "info" => "divide-sky-400 border-info dark:border-info",
    "success" => "divide-emerald-400 border-success dark:border-success",
    "warning" => "divide-yellow-400 border-warning dark:border-warning",
    "error" => "divide-rose-400 border-error dark:border-error"
  }

  @doc """
  Groups accordion items and gives them their style.

      <.accordion id="faq" variant="divided" multiple>
        <.accordion_item id="q1" title="Question">Answer</.accordion_item>
      </.accordion>
  """
  attr :id, :string, required: true

  attr :variant, :string,
    default: "basic",
    values: Map.keys(@variants),
    doc:
      "LineOne's sections: `basic`, `border-bottom`, `bordered` (full bordered), `divided` (items apart), `primary`, `advanced` (a header slot per item)."

  attr :color, :string,
    default: "primary",
    values: ~w(primary secondary info success warning error),
    doc:
      "The `primary` style's frame, dividers and header fill: LineOne's blue by default, or any theme color (the Help page's yellow and sky frames)."

  attr :multiple, :boolean,
    default: false,
    doc: "Sections open independently (LineOne's Collapse)."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def accordion(assigns) do
    ~H"""
    <div
      id={@id}
      class={merge([variant_class(@variant), frame_class(@variant, @color), @class])}
      data-accordion
      data-variant={@variant}
      data-color={@variant == "primary" && @color}
      data-exclusive={bool(!@multiple)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A section of an accordion: its title (or `:header` in the `advanced` style) and its content.

      <.accordion_item id="q1" title="Accordion Item 1" on_open="q1-opened">
        <p>Lorem ipsum.</p>
      </.accordion_item>

  Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.
  """
  attr :id, :string, required: true
  attr :title, :string, default: nil
  attr :open, :boolean, default: false
  attr :on_open, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :on_close, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil

  attr :toggle_label, :string,
    default: "Toggle",
    doc: "The accessible name of the `:header` chevron button."

  attr :class, :any, default: nil, doc: "Merged into the item."
  attr :rest, :global

  slot :header,
    doc: "A header of your own, with the chevron button at its end (LineOne's Advanced)."

  slot :inner_block, required: true

  def accordion_item(%{header: [_ | _]} = assigns) do
    ~H"""
    <Collapse.collapse
      id={@id}
      open={@open}
      on_open={@on_open}
      on_close={@on_close}
      target={@target}
      class={merge(["ac", @class])}
      {@rest}
    >
      <:trigger class="ac-header pointer-events-none flex items-center justify-between bg-slate-150 px-4 py-4 dark:bg-navy-500 sm:px-5">
        <div class="flex items-center space-x-3.5 tracking-wide outline-hidden transition-all">
          {render_slot(@header)}
        </div>
        <span
          class="ac-trigger btn pointer-events-auto -mr-1.5 size-8 rounded-full p-0 hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25"
          aria-label={@toggle_label}
        >
          <.chevron class="ac-icon text-sm transition-transform" />
        </span>
      </:trigger>
      <div class="ac-body">{render_slot(@inner_block)}</div>
    </Collapse.collapse>
    """
  end

  def accordion_item(assigns) do
    ~H"""
    <Collapse.collapse
      id={@id}
      open={@open}
      on_open={@on_open}
      on_close={@on_close}
      target={@target}
      class={merge(["ac", @class])}
      {@rest}
    >
      <:trigger class="ac-trigger flex items-center justify-between py-4 text-base font-medium">
        <p>{@title}</p>
        <div class="ac-icon text-sm font-normal leading-none transition-transform duration-300">
          <.chevron />
        </div>
      </:trigger>
      <div class="ac-body">{render_slot(@inner_block)}</div>
    </Collapse.collapse>
    """
  end

  attr :class, :any, default: nil

  defp chevron(assigns) do
    ~H"""
    <.glyph name={:chevron_down_solid} class={merge(["h-[1em] w-[1em]", @class])} />
    """
  end

  defp variant_class(variant), do: Map.fetch!(@variants, variant)

  defp frame_class("primary", color), do: Map.fetch!(@frames, color)
  defp frame_class(_variant, _color), do: nil
end
