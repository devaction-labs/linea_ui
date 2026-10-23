defmodule LineaUI.Components.Carousel do
  @moduledoc """
  LineOne's Swiper carousels, without Swiper: slides on a CSS scroll-snap track, and the
  `LineaUI.Carousel` hook for arrows, pagination, autoplay, keyboard, swipe and effects.

      <.carousel id="gallery" navigation class="rounded-lg">
        <.carousel_slide><img class="h-full w-full object-cover" src="/a.jpg" alt="" /></.carousel_slide>
        <.carousel_slide><img class="h-full w-full object-cover" src="/b.jpg" alt="" /></.carousel_slide>
      </.carousel>

      <.carousel id="promo" pagination="bullets" autoplay={2000} loop>…</.carousel>
      <.carousel id="tall" direction="vertical" pagination="bullets" class="h-64">…</.carousel>
      <.carousel id="flip" effect="flip" navigation pagination="bullets">…</.carousel>
      <.carousel id="peek" gap={30} pagination="bullets">
        <.carousel_slide class="w-10/12">…</.carousel_slide>
      </.carousel>

  `effect` is one of LineOne's: `slide` (the scrolling track), `fade`, `flip`, `cube`,
  `cards`, `coverflow` and `creative` (slides stacked and moved with CSS transforms).
  `pagination` is `bullets` (clickable), `fraction`, `progress` (the bar on top) or
  `scrollbar` (a draggable bar at the bottom). `zoom={4}` zooms a slide on double click.
  A `:background` slot with `data-carousel-parallax="-23%"` on it, and elements inside slides
  with `data-carousel-parallax="-300"`, move at their own pace while the track scrolls.

  ## State

  `index` is the server's slide. The person can move freely in the browser, and their slide
  survives patches; when the server changes `index`, the carousel goes there.

  ## Events

  `on_change` (an event name or `%JS{}`) runs when the active slide changes; an event name is
  pushed with `%{"id" => id, "index" => index}` (zero-based) to `target`, or to the LiveView.

  From the server, `push_event(socket, "linea:carousel", %{id: "gallery", index: 2})` moves it.
  """

  use LineaUI.Component

  @arrow "M0.38296 20.0762C0.111788 19.805 0.111788 19.3654 0.38296 19.0942L9.19758 10.2796L0.38296 1.46497C0.111788 1.19379 0.111788 0.754138 0.38296 0.482966C0.654131 0.211794 1.09379 0.211794 1.36496 0.482966L10.4341 9.55214C10.8359 9.9539 10.8359 10.6053 10.4341 11.007L1.36496 20.0762C1.09379 20.3474 0.654131 20.3474 0.38296 20.0762Z"

  @doc """
  Renders the carousel. Its children are `carousel_slide/1`s.

  `on_change` is pushed with `%{"id" => id, "index" => index}` when the active slide changes.
  """
  attr(:id, :string, required: true)
  attr(:index, :integer, default: 0, doc: "The active slide, zero-based.")

  attr(:effect, :string,
    default: "slide",
    values: ~w(slide fade flip cube cards coverflow creative)
  )

  attr(:direction, :string, default: "horizontal", values: ~w(horizontal vertical))
  attr(:navigation, :boolean, default: false, doc: "The previous and next arrows.")

  attr(:pagination, :string,
    default: nil,
    values: [nil, "bullets", "fraction", "progress", "scrollbar"]
  )

  attr(:autoplay, :integer, default: nil, doc: "Milliseconds between slides; pauses on hover.")
  attr(:loop, :boolean, default: false, doc: "Wrap around past the last and first slides.")
  attr(:gap, :integer, default: nil, doc: "Pixels between slides (LineOne's `spaceBetween`).")
  attr(:zoom, :integer, default: nil, doc: "Double-click zoom ratio.")
  attr(:on_change, :any, default: nil)
  attr(:target, :any, default: nil)
  attr(:prev_label, :string, default: "Previous slide")
  attr(:next_label, :string, default: "Next slide")
  attr(:bullet_label, :string, default: "Go to slide")
  attr(:label, :string, default: nil, doc: "The carousel's `aria-label`.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)
  slot(:background, doc: "Behind the track, for the parallax background.")

  def carousel(assigns) do
    assigns = assign(assigns, :arrow, @arrow)

    ~H"""
    <div
      id={@id}
      class={merge(["carousel", @class])}
      role="region"
      aria-roledescription="carousel"
      aria-label={@label}
      tabindex="0"
      phx-hook="LineaUI.Carousel"
      phx-target={@target}
      data-server-index={@index}
      data-effect={@effect}
      data-direction={@direction}
      data-loop={bool(@loop)}
      data-autoplay={@autoplay}
      data-zoom={@zoom}
      data-on-change={@on_change}
      data-bullet-label={@bullet_label}
      style={@gap && "--carousel-gap: #{@gap}px"}
      {@rest}
    >
      {render_slot(@background)}
      <div data-carousel-track class="carousel-track">
        {render_slot(@inner_block)}
      </div>
      <button
        :if={@navigation}
        type="button"
        class="carousel-button"
        data-carousel-next
        aria-label={@next_label}
        aria-controls={@id}
      >
        <svg viewBox="0 0 11 20" fill="none" aria-hidden="true"><path d={@arrow} /></svg>
      </button>
      <button
        :if={@navigation}
        type="button"
        class="carousel-button"
        data-carousel-prev
        aria-label={@prev_label}
        aria-controls={@id}
        disabled={!@loop && @index == 0}
      >
        <svg viewBox="0 0 11 20" fill="none" aria-hidden="true"><path d={@arrow} /></svg>
      </button>
      <div
        :if={@pagination in ~w(bullets fraction progress)}
        id={"#{@id}-pagination"}
        class="carousel-pagination"
        data-carousel-pagination={@pagination}
        phx-update="ignore"
      >
      </div>
      <div :if={@pagination == "scrollbar"} class="carousel-scrollbar" data-carousel-scrollbar>
        <div
          id={"#{@id}-thumb"}
          class="carousel-scrollbar-thumb"
          data-carousel-thumb
          phx-update="ignore"
        >
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders one slide. Its content fills it; with `zoom` on the carousel, the first child is
  what double click zooms.
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def carousel_slide(assigns) do
    ~H"""
    <div data-carousel-slide class={merge(["carousel-slide", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
