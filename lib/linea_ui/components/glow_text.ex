defmodule LineaUI.Components.GlowText do
  @moduledoc """
  Text with a living gradient: the colors drift across the letters. The animation slows down
  under `prefers-reduced-motion`.

      <.glow_text as="h1">Signetum</.glow_text>
      <.glow_text tone="warm">New</.glow_text>
  """

  use LineaUI.Component

  @doc """
  Renders the gradient text.

      <.glow_text tone="warm" as="h2">Welcome back</.glow_text>
  """
  attr :tone, :string, default: "default", values: ~w(default warm)
  attr :as, :string, default: "span", values: ~w(span h1 h2 h3 p), doc: "The HTML tag."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def glow_text(assigns) do
    ~H"""
    <.dynamic_tag
      tag_name={@as}
      class={merge(["sg-glow-text", @tone == "warm" && "warm", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end
end
