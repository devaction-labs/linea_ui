defmodule LineaUI.Components.Divider do
  @moduledoc """
  daisyUI's divider (`divider`, `divider-horizontal`, `divider-start`): a line between stacked or side-by-side
  content, with optional text in the middle.

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
    <div role="separator" class={merge(["divider my-2", @class])} {@rest}></div>
    """
  end

  def divider(%{inner_block: []} = assigns) do
    ~H"""
    <div
      role="separator"
      aria-orientation="vertical"
      class={merge(["divider divider-horizontal mx-2", @class])}
      {@rest}
    >
    </div>
    """
  end

  def divider(%{orientation: "horizontal", align: "left"} = assigns) do
    ~H"""
    <div
      role="separator"
      class={
        merge([
          "divider divider-start my-2 text-[11.5px] font-bold tracking-[.06em] text-base-content/50 uppercase",
          @class
        ])
      }
      {@rest}
    >
      <b>{render_slot(@inner_block)}</b>
    </div>
    """
  end

  def divider(%{orientation: "horizontal"} = assigns) do
    ~H"""
    <div role="separator" class={merge(["divider my-2 text-xs text-base-content/50", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  def divider(assigns) do
    ~H"""
    <div
      role="separator"
      aria-orientation="vertical"
      class={merge(["divider divider-horizontal mx-2 text-xs text-base-content/50", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
