defmodule LineaUI.Components.Mask do
  @moduledoc """
  Crops its content to one of LineOne's mask shapes: squircle, reuleaux triangle, diamond,
  hexagon, octagon, star or heart.

      <.mask shape="heart" src="/images/avatar.jpg" alt="Jane" class="size-36" />
      <.mask shape="hexagon" class="size-20 bg-primary">
        <span>JD</span>
      </.mask>

  With `src` it renders the masked image itself; otherwise a block holding the inner content.
  """

  use LineaUI.Component

  @shapes %{
    "squircle" => "mask is-squircle",
    "reuleaux-triangle" => "mask is-reuleaux-triangle",
    "diamond" => "mask is-diamond",
    "hexagon" => "mask is-hexagon",
    "hexagon-2" => "mask is-hexagon-2",
    "octagon" => "mask is-octagon",
    "star" => "mask is-star",
    "star-2" => "mask is-star-2",
    "heart" => "mask is-heart"
  }

  @doc "The shape names `mask/1` takes."
  @spec mask_shapes() :: [String.t()]
  def mask_shapes, do: Map.keys(@shapes)

  @doc "The classes of a mask shape, for elements that wear the mask themselves."
  @spec mask_class(String.t()) :: String.t()
  def mask_class(shape), do: Map.fetch!(@shapes, shape)

  @doc """
  Renders a masked image (with `src`) or a masked block around the inner content. Size it
  with `class`.

      <.mask shape="hexagon" src={@user.photo} alt={@user.name} class="size-20" />
  """
  attr(:shape, :string,
    default: "squircle",
    values: ~w(squircle reuleaux-triangle diamond hexagon hexagon-2 octagon star star-2 heart)
  )

  attr(:src, :string, default: nil)
  attr(:alt, :string, default: "")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def mask(%{src: src} = assigns) when is_binary(src) do
    ~H"""
    <div class={merge(["relative inline-flex size-10 shrink-0", @class])} {@rest}>
      <img
        src={@src}
        alt={@alt}
        class={[mask_class(@shape), "h-full w-full object-cover object-center"]}
      />
    </div>
    """
  end

  def mask(assigns) do
    ~H"""
    <div class={merge([mask_class(@shape), @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end
end
