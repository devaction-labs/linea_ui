defmodule LineaUI.Components.Sticky do
  @moduledoc """
  A block that sticks to the top of the page and takes classes while the page is scrolled: a header that gets an edge, a bar that gets a shadow.

      <.sticky id="page-bar" stuck_class="border-b border-slate-200 shadow-xs">
        …
      </.sticky>

  The hook `LineaUI.Sticky` adds `stuck_class` and sets `data-stuck` once the page is scrolled past `offset` pixels and
  takes them off when it is back. The block is `sticky top-0`.
  """

  use LineaUI.Component

  @doc """
  Renders the sticky block.

      <.sticky id="bar" offset={8} stuck_class="shadow-md">…</.sticky>
  """
  attr :id, :string, required: true

  attr :offset, :integer,
    default: 0,
    doc: "How many pixels the page scrolls before the block counts as stuck."

  attr :stuck_class, :string,
    default: "border-b border-slate-200 dark:border-navy-450",
    doc: "Classes added while stuck."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def sticky(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="LineaUI.Sticky"
      phx-mounted={JS.ignore_attributes(["data-stuck", "class"])}
      data-offset={@offset}
      data-stuck-class={@stuck_class}
      class={merge(["sticky top-0 z-10 border-b border-transparent", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
