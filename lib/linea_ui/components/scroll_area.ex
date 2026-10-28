defmodule LineaUI.Components.ScrollArea do
  @moduledoc """
  A box that scrolls with LineOne's thin scrollbar (`scrollbar-sm`): 6px, no arrows, a transparent
  track and a thumb that shows when the pointer or the focus is inside. For long menus, lists in
  a card, the body of a panel.

      <.scroll_area class="max-h-64">
        <.dropdown_item :for={city <- @cities}>{city}</.dropdown_item>
      </.scroll_area>

  The height comes from `class` (`max-h-64`, `h-full`...). Without the component, the same
  scrollbar is the `scrollbar-sm` class on any box that overflows; `scrollbar-sm scrollbar-always`
  keeps the thumb shown, and LineOne's `is-scrollbar-hidden` hides it.

  `focusable` lets the keyboard scroll the box and draws a 2px focus ring around it. A focusable box
  needs a name, so give it a `label`:

      <.scroll_area focusable label="Release notes" class="max-h-64">…</.scroll_area>

  ## Pinned to the bottom

  `stick_bottom` keeps a list that grows at its end, a chat or a stream of replies, scrolled to its
  last item: the `LineaUI.ScrollBottom` hook scrolls down when the box mounts and each time the
  server patches it, unless the reader scrolled up to read (within 32px of the end counts as the
  end; scrolling back down pins it again). It needs a stable `id`.

      <.scroll_area id="messages" stick_bottom class="h-96 px-4 py-5">
        <.message :for={message <- @messages} message={message} />
      </.scroll_area>
  """

  use LineaUI.Component

  @orientations %{
    "vertical" => "overflow-x-hidden overflow-y-auto overscroll-contain",
    "horizontal" => "overflow-x-auto overflow-y-hidden overscroll-x-contain",
    "both" => "overflow-auto overscroll-contain"
  }

  @scrollbars %{
    "hover" => "scrollbar-sm",
    "always" => "scrollbar-sm scrollbar-always",
    "hidden" => "is-scrollbar-hidden"
  }

  @doc """
  Renders a scrolling box.
  """
  attr :orientation, :string,
    default: "vertical",
    values: Map.keys(@orientations),
    doc: "The directions it scrolls in."

  attr :scrollbar, :string,
    default: "hover",
    values: Map.keys(@scrollbars),
    doc:
      "`hover` shows the thumb under the pointer or the focus, `always` keeps it, `hidden` hides it."

  attr :focusable, :boolean,
    default: false,
    doc:
      "Makes the box reachable with Tab, so the keyboard can scroll it (when nothing inside takes focus)."

  attr :label, :string,
    default: nil,
    doc:
      "With `focusable`, the box becomes a `role=\"region\"` named by this `aria-label`, so a screen reader says what the focus landed on. Ignored when it is not focusable."

  attr :id, :string, default: nil, doc: "Required with `stick_bottom`, and it must not change."

  attr :stick_bottom, :boolean,
    default: false,
    doc: "Keeps the box scrolled to its end when content is added, unless the reader scrolled up."

  attr :class, :any, default: nil, doc: "Its size (`max-h-64`, `h-full`) and padding."
  attr :rest, :global
  slot :inner_block, required: true

  def scroll_area(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook={@stick_bottom && "LineaUI.ScrollBottom"}
      class={
        merge([
          orientation_class(@orientation),
          scrollbar_class(@scrollbar),
          "min-h-0",
          @class
        ])
      }
      tabindex={@focusable && "0"}
      role={@focusable && @label && "region"}
      aria-label={@focusable && @label}
      data-scroll-area
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp orientation_class(orientation), do: Map.fetch!(@orientations, orientation)
  defp scrollbar_class(scrollbar), do: Map.fetch!(@scrollbars, scrollbar)
end
