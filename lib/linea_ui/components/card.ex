defmodule LineaUI.Components.Card do
  @moduledoc """
  LineOne's cards: the white panel, bordered, filled with a theme color, glowing, gradient and
  gradient-outlined.

      <.card>
        <:title>Simple Card</:title>
        Lorem ipsum dolor sit amet.
      </.card>
      <.card variant="bordered" shape="xl">…</.card>
      <.card variant="solid" color="primary"><:title>Primary Card</:title>…</.card>
      <.card variant="gradient" gradient="purple-indigo">…</.card>
      <.card variant="gradient_outline" gradient="sky-blue">…</.card>

  Without `:title` the content fills the card as is; `padded={false}` drops the default padding,
  for cards laid out by hand (`<.card padded={false} class="px-4 pb-4 sm:px-5">`).
  """

  use LineaUI.Component

  @padding "px-4 py-4 sm:px-5"

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

  @shapes %{"rounded" => "", "xl" => "rounded-2xl"}

  @titles %{
    "light" => "text-lg font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100",
    "colored" => "text-lg font-medium tracking-wide line-clamp-1"
  }

  @doc """
  Renders a card, with an optional `:title` above the content.

      <.card variant="glow" color="info">
        <:title>Revenue</:title>
        <p>$12,400 this month.</p>
      </.card>
  """
  attr(:variant, :string,
    default: "default",
    values: ~w(default bordered solid glow gradient gradient_outline),
    doc:
      "`default` is LineOne's white panel with a soft shadow; `solid` and `glow` use `color`; `gradient` and `gradient_outline` use `gradient`."
  )

  attr(:color, :string,
    default: "primary",
    values: ~w(primary secondary info success warning error)
  )

  attr(:gradient, :string,
    default: "purple-indigo",
    values: ~w(purple-indigo fuchsia-pink amber-orange sky-blue green-fuchsia)
  )

  attr(:shape, :string, default: "rounded", values: ~w(rounded xl))
  attr(:padded, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:title, doc: "The card's heading, followed by the content.") do
    attr(:class, :any)
  end

  slot(:inner_block)

  def card(%{variant: "gradient_outline"} = assigns) do
    ~H"""
    <div class={merge([gradient_outline(@gradient), @class])} {@rest}>
      <div class={merge(["rounded-lg bg-slate-50 dark:bg-navy-900", @padded && "px-4 py-4 sm:px-5"])}>
        <.card_body title={@title} title_class={title_class("default")}>
          {render_slot(@inner_block)}
        </.card_body>
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
          shape(@shape),
          @padded && padding(),
          @class
        ])
      }
      {@rest}
    >
      <.card_body title={@title} title_class={title_class(@variant)}>
        {render_slot(@inner_block)}
      </.card_body>
    </div>
    """
  end

  defp padding, do: @padding
  defp shape(shape), do: @shapes[shape]
  defp gradient_outline(gradient), do: @gradient_outlines[gradient]

  defp surface("default", _color, _gradient), do: "card"

  defp surface("bordered", _color, _gradient),
    do: "card border border-slate-150 shadow-none dark:border-navy-600"

  defp surface("solid", color, _gradient), do: @solid[color]
  defp surface("glow", color, _gradient), do: @glow[color]
  defp surface("gradient", _color, gradient), do: @gradients[gradient]

  defp title_class(variant) when variant in ~w(default bordered), do: @titles["light"]
  defp title_class(_variant), do: @titles["colored"]

  attr(:title, :list, required: true)
  attr(:title_class, :string, required: true)
  slot(:inner_block)

  defp card_body(%{title: []} = assigns) do
    ~H"""
    {render_slot(@inner_block)}
    """
  end

  defp card_body(assigns) do
    ~H"""
    <div :for={title <- @title}>
      <h2 class={merge([@title_class, title[:class]])}>{render_slot(title)}</h2>
    </div>
    <div class="pt-2">{render_slot(@inner_block)}</div>
    """
  end
end
