defmodule LineaUI.Components.Typography do
  @moduledoc """
  LineOne's typography: headings in every level and weight, display headings, gradient and
  decorated text, decorated links, inline code and keyboard keys.

      <.heading level={1}>Heading H1</.heading>
      <.heading level={3} weight="light" color="info">Light H3</.heading>
      <.heading display={2}>Display 2</.heading>

      <.text size="lg" decoration="underline">Underlined</.text>
      <.text as="span" size="lg" weight="semibold" gradient="sky-blue">Gradient</.text>
      <.text_link href="#" decoration_color="info" decoration_style="wavy">Tattooine</.text_link>

      Press <.kbd>Ctrl</.kbd> + <.kbd>K</.kbd>, or run <.inline_code>mix test</.inline_code>.
  """

  use LineaUI.Component

  @heading_sizes %{
    1 => "text-3xl",
    2 => "text-2xl",
    3 => "text-xl",
    4 => "text-lg",
    5 => "text-base",
    6 => "text-sm"
  }

  @named_sizes %{
    "sm" => "text-sm",
    "base" => "text-base",
    "lg" => "text-lg",
    "xl" => "text-xl",
    "2xl" => "text-2xl",
    "3xl" => "text-3xl"
  }

  @display_sizes %{
    1 => "text-8xl",
    2 => "text-7xl",
    3 => "text-6xl",
    4 => "text-5xl",
    5 => "text-4xl"
  }

  @weights %{
    "normal" => "",
    "light" => "font-light",
    "medium" => "font-medium",
    "semibold" => "font-semibold",
    "bold" => "font-bold"
  }

  @colors %{
    "default" => "",
    "neutral" => "text-slate-700 dark:text-navy-100",
    "muted" => "text-slate-400 dark:text-navy-300",
    "primary" => "text-primary dark:text-accent-light",
    "secondary" => "text-secondary dark:text-secondary-light",
    "info" => "text-info",
    "success" => "text-success",
    "warning" => "text-warning",
    "error" => "text-error"
  }

  @text_sizes %{
    "inherit" => "",
    "xs" => "text-xs",
    "xs-plus" => "text-xs-plus",
    "sm" => "text-sm",
    "base" => "text-base",
    "lg" => "text-lg",
    "xl" => "text-xl"
  }

  @gradients %{
    "sky-blue" => "bg-gradient-to-r from-sky-400 to-blue-600 bg-clip-text text-transparent",
    "green-fuchsia" =>
      "bg-gradient-to-r from-green-400 to-fuchsia-400 bg-clip-text text-transparent",
    "fuchsia-pink" =>
      "bg-gradient-to-r from-fuchsia-600 to-pink-600 bg-clip-text text-transparent",
    "amber-orange" =>
      "bg-gradient-to-r from-amber-400 to-orange-600 bg-clip-text text-transparent",
    "purple-indigo" =>
      "bg-gradient-to-r from-purple-500 to-indigo-600 bg-clip-text text-transparent"
  }

  @decorations %{
    "underline" => "underline",
    "overline" => "overline",
    "line-through" => "line-through",
    "none" => "no-underline"
  }

  @decoration_colors %{
    "primary" => "decoration-primary",
    "secondary" => "decoration-secondary",
    "info" => "decoration-info",
    "success" => "decoration-success",
    "warning" => "decoration-warning",
    "error" => "decoration-error",
    "current" => "decoration-current"
  }

  @decoration_styles %{
    "solid" => "",
    "wavy" => "decoration-wavy",
    "double" => "decoration-double",
    "dotted" => "decoration-dotted",
    "dashed" => "decoration-dashed"
  }

  @text_colors Map.keys(@colors)

  @doc """
  Renders a heading, `<h1>` to `<h6>`, sized as LineOne's. `display` renders LineOne's display
  headings (an `<h1>` unless `level` says otherwise) from 1, the largest, to 5.

      <.heading level={3} weight="semibold" color="primary">Orders</.heading>
      <.heading display={1}>Welcome</.heading>

  `size` sets the type size apart from the level, so a heading keeps its place in the outline and looks as
  large as the design asks: `<.heading level={2} size="2xl">Overview</.heading>`.
  """
  attr(:level, :integer, default: nil, values: [nil, 1, 2, 3, 4, 5, 6])
  attr(:size, :string, default: nil, values: [nil | Map.keys(@named_sizes)])
  attr(:display, :integer, default: nil, values: [nil, 1, 2, 3, 4, 5])
  attr(:weight, :string, default: "normal", values: ~w(normal light medium semibold bold))
  attr(:color, :string, default: "default", values: @text_colors)
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def heading(assigns) do
    assigns =
      assigns
      |> assign(:tag, "h#{heading_level(assigns)}")
      |> assign(:type_size, heading_size(assigns))

    ~H"""
    <.dynamic_tag
      tag_name={@tag}
      class={merge([@type_size, weight(@weight), color(@color), @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  defp heading_level(%{level: level}) when is_integer(level), do: level
  defp heading_level(%{display: display}) when is_integer(display), do: 1
  defp heading_level(_assigns), do: 2

  defp heading_size(%{size: size}) when is_binary(size), do: @named_sizes[size]
  defp heading_size(%{display: display}) when is_integer(display), do: @display_sizes[display]
  defp heading_size(assigns), do: @heading_sizes[heading_level(assigns)]

  @doc """
  Renders a run of text: a paragraph unless `as` says otherwise.

      <.text size="lg" weight="semibold" gradient="amber-orange">Hello</.text>
  """
  attr(:as, :string, default: "p", values: ~w(p span div strong em small))
  attr(:size, :string, default: "inherit", values: ~w(inherit xs xs-plus sm base lg xl))
  attr(:weight, :string, default: "normal", values: ~w(normal light medium semibold bold))
  attr(:color, :string, default: "default", values: @text_colors)

  attr(:gradient, :string,
    default: nil,
    values: [nil, "sky-blue", "green-fuchsia", "fuchsia-pink", "amber-orange", "purple-indigo"],
    doc: "Paints the text with one of LineOne's gradients."
  )

  attr(:decoration, :string,
    default: nil,
    values: [nil, "underline", "overline", "line-through", "none"]
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def text(assigns) do
    ~H"""
    <.dynamic_tag
      tag_name={@as}
      class={
        merge([
          text_size(@size),
          weight(@weight),
          color(@color),
          gradient(@gradient),
          decoration(@decoration),
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  @doc """
  Renders a link inside running text, underlined in a theme color and style as LineOne's text
  decoration examples.

      <.text_link navigate={~p"/about"} decoration_color="secondary" decoration_style="dotted">
        About us
      </.text_link>
  """
  attr(:decoration_color, :string,
    default: "current",
    values: ~w(current primary secondary info success warning error)
  )

  attr(:decoration_style, :string,
    default: "solid",
    values: ~w(solid wavy double dotted dashed)
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(href navigate patch method download))
  slot(:inner_block, required: true)

  def text_link(assigns) do
    ~H"""
    <.link
      class={
        merge([
          "font-semibold underline decoration-2",
          decoration_color(@decoration_color),
          decoration_style(@decoration_style),
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Renders code inside running text, the way LineOne's pages show class names.

      Use the <.inline_code>rounded-full</.inline_code> utility.
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def inline_code(assigns) do
    ~H"""
    <code class={merge(["inline-code", @class])} {@rest}>{render_slot(@inner_block)}</code>
    """
  end

  @doc """
  Renders a keyboard key.

      <.kbd>Ctrl</.kbd> + <.kbd>K</.kbd>
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def kbd(assigns) do
    ~H"""
    <kbd
      class={
        merge([
          "inline-flex h-5 min-w-5 items-center justify-center rounded-sm border border-b-2 border-slate-300 bg-slate-100 px-1.5 font-inter text-tiny-plus font-medium leading-none text-slate-700 dark:border-navy-450 dark:bg-navy-800 dark:text-navy-100",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </kbd>
    """
  end

  defp weight(weight), do: @weights[weight]
  defp color(color), do: @colors[color]
  defp text_size(size), do: @text_sizes[size]
  defp gradient(nil), do: nil
  defp gradient(gradient), do: @gradients[gradient]
  defp decoration(nil), do: nil
  defp decoration(decoration), do: @decorations[decoration]
  defp decoration_color(color), do: @decoration_colors[color]
  defp decoration_style(style), do: @decoration_styles[style]
end
