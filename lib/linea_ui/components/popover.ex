defmodule LineaUI.Components.Popover do
  @moduledoc """
  LineOne's popover: a white card with an arrow next to its trigger, for more than a tooltip
  holds (text, tags, people, a small form).

      <.popover id="lesson">
        <:trigger><.button color="primary">Lessons</.button></:trigger>
        <:title>Group Lesson</:title>
        <p class="mt-2">Lorem ipsum dolor sit amet.</p>
      </.popover>

      <.popover id="john" trigger_on="hover" placement="top" class="w-48 px-4 py-5 text-center">
        <:trigger><div class="avatar size-8">…</div></:trigger>
        …
      </.popover>

  The default placement is LineOne's `right-start`, falling back to the bottom and the top when
  there is no room. It opens and closes from the browser (`LineaUI.toggle("lesson")`), from the
  server (`LineaUI.close(socket, "lesson")`) or from `open`; a click outside and Esc close it and
  `on_close` runs however it closed.

  The card floats above the page: opened, it sits in the browser's top layer (`popover="manual"`,
  `position: fixed`, placed from the trigger's rectangle), so a scroll area, a drawer's body or an
  ancestor's `z-index` / `transform` neither clip nor cover it. It follows scrolling, flips when
  there is no room and closes when its trigger scrolls out of sight; it stays in the LiveView's DOM,
  so patches and events inside it work as usual.
  """

  use LineaUI.Component

  alias LineaUI.Components.Overlay

  @placements ~w(bottom-start bottom bottom-end top-start top top-end left-start left left-end right-start right right-end)

  @doc """
  Renders a popover.

  Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.
  """
  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :placement, :string, default: "right-start", values: @placements

  attr :fallbacks, :list,
    default: ~w(bottom top),
    doc: "The sides tried, in order, when the placement has no room."

  attr :offset, :integer, default: 12, doc: "Pixels between the trigger and the card."
  attr :trigger_on, :string, default: "click", values: ~w(click hover)
  attr :arrow, :boolean, default: true
  attr :on_open, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :on_close, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil, doc: "The `phx-target` of `on_open` / `on_close` events."
  attr :class, :any, default: nil, doc: "Merged into the card (`max-w-xs`, `w-72 p-3`...)."
  attr :rest, :global
  slot :trigger, required: true
  slot :title, doc: "LineOne's card title."
  slot :inner_block

  def popover(assigns) do
    assigns =
      assigns
      |> assign(:on_open_js, Overlay.callback(assigns.on_open, assigns.id, assigns.target))
      |> assign(:on_close_js, Overlay.callback(assigns.on_close, assigns.id, assigns.target))

    ~H"""
    <div
      id={@id}
      class="relative flex"
      phx-hook="LineaUI.Popover"
      data-popup="dialog"
      data-open={bool(@open)}
      data-placement={@placement}
      data-fallbacks={Enum.join(@fallbacks, ",")}
      data-offset={@offset}
      data-padding="10"
      data-trigger-on={@trigger_on}
      data-on-open={@on_open_js}
      data-on-close={@on_close_js}
      {@rest}
    >
      <div data-trigger class="flex">{render_slot(@trigger)}</div>
      <div
        id={"#{@id}-panel"}
        class="popper-root fixed left-0 top-0 w-max"
        popover="manual"
        role="dialog"
        data-panel
        aria-hidden="true"
        phx-mounted={JS.ignore_attributes(["class", "style", "data-popper-placement", "aria-hidden"])}
      >
        <div class="popper-box">
          <div class={
            merge([
              "rounded-md border border-slate-150 bg-white p-4 dark:border-navy-600 dark:bg-navy-700",
              @class
            ])
          }>
            <h3
              :for={title <- @title}
              class="text-base font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100"
            >
              {render_slot(title)}
            </h3>
            {render_slot(@inner_block)}
          </div>
          <div :if={@arrow} class="size-4" data-popper-arrow>
            <svg
              viewBox="0 0 16 9"
              xmlns="http://www.w3.org/2000/svg"
              class="absolute size-4"
              fill="currentColor"
            >
              <path
                class="text-slate-150 dark:text-navy-600"
                d="M1.5 8.357s-.48.624 2.754-4.779C5.583 1.35 6.796.01 8 0c1.204-.009 2.417 1.33 3.76 3.578 3.253 5.43 2.74 4.78 2.74 4.78h-13z"
              />
              <path
                class="text-white dark:text-navy-700"
                d="M0 9s1.796-.017 4.67-4.648C5.853 2.442 6.93 1.293 8 1.286c1.07-.008 2.147 1.14 3.343 3.066C14.233 9.006 15.999 9 15.999 9H0z"
              />
            </svg>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
