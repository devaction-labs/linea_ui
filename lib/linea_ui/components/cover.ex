defmodule LineaUI.Components.Cover do
  @moduledoc """
  The canvas cover: a wide band in the accent gradient (or a quiet dotted surface) that heads a
  profile or a page, with a title on it, or a record's avatar overlapping its lower edge.

      <.cover title="Distribuidora Sertão" />

      <.cover height={110} title="Distribuidora Sertão" subtitle="Cliente desde 2021">
        <:avatar><.avatar name="Distribuidora Sertão" tint="#1a7f4b" size="64" shape="rounded" /></:avatar>
      </.cover>

      <.cover tone="neutral" height={120} />

  `tone` is `accent` (the teal gradient, white text) or `neutral` (the sunken surface with a dot
  pattern). `src` lays a picture over the band. Without `:avatar` the `title` is written on the
  band, at the bottom; with it, the avatar overlaps the band's lower edge, ringed in the surface
  color, with the `title` and `subtitle` beside it. The inner block goes on the band (actions,
  a badge).
  """

  use LineaUI.Component

  attr(:tone, :string, default: "accent", values: ~w(accent neutral))
  attr(:height, :integer, default: 180, doc: "The band's height in pixels.")
  attr(:src, :string, default: nil, doc: "A picture that covers the band.")
  attr(:title, :string, default: nil)
  attr(:subtitle, :string, default: nil, doc: "Under the `title`, beside the `:avatar`.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:avatar, doc: "An avatar that overlaps the band's lower edge.")
  slot(:inner_block, doc: "Content on the band.")

  def cover(%{avatar: []} = assigns) do
    ~H"""
    <div
      class={merge(["linea-cover", @class])}
      data-tone={@tone}
      style={band_style(@height, @src)}
      {@rest}
    >
      <b :if={@title} class="linea-cover-title">{@title}</b>
      {render_slot(@inner_block)}
    </div>
    """
  end

  def cover(assigns) do
    ~H"""
    <div class={merge(["linea-cover-profile", @class])} {@rest}>
      <div class="linea-cover" data-tone={@tone} style={band_style(@height, @src)}>
        {render_slot(@inner_block)}
      </div>
      <div class="linea-cover-head">
        <span class="linea-cover-avatar">{render_slot(@avatar)}</span>
        <div :if={@title || @subtitle} class="linea-cover-text">
          <b :if={@title} class="linea-cover-name">{@title}</b>
          <span :if={@subtitle} class="linea-cover-sub">{@subtitle}</span>
        </div>
      </div>
    </div>
    """
  end

  defp band_style(height, nil), do: "height: #{height}px"

  defp band_style(height, src),
    do:
      "height: #{height}px; background-image: url(\"#{src}\"); background-size: cover; background-position: center"
end
