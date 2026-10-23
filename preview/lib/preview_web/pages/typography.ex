defmodule PreviewWeb.Pages.Typography do
  use PreviewWeb.Page, title: "Typography", category: :elements, lineone: "elements-typography"

  @fox "The quick brown fox jumps over the lazy dog."

  def render(assigns) do
    assigns = assign(assigns, fox: @fox, levels: 1..6)

    ~H"""
    <div class="grid grid-cols-1 gap-4 sm:gap-5 lg:grid-cols-2 lg:gap-6">
      <.example
        title="Basic Heading"
        text="HTML headings are titles or subtitles that you want to display on a webpage. Check out code for detail of usage."
        class="mt-5 max-w-2xl space-y-4"
      >
        <.heading :for={level <- @levels} level={level}>Heading H{level}</.heading>
      </.example>

      <.example
        title="Light Heading"
        text="HTML headings are available with light variant. Check out code for detail of usage."
        class="mt-5 max-w-2xl space-y-4"
      >
        <.heading :for={level <- @levels} level={level} weight="light">Heading H{level}</.heading>
      </.example>

      <.example
        title="Bold Heading"
        text="HTML headings are available with bold variant. Check out code for detail of usage."
        class="mt-5 max-w-2xl space-y-4"
      >
        <.heading :for={level <- @levels} level={level} weight="semibold">
          Heading H{level}
        </.heading>
      </.example>

      <.example
        title="Colored Heading"
        text="HTML headings can be used in various colors. Check out code for detail of usage."
        class="mt-5 max-w-2xl space-y-4"
      >
        <.heading
          :for={{level, color} <- Enum.zip(@levels, ~w(primary secondary info success warning error))}
          level={level}
          color={color}
        >
          Heading H{level}
        </.heading>
      </.example>

      <div class="lg:col-span-2">
        <.example
          title="Display Heading"
          text="Traditional heading elements are designed to work best in the meat of your page content. Check out code for detail of usage."
          class="mt-5 max-w-2xl space-y-6"
        >
          <.heading :for={display <- 1..5} display={display}>Display {display}</.heading>
        </.example>
      </div>

      <.example
        title="Gradient Text"
        text="The Text can be in gradient variants. Check out code for detail of usage."
        class="mt-5 flex max-w-2xl flex-col space-y-3"
      >
        <.text :for={gradient <- ~w(sky-blue green-fuchsia fuchsia-pink amber-orange)}>
          <.text as="span" size="lg" weight="semibold" gradient={gradient}>{@fox}</.text>
        </.text>
      </.example>

      <.example
        title="Text Decoration"
        text="Utilities for controlling the decoration of text. Check out code for detail of usage."
        class="mt-5 flex max-w-2xl flex-col space-y-3"
      >
        <.text
          :for={decoration <- ~w(underline overline line-through none)}
          size="lg"
          decoration={decoration}
        >
          {@fox}
        </.text>
      </.example>

      <.example
        title="Text Decoration Color"
        text="Utilities for controlling the color of text decorations. Check out code for detail of usage."
        class="mt-5 max-w-2xl"
      >
        <.text size="sm" class="leading-6">
          I’m Derek, an astro-engineer based in Tattooine. I like to build X-Wings at <.text_link
            href="#"
            decoration_color="info"
          >My Company, Inc</.text_link>. Outside of work, I like to
          <.text_link href="#" decoration_color="secondary">watch pod-racing</.text_link>
          and have <.text_link href="#" decoration_color="primary">light-saber</.text_link>
          fights.
        </.text>
      </.example>

      <.example
        title="Text Decoration Style"
        text="Utilities for controlling the style of text decorations. Check out code for detail of usage."
        class="mt-5 max-w-2xl"
      >
        <.text size="sm" class="leading-6">
          I’m Derek, an astro-engineer based in <.text_link
            href="#"
            decoration_color="info"
            decoration_style="wavy"
          >Tattooine</.text_link>. I like to build X-Wings at <.text_link
            href="#"
            decoration_color="info"
            decoration_style="double"
          >
            My Company, Inc
          </.text_link>. Outside of work, I like to
          <.text_link href="#" decoration_color="secondary" decoration_style="dotted">
            watch pod-racing
          </.text_link>
          and have
          <.text_link href="#" decoration_color="primary" decoration_style="dashed">
            light-saber
          </.text_link>
          fights.
        </.text>
      </.example>
    </div>
    """
  end
end
