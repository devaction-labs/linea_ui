defmodule LineaUI.Components.Collapse do
  @moduledoc """
  A section that opens and closes under its trigger, with LineOne's 200ms height animation. It is
  the piece LineOne's Collapse and Accordion pages are built from (see `LineaUI.Components.Accordion`).

      <.collapse id="details">
        <:trigger class="flex items-center justify-between py-4 font-medium">Shipping details</:trigger>
        <p>Ships in two days.</p>
      </.collapse>

  `chevron` adds the rotating chevron LineOne's panels use at the end of the trigger:

      <.collapse id="files" open chevron="down">
        <:trigger class="px-4 text-xs font-medium uppercase">My files</:trigger>
        …
      </.collapse>

  `variant` is the design canvas section by default (see below); `classic` (or `nil`) is the old bare look, and `variant` gives it one of three more looks without writing the trigger's classes: `framed` (a card with a
  12px radius and an inset 1px border, a hover fill, 16/14px padding), `flat` (only a rule under it) and
  `section` (a small uppercase label):

      <.collapse id="filters" variant="section" chevron="down" open>
        <:trigger>Filters</:trigger>
        …
      </.collapse>

  `canvas` is the design canvas section (the look of the canvas accordion): a 14px frame with an inset
  line, the title in the ink at 14px 16px, a muted 13.5/21 body.

  `collapse_text/1` is the other collapse of the canvas: a text clamped to a few lines with a
  "show more" / "show less" link under it.

      <.collapse_text id="desc" lines={2} more="Mostrar mais" less="Mostrar menos">
        Tinta acrílica fosca para paredes internas e externas…
      </.collapse_text>

  It is a native `<details>`: the trigger works with the mouse and the keyboard and the browser
  owns `open`, which survives patches. When the server changes `open`, the server wins.
  `LineaUI.open/close/toggle("details")` (and their socket forms) open and close it too, and
  `on_open` / `on_close` run on every toggle; as event names they push `%{"id" => id}` to the
  LiveView (or `target`).
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  alias LineaUI.Components.Overlay

  @doc """
  Renders a collapsible section.

      <.collapse id="faq-1" open on_close="faq-closed">
        <:trigger>Can I pay later?</:trigger>
        Yes, within 30 days.
      </.collapse>

  Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.
  """
  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :on_open, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :on_close, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil, doc: "The `phx-target` of `on_open` / `on_close` events."

  attr :chevron, :string,
    default: nil,
    values: [nil, "down", "right"],
    doc:
      "Draws a chevron at the end of the trigger (which becomes a flex row with `justify-between`). `down` turns upside down while open, `right` turns down."

  attr :variant, :string,
    default: "canvas",
    values: [nil, "classic", "framed", "flat", "section", "canvas"],
    doc:
      "A ready-made look; `canvas` (the default) is the design canvas section. `classic` (or `nil`) is the old look, no look at all: the trigger is left to its `class`. Others: `framed` (card with an inset border), `flat` (a rule under it), `section` (an uppercase label), `canvas` (the design canvas section). `nil` leaves the trigger to its `class`."

  attr :panel_class, :any,
    default: nil,
    doc: "Merged into the panel (`.ac-panel`) that holds the content (`px-4 pb-4`...)."

  attr :chevron_class, :any, default: nil, doc: "Merged into the chevron's `<svg>`."
  attr :class, :any, default: nil, doc: "Merged into the `<details>`."
  attr :rest, :global

  slot :trigger, required: true do
    attr :class, :any, doc: "Classes of the `<summary>`."
  end

  slot :inner_block, required: true

  def collapse(assigns) do
    assigns =
      assigns
      |> assign(:on_open_js, Overlay.callback(assigns.on_open, assigns.id, assigns.target))
      |> assign(:on_close_js, Overlay.callback(assigns.on_close, assigns.id, assigns.target))

    ~H"""
    <details
      id={@id}
      class={merge(["linea-collapse", @chevron && "group/collapse", @class])}
      open={@open}
      phx-hook="LineaUI.Collapse"
      phx-mounted={JS.ignore_attributes(["open", "name"])}
      data-open={bool(@open)}
      data-variant={@variant not in [nil, "classic"] && @variant}
      data-on-open={@on_open_js}
      data-on-close={@on_close_js}
      {@rest}
    >
      <summary
        :for={trigger <- @trigger}
        class={
          merge([
            "cursor-pointer",
            @chevron && "flex items-center justify-between",
            Map.get(trigger, :class)
          ])
        }
      >
        {render_slot(trigger)}
        <.chevron_icon :if={@chevron} kind={@chevron} class={@chevron_class} />
      </summary>
      <div class={merge(["ac-panel", @panel_class])}>{render_slot(@inner_block)}</div>
    </details>
    """
  end

  @doc """
  A text clamped to `lines` lines, with a link under it that shows the rest ("show more") and
  hides it again ("show less"). It works in the browser (no event to the server); the link has
  `aria-expanded` and `aria-controls`.

      <.collapse_text id="desc" lines={3} more="Mostrar mais" less="Mostrar menos">
        {@product.description}
      </.collapse_text>
  """
  attr :id, :string, required: true
  attr :lines, :integer, default: 2, doc: "How many lines show while it is closed."
  attr :open, :boolean, default: false, doc: "Starts with the whole text shown."
  attr :more, :string, default: "Show more", doc: "The link while the text is clamped."
  attr :less, :string, default: "Show less", doc: "The link while the whole text shows."
  attr :class, :any, default: nil, doc: "Merged into the wrapper."
  attr :text_class, :any, default: nil, doc: "Merged into the text."
  attr :rest, :global
  slot :inner_block, required: true

  def collapse_text(assigns) do
    ~H"""
    <div id={@id} class={merge(["collapse-text", @class])} data-open={@open && "true"} {@rest}>
      <p
        id={"#{@id}-text"}
        class={merge(["collapse-text-body m-0", @text_class])}
        style={"--lines: #{@lines}"}
      >
        {render_slot(@inner_block)}
      </p>
      <button
        type="button"
        class="collapse-text-toggle"
        aria-controls={"#{@id}-text"}
        aria-expanded={to_string(@open)}
        phx-click={
          JS.toggle_attribute({"data-open", "true"}, to: "##{@id}")
          |> JS.toggle_attribute({"aria-expanded", "true", "false"})
        }
      >
        <span class="collapse-text-more">{@more}</span><span class="collapse-text-less">{@less}</span>
      </button>
    </div>
    """
  end

  attr :kind, :string, required: true
  attr :class, :any, default: nil

  defp chevron_icon(%{kind: "right"} = assigns) do
    ~H"""
    <.glyph
      name={:chevron_right}
      class={
        merge([
          "size-4 shrink-0 text-slate-400 transition-transform group-open/collapse:rotate-90 dark:text-navy-300",
          @class
        ])
      }
      stroke_width="2"
    />
    """
  end

  defp chevron_icon(assigns) do
    ~H"""
    <.glyph
      name={:chevron_down}
      class={
        merge([
          "size-4 shrink-0 text-slate-400 transition-transform group-open/collapse:rotate-180 dark:text-navy-300",
          @class
        ])
      }
      stroke_width="2"
    />
    """
  end
end
