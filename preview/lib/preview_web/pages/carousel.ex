defmodule PreviewWeb.Pages.Carousel do
  use PreviewWeb.Page, title: "Carousel", category: :components, lineone: "components-carousel"

  def mount(socket), do: assign(socket, slide: 0)

  def handle_event("slid", %{"index" => index}, socket),
    do: {:noreply, assign(socket, slide: index)}

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 lg:gap-6">
      <div class="space-y-4 sm:space-y-5 lg:space-y-6">
        <.section title="Default Carousel">
          <.carousel id="carousel1" navigation class="rounded-lg" index={@slide} on_change="slid">
            <.carousel_slide :for={
              {image, position} <- [
                {6, ""},
                {3, "object-top"},
                {2, "object-center"},
                {9, "object-center"}
              ]
            }>
              <.photo n={image} class={position} />
            </.carousel_slide>
          </.carousel>
        </.section>
        <.section title="Lazy Loading Images">
          <.carousel id="carousel2" navigation pagination="progress" class="rounded-lg">
            <.carousel_slide :for={image <- [3, 19, 17, 18]}>
              <.photo n={image} loading="lazy" />
            </.carousel_slide>
          </.carousel>
        </.section>
        <.section title="Space Between">
          <.carousel id="carousel3" pagination="bullets" gap={30}>
            <.carousel_slide
              :for={
                {image, position} <- [
                  {8, ""},
                  {3, "object-top"},
                  {9, "object-center"},
                  {7, "object-center"}
                ]
              }
              class="w-10/12"
            >
              <.photo n={image} class={["rounded-lg", position]} />
            </.carousel_slide>
          </.carousel>
        </.section>
        <.section title="Zoom">
          <.carousel id="carousel4" navigation pagination="bullets" zoom={4}>
            <.carousel_slide :for={image <- [9, 2, 7, 9]}><.photo n={image} /></.carousel_slide>
          </.carousel>
        </.section>
        <.section title="Flip Effect">
          <.carousel id="carousel5" effect="flip" navigation pagination="bullets">
            <.carousel_slide :for={image <- [9, 2, 7, 9]}><.photo n={image} /></.carousel_slide>
          </.carousel>
        </.section>
        <.section title="Cube Effect">
          <.carousel id="carousel6" effect="cube" pagination="bullets">
            <.carousel_slide :for={image <- [4, 6, 2, 1]}>
              <.photo n={image} class="rounded-lg" />
            </.carousel_slide>
          </.carousel>
        </.section>
        <.section title="Card Effect" wrapper="mx-auto mt-5 w-10/12">
          <.carousel id="carousel7" effect="cards">
            <.carousel_slide :for={image <- [4, 6, 2, 1]} class="rounded-lg">
              <.photo n={image} class="rounded-lg" />
            </.carousel_slide>
          </.carousel>
        </.section>
      </div>
      <div class="space-y-4 sm:space-y-5 lg:space-y-6">
        <.section title="Pagination">
          <.carousel id="carousel8" pagination="bullets" class="rounded-lg">
            <.carousel_slide :for={
              {image, position} <- [
                {5, ""},
                {1, "object-top"},
                {2, "object-center"},
                {9, "object-center"}
              ]
            }>
              <.photo n={image} class={position} />
            </.carousel_slide>
          </.carousel>
        </.section>
        <.section title="Vertical Slider">
          <.carousel id="carousel9" direction="vertical" pagination="bullets" class="h-64 rounded-lg">
            <.carousel_slide :for={
              {image, position} <- [{4, "object-center"}, {8, ""}, {2, ""}, {1, ""}]
            }>
              <.photo n={image} class={position} />
            </.carousel_slide>
          </.carousel>
        </.section>
        <.section title="With Scrollbar">
          <.carousel
            id="carousel10"
            navigation
            pagination="scrollbar"
            autoplay={2000}
            class="rounded-lg"
          >
            <.carousel_slide :for={
              {image, position} <- [
                {5, ""},
                {1, "object-top"},
                {2, "object-center"},
                {9, "object-center"}
              ]
            }>
              <.photo n={image} class={position} />
            </.carousel_slide>
          </.carousel>
        </.section>
        <.section title="Fade Effect">
          <.carousel id="carousel11" effect="fade" navigation class="rounded-lg">
            <.carousel_slide :for={
              {image, position} <- [
                {5, ""},
                {1, "object-top"},
                {2, "object-center"},
                {9, "object-center"}
              ]
            }>
              <.photo n={image} class={position} />
            </.carousel_slide>
          </.carousel>
        </.section>
        <.section title="Coverflow Effect">
          <.carousel id="carousel12" effect="coverflow" navigation class="rounded-lg">
            <.carousel_slide :for={
              {image, position} <- [
                {9, ""},
                {1, "object-top"},
                {2, "object-center"},
                {9, "object-center"}
              ]
            }>
              <.photo n={image} class={position} />
            </.carousel_slide>
          </.carousel>
        </.section>
        <.section title="Parallax">
          <.carousel id="carousel13" navigation class="h-64 rounded-lg">
            <:background>
              <div
                class="carousel-parallax-bg"
                style="background-image: url('/lineone/images/object/object-2.jpg')"
                data-carousel-parallax="-23%"
              >
              </div>
            </:background>
            <.carousel_slide :for={n <- 1..3} class="p-6">
              <div class="text-3xl font-light text-white" data-carousel-parallax="-300">
                Slide {n}
              </div>
              <div class="mt-2 text-2xl text-white" data-carousel-parallax="-200">Subtitle</div>
              <div class="mt-4 text-white" data-carousel-parallax="-100">
                <p>
                  Lorem ipsum dolor sit amet, consectetur adipisicing elit. Ab at, consectetur
                  cupiditate debitis expedita fugit, modi nemo nobis odit perferendis quaerat quia
                  reiciendis repudiandae rerum sed?
                </p>
              </div>
            </.carousel_slide>
          </.carousel>
        </.section>
        <.section title="Creative Effect">
          <.carousel id="carousel14" effect="creative" class="rounded-lg">
            <.carousel_slide :for={image <- [4, 6, 2, 1]}>
              <.photo n={image} class="rounded-lg" />
            </.carousel_slide>
          </.carousel>
        </.section>
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :wrapper, :string, default: "mt-5"
  slot :inner_block, required: true

  defp section(assigns) do
    ~H"""
    <.example title={@title} class="max-w-xl">
      <p>
        <a
          href="https://github.com/nolimits4web/swiper"
          class="font-normal text-primary transition-colors hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
        >
          Swiper
        </a>
        is the free and most modern mobile touch slider with hardware accelerated transitions and amazing native behavior. Check out code for detail of usage.
      </p>
      <div class={@wrapper}>{render_slot(@inner_block)}</div>
    </.example>
    """
  end

  attr :n, :integer, required: true
  attr :class, :any, default: nil
  attr :loading, :string, default: nil

  defp photo(assigns) do
    ~H"""
    <img
      class={["h-full w-full object-cover", @class]}
      src={"/lineone/images/object/object-#{@n}.jpg"}
      loading={@loading}
      alt="image"
      draggable="false"
    />
    """
  end
end
