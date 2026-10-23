defmodule LineaUI.Components.Avatar do
  @moduledoc """
  LineOne's avatars: an image or initials in a circle, a square, a squircle or any mask shape,
  with a status dot, a gradient ring, and stacked in groups.

      <.avatar src="/images/jane.jpg" alt="Jane" />
      <.avatar initials="jd" color="primary" size="md" shape="square" />
      <.avatar initials="jd" color="info" variant="soft" />
      <.avatar src="/images/jane.jpg" size="lg" status="success" />
      <.avatar initials="jd" status="primary" status_position="bottom-left" ping />
      <.avatar src="/images/jane.jpg" gradient="sky-blue" size="lg" />

      <.avatar_group>
        <.avatar :for={user <- @users} src={user.photo} size="xs" ring />
      </.avatar_group>

  The inner block, when given, replaces the initials (an icon, a counter).
  """

  use LineaUI.Component

  alias LineaUI.Components.Mask

  @sizes %{
    "xs" => "size-8",
    "sm" => "size-10",
    "md" => "size-12",
    "lg" => "size-16",
    "xl" => "size-20",
    "2xl" => "size-24"
  }

  @text_sizes %{
    "xs" => "text-xs-plus",
    "sm" => "",
    "md" => "text-base",
    "lg" => "text-lg",
    "xl" => "text-xl",
    "2xl" => "text-2xl"
  }

  @shapes %{
    "circle" => "rounded-full",
    "square" => "rounded-lg",
    "rounded" => "rounded-xl"
  }

  @initials %{
    "solid" => %{
      "neutral" => "bg-slate-200 text-slate-600 dark:bg-navy-500 dark:text-navy-100",
      "primary" => "bg-primary text-white dark:bg-accent",
      "secondary" => "bg-secondary text-white",
      "info" => "bg-info text-white",
      "success" => "bg-success text-white",
      "warning" => "bg-warning text-white",
      "error" => "bg-error text-white"
    },
    "soft" => %{
      "neutral" => "bg-slate-150/60 text-slate-600 dark:bg-navy-500/40 dark:text-navy-100",
      "primary" => "bg-primary/10 text-primary dark:bg-accent-light/10 dark:text-accent-light",
      "secondary" =>
        "bg-secondary/10 text-secondary dark:bg-secondary-light/10 dark:text-secondary-light",
      "info" => "bg-info/10 text-info",
      "success" => "bg-success/10 text-success",
      "warning" => "bg-warning/10 text-warning",
      "error" => "bg-error/10 text-error"
    },
    "bordered" => %{
      "neutral" =>
        "border border-slate-300 bg-slate-150/60 text-slate-600 dark:border-navy-450 dark:bg-navy-500/40 dark:text-navy-100",
      "primary" =>
        "border border-primary/30 bg-primary/10 text-primary dark:border-accent-light/30 dark:bg-accent-light/10 dark:text-accent-light",
      "secondary" =>
        "border border-secondary/30 bg-secondary/10 text-secondary dark:border-secondary-light/30 dark:bg-secondary-light/10 dark:text-secondary-light",
      "info" => "border border-info/30 bg-info/10 text-info",
      "success" => "border border-success/30 bg-success/10 text-success",
      "warning" => "border border-warning/30 bg-warning/10 text-warning",
      "error" => "border border-error/30 bg-error/10 text-error"
    },
    "skeleton" => %{
      "neutral" => "bg-slate-200 text-white dark:bg-navy-500",
      "primary" => "bg-slate-200 text-white dark:bg-navy-500",
      "secondary" => "bg-slate-200 text-white dark:bg-navy-500",
      "info" => "bg-slate-200 text-white dark:bg-navy-500",
      "success" => "bg-slate-200 text-white dark:bg-navy-500",
      "warning" => "bg-slate-200 text-white dark:bg-navy-500",
      "error" => "bg-slate-200 text-white dark:bg-navy-500"
    }
  }

  @dots %{
    "neutral" => "bg-slate-300",
    "primary" => "bg-primary dark:bg-accent",
    "secondary" => "bg-secondary dark:bg-secondary-light",
    "info" => "bg-info",
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error"
  }

  @pings %{
    "neutral" => "bg-slate-300",
    "primary" => "bg-primary dark:bg-accent",
    "secondary" => "bg-secondary dark:bg-secondary-light",
    "info" => "bg-info",
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error"
  }

  @dot_sizes %{
    "round" => %{
      "xs" => "size-2.5 border",
      "sm" => "size-3 border-2",
      "md" => "size-3.5 border-2",
      "lg" => "m-0.5 size-3.5 border-2",
      "xl" => "m-1 size-4 border-2",
      "2xl" => "m-1.5 size-4 border-2"
    },
    "mask" => %{
      "xs" => "-m-px size-2.5 border",
      "sm" => "-m-0.5 size-3 border-2",
      "md" => "-m-0.5 size-3.5 border-2",
      "lg" => "-m-px size-3.5 border-2",
      "xl" => "size-4 border-2",
      "2xl" => "size-4 border-2"
    }
  }

  @positions %{
    "top-right" => "right-0",
    "top-left" => "left-0",
    "bottom-right" => "bottom-0 right-0",
    "bottom-left" => "bottom-0 left-0"
  }

  @gradients %{
    "sky-blue" => "bg-gradient-to-r from-sky-400 to-blue-600",
    "amber-orange" => "bg-gradient-to-r from-amber-400 to-orange-600",
    "pink-rose" => "bg-gradient-to-r from-pink-500 to-rose-500",
    "purple-orange" => "bg-gradient-to-r from-purple-500 to-orange-600",
    "green-fuchsia" => "bg-gradient-to-r from-green-400 to-fuchsia-400",
    "purple-indigo" => "bg-gradient-to-r from-purple-500 to-indigo-600",
    "fuchsia-pink" => "bg-gradient-to-r from-fuchsia-600 to-pink-600"
  }

  @colors ~w(neutral primary secondary info success warning error)

  @doc "Renders an avatar."
  attr(:src, :string, default: nil)
  attr(:alt, :string, default: "avatar")
  attr(:initials, :string, default: nil, doc: "Shown (upper-cased) when there is no `src`.")
  attr(:size, :string, default: "sm", values: ~w(xs sm md lg xl 2xl))

  attr(:shape, :string,
    default: "circle",
    values:
      ~w(circle square rounded squircle reuleaux-triangle diamond hexagon hexagon-2 octagon star star-2 heart),
    doc: "`square` is LineOne's `rounded-lg`, `rounded` its `rounded-xl`; the others are masks."
  )

  attr(:color, :string, default: "neutral", values: @colors, doc: "The initials' color.")

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid soft bordered skeleton),
    doc: "How the initials are painted; `skeleton` is the grey placeholder."
  )

  attr(:status, :string, default: nil, values: [nil | @colors], doc: "A status dot's color.")

  attr(:status_position, :string,
    default: "top-right",
    values: ~w(top-right top-left bottom-right bottom-left)
  )

  attr(:ping, :boolean, default: false, doc: "Animates the status dot with a ping.")
  attr(:ring, :boolean, default: false, doc: "The white ring avatars wear inside a group.")

  attr(:gradient, :string,
    default: nil,
    values: [
      nil,
      "sky-blue",
      "amber-orange",
      "pink-rose",
      "purple-orange",
      "green-fuchsia",
      "purple-indigo",
      "fuchsia-pink"
    ],
    doc: "A gradient border around the avatar."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  def avatar(%{gradient: gradient} = assigns) when is_binary(gradient) do
    ~H"""
    <div
      class={merge(["flex rounded-full p-0.5", gradient_class(@gradient), size(@size), @class])}
      {@rest}
    >
      <div class="avatar h-full w-full rounded-full bg-white p-[3px] dark:bg-navy-700">
        <.face {assigns} />
        <.status_dot :if={@status} {assigns} />
      </div>
    </div>
    """
  end

  def avatar(assigns) do
    ~H"""
    <div class={merge(["avatar", size(@size), @ring && "hover:z-10", @class])} {@rest}>
      <.face {assigns} />
      <.status_dot :if={@status} {assigns} />
    </div>
    """
  end

  defp face(%{src: src} = assigns) when is_binary(src) do
    ~H"""
    <img class={[shape(@shape), ring(@ring)]} src={@src} alt={@alt} />
    """
  end

  defp face(assigns) do
    ~H"""
    <div class={[
      "is-initial uppercase",
      shape(@shape),
      text_size(@size),
      initials(@variant, @color),
      ring(@ring)
    ]}>
      {render_slot(@inner_block) || @initials}
    </div>
    """
  end

  defp status_dot(assigns) do
    ~H"""
    <div class={[
      "absolute rounded-full border-white dark:border-navy-700",
      position(@status_position),
      dot_size(@shape, @size),
      dot(@status)
    ]}>
      <span
        :if={@ping}
        class={[
          "absolute inline-flex h-full w-full animate-ping rounded-full opacity-80",
          ping(@status)
        ]}
      ></span>
    </div>
    """
  end

  defp size(size), do: @sizes[size]
  defp text_size(size), do: @text_sizes[size]
  defp initials(variant, color), do: @initials[variant][color]
  defp dot(color), do: @dots[color]
  defp ping(color), do: @pings[color]
  defp position(position), do: @positions[position]
  defp gradient_class(gradient), do: @gradients[gradient]

  defp shape(shape) when is_map_key(@shapes, shape), do: @shapes[shape]
  defp shape(shape), do: Mask.mask_class(shape)

  defp dot_size(shape, size) when is_map_key(@shapes, shape), do: @dot_sizes["round"][size]
  defp dot_size(_shape, size), do: @dot_sizes["mask"][size]

  defp ring(true), do: "ring-2 ring-white dark:ring-navy-700"
  defp ring(false), do: nil

  @doc """
  Stacks avatars so they overlap, as LineOne's avatar group. Give the avatars `ring` so each
  one is outlined against the next.

      <.avatar_group>
        <.avatar src="/a.jpg" size="xs" ring />
        <.avatar initials="jd" color="info" size="xs" ring />
      </.avatar_group>
  """
  attr(:pulse, :boolean, default: false, doc: "Pulses the whole group, for skeletons.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def avatar_group(assigns) do
    ~H"""
    <div class={merge(["flex flex-wrap -space-x-2", @pulse && "animate-pulse", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
