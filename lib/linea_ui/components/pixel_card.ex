defmodule LineaUI.Components.PixelCard do
  @moduledoc """
  The canvas's pixel card: a card to choose from (a model, a module, an integration) that, on hover or keyboard
  focus, lights up a matrix of pixels in its top right corner, in the card's colour. The pixels blink in frames
  (the pattern changes every 0.3s) and fade towards the centre, so the text stays readable.

      <.pixel_card navigate={~p"/novo/loja"} color="red" icon="huge-shopping-cart-01"
        title="Loja" description="PDV, estoque, NFC-e" />

      <div class="grid grid-cols-3 gap-2.5">
        <.pixel_card navigate={~p"/novo/loja"} color="red" icon="huge-shopping-cart-01"
          title="Loja" description="PDV, estoque, NFC-e" />
        <.pixel_card phx-click="pick" phx-value-id="agenda" color="ink" icon="huge-calendar-03"
          title="Agenda" description="Horários e lembretes" />
      </div>

  With `href`, `navigate` or `patch` the card is a link (`<a>`); with none it is a `<button type="button">` that
  takes `phx-click` and the other events through `rest`. Both are focusable, and the keyboard focus does what the
  hover does: the pixels, the stronger outline and the arrow (`arrow={false}` leaves the arrow out).

  `color` takes a palette name (`red`, `rose`, `green`, `teal`, `blue`, `violet`, `amber`, `ink`); without it the
  card takes the accent. Any other colour goes through the `--px` custom property:

      <.pixel_card title="Marca" description="--px: var(--accent)" style="--px: #f97316" />

  The cards sit in a 3-column grid of the canvas with `sg-px-grid`, and `sg-px-sec` is the heading of a section of
  them (a bold name over a muted line); both are plain classes.

  ## How the pixels blink

  There is no JavaScript. The card's `::before` is masked by a 60px tile of 2.6px squares (three tiles, `--pxa`,
  `--pxb` and `--pxc`, each with its own random pattern and opacities) intersected with a radial gradient from the
  top right corner. A stepped keyframe (`sg-px-twinkle`, `.9s steps(1)`) swaps the tile every 0.3s. Under
  `prefers-reduced-motion: reduce` the animation is off: the first tile stays drawn, lit on hover and focus.
  """

  use LineaUI.Component

  alias LineaUI.Components.Icon

  attr(:title, :string, required: true, doc: "The bold name of the option.")
  attr(:description, :string, default: nil, doc: "The muted line under the name.")

  attr(:icon, :string,
    default: nil,
    doc: "A Hugeicons name, drawn white in a round chip of the card's colour."
  )

  attr(:color, :string,
    default: nil,
    values: [nil | ~w(red rose green teal blue violet amber ink)],
    doc: "A palette name; any other colour goes in `style=\"--px: …\"`. The accent when none."
  )

  attr(:arrow, :boolean,
    default: true,
    doc: "The arrow that appears at the bottom right on hover and focus."
  )

  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include: ~w(href navigate patch method disabled),
    doc:
      "`href`, `navigate` or `patch` make it a link; otherwise it is a button and takes `phx-click`."
  )

  slot(:inner_block, doc: "Extra content under the description.")

  def pixel_card(%{rest: rest} = assigns)
      when is_map_key(rest, :href) or is_map_key(rest, :navigate) or is_map_key(rest, :patch) do
    ~H"""
    <.link class={classes(@color, @class)} {@rest}>
      <.body icon={@icon} title={@title} description={@description} arrow={@arrow}>
        {render_slot(@inner_block)}
      </.body>
    </.link>
    """
  end

  def pixel_card(assigns) do
    ~H"""
    <button type="button" class={classes(@color, @class)} {@rest}>
      <.body icon={@icon} title={@title} description={@description} arrow={@arrow}>
        {render_slot(@inner_block)}
      </.body>
    </button>
    """
  end

  defp classes(color, class), do: merge(["sg-px", color, class])

  attr(:icon, :string, default: nil)
  attr(:title, :string, required: true)
  attr(:description, :string, default: nil)
  attr(:arrow, :boolean, default: true)
  slot(:inner_block)

  defp body(assigns) do
    ~H"""
    <span :if={@icon} class="ico"><Icon.icon name={@icon} class="size-[13px]" /></span>
    <b>{@title}</b>
    <span :if={@description} class="d">{@description}</span>
    {render_slot(@inner_block)}
    <span :if={@arrow} class="go" aria-hidden="true">
      <Icon.icon name="huge-arrow-up-right-01" class="size-3.5" />
    </span>
    """
  end
end
