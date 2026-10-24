defmodule LineaUI.Components.Card do
  @moduledoc """
  LineOne's cards: the white panel, bordered, outlined, tinted, filled with a theme color, glowing,
  gradient and gradient-outlined, with optional composable parts (header, body, footer).

      <.card>
        <:title>Simple Card</:title>
        Lorem ipsum dolor sit amet.
      </.card>
      <.card variant="bordered" shape="xl">…</.card>
      <.card variant="flat">No shadow</.card>
      <.card variant="solid" color="primary"><:title>Primary Card</:title>…</.card>
      <.card variant="gradient" gradient="purple-indigo">…</.card>
      <.card variant="gradient_outline" gradient="sky-blue">…</.card>

  Without `:title` the content fills the card as is, padded evenly like a bordered `div`;
  `padded={false}` drops the default padding, for cards laid out by hand
  (`<.card padded={false} class="px-4 pb-4 sm:px-5">`).

  ## Parts

  A card is made of optional parts; use the ones you need. Anything placed directly in the card
  keeps the card's padding.

      <.card variant="soft" body="inset" size="lg">
        <.card_header>
          <.card_heading>Profile</.card_heading>
          <.card_subheading>Make yourself at home</.card_subheading>
          <.card_actions><.button icon size="sm" variant="flat" aria-label="More">…</.button></.card_actions>
        </.card_header>
        <.card_body class="space-y-6">
          <.input name="name" label="Name" value="Olivia Martin" />
        </.card_body>
        <.card_footer>
          <span class="text-xs">All changes saved</span>
          <.card_actions><.button size="sm">Save</.button></.card_actions>
        </.card_footer>
      </.card>

  * `card_header/1` holds `card_heading/1`, `card_subheading/1` and `card_actions/1`. Actions
    sit in the corner, centered on the heading; written before the heading they go to the
    leading side. Small buttons hang in the header's padding without making it taller.
  * `card_body/1` is the main content. It may hold its own `card_header/1` and `card_footer/1`
    as sub-sections, spaced and padded by the body.
  * `card_footer/1` holds supporting text and actions, or a heading, subheading and actions
    exactly like a header.
  * `card_header/1` and `card_footer/1` also work outside a card; give them the `size` of the
    card they stand with.
  * `card_bleed/1` makes media fill the card's sides, reach the top or bottom when it is the
    first or last thing in the body, and round only the corners it touches.

        <.card body="inset">
          <.card_body><.card_bleed><img src={@cover} alt="" /></.card_bleed></.card_body>
          <.card_footer>
            <.card_heading>Morning hike</.card_heading>
            <.card_subheading>Sept 12</.card_subheading>
          </.card_footer>
        </.card>

  * A `table/1` with `bleed` inside a card runs its rows edge to edge while its content stays
    aligned with the card's, and reaches the top and bottom of the body when it is the only
    thing in it.

  ## Surfaces and treatments

  `variant` is the surface: `default` (soft shadow in light, elevation in dark, a faint
  highlight along the inside top edge in light mode unless `highlight={false}`), `flat`,
  `bordered`, `outline` (border only), `muted` and `soft` (quiet tints that adapt to the color
  behind them, in light and dark), `filled` (a tint without border) and the colored `solid`,
  `glow`, `gradient`, `gradient_outline`.

  `body` is how the parts are told apart: `seamless` (one surface, parts spaced by the card's
  padding), `divided` (hairlines between parts, `divider="inset"` stops them at the content
  edges), `separated` (tinted bands for header and footer), `inset` (the body is a panel inside
  the card, with corners concentric to the card's: raised on a tinted card, recessed on a plain
  one) and `flush` (the same panel running to the card's sides). With `padded={false}` the
  parts pad themselves and `body` has no effect.

  `size` (`xs`, `sm`, `md`, `lg`) sets padding, type, corners and the spacing between parts.
  The card publishes these as CSS variables (`--card-p`, `--card-r`, `--card-i`, and per
  treatment `--card-hx`, `--card-hy`, `--card-bx`, `--card-by`, `--card-bleed-x`...), which the
  parts and the `bleed` of `table/1` read; the rules live in `assets/css/parts/card.css`.
  """

  use LineaUI.Component

  @solid %{
    "primary" => "rounded-lg bg-primary text-white dark:bg-accent",
    "secondary" => "rounded-lg bg-secondary text-white",
    "info" => "rounded-lg bg-info text-white",
    "success" => "rounded-lg bg-success text-white",
    "warning" => "rounded-lg bg-warning text-white",
    "error" => "rounded-lg bg-error text-white"
  }

  @glow %{
    "primary" =>
      "rounded-lg bg-primary text-white shadow-lg shadow-primary/50 dark:bg-accent dark:shadow-accent/50",
    "secondary" => "rounded-lg bg-secondary text-white shadow-lg shadow-secondary/50",
    "info" => "rounded-lg bg-info text-white shadow-lg shadow-info/50",
    "success" => "rounded-lg bg-success text-white shadow-lg shadow-success/50",
    "warning" => "rounded-lg bg-warning text-white shadow-lg shadow-warning/50",
    "error" => "rounded-lg bg-error text-white shadow-lg shadow-error/50"
  }

  @gradients %{
    "purple-indigo" => "rounded-lg bg-gradient-to-br from-purple-500 to-indigo-600 text-white",
    "fuchsia-pink" => "rounded-lg bg-gradient-to-r from-fuchsia-600 to-pink-600 text-white",
    "amber-orange" => "rounded-lg bg-gradient-to-br from-amber-400 to-orange-600 text-white",
    "sky-blue" => "rounded-lg bg-gradient-to-r from-sky-400 to-blue-600 text-white",
    "green-fuchsia" => "rounded-lg bg-gradient-to-r from-green-400 to-fuchsia-400 text-white"
  }

  @gradient_outlines %{
    "purple-indigo" => "rounded-lg bg-gradient-to-r from-purple-500 to-indigo-600 p-1",
    "fuchsia-pink" => "rounded-lg bg-gradient-to-r from-fuchsia-600 to-pink-600 p-1",
    "amber-orange" => "rounded-lg bg-gradient-to-r from-amber-400 to-orange-600 p-1",
    "sky-blue" => "rounded-lg bg-gradient-to-r from-sky-400 to-blue-600 p-1",
    "green-fuchsia" => "rounded-lg bg-gradient-to-r from-green-400 to-fuchsia-400 p-1"
  }

  @shapes %{"rounded" => "", "xl" => "rounded-2xl [--card-r:1rem]"}
  @outline_inner_shapes %{"rounded" => "", "xl" => "rounded-xl [--card-r:0.75rem]"}

  @titles %{
    "light" => "text-lg font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100",
    "colored" => "text-lg font-medium tracking-wide line-clamp-1"
  }

  @surfaces ~w(default flat bordered outline muted soft filled)

  @aligns %{
    "start" => "justify-start",
    "center" => "justify-center",
    "end" => "justify-end",
    "between" => "justify-between"
  }

  @heading_sizes %{"base" => nil, "lg" => "text-base leading-6", "xl" => "text-xl leading-7"}

  @doc """
  Renders a card, with an optional `:title` above the content, or composed of
  `card_header/1`, `card_body/1` and `card_footer/1`.

      <.card variant="glow" color="info">
        <:title>Revenue</:title>
        <p>$12,400 this month.</p>
      </.card>
  """
  attr(:variant, :string,
    default: "default",
    values:
      ~w(default flat bordered outline muted soft filled solid glow gradient gradient_outline),
    doc:
      "`default` is LineOne's white panel with a soft shadow (elevation in dark); `flat` is the same panel without the shadow; `bordered` adds a border; `outline` is the border only; `muted` and `soft` are quiet tints (`muted` the stronger) and `filled` a tint without border, all adapting to the color behind them; `solid` and `glow` use `color`; `gradient` and `gradient_outline` use `gradient`."
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg),
    doc: "Padding, type, corners and the spacing between parts."
  )

  attr(:body, :string,
    default: "seamless",
    values: ~w(seamless divided separated inset flush),
    doc:
      "How `card_header/1`, `card_body/1` and `card_footer/1` are told apart: one surface, hairlines, tinted bands, a body panel inside the card with concentric corners, or a body panel that reaches the card's sides."
  )

  attr(:divider, :string,
    default: "full",
    values: ~w(full inset),
    doc: "With `body=\"divided\"`, `inset` stops the lines at the content edges."
  )

  attr(:highlight, :boolean,
    default: true,
    doc:
      "A faint highlight along the inside top edge of the `default`, `muted`, `soft` and `filled` surfaces in light mode."
  )

  attr(:color, :string,
    default: "primary",
    values: ~w(primary secondary info success warning error)
  )

  attr(:gradient, :string,
    default: "purple-indigo",
    values: ~w(purple-indigo fuchsia-pink amber-orange sky-blue green-fuchsia)
  )

  attr(:shape, :string,
    default: "rounded",
    values: ~w(rounded xl),
    doc:
      "`xl` is `rounded-2xl`; on `gradient_outline` the outer edge and the inner panel follow it."
  )

  attr(:padded, :boolean,
    default: true,
    doc: "`false` leaves the card without padding; its parts then pad themselves."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:title, doc: "The card's heading, followed by the content.") do
    attr(:class, :any)
  end

  slot(:inner_block)

  def card(%{variant: "gradient_outline"} = assigns) do
    ~H"""
    <div class={merge([gradient_outline(@gradient), shape(@shape), @class])} {@rest}>
      <div
        class={
          merge([
            "card rounded-lg bg-slate-50 shadow-none [--card-r:0.5rem] dark:bg-navy-900",
            outline_inner_shape(@shape)
          ])
        }
        data-size={@size}
        data-body={@body}
        data-divider={@divider}
        data-padded={to_string(@padded)}
      >
        <.title_block title={@title} title_class={title_class("default")}>
          {render_slot(@inner_block)}
        </.title_block>
      </div>
    </div>
    """
  end

  def card(assigns) do
    ~H"""
    <div
      class={merge([surface(@variant, @color, @gradient), shape(@shape), @class])}
      data-size={@size}
      data-body={@body}
      data-divider={@divider}
      data-variant={data_variant(@variant)}
      data-highlight={to_string(@highlight)}
      data-padded={to_string(@padded)}
      {@rest}
    >
      <.title_block title={@title} title_class={title_class(@variant)}>
        {render_slot(@inner_block)}
      </.title_block>
    </div>
    """
  end

  @doc """
  The top of a card: `card_heading/1`, `card_subheading/1` and `card_actions/1`.

      <.card_header>
        <.card_actions><.button icon size="sm" variant="flat" aria-label="More">…</.button></.card_actions>
        <.card_heading>Activity</.card_heading>
        <.card_subheading>Last 30 days</.card_subheading>
      </.card_header>

  Inside a card it follows the card's `body`; nested in a `card_body/1` it follows the body's
  padding. Outside a card it adds no padding of its own and `size` sets its type.
  """
  attr(:size, :string,
    default: nil,
    values: [nil, "xs", "sm", "md", "lg"],
    doc: "The size of the card it stands with, when used outside a card."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_header(assigns) do
    ~H"""
    <div class={merge(["card-header", @class])} data-size={@size} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "The title of a `card_header/1` or `card_footer/1`."
  attr(:size, :string,
    default: "base",
    values: ~w(base lg xl),
    doc: "`base` is the header's type size; `lg` and `xl` are for standalone headings."
  )

  attr(:level, :integer,
    default: 2,
    values: [1, 2, 3, 4, 5, 6],
    doc: "The heading level of the element (`h1` to `h6`)."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_heading(assigns) do
    ~H"""
    <.dynamic_tag
      tag_name={"h#{@level}"}
      class={merge(["card-heading", heading_size(@size), @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  @doc "The line under the heading of a `card_header/1` or `card_footer/1`."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_subheading(assigns) do
    ~H"""
    <p class={merge(["card-subheading", @class])} {@rest}>{render_slot(@inner_block)}</p>
    """
  end

  @doc """
  Buttons or links of a `card_header/1` or `card_footer/1`. They sit in the corner, centered on
  the heading (at the trailing side, or at the leading side when written before the heading);
  small buttons hang in the part's padding and do not make it taller.
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_actions(assigns) do
    ~H"""
    <div class={merge(["card-actions", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc """
  The main content of a card. In the `inset` and `flush` treatments it is the panel; a
  `card_header/1` or `card_footer/1` nested in it follows the body's padding.
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_body(assigns) do
    ~H"""
    <div class={merge(["card-body", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc """
  The bottom of a card: supporting text and `card_actions/1`, or a `card_heading/1`,
  `card_subheading/1` and actions laid out like a header. Buttons written directly in it are
  placed by `align`.
  """
  attr(:align, :string,
    default: "end",
    values: ~w(start center end between),
    doc: "Where loose content (text, buttons) sits on the row."
  )

  attr(:size, :string,
    default: nil,
    values: [nil, "xs", "sm", "md", "lg"],
    doc: "The size of the card it stands with, when used outside a card."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_footer(assigns) do
    ~H"""
    <div class={merge(["card-footer", align(@align), @class])} data-size={@size} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Media for a `card_body/1`: it reaches the card's sides, the top when it is the first thing in
  the body and the bottom when it is the last, and rounds only the corners it touches (the
  panel's in `inset` and `flush`).
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_bleed(assigns) do
    ~H"""
    <div class={merge(["card-bleed", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  defp shape(shape), do: @shapes[shape]
  defp gradient_outline(gradient), do: @gradient_outlines[gradient]
  defp outline_inner_shape(shape), do: @outline_inner_shapes[shape]
  defp heading_size(size), do: @heading_sizes[size]
  defp align(align), do: @aligns[align]

  defp data_variant(variant) when variant in @surfaces, do: variant
  defp data_variant(_variant), do: nil

  defp surface("flat", _color, _gradient), do: "card shadow-none"

  defp surface("bordered", _color, _gradient),
    do: "card border border-slate-150 shadow-none dark:border-navy-600"

  defp surface(variant, _color, _gradient) when variant in @surfaces, do: "card"
  defp surface("solid", color, _gradient), do: [@solid[color], "[--card-r:0.5rem]"]
  defp surface("glow", color, _gradient), do: [@glow[color], "[--card-r:0.5rem]"]
  defp surface("gradient", _color, gradient), do: [@gradients[gradient], "[--card-r:0.5rem]"]

  defp title_class(variant) when variant in @surfaces, do: @titles["light"]
  defp title_class(_variant), do: @titles["colored"]

  attr(:title, :list, required: true)
  attr(:title_class, :string, required: true)
  slot(:inner_block)

  defp title_block(%{title: []} = assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  defp title_block(assigns) do
    ~H"""
    <div :for={title <- @title}>
      <h2 class={merge([@title_class, title[:class]])}>{render_slot(title)}</h2>
    </div>
    <div class="pt-2">{render_slot(@inner_block)}</div>
    """
  end
end
