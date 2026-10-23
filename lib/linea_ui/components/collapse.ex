defmodule LineaUI.Components.Collapse do
  @moduledoc """
  A section that opens and closes under its trigger, with LineOne's 200ms height animation. It is
  the piece LineOne's Collapse and Accordion pages are built from (see `LineaUI.Components.Accordion`).

      <.collapse id="details">
        <:trigger class="flex items-center justify-between py-4 font-medium">Shipping details</:trigger>
        <p>Ships in two days.</p>
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
      class={merge(["linea-collapse", @class])}
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
        class={merge(["cursor-pointer outline-hidden", Map.get(trigger, :class)])}
      >
        {render_slot(trigger)}
      </summary>
      <div class="ac-panel">{render_slot(@inner_block)}</div>
    </details>
    """
  end
end
