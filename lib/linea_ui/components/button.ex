defmodule LineaUI.Components.Button do
  @moduledoc """
  LineOne's buttons: filled, outlined, soft, bordered, flat and glowing, in every theme color.

      <.button>Neutral</.button>
      <.button color="primary">Save</.button>
      <.button color="error" variant="outline" shape="pill">Delete</.button>
      <.button color="info" icon aria-label="Search"><svg>…</svg></.button>
      <.button navigate={~p"/orders"} color="primary" variant="soft">Orders</.button>
      <.button icon variant="flat" color="current" aria-label="Menu"><svg>…</svg></.button>
      <.button variant="glass">On a gradient card</.button>

  With `href`, `navigate` or `patch` it renders a link that looks the same.

  While work runs, `loading` disables the button (no double submit), marks it `aria-busy` and
  puts the canvas's 14px spinner (`sg-spin`) in the color of its text before the label; change
  the label to the gerund yourself:

      <.button color="primary" loading={@saving}>{if @saving, do: "Saving…", else: "Save"}</.button>

  A `disabled` button is faded (the canvas's 45% opacity). An icon button takes `pip`, the accent
  dot on its corner that tells there is something new:

      <.button icon variant="outline" pip aria-label="Notifications"><svg>…</svg></.button>
  """

  use LineaUI.Component
  import LineaUI.Components.Spinner, only: [spinner: 1]

  @doc """
  Renders a button, or a link when `href`, `navigate` or `patch` is given.
  """
  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error white current mono),
    doc:
      "`white` is for buttons on colored or gradient surfaces; `current` takes the parent's text color (`solid` and `glow` have no `current`)."
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid glow outline soft bordered flat glass ghost dim),
    doc:
      "`solid` is filled, `glow` adds the colored shadow, `ghost` is transparent until hovered and `dim` is muted text that darkens on hover (`kt-btn-ghost` and `kt-btn-dim`; `mono` is its black button), `bordered` is soft with a tinted border, `flat` has no background until hovered, `glass` is translucent white with white text for gradient and colored cards (it ignores `color`)."
  )

  attr(:size, :string, default: "md", values: ~w(xs sm md lg xl))
  attr(:shape, :string, default: "pill", values: ~w(rounded pill square))
  attr(:icon, :boolean, default: false, doc: "A square button that holds only an icon.")
  attr(:type, :string, default: "button")
  attr(:disabled, :boolean, default: false)

  attr(:loading, :boolean,
    default: false,
    doc: "Disables the button, marks it `aria-busy` and shows a spinner before the label."
  )

  attr(:pip, :boolean,
    default: false,
    doc: "With `icon`, the canvas's accent dot on the corner (an unread notice)."
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
    |> assign(:classes, classes(assigns))
    |> assign(:inactive, assigns.disabled or assigns.loading)
    |> render_button()
  end

  # The canvas buttons: `sg-btn` (pill) and `sg-ib` (the round icon button), with their own variants.
  defp classes(assigns) do
    merge([
      (assigns.icon && icon_class(assigns)) || button_class(assigns),
      assigns.class
    ])
  end

  defp icon_class(%{size: size, variant: variant}) do
    [
      "sg-ib",
      size in ~w(xs sm) && "sm",
      variant in ~w(flat ghost dim) && "plain"
    ]
  end

  defp button_class(%{color: color, variant: variant, size: size, shape: shape}) do
    [
      "sg-btn",
      tone(color, variant),
      size in ~w(xs sm) && "sm",
      size in ~w(lg xl) && "lg",
      shape == "square" && "sq"
    ]
  end

  defp tone("mono", _variant), do: "solid"
  defp tone("error", _variant), do: "danger"
  defp tone("primary", "solid"), do: "accent"
  defp tone("primary", "glow"), do: "accent"
  defp tone(_color, variant) when variant in ~w(soft bordered), do: "soft"
  defp tone(_color, variant) when variant in ~w(flat ghost dim), do: "ghost"
  defp tone(_color, _variant), do: nil

  defp render_button(%{rest: rest} = assigns)
       when is_map_key(rest, :href) or is_map_key(rest, :navigate) or is_map_key(rest, :patch) do
    ~H"""
    <.link
      class={@classes}
      aria-disabled={@inactive && "true"}
      aria-busy={@loading && "true"}
      tabindex={@inactive && "-1"}
      {@rest}
    >
      <.spinner :if={@loading} variant="canvas" color="current" size="xs" label={@loading_label} />
      {render_slot(@inner_block)}
      <span :if={@pip} class="pip" aria-hidden="true"></span>
    </.link>
    """
  end

  defp render_button(assigns) do
    ~H"""
    <button type={@type} class={@classes} disabled={@inactive} aria-busy={@loading && "true"} {@rest}>
      <.spinner :if={@loading} variant="canvas" color="current" size="xs" label={@loading_label} />
      {render_slot(@inner_block)}
      <span :if={@pip} class="pip" aria-hidden="true"></span>
    </button>
    """
  end

  @doc """
  Joins buttons side by side into one segmented control.

      <.button_group>
        <.button variant="outline">Day</.button>
        <.button variant="outline">Week</.button>
      </.button_group>
  """
  attr(:shape, :string,
    default: "rounded",
    values: ~w(rounded pill),
    doc: "`pill` rounds the outer ends fully, as LineOne's First / Second / Third group."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def button_group(assigns) do
    ~H"""
    <div
      class={
        merge([
          "flex -space-x-px [&>*:not(:first-child)]:rounded-l-none [&>*:not(:last-child)]:rounded-r-none [&>*:focus]:z-10",
          group_shape(@shape),
          @class
        ])
      }
      role="group"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp group_shape("pill"),
    do: "[&>*:first-child]:rounded-l-full [&>*:last-child]:rounded-r-full"

  defp group_shape("rounded"), do: nil
end
