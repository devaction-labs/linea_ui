defmodule LineaUI.Components.HeroCard do
  @moduledoc """
  The canvas hero card: the welcome or the insight at the top of a page. The text on the left (an eyebrow
  in mono caps with an optional icon, the title, the description and the actions) and a picture on the right,
  as tall as the card, fading into it from the left.

      <.hero_card eyebrow="Bem-vindo de volta" title="Metas do ano" description="Alinhamento e metas do trimestre.">
        <:actions>
          <.button color="neutral" size="lg"><.icon name="huge-add-01" /> Nova meta</.button>
          <.button variant="outline" size="lg"><.icon name="huge-view" /> Quadro de visão</.button>
        </:actions>
        <:art><.summit /></:art>
      </.hero_card>

      <.hero_card eyebrow="Sugestão da IA" title="Revisar os pull requests da API v2" src={~p"/images/hero.jpg"}>
        <:icon><.icon name="huge-ai-magic" /></:icon>
        ...
      </.hero_card>

  The picture is `src` (an `<img>`, `alt` empty unless it says something) or the `:art` slot (an inline SVG
  such as `summit/1`, the package's landscape). `position` moves the crop (`object-position`). `size="lg"`
  makes the title and the card taller; `variant="panel"` puts it on the panel color instead of the soft gray.
  `summit/1` draws gradients with ids prefixed by its `id` attr (default `"hs"`): when more than one summit
  may be on the page (say one hidden on mobile), give each its own, `<.summit id="hero-mobile" />`.
  On a phone the picture goes on top and fades down. Styles: `canvas-hero-card.css` (`linea-hero`).
  """

  use LineaUI.Component

  attr :eyebrow, :string, default: nil, doc: "The small mono caps line above the title."
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :src, :string, default: nil, doc: "The picture on the right."
  attr :alt, :string, default: ""

  attr :position, :string,
    default: "center",
    doc: "The crop of the picture (`right`, `70% center`...)."

  attr :size, :string, default: "md", values: ~w(md lg)
  attr :variant, :string, default: "soft", values: ~w(soft panel)
  attr :heading, :string, default: "h2", values: ~w(h1 h2 h3), doc: "The tag of the title."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon, doc: "An icon before the eyebrow."
  slot :inner_block, doc: "Under the description: a progress bar, a note."
  slot :actions
  slot :art, doc: "The picture as markup (an SVG), instead of `src`."

  def hero_card(assigns) do
    ~H"""
    <section class={merge(["linea-hero", @class])} data-size={@size} data-variant={@variant} {@rest}>
      <div class="linea-hero-body">
        <span :if={@eyebrow || @icon != []} class="linea-hero-eyebrow">{render_slot(@icon)}{@eyebrow}</span>
        <.dynamic_tag tag_name={@heading} class="linea-hero-title">{@title}</.dynamic_tag>
        <p :if={@description} class="linea-hero-desc">{@description}</p>
        {render_slot(@inner_block)}
        <div :if={@actions != []} class="linea-hero-actions">{render_slot(@actions)}</div>
      </div>
      <div :if={@src || @art != []} class="linea-hero-art" style={"--hero-position: #{@position}"}>
        <img :if={@src && @art == []} src={@src} alt={@alt} loading="lazy" />
        {render_slot(@art)}
      </div>
    </section>
    """
  end
end
