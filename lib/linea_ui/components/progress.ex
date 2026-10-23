defmodule LineaUI.Components.Progress do
  @moduledoc """
  LineOne's linear progress bar, solid or soft, in every size, with the active shimmer or the
  indeterminate slide.

      <.progress value={42} />
      <.progress value={70} color="success" variant="soft" />
      <.progress value={50} color="primary" active />
      <.progress indeterminate color="info" size="sm" />

  `value` is read against `max` (100 by default) and updates with the assign.
  """

  use LineaUI.Component

  @tracks %{
    "solid" => %{
      "neutral" => "bg-slate-150 dark:bg-navy-500",
      "primary" => "bg-slate-150 dark:bg-navy-500",
      "secondary" => "bg-slate-150 dark:bg-navy-500",
      "info" => "bg-slate-150 dark:bg-navy-500",
      "success" => "bg-slate-150 dark:bg-navy-500",
      "warning" => "bg-slate-150 dark:bg-navy-500",
      "error" => "bg-slate-150 dark:bg-navy-500"
    },
    "soft" => %{
      "neutral" => "bg-slate-500/15 dark:bg-navy-400/25",
      "primary" => "bg-primary/15 dark:bg-accent/25",
      "secondary" => "bg-secondary/15 dark:bg-secondary-light/25",
      "info" => "bg-info/15 dark:bg-info/25",
      "success" => "bg-success/15 dark:bg-success/25",
      "warning" => "bg-warning/15 dark:bg-warning/25",
      "error" => "bg-error/15 dark:bg-error/25"
    }
  }

  @bars %{
    "neutral" => "bg-slate-500 dark:bg-navy-400",
    "primary" => "bg-primary dark:bg-accent",
    "secondary" => "bg-secondary",
    "info" => "bg-info",
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error"
  }

  @sizes %{"sm" => "h-1", "md" => "h-2", "lg" => "h-3", "xl" => "h-4"}

  @doc """
  Renders a progress bar.

      <.progress value={@uploaded} max={@total} color="success" variant="soft" active />
  """
  attr(:value, :any, default: 0, doc: "A number between 0 and `max`.")
  attr(:max, :any, default: 100)

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error)
  )

  attr(:variant, :string,
    default: "solid",
    values: ~w(solid soft),
    doc: "`soft` tints the track with the bar's color."
  )

  attr(:size, :string, default: "md", values: ~w(sm md lg xl))
  attr(:active, :boolean, default: false, doc: "A light sweeping over the bar.")

  attr(:indeterminate, :boolean,
    default: false,
    doc: "A bar sliding across the track, when the end is not known."
  )

  attr(:label, :string, default: nil, doc: "The `aria-label` of the progress bar.")
  attr(:class, :any, default: nil)
  attr(:bar_class, :any, default: nil)
  attr(:rest, :global)

  def progress(assigns) do
    assigns = assign(assigns, :percent, percent(assigns.value, assigns.max))

    ~H"""
    <div
      role="progressbar"
      aria-label={@label}
      aria-valuemin="0"
      aria-valuemax={@max}
      aria-valuenow={!@indeterminate && @value}
      class={merge(["progress", track(@variant, @color), size(@size), @class])}
      {@rest}
    >
      <div
        class={
          merge([
            "rounded-full",
            bar(@color),
            @active && "is-active relative overflow-hidden",
            @indeterminate && "is-indeterminate relative w-4/12",
            @bar_class
          ])
        }
        style={!@indeterminate && "width: #{@percent}%"}
      >
      </div>
    </div>
    """
  end

  defp percent(value, limit) when is_number(value) and is_number(limit) and limit > 0,
    do: (value / limit * 100) |> min(100.0) |> max(0.0) |> Float.round(4)

  defp percent(_value, _max), do: 0

  defp track(variant, color), do: @tracks[variant][color]
  defp bar(color), do: @bars[color]
  defp size(size), do: @sizes[size]
end
