defmodule LineaUI.Components.Divider do
  @moduledoc """
  LineOne's divider: a hairline between stacked or side-by-side content, with optional text in
  the middle.

      <.divider />
      <.divider>OR</.divider>
      <div class="flex">
        <div>…</div>
        <.divider orientation="vertical">OR</.divider>
        <div>…</div>
      </div>

  `horizontal` is a horizontal line between content stacked vertically (what LineOne's page calls
  "Divider Vertical"); `vertical` is a vertical line in a row.
  """

  use LineaUI.Component

  @line "bg-slate-200 dark:bg-navy-500"

  @doc "Renders a divider, with the inner block as its text when given."
  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def divider(%{inner_block: [], orientation: "horizontal"} = assigns) do
    ~H"""
    <div role="separator" class={merge(["my-4 h-px", line(), @class])} {@rest}></div>
    """
  end

  def divider(%{inner_block: []} = assigns) do
    ~H"""
    <div
      role="separator"
      aria-orientation="vertical"
      class={merge(["mx-4 my-1 w-px", line(), @class])}
      {@rest}
    >
    </div>
    """
  end

  def divider(%{orientation: "horizontal"} = assigns) do
    ~H"""
    <div role="separator" class={merge(["my-4 flex items-center space-x-3", @class])} {@rest}>
      <div class={["h-px flex-1", line()]}></div>
      <p>{render_slot(@inner_block)}</p>
      <div class={["h-px flex-1", line()]}></div>
    </div>
    """
  end

  def divider(assigns) do
    ~H"""
    <div
      role="separator"
      aria-orientation="vertical"
      class={merge(["mx-4 flex flex-col items-center space-y-3", @class])}
      {@rest}
    >
      <div class={["w-px flex-1", line()]}></div>
      <p>{render_slot(@inner_block)}</p>
      <div class={["w-px flex-1", line()]}></div>
    </div>
    """
  end

  defp line, do: @line
end
