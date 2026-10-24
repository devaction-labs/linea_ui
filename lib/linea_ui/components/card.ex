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

  Without `:title` the content fills the card as is, padded evenly; `padded={false}` drops the
  default padding, for cards laid out by hand (`<.card padded={false} class="px-4 pb-4 sm:px-5">`).

  ## Parts

  A card is made of optional parts; use the ones you need. Anything placed directly in the card
  keeps the card's padding.

      <.card variant="outline" size="sm" body="divided">
        <.card_header>
          <.card_heading>Invoice 2041</.card_heading>
          <.card_subheading>Due on March 3</.card_subheading>
          <.card_actions><.button size="xs">Edit</.button></.card_actions>
        </.card_header>
        <.card_body>Three line items, $1,240.00.</.card_body>
        <.card_footer>
          <.button size="sm" variant="flat">Cancel</.button>
          <.button size="sm">Pay</.button>
        </.card_footer>
      </.card>

  * `card_header/1` holds `card_heading/1`, `card_subheading/1` and `card_actions/1`. Actions go
    to the trailing side; written before the heading they go to the leading side. Small buttons
    in the actions sit in the header's padding without making it taller.
  * `card_body/1` is the content. `card_footer/1` holds the buttons, `align` places them.
  * `card_header/1` and `card_footer/1` also work outside a card (they pad themselves) and
    nested inside a `card_body/1` (they follow the body's padding).
  * `card_bleed/1` makes an image fill the body up to its edges while the footer keeps its
    padding; `edges` picks the sides (`all`, `top`, `bottom`, `x`). Rounded edges follow the
    card (concentric in `inset`).

        <.card body="inset">
          <.card_body><.card_bleed><img src={@cover} alt="" /></.card_bleed></.card_body>
          <.card_footer>Cover</.card_footer>
        </.card>

  * A `table/1` with `bleed` inside a card runs its rows edge to edge while its content stays
    aligned with the card's.

  ## Surfaces and treatments

  `variant` is the surface: `default` (soft shadow in light, elevation in dark), `flat`,
  `bordered`, `outline` (border only), `muted` and `soft` (quiet tints that adapt to the
  background, in light and dark), `filled` (no border) and the colored `solid`, `glow`,
  `gradient`, `gradient_outline`.

  `body` is how the parts are told apart: `seamless` (one surface, tighter spacing), `divided`
  (lines between parts), `separated` (tinted bands for header and footer), `inset` (the body
  gets its own panel, with corners concentric to the card's) and `flush` (the body panel
  reaches the card's sides). With `padded={false}` the parts pad themselves and `body` has no
  effect.

  `size` (`xs`, `sm`, `md`, `lg`) sets padding, typography, corners and the gaps between parts.
  The card publishes them as CSS variables (`--card-px`, `--card-py`, `--card-gap`,
  `--card-r`), which the parts and the `bleed` of `table/1` read.
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

  @heading_color "[--card-hd:var(--color-slate-700)] dark:[--card-hd:var(--color-navy-100)] [--card-panel:#fff] dark:[--card-panel:var(--color-navy-700)]"

  @sizes %{
    "xs" =>
      "text-xs [--card-px:0.625rem] [--card-py:0.625rem] [--card-gap:0.5rem] [--card-inset:0.125rem] [--card-h:0.8125rem] [--card-s:0.6875rem]",
    "sm" =>
      "text-xs-plus [--card-px:0.875rem] [--card-py:0.875rem] [--card-gap:0.625rem] [--card-inset:0.1875rem] [--card-h:0.875rem] [--card-s:0.75rem]",
    "md" =>
      "[--card-px:1rem] sm:[--card-px:1.25rem] [--card-py:1rem] [--card-gap:0.75rem] [--card-inset:0.25rem] [--card-h:0.9375rem] [--card-s:0.8125rem]",
    "lg" =>
      "text-base [--card-px:1.25rem] sm:[--card-px:1.5rem] [--card-py:1.25rem] sm:[--card-py:1.5rem] [--card-gap:1rem] [--card-inset:0.375rem] [--card-h:1.0625rem] [--card-s:0.875rem]"
  }

  @corners %{
    "xs" => "rounded [--card-r:0.25rem]",
    "sm" => "rounded-md [--card-r:0.375rem]",
    "md" => "rounded-lg [--card-r:0.5rem]",
    "lg" => "rounded-xl [--card-r:0.75rem]"
  }

  @paddings %{
    "xs" => "px-2.5 py-2.5",
    "sm" => "px-3.5 py-3.5",
    "md" => "px-4 py-4 sm:px-5",
    "lg" => "px-5 py-5 sm:px-6 sm:py-6"
  }

  @modes %{
    "seamless" =>
      "[--p-mx:0px] [--p-mt:0px] [--p-px:0px] [--p-py:0px] [--p-gap:var(--card-gap)] [--p-line:0px] [--p-band:transparent] [--b-mx:0px] [--b-mt:0px] [--b-px:0px] [--b-py:0px] [--b-bg:transparent] [--b-r:var(--card-r)] [--b-line:0px]",
    "divided" =>
      "[--p-mx:calc(var(--card-px)*-1)] [--p-mt:calc(var(--card-py)*-1)] [--p-px:var(--card-px)] [--p-py:var(--card-py)] [--p-gap:0px] [--p-line:1px] [--p-band:transparent] [--b-mx:calc(var(--card-px)*-1)] [--b-mt:calc(var(--card-py)*-1)] [--b-px:var(--card-px)] [--b-py:var(--card-py)] [--b-bg:var(--card-panel,transparent)] [--b-r:var(--card-r)] [--b-line:0px]",
    "separated" =>
      "[--p-mx:calc(var(--card-px)*-1)] [--p-mt:calc(var(--card-py)*-1)] [--p-px:var(--card-px)] [--p-py:var(--card-py)] [--p-gap:0px] [--p-line:0px] [--p-band:rgb(15_23_42/0.04)] dark:[--p-band:rgb(255_255_255/0.05)] [--b-mx:calc(var(--card-px)*-1)] [--b-mt:calc(var(--card-py)*-1)] [--b-px:var(--card-px)] [--b-py:var(--card-py)] [--b-bg:var(--card-panel,transparent)] [--b-r:var(--card-r)] [--b-line:0px]",
    "inset" =>
      "p-(--card-inset) [--p-mx:0px] [--p-mt:0px] [--p-px:var(--card-px)] [--p-py:var(--card-py)] [--p-gap:0px] [--p-line:0px] [--p-band:transparent] [--b-mx:0px] [--b-mt:0px] [--b-px:var(--card-px)] [--b-py:var(--card-py)] [--b-bg:var(--card-panel,transparent)] [--b-r:calc(var(--card-r)_-_var(--card-inset))] [--b-line:1px] [--b-lx:1px] [--b-sh:0_1px_2px_rgb(15_23_42/0.06)]",
    "flush" =>
      "[--p-mx:calc(var(--card-px)*-1)] [--p-mt:calc(var(--card-py)*-1)] [--p-px:var(--card-px)] [--p-py:var(--card-py)] [--p-gap:0px] [--p-line:0px] [--p-band:transparent] [--b-mx:calc(var(--card-px)*-1)] [--b-mt:calc(var(--card-py)*-1)] [--b-px:var(--card-px)] [--b-py:var(--card-py)] [--b-bg:var(--card-panel,transparent)] [--b-r:var(--card-r)] [--b-line:1px] [--b-sh:0_1px_2px_rgb(15_23_42/0.06)]"
  }

  @unpadded "[--p-mx:0px] [--p-mt:0px] [--p-px:1rem] [--p-py:1rem] [--p-gap:0px] [--p-line:0px] [--p-band:transparent] [--b-mx:0px] [--b-mt:0px] [--b-px:0px] [--b-py:0px] [--b-bg:transparent] [--b-r:var(--card-r)] [--b-line:0px]"

  @header "grid grid-cols-[auto_minmax(0,1fr)_auto] items-start rounded-t-[inherit] border-slate-150 bg-[color:var(--p-band,transparent)] mx-[var(--p-mx,0px)] px-[var(--p-px,1rem)] py-[var(--p-py,1rem)] first:mt-[var(--p-mt,0px)] not-last:mb-[var(--p-gap,0px)] not-last:border-b-[length:var(--p-line,0px)] dark:border-navy-500"

  @heading "col-start-2 row-start-1 min-w-0 text-[length:var(--card-h,1.125rem)] font-medium leading-7 tracking-wide text-[color:var(--card-hd,inherit)]"

  @subheading "col-start-2 row-start-2 min-w-0 text-[length:var(--card-s,0.875rem)] opacity-80"

  @actions "col-start-3 row-start-1 self-center -my-1.5 ms-3 flex items-center gap-2 first:col-start-1 first:ms-0 first:me-3"

  @body "border-slate-150 bg-[color:var(--b-bg,transparent)] mx-[var(--b-mx,0px)] px-[var(--b-px,0px)] py-[var(--b-py,0px)] rounded-[var(--b-r,0px)] border-x-[length:var(--b-lx,0px)] border-y-[length:var(--b-line,0px)] [box-shadow:var(--b-sh,none)] first:mt-[var(--b-mt,0px)] last:mb-[var(--b-mt,0px)] not-last:mb-[var(--p-gap,0px)] [--p-mx:0px] [--p-mt:0px] [--p-px:0px] [--p-py:0px] [--p-gap:var(--card-gap,0px)] [--p-line:0px] [--p-band:transparent] dark:border-navy-500"

  @footer "flex flex-wrap items-center gap-2 rounded-b-[inherit] border-slate-150 bg-[color:var(--p-band,transparent)] mx-[var(--p-mx,0px)] px-[var(--p-px,1rem)] py-[var(--p-py,1rem)] last:mb-[var(--p-mt,0px)] not-first:border-t-[length:var(--p-line,0px)] dark:border-navy-500"

  @aligns %{
    "start" => "justify-start",
    "center" => "justify-center",
    "end" => "justify-end",
    "between" => "justify-between"
  }

  @bleed "block overflow-hidden [&_img]:block [&_img]:w-full [&_img]:object-cover"

  @bleed_edges %{
    "all" => "-mx-[var(--card-px,1rem)] -my-[var(--card-py,1rem)] rounded-[var(--b-r,0px)]",
    "x" => "-mx-[var(--card-px,1rem)]",
    "top" => "-mx-[var(--card-px,1rem)] -mt-[var(--card-py,1rem)] rounded-t-[var(--b-r,0px)]",
    "bottom" => "-mx-[var(--card-px,1rem)] -mb-[var(--card-py,1rem)] rounded-b-[var(--b-r,0px)]"
  }

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
      "`default` is LineOne's white panel with a soft shadow (elevation in dark); `flat` is the same panel without the shadow; `bordered` adds a border; `outline` is the border only; `muted` and `soft` are quiet neutral tints, `muted` the stronger that adapt to the background; `filled` is a solid fill without border; `solid` and `glow` use `color`; `gradient` and `gradient_outline` use `gradient`."
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg),
    doc: "Padding, typography, corners and the gap between parts. `md` is the original card."
  )

  attr(:body, :string,
    default: "seamless",
    values: ~w(seamless divided separated inset flush),
    doc:
      "How `card_header/1`, `card_body/1` and `card_footer/1` are told apart: one surface, lines, tinted bands, a body panel with concentric corners, or a body panel that reaches the card's sides."
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
      <div class={
        merge([
          "rounded-lg bg-slate-50 dark:bg-navy-900",
          size(@size),
          outline_inner_shape(@shape),
          layout(@padded, @size, @body)
        ])
      }>
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
      class={
        merge([
          surface(@variant, @color, @gradient),
          size(@size),
          corners(@size),
          shape(@shape),
          layout(@padded, @size, @body),
          @class
        ])
      }
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
        <.card_actions><.button size="xs">Menu</.button></.card_actions>
        <.card_heading>Activity</.card_heading>
        <.card_subheading>Last 30 days</.card_subheading>
      </.card_header>

  It pads itself outside a card, and follows the card's `body` inside one.
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_header(assigns) do
    ~H"""
    <div class={merge([header(), @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "The title of a `card_header/1`."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_heading(assigns) do
    ~H"""
    <h2 class={merge([heading(), @class])} {@rest}>{render_slot(@inner_block)}</h2>
    """
  end

  @doc "The line under the heading of a `card_header/1`."
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_subheading(assigns) do
    ~H"""
    <p class={merge([subheading(), @class])} {@rest}>{render_slot(@inner_block)}</p>
    """
  end

  @doc """
  Buttons or links of a `card_header/1`. They sit at the trailing side, or at the leading side
  when written before the heading, and do not make the header taller.
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_actions(assigns) do
    ~H"""
    <div class={merge([actions(), @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc """
  The content of a card. In the `inset` and `flush` treatments it is the panel; a
  `card_header/1` or `card_footer/1` nested in it follows the body's padding.
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_body(assigns) do
    ~H"""
    <div class={merge([body(), @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc """
  The bottom of a card, for its buttons. It pads itself outside a card, and follows the card's
  `body` inside one.
  """
  attr(:align, :string,
    default: "end",
    values: ~w(start center end between),
    doc: "Where the content sits on the row."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_footer(assigns) do
    ~H"""
    <div class={merge([footer(), align(@align), @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc """
  Lets an image (or any media) fill a `card_body/1` up to its edges, cancelling the card's
  padding on the chosen sides; the footer keeps its padding.
  """
  attr(:edges, :string,
    default: "all",
    values: ~w(all top bottom x),
    doc:
      "`all` bleeds on every side and rounds all corners; `top` and `bottom` bleed to one end and round it (next to a header or footer); `x` bleeds sideways only."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card_bleed(assigns) do
    ~H"""
    <div class={merge([bleed(), bleed_edges(@edges), @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp layout(true, size, body), do: [@paddings[size], @modes[body]]
  defp layout(false, _size, _body), do: @unpadded

  defp size(size), do: @sizes[size]
  defp corners(size), do: @corners[size]
  defp shape(shape), do: @shapes[shape]
  defp gradient_outline(gradient), do: @gradient_outlines[gradient]
  defp outline_inner_shape(shape), do: @outline_inner_shapes[shape]
  defp header, do: @header
  defp heading, do: @heading
  defp subheading, do: @subheading
  defp actions, do: @actions
  defp body, do: @body
  defp footer, do: @footer
  defp align(align), do: @aligns[align]
  defp bleed, do: @bleed
  defp bleed_edges(edges), do: @bleed_edges[edges]

  defp surface("default", _color, _gradient), do: ["card", @heading_color]
  defp surface("flat", _color, _gradient), do: ["card shadow-none", @heading_color]

  defp surface("bordered", _color, _gradient),
    do: ["card border border-slate-150 shadow-none dark:border-navy-600", @heading_color]

  defp surface("outline", _color, _gradient),
    do: [
      "card border border-slate-200 bg-transparent shadow-none dark:border-navy-500 dark:bg-transparent",
      @heading_color
    ]

  defp surface("muted", _color, _gradient),
    do: [
      "card border border-slate-200/70 bg-slate-100 shadow-none dark:border-navy-500 dark:bg-navy-600/50",
      @heading_color
    ]

  defp surface("soft", _color, _gradient),
    do: [
      "card border border-slate-150 bg-slate-50 shadow-none dark:border-navy-600 dark:bg-navy-700/60",
      @heading_color
    ]

  defp surface("filled", _color, _gradient),
    do: ["card bg-slate-100 shadow-none dark:bg-navy-600/50", @heading_color]

  defp surface("solid", color, _gradient), do: @solid[color]
  defp surface("glow", color, _gradient), do: @glow[color]
  defp surface("gradient", _color, gradient), do: @gradients[gradient]

  defp title_class(variant) when variant in ~w(default flat bordered outline muted soft filled),
    do: @titles["light"]

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
