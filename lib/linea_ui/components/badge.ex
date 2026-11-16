defmodule LineaUI.Components.Badge do
  @moduledoc """
  daisyUI's badge (`badge`): filled, glowing, soft, outlined or bare text, with a dot, an icon or a
  remove button. The classes are daisyUI's (`badge-primary`, `badge-soft`, `badge-outline`, `badge-sm`…), so the
  theme paints it.

      <.badge>Default</.badge>
      <.badge color="success" shape="pill">Paid</.badge>
      <.badge color="primary" variant="soft" dot>Online</.badge>
      <.badge color="error" variant="outline" shape="pill">Error</.badge>
      <.badge on_remove={JS.hide()}>Filter</.badge>
      <.badge color="success" variant="soft" size="sm">UI/UX</.badge>
      <.badge color="white" variant="outline" shape="pill">Tag</.badge>
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  @doc """
  Renders a badge.

      <.badge color="success" variant="soft" shape="pill" dot>Active</.badge>
  """
  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error dark light white),
    doc:
      "`white` is for badges on colored or gradient cards: `variant=\"outline\"` is a white outline, `soft` a translucent white chip."
  )

  attr(:variant, :string,
    default: "soft",
    values: ~w(solid glow soft outline flat),
    doc:
      "`soft` (the default, `badge-soft`) is the tinted chip, `solid` the filled badge, `outline` `badge-outline`, `flat` only the colored text."
  )

  attr(:size, :string,
    default: nil,
    values: [nil | ~w(xs sm md lg)],
    doc: "daisyUI's `badge-xs` to `badge-lg`; without it the badge is daisyUI's default (`md`)."
  )

  attr(:shape, :string, default: "rounded", values: ~w(rounded pill square))
  attr(:dot, :boolean, default: false, doc: "A dot in the badge's color before the content.")

  attr(:on_remove, :any,
    default: nil,
    doc:
      "An event name or a `JS` command: adds a small round remove button after the content. The event's payload is `%{\"id\" => id}`."
  )

  attr(:id, :string, default: nil)

  attr(:target, :any,
    default: nil,
    doc: "The `phx-target` of `on_remove` when it is an event name."
  )

  attr(:remove_label, :string, default: "Remove")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def badge(assigns) do
    ~H"""
    <span
      id={@id}
      class={
        merge([
          "badge",
          color_class(@color),
          variant_class(@variant),
          @size && "badge-#{@size}",
          shape_class(@shape),
          @class
        ])
      }
      {@rest}
    >
      <span :if={@dot} class="status bg-current" aria-hidden="true"></span>
      {render_slot(@inner_block)}
      <button
        :if={@on_remove}
        type="button"
        aria-label={@remove_label}
        phx-click={remove_js(@on_remove, @target, @id)}
        class="-mr-1 inline-grid size-4 cursor-pointer place-items-center rounded-full bg-current/15 hover:bg-current/25 focus-visible:outline-2 focus-visible:outline-current"
      >
        <.glyph name={:close} class="size-3" stroke_width="3" />
      </button>
    </span>
    """
  end

  defp remove_js(%JS{} = js, _target, _id), do: js
  defp remove_js(event, nil, id), do: JS.push(event, value: %{id: id})
  defp remove_js(event, target, id), do: JS.push(event, target: target, value: %{id: id})

  defp color_class(color) when color in ~w(primary secondary info success warning error),
    do: "badge-" <> color

  defp color_class("dark"), do: "badge-neutral"
  defp color_class("light"), do: "badge-ghost"
  defp color_class("white"), do: "[--badge-color:#fff] [--badge-fg:#0a0a0a]"
  defp color_class(_neutral), do: nil

  defp variant_class("soft"), do: "badge-soft"
  defp variant_class("outline"), do: "badge-outline"
  defp variant_class("flat"), do: "border-transparent bg-transparent px-0"

  defp variant_class("glow"),
    do:
      "shadow-[0_4px_12px_-4px_color-mix(in_oklab,var(--badge-color,var(--color-base-content))_70%,transparent)]"

  defp variant_class(_solid), do: nil

  defp shape_class("pill"), do: "rounded-full"
  defp shape_class("square"), do: "rounded-[calc(var(--radius-selector)*.5)]"
  defp shape_class(_rounded), do: nil
end
