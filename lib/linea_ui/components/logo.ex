defmodule LineaUI.Components.Logo do
  @moduledoc """
  The LineaUI mark: a drop inside a hexagon, after the DevAction Hub logo. The ring follows the page's ink (dark on
  light, silver on dark), the body stays near-black and the drop takes the theme's accent, so it changes with
  `theme_picker/1`. `tone="mono"` draws the drop in light silver instead, as the Hub does on black.

      <.linea_logo />
      <.linea_logo size={24} wordmark />
      <.linea_logo id="hero-logo" size={96} tone="mono" />

  Each logo's gradients are named after its `id`; give one when the page has more than one logo with different
  tones.
  """

  use LineaUI.Component

  attr :id, :string, default: "linea-logo", doc: "Names the gradients."
  attr :size, :integer, default: 32, doc: "The side of the mark, in px."

  attr :tone, :string,
    default: "accent",
    values: ~w(accent mono),
    doc: "The drop: the theme's accent or silver."

  attr :wordmark, :boolean, default: false, doc: "Adds \"LineaUI\" after the mark."
  attr :label, :string, default: "LineaUI", doc: "The accessible name."
  attr :class, :any, default: nil
  attr :rest, :global

  def linea_logo(assigns) do
    ~H"""
    <span class={merge(["sg-logo", @class])} {@rest}>
      <svg
        viewBox="0 0 64 64"
        width={@size}
        height={@size}
        role="img"
        aria-label={@label}
        class={["sg-logo-mark", @size < 24 && "small"]}
      >
        <defs>
          <linearGradient id={"#{@id}-r"} x1="10" y1="6" x2="56" y2="58" gradientUnits="userSpaceOnUse">
            <stop style="stop-color:var(--logo-ring-0,var(--ink))" />
            <stop offset="1" style="stop-color:var(--logo-ring-1,var(--faint))" />
          </linearGradient>
          <linearGradient id={"#{@id}-b"} x1="14" y1="12" x2="50" y2="54" gradientUnits="userSpaceOnUse">
            <stop style="stop-color:var(--logo-body-0,#262a36)" />
            <stop offset="1" style="stop-color:var(--logo-body-1,#020209)" />
          </linearGradient>
        </defs>
        <path
          class="ring"
          d="M27.24 5.15Q32 2.4 36.76 5.15L52.87 14.45Q57.63 17.2 57.63 22.7L57.63 41.3Q57.63 46.8 52.87 49.55L36.76 58.85Q32 61.6 27.24 58.85L11.13 49.55Q6.37 46.8 6.37 41.3L6.37 22.7Q6.37 17.2 11.13 14.45Z"
          fill="none"
          stroke={"url(##{@id}-r)"}
        />
        <path
          d="M27.67 11.9Q32 9.4 36.33 11.9L47.24 18.2Q51.57 20.7 51.57 25.7L51.57 38.3Q51.57 43.3 47.24 45.8L36.33 52.1Q32 54.6 27.67 52.1L16.76 45.8Q12.43 43.3 12.43 38.3L12.43 25.7Q12.43 20.7 16.76 18.2Z"
          fill={"url(##{@id}-b)"}
        />
        <path
          class={["drop", @tone]}
          d="M34.2 15.2C33.4 21.6 21.4 27.2 21.4 37.6A11 11 0 0 0 43.4 37.6C43.4 31.4 36.4 28.6 34.7 23.4C33.9 20.9 33.9 18 34.2 15.2Z"
        />
      </svg>
      <span :if={@wordmark} class="sg-logo-word" aria-hidden="true">Linea<b>UI</b></span>
    </span>
    """
  end
end
