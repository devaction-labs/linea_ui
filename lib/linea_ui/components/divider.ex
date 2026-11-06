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

  With text, `align="left"` puts it at the start as a small uppercase title, the line running to
  the end: the heading of a group of fields.

      <.divider align="left">Entrega</.divider>

  `horizontal` is a horizontal line between content stacked vertically (what LineOne's page calls
  "Divider Vertical"); `vertical` is a vertical line in a row.
  """

  use LineaUI.Component

  # the canvas `--line`, in light and dark
  @line "bg-(--line)"

  @doc """
  Renders a divider, with the inner block as its text when given.

      <.divider>OR</.divider>
      <.divider orientation="vertical" />
  """
  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))

  attr(:align, :string,
    default: "center",
    values: ~w(center left),
    doc:
      "Where a horizontal divider's text sits: `center` between two lines, `left` as a small uppercase title before one."
  )

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

  def divider(%{orientation: "horizontal", align: "left"} = assigns) do
    ~H"""
    <div role="separator" class={merge(["my-4 flex items-center gap-2.5", @class])} {@rest}>
      <b class="text-[11.5px] font-bold tracking-[.06em] text-(--faint) uppercase">
        {render_slot(@inner_block)}
      </b>
      <div class={["h-px flex-1", line()]}></div>
    </div>
    """
  end

  def divider(%{orientation: "horizontal"} = assigns) do
    ~H"""
    <div
      role="separator"
      class={merge(["my-4 flex items-center gap-3 text-xs/5 text-(--faint)", @class])}
      {@rest}
    >
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
