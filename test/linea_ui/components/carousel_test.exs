defmodule LineaUI.Components.CarouselTest do
  use LineaUI.ComponentCase, async: true

  test "a scroll-snap track with slides and the hook's data" do
    html =
      render(~H"""
      <.carousel id="c" class="rounded-lg">
        <.carousel_slide>One</.carousel_slide>
        <.carousel_slide class="w-10/12">Two</.carousel_slide>
      </.carousel>
      """)

    assert [root] = find(html, "#c[phx-hook='LineaUI.Carousel'][role=region]") |> Enum.to_list()
    assert LazyHTML.attribute(root, "data-effect") == ["slide"]
    assert LazyHTML.attribute(root, "data-direction") == ["horizontal"]
    assert LazyHTML.attribute(root, "data-server-index") == ["0"]
    assert LazyHTML.attribute(root, "data-loop") == ["false"]
    assert "rounded-lg" in classes(html, "#c")

    assert [_, _] =
             find(html, "#c > [data-carousel-track] > [data-carousel-slide]") |> Enum.to_list()

    assert "w-10/12" in classes(html, "[data-carousel-slide]:nth-child(2)")
    assert [] = find(html, "[data-carousel-next]") |> Enum.to_list()
    assert [] = find(html, "[data-carousel-pagination]") |> Enum.to_list()
  end

  test "navigation, pagination, effect, autoplay and loop" do
    html =
      render(~H"""
      <.carousel
        id="c"
        navigation
        pagination="bullets"
        effect="flip"
        autoplay={2000}
        loop
        gap={30}
        zoom={4}
        index={2}
        direction="vertical"
      >
        <.carousel_slide>One</.carousel_slide>
      </.carousel>
      """)

    root = find(html, "#c")
    assert LazyHTML.attribute(root, "data-effect") == ["flip"]
    assert LazyHTML.attribute(root, "data-direction") == ["vertical"]
    assert LazyHTML.attribute(root, "data-autoplay") == ["2000"]
    assert LazyHTML.attribute(root, "data-loop") == ["true"]
    assert LazyHTML.attribute(root, "data-zoom") == ["4"]
    assert LazyHTML.attribute(root, "data-server-index") == ["2"]
    assert LazyHTML.attribute(root, "style") == ["--carousel-gap: 30px"]

    assert [_] =
             find(html, "button[data-carousel-prev][aria-label='Previous slide']")
             |> Enum.to_list()

    assert [_] = find(html, "button[data-carousel-next] svg") |> Enum.to_list()

    assert [_] =
             find(html, "#c-pagination[data-carousel-pagination=bullets][phx-update=ignore]")
             |> Enum.to_list()
  end

  test "the prev arrow starts disabled at the first slide without loop" do
    html = render(~H|<.carousel id="c" navigation>
  <.carousel_slide>A</.carousel_slide>
</.carousel>|)
    assert [_] = find(html, "button[data-carousel-prev][disabled]") |> Enum.to_list()
  end

  test "the scrollbar and the parallax background" do
    html =
      render(~H"""
      <.carousel id="c" pagination="scrollbar">
        <:background>
          <div data-carousel-parallax="-23%" class="carousel-parallax-bg"></div>
        </:background>
        <.carousel_slide>A</.carousel_slide>
      </.carousel>
      """)

    assert [_] =
             find(html, "[data-carousel-scrollbar] > #c-thumb[data-carousel-thumb]")
             |> Enum.to_list()

    assert [_] = find(html, "#c > [data-carousel-parallax]") |> Enum.to_list()
  end

  test "on_change and target" do
    html =
      render(~H|<.carousel id="c" on_change="slid" target="#x">
  <.carousel_slide>A</.carousel_slide>
</.carousel>|)

    assert LazyHTML.attribute(find(html, "#c"), "data-on-change") == ["slid"]
    assert LazyHTML.attribute(find(html, "#c"), "phx-target") == ["#x"]
  end

  test "navigation=outside pads the carousel and keeps the arrows" do
    html =
      render(~H"""
      <.carousel id="o" navigation="outside">
        <.carousel_slide>x</.carousel_slide>
      </.carousel>
      <.carousel id="i" navigation="inside">
        <.carousel_slide>x</.carousel_slide>
      </.carousel>
      <.carousel id="n">
        <.carousel_slide>x</.carousel_slide>
      </.carousel>
      """)

    assert [_] = find(html, "#o[data-navigation=outside]") |> Enum.to_list()
    assert [_, _] = find(html, "#o .carousel-button") |> Enum.to_list()
    assert [] = find(html, "#i[data-navigation]") |> Enum.to_list()
    assert [_, _] = find(html, "#i .carousel-button") |> Enum.to_list()
    assert [] = find(html, "#n .carousel-button") |> Enum.to_list()
  end
end

defmodule LineaUI.Components.CarouselLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule CarouselLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, _session, socket), do: {:ok, assign(socket, index: 0)}

    def render(assigns) do
      ~H"""
      <.carousel id="gallery" index={@index} on_change="slid" navigation pagination="bullets">
        <.carousel_slide :for={n <- 1..3}>Slide {n}</.carousel_slide>
      </.carousel>
      <button id="last" phx-click="last">last</button>
      <p id="index">{@index}</p>
      """
    end

    def handle_event("slid", %{"id" => "gallery", "index" => index}, socket),
      do: {:noreply, assign(socket, index: index)}

    def handle_event("last", _params, socket) do
      {:noreply,
       socket
       |> assign(index: 2)
       |> push_event("linea:carousel", %{id: "gallery", index: 2})}
    end
  end

  test "the hook's on_change reaches the server", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, CarouselLive)
    html = view |> element("#gallery") |> render_hook("slid", %{"id" => "gallery", "index" => 1})
    assert [_] = find(html, "#gallery[data-server-index='1']") |> Enum.to_list()
  end

  test "the server moves the carousel", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, CarouselLive)
    html = view |> element("#last") |> render_click()
    assert [_] = find(html, "#gallery[data-server-index='2']") |> Enum.to_list()
    assert_push_event(view, "linea:carousel", %{id: "gallery", index: 2})
  end
end
