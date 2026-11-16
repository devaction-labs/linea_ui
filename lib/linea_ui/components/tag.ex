defmodule LineaUI.Components.Tag do
  @moduledoc """
  LineOne's tags: clickable badges that represent an attribute, a filter or an action.

      <.tag href="#">Default</.tag>
      <.tag navigate={~p"/tags/elixir"} color="primary" shape="pill">Elixir</.tag>
      <.tag color="info" variant="bordered" shape="pill" phx-click="filter">Info</.tag>

  A filter chip that can be selected takes `active`:

      <.tag :for={tag <- @tags} variant="soft" active={tag in @selected} phx-click="toggle" phx-value-tag={tag}>
        {tag}
      </.tag>

  `tag_group/1` joins tags (and badges) side by side:

      <.tag_group>
        <.tag color="neutral">Primary</.tag>
        <.tag color="primary">55</.tag>
      </.tag_group>

  A selected chip (`active`) is a solid primary fill with white text, for every variant but `flat`.

  `variant="flat"` is the canvas tag (`sg-tag`): 26px, regular weight, muted text on the sunken fill; its
  active state is the accent tint. `tint` paints a tag in a colour of its own (a user's label colour):

      <.tag variant="flat" active>Todos</.tag>
      <.tag variant="flat" tint="#0d8f91">VIP</.tag>
  `count` puts a small pill with a number inside the tag.

  With `href`, `navigate` or `patch` a tag is a link; otherwise it is a button.

  A tag that only labels (inside a link or a table row) is not interactive: `as="span"` or `static`
  renders a `<span>` with the same classes, so no button is nested in a link:

      <a href="/runs/1">Run 1 <.tag variant="flat" as="span">test</.tag></a>
  """

  use LineaUI.Component

  # daisyUI's badge, sized as LineOne's tag (28px, 12.5px type) and clickable
  @base "badge tag h-7 cursor-pointer gap-1.5 px-[11px] text-[12.5px] leading-none font-medium whitespace-nowrap transition-all duration-200 outline-hidden focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary/50 disabled:pointer-events-none disabled:opacity-55 aria-disabled:pointer-events-none aria-disabled:opacity-55"

  @variants %{
    "solid" => %{
      "neutral" => "border-base-200 bg-base-200 text-base-content hover:bg-base-300",
      "light" => "border-base-200 bg-base-200 text-base-content hover:bg-base-300",
      "primary" => "badge-primary hover:brightness-95",
      "secondary" => "badge-secondary hover:brightness-95",
      "info" => "badge-info hover:brightness-95",
      "success" => "badge-success hover:brightness-95",
      "warning" => "badge-warning hover:brightness-95",
      "error" => "badge-error hover:brightness-95"
    },
    "soft" => %{
      "neutral" => "badge-ghost text-base-content/85 hover:bg-base-300",
      "light" => "badge-ghost text-base-content/85 hover:bg-base-300",
      "primary" => "badge-soft badge-primary hover:brightness-95",
      "secondary" => "badge-soft badge-secondary hover:brightness-95",
      "info" => "badge-soft badge-info hover:brightness-95",
      "success" => "badge-soft badge-success hover:brightness-95",
      "warning" => "badge-soft badge-warning hover:brightness-95",
      "error" => "badge-soft badge-error hover:brightness-95"
    },
    "bordered" => %{
      "neutral" => "badge-ghost border-base-content/20 text-base-content/85 hover:bg-base-300",
      "light" => "badge-ghost border-base-content/20 text-base-content/85 hover:bg-base-300",
      "primary" => "badge-soft badge-primary border-primary/30 hover:brightness-95",
      "secondary" => "badge-soft badge-secondary border-secondary/30 hover:brightness-95",
      "info" => "badge-soft badge-info border-info/30 hover:brightness-95",
      "success" => "badge-soft badge-success border-success/30 hover:brightness-95",
      "warning" => "badge-soft badge-warning border-warning/30 hover:brightness-95",
      "error" => "badge-soft badge-error border-error/30 hover:brightness-95"
    },
    "outline" => %{
      "neutral" => "badge-outline border-base-content/20 text-base-content hover:bg-base-200",
      "light" => "badge-outline border-base-content/20 text-base-content hover:bg-base-200",
      "primary" => "badge-outline badge-primary hover:bg-primary/10",
      "secondary" => "badge-outline badge-secondary hover:bg-secondary/10",
      "info" => "badge-outline badge-info hover:bg-info/10",
      "success" => "badge-outline badge-success hover:bg-success/10",
      "warning" => "badge-outline badge-warning hover:bg-warning/10",
      "error" => "badge-outline badge-error hover:bg-error/10"
    }
  }

  @flat "tag-flat badge-ghost border-transparent font-normal text-base-content/60 hover:text-base-content"

  @flat_on "tag-flat on badge-soft badge-primary"

  @active "badge-primary"

  @shapes %{"rounded" => "", "pill" => "rounded-full", "square" => "rounded-none"}

  @doc """
  Renders a tag: a link with `href`, `navigate` or `patch`, a button otherwise.

      <.tag patch={~p"/posts?tag=elixir"} color="primary" variant="bordered" shape="pill">Elixir</.tag>
  """
  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error light)
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid soft bordered outline flat),
    doc:
      "`flat` is the canvas tag: muted text on the sunken fill, the accent tint when `active`; `color` does not apply to it."
  )

  attr(:tint, :string,
    default: nil,
    doc:
      "A colour of its own (any CSS colour, e.g. `\"#8a5cd6\"`): the text in that colour on a 14% tint of it. Overrides `color`."
  )

  attr(:active, :boolean,
    default: false,
    doc:
      "The selected state of a filter chip (and `aria-pressed=\"true\"`): a solid `primary` fill with white text and a primary border whatever its `color`, or the accent tint for `variant=\"flat\"`, so a list of chips only toggles this."
  )

  attr(:count, :integer,
    default: nil,
    doc: "A small pill with this number inside the tag, after the label (a filter's results)."
  )

  attr(:shape, :string, default: "rounded", values: ~w(rounded pill square))

  attr(:as, :string,
    default: nil,
    values: [nil, "span"],
    doc:
      "`span` renders a non-interactive `<span>` instead of a button or link (it ignores `type`, `href`, `navigate` and `patch`)."
  )

  attr(:static, :boolean,
    default: false,
    doc: "The same as `as=\"span\"`: a plain label with no button, for use inside links."
  )

  attr(:type, :string, default: "button")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(href navigate patch method download name value disabled))
  slot(:inner_block, required: true)

  def tag(assigns) do
    assigns
    |> assign(
      :classes,
      merge([
        @base,
        variant_classes(assigns),
        @shapes[assigns.shape],
        assigns.class
      ])
    )
    |> assign(:style, assigns.tint && "--tag-tint:#{assigns.tint}")
    |> render_tag()
  end

  defp variant_classes(%{tint: tint, variant: variant}) when is_binary(tint),
    do: [variant == "flat" && @flat, "tag-tint"]

  defp variant_classes(%{variant: "flat", active: true}), do: @flat_on
  defp variant_classes(%{variant: "flat"}), do: @flat
  defp variant_classes(%{active: true}), do: @active
  defp variant_classes(%{variant: variant, color: color}), do: @variants[variant][color]

  defp render_tag(%{as: "span"} = assigns), do: render_span(assigns)
  defp render_tag(%{static: true} = assigns), do: render_span(assigns)

  defp render_tag(%{rest: rest} = assigns)
       when is_map_key(rest, :href) or is_map_key(rest, :navigate) or is_map_key(rest, :patch) do
    ~H"""
    <.link class={@classes} style={@style} aria-current={@active && "true"} {@rest}>
      {render_slot(@inner_block)}<.tag_count :if={@count} count={@count} />
    </.link>
    """
  end

  defp render_tag(assigns) do
    ~H"""
    <button type={@type} class={@classes} style={@style} aria-pressed={@active && "true"} {@rest}>
      {render_slot(@inner_block)}<.tag_count :if={@count} count={@count} />
    </button>
    """
  end

  defp render_span(assigns) do
    assigns =
      assign(
        assigns,
        :rest,
        Map.drop(assigns.rest, [:href, :navigate, :patch, :method, :download])
      )

    ~H"""
    <span class={@classes} style={@style} {@rest}>
      {render_slot(@inner_block)}<.tag_count :if={@count} count={@count} />
    </span>
    """
  end

  defp tag_count(assigns) do
    ~H"""
    <span class="tag-count ml-1.5 inline-flex h-[18px] min-w-[18px] items-center justify-center rounded-full bg-current/15 px-1.5 align-middle text-[11px] font-semibold leading-none">
      {@count}
    </span>
    """
  end

  @doc """
  Joins tags and badges side by side: the inner corners are squared and the borders overlap.

      <.tag_group>
        <.tag color="info" variant="soft">Message</.tag>
        <.tag color="info">65</.tag>
      </.tag_group>
  """
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def tag_group(assigns) do
    ~H"""
    <div
      class={
        merge([
          "inline-flex -space-x-px [&>*:not(:first-child)]:rounded-l-none [&>*:not(:last-child)]:rounded-r-none",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
