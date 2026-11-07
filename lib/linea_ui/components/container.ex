defmodule LineaUI.Components.Container do
  @moduledoc """
  The page containers: `container_fixed/1` centers its content up to the `xl` breakpoint,
  `container_fluid/1` fills the width. Both keep a 24px gutter, 30px from `xl` on.

      <.container_fixed>
        <h1>Title</h1>
      </.container_fixed>
  """

  use LineaUI.Component

  @fixed "w-full grow px-6 xl:mx-auto xl:max-w-(--breakpoint-xl) xl:px-7.5"
  @fluid "w-full grow px-6 xl:px-7.5"

  @doc "A centered container, as wide as the `xl` breakpoint at most."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def container_fixed(assigns) do
    assigns = assign(assigns, :base, @fixed)

    ~H"""
    <div class={merge([@base, @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "A container as wide as its parent."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def container_fluid(assigns) do
    assigns = assign(assigns, :base, @fluid)

    ~H"""
    <div class={merge([@base, @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end
end
