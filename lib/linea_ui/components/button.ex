defmodule LineaUI.Components.Button do
  @moduledoc """
  daisyUI's button (`btn`): filled, outlined, soft, ghost and glass, in every theme color.

      <.button>Neutral</.button>
      <.button color="primary">Save</.button>
      <.button color="error" variant="outline">Delete</.button>
      <.button color="info" icon aria-label="Search"><svg>…</svg></.button>
      <.button navigate={~p"/orders"} color="primary" variant="soft">Orders</.button>
      <.button icon variant="flat" color="current" aria-label="Menu"><svg>…</svg></.button>
      <.button variant="glass">On a gradient card</.button>

  With `href`, `navigate` or `patch` it renders a link that looks the same.

  The classes are daisyUI's: `btn`, its color (`btn-primary`, `btn-error`…), style (`btn-outline`, `btn-soft`,
  `btn-ghost`), size (`btn-xs` to `btn-xl`) and shape (`btn-square`, `btn-circle`), so the theme (`data-theme`)
  paints it, and any other daisyUI or Tailwind class can be added.

  While work runs, `loading` disables the button (no double submit), marks it `aria-busy` and puts daisyUI's
  spinner (`loading loading-spinner`) before the label; change the label to the gerund yourself:

      <.button color="primary" loading={@saving}>{if @saving, do: "Saving…", else: "Save"}</.button>

  A button and a field of the same `size` have the same height (daisyUI's `--size-field`), so `control` is no longer
  needed to line them up; it is kept so existing calls compile. A `disabled` button is faded. An icon button takes
  `pip`, the accent dot on its corner (`indicator` and `status`) that tells there is something new:

      <.button icon variant="outline" pip aria-label="Notifications"><svg>…</svg></.button>
  """

  use LineaUI.Component

  @doc """
  Renders a button, or a link when `href`, `navigate` or `patch` is given.
  """
  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error white current mono),
    doc:
      "`white` is for buttons on colored or gradient surfaces; `current` takes the parent's text color; `mono` is daisyUI's `btn-neutral`."
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid glow outline soft bordered flat glass ghost dim),
    doc:
      "`solid` is filled, `glow` adds a colored shadow, `outline` is `btn-outline`, `soft` is `btn-soft` (`bordered` adds a tinted border), `flat` and `ghost` are `btn-ghost`, `dim` is a ghost with muted text that darkens on hover, `glass` is daisyUI's `glass` for gradient and colored cards."
  )

  attr(:size, :string, default: "md", values: ~w(xs sm md lg xl))

  attr(:shape, :string,
    default: "rounded",
    values: ~w(rounded pill square),
    doc:
      "`rounded` (the theme's `--radius-field`, the default), `pill` (fully round ends, opt-in; `btn-circle` on an icon button) or `square` (tighter corners)."
  )

  attr(:icon, :boolean,
    default: false,
    doc: "A square button that holds only an icon (`btn-square`). Always pass `aria-label`."
  )

  attr(:control, :boolean,
    default: false,
    doc:
      "Kept for compatibility: daisyUI's buttons and fields of a `size` already share one height."
  )

  attr(:type, :string, default: "button")
  attr(:disabled, :boolean, default: false)

  attr(:loading, :boolean,
    default: false,
    doc: "Disables the button, marks it `aria-busy` and shows a spinner before the label."
  )

  attr(:pip, :boolean,
    default: false,
    doc:
      "The accent dot on the corner (an unread notice), as daisyUI's `indicator` with a `status`."
  )

  attr(:loading_label, :string,
    default: "Loading",
    doc: "Read by screen readers for the spinner."
  )

  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include: ~w(href navigate patch method download target rel form name value)
  )

  slot(:inner_block, required: true)

  def button(assigns) do
    assigns
    |> assign_derived(:classes, [:icon, :size, :variant, :color, :shape, :pip, :class], fn ->
      classes(assigns)
    end)
    |> assign_derived(:inactive, [:disabled, :loading], fn ->
      assigns.disabled or assigns.loading
    end)
    |> render_button()
  end

  defp classes(assigns), do: LineaUI.Daisy.btn(assigns)

  defp render_button(%{rest: rest} = assigns)
       when is_map_key(rest, :href) or is_map_key(rest, :navigate) or is_map_key(rest, :patch) do
    ~H"""
    <.link
      class={merge([@classes, @inactive && "btn-disabled"])}
      aria-disabled={@inactive && "true"}
      aria-busy={@loading && "true"}
      tabindex={@inactive && "-1"}
      {@rest}
    >
      <.busy :if={@loading} label={@loading_label} />
      {render_slot(@inner_block)}
      <span :if={@pip} class="indicator-item status status-primary" aria-hidden="true"></span>
    </.link>
    """
  end

  defp render_button(assigns) do
    ~H"""
    <button type={@type} class={@classes} disabled={@inactive} aria-busy={@loading && "true"} {@rest}>
      <.busy :if={@loading} label={@loading_label} />
      {render_slot(@inner_block)}
      <span :if={@pip} class="indicator-item status status-primary" aria-hidden="true"></span>
    </button>
    """
  end

  attr(:label, :string, required: true)

  defp busy(assigns) do
    ~H"""
    <span role="status" class="loading loading-spinner loading-xs">
      <span class="sr-only">{@label}</span>
    </span>
    """
  end

  @doc """
  Joins buttons side by side into one segmented control (daisyUI's `join`).

      <.button_group>
        <.button variant="outline">Day</.button>
        <.button variant="outline">Week</.button>
      </.button_group>
  """
  attr(:shape, :string,
    default: "rounded",
    values: ~w(rounded pill),
    doc: "`pill` rounds the outer ends fully."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def button_group(assigns) do
    ~H"""
    <div
      class={merge(["join", @shape == "pill" && "[--join-r:9999px]", @class])}
      role="group"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
