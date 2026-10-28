defmodule LineaUI.Components.Carousel do
  @moduledoc """
  LineOne's Swiper carousels, without Swiper: slides on a CSS scroll-snap track, and the
  `LineaUI.Carousel` hook for arrows, pagination, autoplay, keyboard, swipe and effects.

      <.carousel id="gallery" navigation class="rounded-lg">
        <.carousel_slide><img class="h-full w-full object-cover" src="/a.jpg" alt="" /></.carousel_slide>
        <.carousel_slide><img class="h-full w-full object-cover" src="/b.jpg" alt="" /></.carousel_slide>
      </.carousel>

      <.carousel id="beside" navigation="outside">…</.carousel>
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

  The previous arrow comes before the next one in the DOM (the tab order), and both point
  to the track with `aria-controls`.

  ## State

  `index` is the server's slide. The person can move freely in the browser, and their slide
  survives patches; when the server changes `index`, the carousel goes there.

  ## Events

  `on_change` (an event name or `%JS{}`) runs when the active slide changes; an event name is
  pushed with `%{"id" => id, "index" => index}` (zero-based) to `target`, or to the LiveView.

  From the server, `push_event(socket, "linea:carousel", %{id: "gallery", index: 2})` moves it.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  @doc """
  Renders the carousel. Its children are `carousel_slide/1`s.

  `on_change` is pushed with `%{"id" => id, "index" => index}` (zero-based) when the active
  slide changes; a `%JS{}` is executed instead. The server moves it by changing `index`, or with
  `push_event(socket, "linea:carousel", %{id: id, index: n})`.

      <.carousel id="gallery" index={@slide} on_change="slid" navigation pagination="bullets">
        <.carousel_slide :for={src <- @images}>
          <img class="h-full w-full object-cover" src={src} alt="" />
        </.carousel_slide>
      </.carousel>

      def handle_event("slid", %{"index" => index}, socket), do: {:noreply, assign(socket, slide: index)}
  """
  attr(:id, :string, required: true)
  attr(:index, :integer, default: 0, doc: "The active slide, zero-based.")

  attr(:effect, :string,
    default: "slide",
    doc:
      "`slide` scrolls a snap track; the others stack the slides and animate them like Swiper's effects.",
    values: ~w(slide fade flip cube cards coverflow creative)
  )

  attr(:direction, :string, default: "horizontal", values: ~w(horizontal vertical))

  attr(:navigation, :any,
    default: false,
    values: [true, false, "inside", "outside"],
    doc:
      "The previous and next arrows. `true` or `\"inside\"` lays them over the track; `\"outside\"` pads the carousel and puts them beside the track (the `slide` effect)."
  )

  attr(:pagination, :string,
    default: nil,
    doc:
      "`bullets` (clickable dots), `fraction` (`2 / 4`), `progress` (bar on top), `scrollbar` (draggable bar).",
    values: [nil, "bullets", "fraction", "progress", "scrollbar"]
  )

  attr(:autoplay, :integer, default: nil, doc: "Milliseconds between slides; pauses on hover.")
  attr(:loop, :boolean, default: false, doc: "Wrap around past the last and first slides.")
  attr(:gap, :integer, default: nil, doc: "Pixels between slides (LineOne's `spaceBetween`).")
  attr(:zoom, :integer, default: nil, doc: "Double-click zoom ratio.")

  attr(:on_change, :any,
    default: nil,
    doc: "Event name or `%JS{}`; pushed with `%{\"id\" => id, \"index\" => index}`."
  )

  attr(:target, :any, default: nil, doc: "The `phx-target` `on_change` goes to.")
  attr(:prev_label, :string, default: "Previous slide")
  attr(:next_label, :string, default: "Next slide")
  attr(:bullet_label, :string, default: "Go to slide")
  attr(:label, :string, default: nil, doc: "The carousel's `aria-label`.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)
  slot(:background, doc: "Behind the track, for the parallax background.")

  def carousel(assigns) do
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
      data-navigation={@navigation == "outside" && "outside"}
      data-loop={bool(@loop)}
      data-autoplay={@autoplay}
      data-zoom={@zoom}
      data-on-change={@on_change}
      data-bullet-label={@bullet_label}
      style={@gap && "--carousel-gap: #{@gap}px"}
      {@rest}
    >
      {render_slot(@background)}
      <div id={"#{@id}-track"} data-carousel-track class="carousel-track">
        {render_slot(@inner_block)}
      </div>
      <button
        :if={@navigation not in [false, nil]}
        type="button"
        class="carousel-button"
        data-carousel-prev
        aria-label={@prev_label}
        aria-controls={"#{@id}-track"}
        disabled={!@loop && @index == 0}
      >
        <.glyph name={:carousel_arrow} class={nil} />
      </button>
      <button
        :if={@navigation not in [false, nil]}
        type="button"
        class="carousel-button"
        data-carousel-next
        aria-label={@next_label}
        aria-controls={"#{@id}-track"}
      >
        <.glyph name={:carousel_arrow} class={nil} />
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
  what double click zooms. Give it a width (`class="w-10/12"`) to show the next slide peeking.

      <.carousel_slide class="w-10/12">
        <img class="h-full w-full rounded-lg object-cover" src="/a.jpg" alt="" />
      </.carousel_slide>
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
