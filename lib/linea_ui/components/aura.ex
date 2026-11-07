defmodule LineaUI.Components.Aura do
  @moduledoc """
  The canvas's aura: a ring of light that runs along the border of any element while something works in
  the background (the assistant, a slow request). The inner content keeps its own look; the aura only
  draws the ring around it, over the box's border, and rounds the child to `radius`.

      <.aura tone="ai">
        <.toast_card icon="huge-sparkles" title="Assistant reading the invoice" dismissible={false} />
      </.aura>

      <.aura tone="ai" radius="pill" width="sm"><.button>Summarize</.button></.aura>
      <.aura mode="glow" tone="warn" shadow>…needs you…</.aura>

  `mode` is `spin` (a light turns while it works), `dual` (two colors, for a result that is ready) or
  `glow` (pulses, without turning, when it needs the person). `tone` picks the light: `ai` (teal and
  violet), `info`, `pos`, `warn`, `neg`, `violet`, or the accent by default. The ring stops turning for
  people who ask for reduced motion.
  """

  use LineaUI.Component

  @modes ~w(spin dual glow)
  @tones ~w(accent ai info pos warn neg violet)
  @widths ~w(xs sm default lg)
  @radii ~w(default pill r12)

  @doc "The modes an aura takes."
  @spec aura_modes() :: [String.t()]
  def aura_modes, do: @modes

  attr :mode, :string,
    default: "spin",
    values: @modes,
    doc: "`spin` turns one light, `dual` two colors, `glow` pulses instead of turning."

  attr :tone, :string,
    default: "accent",
    values: @tones,
    doc: "The light: the accent, `ai` (teal and violet), or a status tone."

  attr :width, :string,
    default: "default",
    values: @widths,
    doc: "The thickness of the ring: 0.75px, 1px, 1.25px (default) or 2px."

  attr :radius, :string,
    default: "default",
    values: @radii,
    doc: "The corner of the child: 16px, a pill or 12px."

  attr :shadow, :boolean, default: false, doc: "A soft drop shadow under the ring."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def aura(assigns) do
    ~H"""
    <div
      class={
        merge([
          "sg-aura",
          @shadow && "sg-aura-shadow",
          tone_class(@tone),
          mode_class(@mode),
          width_class(@width),
          radius_class(@radius),
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp tone_class("accent"), do: nil
  defp tone_class(tone), do: tone

  defp mode_class("spin"), do: nil
  defp mode_class(mode), do: mode

  defp width_class("default"), do: nil
  defp width_class(width), do: width

  defp radius_class("default"), do: nil
  defp radius_class(radius), do: radius
end
