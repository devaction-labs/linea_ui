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

  With `href`, `navigate` or `patch` a tag is a link; otherwise it is a button.
  """

  use LineaUI.Component

  @base "tag disabled:pointer-events-none disabled:opacity-60 aria-disabled:pointer-events-none aria-disabled:opacity-60"

  @variants %{
    "solid" => %{
      "neutral" =>
        "bg-slate-150 text-slate-800 hover:bg-slate-200 focus:bg-slate-200 active:bg-slate-200/80 dark:bg-navy-500 dark:text-navy-100 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90",
      "primary" =>
        "bg-primary text-white hover:bg-primary-focus focus:bg-primary-focus active:bg-primary-focus/90 dark:bg-accent dark:hover:bg-accent-focus dark:focus:bg-accent-focus dark:active:bg-accent/90",
      "secondary" =>
        "bg-secondary text-white hover:bg-secondary-focus focus:bg-secondary-focus active:bg-secondary-focus/90",
      "info" =>
        "bg-info text-white hover:bg-info-focus focus:bg-info-focus active:bg-info-focus/90",
      "success" =>
        "bg-success text-white hover:bg-success-focus focus:bg-success-focus active:bg-success-focus/90",
      "warning" =>
        "bg-warning text-white hover:bg-warning-focus focus:bg-warning-focus active:bg-warning-focus/90",
      "error" =>
        "bg-error text-white hover:bg-error-focus focus:bg-error-focus active:bg-error-focus/90",
      "light" =>
        "bg-slate-150 text-slate-800 hover:bg-slate-200 focus:bg-slate-200 active:bg-slate-200/80"
    },
    "soft" => %{
      "neutral" =>
        "bg-slate-150/60 text-slate-700 hover:bg-slate-150 focus:bg-slate-150 active:bg-slate-150/80 dark:bg-navy-500/40 dark:text-navy-100 dark:hover:bg-navy-500 dark:focus:bg-navy-500 dark:active:bg-navy-500/90",
      "primary" =>
        "bg-primary/10 text-primary hover:bg-primary/20 focus:bg-primary/20 active:bg-primary/25 dark:bg-accent-light/10 dark:text-accent-light dark:hover:bg-accent-light/20 dark:focus:bg-accent-light/20 dark:active:bg-accent-light/25",
      "secondary" =>
        "bg-secondary/10 text-secondary hover:bg-secondary/20 focus:bg-secondary/20 active:bg-secondary/25 dark:bg-secondary-light/10 dark:text-secondary-light dark:hover:bg-secondary-light/20 dark:focus:bg-secondary-light/20 dark:active:bg-secondary-light/25",
      "info" => "bg-info/10 text-info hover:bg-info/20 focus:bg-info/20 active:bg-info/25",
      "success" =>
        "bg-success/10 text-success hover:bg-success/20 focus:bg-success/20 active:bg-success/25",
      "warning" =>
        "bg-warning/10 text-warning hover:bg-warning/20 focus:bg-warning/20 active:bg-warning/25",
      "error" => "bg-error/10 text-error hover:bg-error/20 focus:bg-error/20 active:bg-error/25",
      "light" =>
        "bg-slate-150/60 text-slate-700 hover:bg-slate-150 focus:bg-slate-150 active:bg-slate-150/80"
    },
    "bordered" => %{
      "neutral" =>
        "border border-slate-300 bg-slate-150/60 text-slate-700 hover:bg-slate-150 focus:bg-slate-150 active:bg-slate-150/80 dark:border-navy-450 dark:bg-navy-500/40 dark:text-navy-100 dark:hover:bg-navy-500 dark:focus:bg-navy-500 dark:active:bg-navy-500/90",
      "primary" =>
        "border border-primary/30 bg-primary/10 text-primary hover:bg-primary/20 focus:bg-primary/20 active:bg-primary/25 dark:border-accent-light/30 dark:bg-accent-light/10 dark:text-accent-light dark:hover:bg-accent-light/20 dark:focus:bg-accent-light/20 dark:active:bg-accent-light/25",
      "secondary" =>
        "border border-secondary/30 bg-secondary/10 text-secondary hover:bg-secondary/20 focus:bg-secondary/20 active:bg-secondary/25 dark:border-secondary-light/30 dark:bg-secondary-light/10 dark:text-secondary-light dark:hover:bg-secondary-light/20 dark:focus:bg-secondary-light/20 dark:active:bg-secondary-light/25",
      "info" =>
        "border border-info/30 bg-info/10 text-info hover:bg-info/20 focus:bg-info/20 active:bg-info/25",
      "success" =>
        "border border-success/30 bg-success/10 text-success hover:bg-success/20 focus:bg-success/20 active:bg-success/25",
      "warning" =>
        "border border-warning/30 bg-warning/10 text-warning hover:bg-warning/20 focus:bg-warning/20 active:bg-warning/25",
      "error" =>
        "border border-error/30 bg-error/10 text-error hover:bg-error/20 focus:bg-error/20 active:bg-error/25",
      "light" =>
        "border border-slate-300 bg-slate-150/60 text-slate-700 hover:bg-slate-150 focus:bg-slate-150 active:bg-slate-150/80"
    },
    "outline" => %{
      "neutral" =>
        "border border-slate-300 text-slate-800 hover:bg-slate-150 focus:bg-slate-150 active:bg-slate-150/80 dark:border-navy-450 dark:text-navy-50 dark:hover:bg-navy-500 dark:focus:bg-navy-500 dark:active:bg-navy-500/90",
      "primary" =>
        "border border-primary text-primary hover:bg-primary/20 focus:bg-primary/20 active:bg-primary/25 dark:border-accent-light dark:text-accent-light dark:hover:bg-accent-light/20 dark:focus:bg-accent-light/20 dark:active:bg-accent-light/25",
      "secondary" =>
        "border border-secondary text-secondary hover:bg-secondary/20 focus:bg-secondary/20 active:bg-secondary/25 dark:border-secondary-light dark:text-secondary-light dark:hover:bg-secondary-light/20 dark:focus:bg-secondary-light/20 dark:active:bg-secondary-light/25",
      "info" =>
        "border border-info text-info hover:bg-info/20 focus:bg-info/20 active:bg-info/25",
      "success" =>
        "border border-success text-success hover:bg-success/20 focus:bg-success/20 active:bg-success/25",
      "warning" =>
        "border border-warning text-warning hover:bg-warning/20 focus:bg-warning/20 active:bg-warning/25",
      "error" =>
        "border border-error text-error hover:bg-error/20 focus:bg-error/20 active:bg-error/25",
      "light" =>
        "border border-slate-150 text-slate-800 hover:bg-slate-150 focus:bg-slate-150 active:bg-slate-150/80"
    }
  }

  @shapes %{"rounded" => "", "pill" => "rounded-full", "square" => "rounded-none"}

  @doc """
  Renders a tag: a link with `href`, `navigate` or `patch`, a button otherwise.

      <.tag patch={~p"/posts?tag=elixir"} color="primary" variant="bordered" shape="pill">Elixir</.tag>
  """
  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error light)
  )

  attr(:variant, :string, default: "solid", values: ~w(solid soft bordered outline))

  attr(:active, :boolean,
    default: false,
    doc:
      "The selected state of a filter chip: the tag takes the `primary` color of its `variant` (and `aria-pressed=\"true\"`) whatever its `color`, so a list of chips only toggles this."
  )

  attr(:shape, :string, default: "rounded", values: ~w(rounded pill square))
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
        @variants[assigns.variant][active_color(assigns)],
        @shapes[assigns.shape],
        assigns.class
      ])
    )
    |> render_tag()
  end

  defp active_color(%{active: true}), do: "primary"
  defp active_color(%{color: color}), do: color

  defp render_tag(%{rest: rest} = assigns)
       when is_map_key(rest, :href) or is_map_key(rest, :navigate) or is_map_key(rest, :patch) do
    ~H"""
    <.link class={@classes} aria-current={@active && "true"} {@rest}>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp render_tag(assigns) do
    ~H"""
    <button type={@type} class={@classes} aria-pressed={@active && "true"} {@rest}>
      {render_slot(@inner_block)}
    </button>
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
          "flex -space-x-px [&>*:not(:first-child)]:rounded-l-none [&>*:not(:last-child)]:rounded-r-none",
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
