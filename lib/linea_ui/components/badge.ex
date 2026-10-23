defmodule LineaUI.Components.Badge do
  @moduledoc """
  LineOne's badges: filled, glowing, soft, outlined or bare text, with a dot, an icon or a
  remove button.

      <.badge>Default</.badge>
      <.badge color="success" shape="pill">Paid</.badge>
      <.badge color="primary" variant="soft" dot>Online</.badge>
      <.badge color="error" variant="outline" shape="pill">Error</.badge>
      <.badge on_remove={JS.hide()}>Filter</.badge>
  """

  use LineaUI.Component

  @variants %{
    "solid" => %{
      "neutral" => "bg-slate-150 text-slate-800 dark:bg-navy-500 dark:text-navy-100",
      "primary" => "bg-primary text-white dark:bg-accent",
      "secondary" => "bg-secondary text-white",
      "info" => "bg-info text-white",
      "success" => "bg-success text-white",
      "warning" => "bg-warning text-white",
      "error" => "bg-error text-white",
      "dark" => "bg-navy-700 text-white dark:bg-navy-900",
      "light" => "bg-slate-150 text-slate-800"
    },
    "glow" => %{
      "neutral" =>
        "bg-slate-150 text-slate-800 shadow-soft shadow-slate-200/50 dark:bg-navy-500 dark:text-navy-100 dark:shadow-navy-450/50",
      "primary" =>
        "bg-primary text-white shadow-soft shadow-primary/50 dark:bg-accent dark:shadow-accent/50",
      "secondary" => "bg-secondary text-white shadow-soft shadow-secondary/50",
      "info" => "bg-info text-white shadow-soft shadow-info/50",
      "success" => "bg-success text-white shadow-soft shadow-success/50",
      "warning" => "bg-warning text-white shadow-soft shadow-warning/50",
      "error" => "bg-error text-white shadow-soft shadow-error/50",
      "dark" =>
        "bg-navy-700 text-white shadow-soft shadow-navy-700/50 dark:bg-navy-900 dark:shadow-navy-900/50",
      "light" => "bg-slate-150 text-slate-800 shadow-soft shadow-slate-200/50"
    },
    "soft" => %{
      "neutral" => "bg-slate-150/60 text-slate-700 dark:bg-navy-500/40 dark:text-navy-100",
      "primary" => "bg-primary/10 text-primary dark:bg-accent-light/15 dark:text-accent-light",
      "secondary" =>
        "bg-secondary/10 text-secondary dark:bg-secondary-light/15 dark:text-secondary-light",
      "info" => "bg-info/10 text-info dark:bg-info/15",
      "success" => "bg-success/10 text-success dark:bg-success/15",
      "warning" => "bg-warning/10 text-warning dark:bg-warning/15",
      "error" => "bg-error/10 text-error dark:bg-error/15",
      "dark" => "bg-navy-700/10 text-navy-700 dark:bg-navy-900/40 dark:text-navy-100",
      "light" => "bg-slate-150/60 text-slate-700"
    },
    "outline" => %{
      "neutral" =>
        "border border-slate-300 text-slate-800 dark:border-navy-450 dark:text-navy-50",
      "primary" =>
        "border border-primary text-primary dark:border-accent-light dark:text-accent-light",
      "secondary" =>
        "border border-secondary text-secondary dark:border-secondary-light dark:text-secondary-light",
      "info" => "border border-info text-info",
      "success" => "border border-success text-success",
      "warning" => "border border-warning text-warning",
      "error" => "border border-error text-error",
      "dark" => "border border-navy-700 text-navy-700 dark:border-navy-900 dark:text-navy-100",
      "light" => "border border-slate-150 text-slate-800"
    },
    "flat" => %{
      "neutral" => "text-slate-800 dark:text-navy-100",
      "primary" => "text-primary dark:text-accent-light",
      "secondary" => "text-secondary dark:text-secondary-light",
      "info" => "text-info",
      "success" => "text-success",
      "warning" => "text-warning",
      "error" => "text-error",
      "dark" => "text-navy-700 dark:text-navy-100",
      "light" => "text-slate-150"
    }
  }

  @shapes %{"rounded" => "", "pill" => "rounded-full", "square" => "rounded-none"}

  @doc "Renders a badge."
  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error dark light)
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid glow soft outline flat),
    doc: "`flat` is only the colored text, as LineOne's badges with dots."
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
          spacing(@dot),
          variant_class(@variant, @color),
          shape_class(@shape),
          @class
        ])
      }
      {@rest}
    >
      <span :if={@dot} class="size-2 rounded-full bg-current"></span>
      {render_slot(@inner_block)}
      <button
        :if={@on_remove}
        type="button"
        aria-label={@remove_label}
        phx-click={remove_js(@on_remove, @target, @id)}
        class="btn size-4.5 rounded-full bg-black/20 p-0 hover:bg-black/30 focus:bg-black/30 dark:bg-white/20 dark:hover:bg-white/30 dark:focus:bg-white/30"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="size-3 dark:text-navy-50"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="3"
            d="M6 18L18 6M6 6l12 12"
          />
        </svg>
      </button>
    </span>
    """
  end

  defp remove_js(%JS{} = js, _target, _id), do: js
  defp remove_js(event, nil, id), do: JS.push(event, value: %{id: id})
  defp remove_js(event, target, id), do: JS.push(event, target: target, value: %{id: id})

  defp spacing(true), do: "space-x-2.5"
  defp spacing(false), do: "space-x-2"

  defp variant_class(variant, color), do: @variants[variant][color]
  defp shape_class(shape), do: @shapes[shape]
end
