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
  puts a small spinner in the color of its text before the label; change the label to the
  gerund yourself:

      <.button color="primary" loading={@saving}>{if @saving, do: "Saving…", else: "Save"}</.button>
  """

  use LineaUI.Component
  import LineaUI.Components.Spinner, only: [spinner: 1]

  @base "btn font-medium disabled:pointer-events-none disabled:select-none disabled:opacity-60 aria-disabled:pointer-events-none aria-disabled:select-none aria-disabled:opacity-60"

  @variants %{
    "solid" => %{
      "neutral" =>
        "bg-slate-150 text-slate-800 hover:bg-slate-200 focus:bg-slate-200 active:bg-slate-200/80 dark:bg-navy-500 dark:text-navy-50 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90",
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
      "white" =>
        "bg-white text-slate-800 hover:bg-slate-100 focus:bg-slate-100 active:bg-slate-100/80"
    },
    "glow" => %{
      "neutral" =>
        "bg-slate-150 text-slate-800 hover:bg-slate-200 hover:shadow-lg hover:shadow-slate-200/50 focus:bg-slate-200 focus:shadow-lg focus:shadow-slate-200/50 active:bg-slate-200/80 dark:bg-navy-500 dark:text-navy-50 dark:hover:bg-navy-450 dark:hover:shadow-navy-450/50 dark:focus:bg-navy-450 dark:focus:shadow-navy-450/50 dark:active:bg-navy-450/90",
      "primary" =>
        "bg-primary text-white hover:bg-primary-focus hover:shadow-lg hover:shadow-primary/50 focus:bg-primary-focus focus:shadow-lg focus:shadow-primary/50 active:bg-primary-focus/90 dark:bg-accent dark:hover:bg-accent-focus dark:hover:shadow-accent/50 dark:focus:bg-accent-focus dark:focus:shadow-accent/50 dark:active:bg-accent/90",
      "secondary" =>
        "bg-secondary text-white shadow-lg shadow-secondary/50 hover:bg-secondary-focus focus:bg-secondary-focus active:bg-secondary-focus/90",
      "info" =>
        "bg-info text-white hover:bg-info-focus hover:shadow-lg hover:shadow-info/50 focus:bg-info-focus focus:shadow-lg focus:shadow-info/50 active:bg-info-focus/90",
      "success" =>
        "bg-success text-white hover:bg-success-focus hover:shadow-lg hover:shadow-success/50 focus:bg-success-focus focus:shadow-lg focus:shadow-success/50 active:bg-success-focus/90",
      "warning" =>
        "bg-warning text-white shadow-lg shadow-warning/50 hover:bg-warning-focus focus:bg-warning-focus active:bg-warning-focus/90",
      "error" =>
        "bg-error text-white hover:bg-error-focus hover:shadow-lg hover:shadow-error/50 focus:bg-error-focus focus:shadow-lg focus:shadow-error/50 active:bg-error-focus/90",
      "white" =>
        "bg-white text-slate-800 hover:bg-slate-100 hover:shadow-lg hover:shadow-white/50 focus:bg-slate-100 focus:shadow-lg focus:shadow-white/50 active:bg-slate-100/80"
    },
    "outline" => %{
      "neutral" =>
        "border border-slate-300 text-slate-800 hover:bg-slate-150 focus:bg-slate-150 active:bg-slate-150/80 dark:border-navy-450 dark:text-navy-50 dark:hover:bg-navy-500 dark:focus:bg-navy-500 dark:active:bg-navy-500/90",
      "primary" =>
        "border border-primary text-primary hover:bg-primary hover:text-white focus:bg-primary focus:text-white active:bg-primary/90 dark:border-accent dark:text-accent-light dark:hover:bg-accent dark:hover:text-white dark:focus:bg-accent dark:focus:text-white dark:active:bg-accent/90",
      "secondary" =>
        "border border-secondary text-secondary hover:bg-secondary hover:text-white focus:bg-secondary focus:text-white active:bg-secondary/90 dark:text-secondary-light dark:hover:bg-secondary dark:hover:text-white dark:focus:bg-secondary dark:focus:text-white dark:active:bg-secondary/90",
      "info" =>
        "border border-info text-info hover:bg-info hover:text-white focus:bg-info focus:text-white active:bg-info/90",
      "success" =>
        "border border-success text-success hover:bg-success hover:text-white focus:bg-success focus:text-white active:bg-success/90",
      "warning" =>
        "border border-warning text-warning hover:bg-warning hover:text-white focus:bg-warning focus:text-white active:bg-warning/90",
      "error" =>
        "border border-error text-error hover:bg-error hover:text-white focus:bg-error focus:text-white active:bg-error/90",
      "white" =>
        "border border-white text-white hover:bg-white hover:text-slate-800 focus:bg-white focus:text-slate-800 active:bg-white/90",
      "current" =>
        "border border-current text-current hover:bg-current/10 focus:bg-current/10 active:bg-current/15"
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
      "white" => "bg-white/10 text-white hover:bg-white/20 focus:bg-white/20 active:bg-white/25",
      "current" =>
        "bg-slate-150/60 text-current hover:bg-slate-150 focus:bg-slate-150 active:bg-slate-150/80 dark:bg-navy-500/40 dark:text-current dark:hover:bg-navy-500 dark:focus:bg-navy-500 dark:active:bg-navy-500/90"
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
      "white" =>
        "border border-white/30 bg-white/10 text-white hover:bg-white/20 focus:bg-white/20 active:bg-white/25",
      "current" =>
        "border border-current/30 bg-current/10 text-current hover:bg-current/20 focus:bg-current/20 active:bg-current/25"
    },
    "flat" => %{
      "neutral" =>
        "text-slate-700 hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:text-navy-100 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25",
      "primary" =>
        "text-primary hover:bg-primary/20 focus:bg-primary/20 active:bg-primary/25 dark:text-accent-light dark:hover:bg-accent-light/20 dark:focus:bg-accent-light/20 dark:active:bg-accent-light/25",
      "secondary" =>
        "text-secondary hover:bg-secondary/20 focus:bg-secondary/20 active:bg-secondary/25 dark:text-secondary-light dark:hover:bg-secondary-light/20 dark:focus:bg-secondary-light/20 dark:active:bg-secondary-light/25",
      "info" => "text-info hover:bg-info/20 focus:bg-info/20 active:bg-info/25",
      "success" => "text-success hover:bg-success/20 focus:bg-success/20 active:bg-success/25",
      "warning" => "text-warning hover:bg-warning/20 focus:bg-warning/20 active:bg-warning/25",
      "error" => "text-error hover:bg-error/20 focus:bg-error/20 active:bg-error/25",
      "white" => "text-white hover:bg-white/20 focus:bg-white/20 active:bg-white/25",
      "current" =>
        "text-current hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:text-current dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25"
    }
  }

  @glass "border border-white/10 bg-white/20 text-white hover:bg-white/30 focus:bg-white/30 active:bg-white/40 dark:bg-white/20 dark:text-white dark:hover:bg-white/30 dark:focus:bg-white/30"

  @sizes %{
    "xs" => "h-6 rounded-sm px-3 text-xs",
    "sm" => "h-8 rounded-md px-4 text-xs-plus",
    "md" => "",
    "lg" => "h-11 text-base",
    "xl" => "h-12 text-base"
  }

  @icon_sizes %{
    "xs" => "size-6 rounded-sm p-0 text-xs",
    "sm" => "size-7 rounded-md p-0 text-xs-plus",
    "md" => "size-9 p-0",
    "lg" => "size-11 p-0 text-base",
    "xl" => "size-12 p-0 text-base"
  }

  @shapes %{
    "rounded" => "",
    "pill" => "rounded-full",
    "square" => "rounded-none"
  }

  @doc """
  Renders a button, or a link when `href`, `navigate` or `patch` is given.
  """
  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error white current),
    doc:
      "`white` is for buttons on colored or gradient surfaces; `current` takes the parent's text color (`solid` and `glow` have no `current`)."
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid glow outline soft bordered flat glass),
    doc:
      "`solid` is filled, `glow` adds the colored shadow, `bordered` is soft with a tinted border, `flat` has no background until hovered, `glass` is translucent white with white text for gradient and colored cards (it ignores `color`)."
  )

  attr(:size, :string, default: "md", values: ~w(xs sm md lg xl))
  attr(:shape, :string, default: "rounded", values: ~w(rounded pill square))
  attr(:icon, :boolean, default: false, doc: "A square button that holds only an icon.")
  attr(:type, :string, default: "button")
  attr(:disabled, :boolean, default: false)

  attr(:loading, :boolean,
    default: false,
    doc: "Disables the button, marks it `aria-busy` and shows a spinner before the label."
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

  defp classes(assigns) do
    merge([
      @base,
      variant_class(assigns.variant, assigns.color),
      size_class(assigns),
      @shapes[assigns.shape],
      assigns.loading && "disabled:opacity-85 aria-disabled:opacity-85",
      assigns.class
    ])
  end

  defp variant_class("glass", _color), do: @glass
  defp variant_class(variant, color), do: @variants[variant][color]

  defp size_class(%{icon: true, size: size}), do: @icon_sizes[size]
  defp size_class(%{size: size}), do: @sizes[size]

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
      <.spinner :if={@loading} color="current" size="xs" label={@loading_label} />
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp render_button(assigns) do
    ~H"""
    <button type={@type} class={@classes} disabled={@inactive} aria-busy={@loading && "true"} {@rest}>
      <.spinner :if={@loading} color="current" size="xs" label={@loading_label} />
      {render_slot(@inner_block)}
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
