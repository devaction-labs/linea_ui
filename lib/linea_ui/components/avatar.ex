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

      <.avatar src="/images/jane.jpg" size="2xs" ring={1} ring_color="primary" />
      <.avatar src="/images/jane.jpg" size="lg" face_class="border-2 border-white dark:border-navy-700" />
      <.avatar src="/images/jane.jpg" status="success" status_position="bottom-right" />

  The inner block, when given, replaces the initials (an icon, a counter).

  ## People, companies and the assistant

  `name` gives the initials (first and last word) and, with `color="auto"`, a color that is always
  the same for the same name; `status` also takes the presence of a person, drawn at the bottom
  right; `kind` draws a company, a customer, a supplier, the assistant or the "invite" placeholder;
  `size` also takes the pixels, `"24"`, `"32"`, `"40"`, `"48"` and `"64"`:

      <.avatar name="Ana Souza" color="auto" size="40" status="online" />
      <.avatar kind="company" name="Farmácia Signetum" size="48" />
      <.avatar kind="assistant" size="32" />
      <.avatar kind="invite" size="40" />

      <.avatar_group more={3} size="32">
        <.avatar :for={user <- @users} name={user.name} color="auto" size="32" ring />
      </.avatar_group>
  """

  use LineaUI.Component

  alias LineaUI.Components.Mask

  @sizes %{
    "3xs" => "size-6",
    "2xs" => "size-7",
    "xs" => "size-8",
    "xs-plus" => "size-9",
    "sm" => "size-10",
    "md" => "size-12",
    "lg" => "size-16",
    "xl" => "size-20",
    "2xl" => "size-24"
  }

  @text_sizes %{
    "3xs" => "text-tiny",
    "2xs" => "text-xs-plus",
    "xs" => "text-xs-plus",
    "xs-plus" => "text-xs-plus",
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
    "error" => "bg-error",
    "online" => "bg-success",
    "away" => "bg-warning",
    "busy" => "bg-error",
    "offline" => "bg-slate-400"
  }

  @pings %{
    "neutral" => "bg-slate-300",
    "primary" => "bg-primary dark:bg-accent",
    "secondary" => "bg-secondary dark:bg-secondary-light",
    "info" => "bg-info",
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error",
    "online" => "bg-success",
    "away" => "bg-warning",
    "busy" => "bg-error",
    "offline" => "bg-slate-400"
  }

  @dot_sizes %{
    "round" => %{
      "3xs" => "size-2 border",
      "2xs" => "size-2 border",
      "xs-plus" => "size-2.5 border",
      "xs" => "size-2.5 border",
      "sm" => "size-3 border-2",
      "md" => "size-3.5 border-2",
      "lg" => "m-0.5 size-3.5 border-2",
      "xl" => "m-1 size-4 border-2",
      "2xl" => "m-1.5 size-4 border-2"
    },
    "mask" => %{
      "3xs" => "-m-px size-2 border",
      "2xs" => "-m-px size-2 border",
      "xs-plus" => "-m-px size-2.5 border",
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
  @presences ~w(online away busy offline)
  @kinds ~w(company customer supplier assistant invite)
  @squared_kinds ~w(company customer supplier)

  @size_aliases %{"24" => "3xs", "32" => "xs", "40" => "sm", "48" => "md", "64" => "lg"}

  @auto [
    "bg-primary text-white dark:bg-accent",
    "bg-info text-white",
    "bg-success text-white",
    "bg-warning text-white",
    "bg-pink-600 text-white",
    "bg-violet-600 text-white",
    "bg-teal-600 text-white",
    "bg-error text-white"
  ]

  @kind_faces %{
    "company" => "bg-navy-900 text-white dark:bg-navy-500",
    "customer" => "bg-success-focus text-white",
    "supplier" => "bg-warning-focus text-white",
    "assistant" =>
      "bg-linear-to-br from-primary to-purple-500 text-white dark:from-accent dark:to-purple-400",
    "invite" =>
      "border-[1.5px] border-dashed border-slate-300 bg-transparent text-slate-500 dark:border-navy-450 dark:text-navy-200"
  }

  @ring_widths %{
    "1" => "ring-1",
    "2" => "ring-2",
    "4" => "ring-4"
  }

  @ring_colors %{
    "white" => "ring-white dark:ring-navy-700",
    "neutral" => "ring-slate-300 dark:ring-navy-450",
    "primary" => "ring-primary dark:ring-accent",
    "secondary" => "ring-secondary dark:ring-secondary-light",
    "info" => "ring-info",
    "success" => "ring-success",
    "warning" => "ring-warning",
    "error" => "ring-error"
  }

  @overlaps %{"2" => "-space-x-2", "3" => "-space-x-3"}

  @doc "Renders an avatar."
  attr(:src, :string, default: nil)
  attr(:alt, :string, default: "avatar", doc: "The picture's text; the `name` when not given.")
  attr(:initials, :string, default: nil, doc: "Shown (upper-cased) when there is no `src`.")

  attr(:name, :string,
    default: nil,
    doc:
      "A person or company name: its first and last word give the initials when there are none, and `color=\"auto\"` picks a color from it."
  )

  attr(:kind, :string,
    default: nil,
    values: [nil | @kinds],
    doc:
      "`company`, `customer` and `supplier` are rounded squares in the navy, green and amber of their lists, with the initials; `assistant` is the indigo to purple gradient with a sparkle; `invite` is the dashed \"add a person\" placeholder."
  )

  attr(:size, :string,
    default: "sm",
    values: ~w(3xs 2xs xs xs-plus sm md lg xl 2xl 24 32 40 48 64),
    doc:
      "`3xs` is size-6, `2xs` size-7, `xs` size-8, `xs-plus` size-9, `sm` size-10 (default), `md` size-12, `lg` size-16, `xl` size-20, `2xl` size-24. The pixel sizes are aliases: `24` is `3xs`, `32` is `xs`, `40` is `sm`, `48` is `md`, `64` is `lg`."
  )

  attr(:shape, :string,
    default: "circle",
    values:
      ~w(circle square rounded squircle reuleaux-triangle diamond hexagon hexagon-2 octagon star star-2 heart),
    doc: "`square` is LineOne's `rounded-lg`, `rounded` its `rounded-xl`; the others are masks."
  )

  attr(:color, :string,
    default: "neutral",
    values: ["auto" | @colors],
    doc:
      "The initials' color; `auto` takes one of eight from the `name`, always the same for the same name (solid only)."
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid soft bordered skeleton),
    doc: "How the initials are painted; `skeleton` is the grey placeholder."
  )

  attr(:status, :any,
    default: nil,
    values: [nil, false | @colors ++ @presences],
    doc:
      "A status dot's color; `nil` or `false` shows no dot. Works the same on an image and on initials. `online` (green), `away` (amber), `busy` (red) and `offline` (grey) are a person's presence, at the bottom right unless `status_position` says otherwise."
  )

  attr(:status_position, :string,
    default: nil,
    values: [nil | ~w(top-right top-left bottom-right bottom-left)],
    doc: "`top-right`, or `bottom-right` for a presence."
  )

  attr(:ping, :boolean, default: false, doc: "Animates the status dot with a ping.")

  attr(:ring, :any,
    default: false,
    values: [true, false, 1, 2, 4, "1", "2", "4"],
    doc:
      "The ring avatars wear inside a group. `true` is a 2px ring; `1`, `2` or `4` pick the width."
  )

  attr(:ring_color, :string,
    default: "white",
    values: ~w(white neutral primary secondary info success warning error),
    doc: "`white` is white in light mode and the card color in dark mode."
  )

  attr(:face_class, :any,
    default: nil,
    doc:
      "Classes merged into the picture or initials face itself (a border, a shadow), while `class` goes on the wrapper."
  )

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

  def avatar(assigns), do: assigns |> prepare() |> render_avatar()

  defp prepare(assigns) do
    assigns
    |> assign(:size, Map.get(@size_aliases, assigns.size, assigns.size))
    |> assign(:initials, assigns.initials || initials_of(assigns.name))
    |> assign(:alt, alt_of(assigns))
    |> assign(:status_position, status_position(assigns))
    |> assign(:shape, shape_of(assigns))
  end

  defp initials_of(nil), do: nil

  defp initials_of(name) do
    case String.split(name) do
      [] -> nil
      [word] -> String.slice(word, 0, 2)
      [first | rest] -> String.first(first) <> String.first(List.last(rest))
    end
  end

  defp alt_of(%{alt: "avatar", name: name}) when is_binary(name), do: name
  defp alt_of(%{alt: alt}), do: alt

  defp status_position(%{status_position: nil, status: status}) when status in @presences,
    do: "bottom-right"

  defp status_position(%{status_position: nil}), do: "top-right"
  defp status_position(%{status_position: position}), do: position

  defp shape_of(%{kind: kind}) when kind in @squared_kinds, do: "rounded"
  defp shape_of(%{shape: shape}), do: shape

  defp render_avatar(%{gradient: gradient} = assigns) when is_binary(gradient) do
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

  defp render_avatar(assigns) do
    ~H"""
    <div class={merge(["avatar", size(@size), @ring && "hover:z-10", @class])} {@rest}>
      <.face {assigns} />
      <.status_dot :if={@status} {assigns} />
    </div>
    """
  end

  defp face(%{src: src} = assigns) when is_binary(src) do
    ~H"""
    <img class={merge([shape(@shape), ring(@ring, @ring_color), @face_class])} src={@src} alt={@alt} />
    """
  end

  defp face(%{kind: "assistant"} = assigns) do
    ~H"""
    <div class={
      merge([
        "is-initial flex items-center justify-center",
        shape(@shape),
        kind_face("assistant"),
        ring(@ring, @ring_color),
        @face_class
      ])
    }>
      {render_slot(@inner_block) || sparkle(assigns)}
    </div>
    """
  end

  defp face(%{kind: "invite"} = assigns) do
    ~H"""
    <div class={
      merge([
        "is-initial flex items-center justify-center",
        shape(@shape),
        kind_face("invite"),
        ring(@ring, @ring_color),
        @face_class
      ])
    }>
      {render_slot(@inner_block) || plus(assigns)}
    </div>
    """
  end

  defp face(assigns) do
    ~H"""
    <div class={
      merge([
        "is-initial uppercase",
        shape(@shape),
        text_size(@size),
        initials(@variant, @color, @kind, @name),
        ring(@ring, @ring_color),
        @face_class
      ])
    }>
      {render_slot(@inner_block) || @initials}
    </div>
    """
  end

  defp sparkle(assigns) do
    ~H"""
    <svg
      class="size-[45%]"
      viewBox="0 0 24 24"
      fill="currentColor"
      stroke="none"
      aria-hidden="true"
    >
      <path d="M12 3l1.8 4.2L18 9l-4.2 1.8L12 15l-1.8-4.2L6 9l4.2-1.8zM18 15l.9 2.1L21 18l-2.1.9L18 21l-.9-2.1L15 18l2.1-.9z" />
    </svg>
    """
  end

  defp plus(assigns) do
    ~H"""
    <svg
      class="size-[40%]"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      aria-hidden="true"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="M12 5v14M5 12h14" />
    </svg>
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

  defp initials(_variant, _color, kind, _name) when is_map_key(@kind_faces, kind),
    do: @kind_faces[kind]

  defp initials(_variant, "auto", _kind, name) when is_binary(name),
    do: Enum.at(@auto, :erlang.phash2(name, length(@auto)))

  defp initials(variant, "auto", _kind, _name), do: initials(variant, "neutral", nil, nil)
  defp initials(variant, color, _kind, _name), do: @initials[variant][color]
  defp kind_face(kind), do: @kind_faces[kind]
  defp dot(color), do: @dots[color]
  defp ping(color), do: @pings[color]
  defp position(position), do: @positions[position]
  defp gradient_class(gradient), do: @gradients[gradient]

  defp shape(shape) when is_map_key(@shapes, shape), do: @shapes[shape]
  defp shape(shape), do: Mask.mask_class(shape)

  defp dot_size(shape, size) when is_map_key(@shapes, shape), do: @dot_sizes["round"][size]
  defp dot_size(_shape, size), do: @dot_sizes["mask"][size]

  defp ring(false, _color), do: nil
  defp ring(true, color), do: ring(2, color)
  defp ring(width, color), do: "#{@ring_widths[to_string(width)]} #{@ring_colors[color]}"

  @doc """
  Stacks avatars so they overlap, as LineOne's avatar group. Give the avatars `ring` so each
  one is outlined against the next.

      <.avatar_group>
        <.avatar src="/a.jpg" size="xs" ring />
        <.avatar initials="jd" color="info" size="xs" ring />
      </.avatar_group>
  """
  attr(:pulse, :boolean, default: false, doc: "Pulses the whole group, for skeletons.")

  attr(:overlap, :string,
    default: "2",
    values: ~w(2 3),
    doc: "How far the avatars overlap: `2` is `-space-x-2`, `3` is `-space-x-3`."
  )

  attr(:more, :integer,
    default: nil,
    doc: "How many more people there are than avatars: draws a \"+N\" avatar at the end."
  )

  attr(:size, :string,
    default: "xs",
    values: ~w(3xs 2xs xs xs-plus sm md lg xl 2xl 24 32 40 48 64),
    doc: "The size of the \"+N\" avatar; give it the same `size` as the avatars."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def avatar_group(assigns) do
    ~H"""
    <div
      class={merge(["flex flex-wrap", overlap(@overlap), @pulse && "animate-pulse", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
      <.avatar
        :if={@more}
        initials={"+#{@more}"}
        variant="soft"
        size={@size}
        ring
      />
    </div>
    """
  end

  defp overlap(overlap), do: @overlaps[overlap]
end
