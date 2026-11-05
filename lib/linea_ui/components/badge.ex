defmodule LineaUI.Components.Badge do
  @moduledoc """
  LineOne's badges: filled, glowing, soft, outlined or bare text, with a dot, an icon or a
  remove button.

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
    default: "solid",
    values: ~w(solid glow soft outline flat),
    doc: "`flat` is only the colored text, as LineOne's badges with dots."
  )

  attr(:size, :string,
    default: nil,
    values: [nil | ~w(xs sm md lg)],
    doc:
      "Fixed heights as LineOne's compact badges: `xs` h-4.5, `sm` h-5, `md` h-5.5 with larger text, `lg` h-6. Without it the badge keeps its padding-based height."
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
      class={merge(["sg-badge", tone(@color), @class])}
      {@rest}
    >
      <span :if={@dot} class="dot"></span>
      {render_slot(@inner_block)}
      <button
        :if={@on_remove}
        type="button"
        aria-label={@remove_label}
        phx-click={remove_js(@on_remove, @target, @id)}
        class="btn size-4.5 rounded-full bg-black/20 p-0 hover:bg-black/30 focus:bg-black/30 dark:bg-white/20 dark:hover:bg-white/30 dark:focus:bg-white/30"
      >
        <.glyph name={:close} class="size-3 dark:text-navy-50" stroke_width="3" />
      </button>
    </span>
    """
  end

  defp remove_js(%JS{} = js, _target, _id), do: js
  defp remove_js(event, nil, id), do: JS.push(event, value: %{id: id})
  defp remove_js(event, target, id), do: JS.push(event, target: target, value: %{id: id})

  defp tone("success"), do: "pos"
  defp tone("error"), do: "neg"
  defp tone("warning"), do: "warn"
  defp tone("info"), do: "info"
  defp tone("primary"), do: "acc"
  defp tone("secondary"), do: "acc"
  defp tone("dark"), do: "solid"
  defp tone(_color), do: nil
end
