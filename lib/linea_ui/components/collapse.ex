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

  It is a native `<details>`: the trigger works with the mouse and the keyboard and the browser
  owns `open`, which survives patches. When the server changes `open`, the server wins.
  `LineaUI.open/close/toggle("details")` (and their socket forms) open and close it too, and
  `on_open` / `on_close` run on every toggle; as event names they push `%{"id" => id}` to the
  LiveView (or `target`).
  """

  use LineaUI.Component

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
      data-on-open={@on_open_js}
      data-on-close={@on_close_js}
      {@rest}
    >
      <summary
        :for={trigger <- @trigger}
        class={
          merge([
            "cursor-pointer outline-hidden",
            @chevron && "flex items-center justify-between",
            Map.get(trigger, :class)
          ])
        }
      >
        {render_slot(trigger)}
        <.chevron_icon :if={@chevron} kind={@chevron} class={@chevron_class} />
      </summary>
      <div class="ac-panel">{render_slot(@inner_block)}</div>
    </details>
    """
  end

  attr :kind, :string, required: true
  attr :class, :any, default: nil

  defp chevron_icon(%{kind: "right"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={merge(["size-3.5 shrink-0 transition-transform group-open/collapse:rotate-90", @class])}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="2.5"
      aria-hidden="true"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
    </svg>
    """
  end

  defp chevron_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={merge(["size-3.5 shrink-0 transition-transform group-open/collapse:rotate-180", @class])}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="2.5"
      aria-hidden="true"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
    </svg>
    """
  end
end
