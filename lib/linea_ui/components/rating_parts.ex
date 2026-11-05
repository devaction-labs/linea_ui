defmodule LineaUI.Components.RatingParts do
  @moduledoc """
  A static star rating as parts: a row and its cells, each holding a solid and an outline star (the classes
  `rating-on` and `rating-off` on the icons). A cell shows the solid star when `on`.

      <.rating_row>
        <.rating_cell on>
          <.icon name="solid-star" class="rating-on text-base" />
          <.icon name="outline-star" class="rating-off text-base" />
        </.rating_cell>
        <.rating_cell>...</.rating_cell>
      </.rating_row>

  Use `rating/1` for a rating the user can set.
  """

  use LineaUI.Component

  @doc "The row of stars."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def rating_row(assigns) do
    ~H"""
    <div class={merge(["rating-row", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "One star; `on` shows the solid one, `half` the solid one over the left half of the outline (give the solid icon `style=\"width: 50%\"`)."
  attr :on, :boolean, default: false
  attr :half, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def rating_cell(assigns) do
    ~H"""
    <div class={merge(["rating-cell", @class])} data-on={@on || nil} data-half={@half || nil} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
