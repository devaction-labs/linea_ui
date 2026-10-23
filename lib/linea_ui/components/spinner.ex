defmodule LineaUI.Components.Spinner do
  @moduledoc """
  LineOne's spinners: the border ring (plain or soft), the growing dot and the SVG ring, with
  the linear or the elastic timing.

      <.spinner />
      <.spinner color="primary" variant="soft" elastic />
      <.spinner color="success" variant="grow" size="lg" />
      <.spinner color="error" variant="svg" />
  """

  use LineaUI.Component

  @borders %{
    "neutral" =>
      "border-slate-500 border-r-transparent dark:border-navy-300 dark:border-r-transparent",
    "primary" =>
      "border-primary border-r-transparent dark:border-accent dark:border-r-transparent",
    "secondary" => "border-secondary border-r-transparent",
    "info" => "border-info border-r-transparent",
    "success" => "border-success border-r-transparent",
    "warning" => "border-warning border-r-transparent",
    "error" => "border-error border-r-transparent",
    "white" => "border-white border-r-transparent",
    "current" => "border-current border-r-transparent"
  }

  @soft %{
    "neutral" =>
      "border-slate-150 border-r-slate-500 dark:border-navy-500 dark:border-r-navy-300",
    "primary" => "border-primary/30 border-r-primary dark:border-accent/30 dark:border-r-accent",
    "secondary" => "border-secondary/30 border-r-secondary",
    "info" => "border-info/30 border-r-info",
    "success" => "border-success/30 border-r-success",
    "warning" => "border-warning/30 border-r-warning",
    "error" => "border-error/30 border-r-error",
    "white" => "border-white/30 border-r-white",
    "current" => "border-current/30 border-r-current"
  }

  @dots %{
    "neutral" => "bg-slate-500 dark:bg-navy-300",
    "primary" => "bg-primary dark:bg-accent",
    "secondary" => "bg-secondary",
    "info" => "bg-info",
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error",
    "white" => "bg-white",
    "current" => "bg-current"
  }

  @texts %{
    "neutral" => "text-slate-500 dark:text-navy-300",
    "primary" => "text-primary dark:text-accent",
    "secondary" => "text-secondary dark:text-secondary-light",
    "info" => "text-info",
    "success" => "text-success",
    "warning" => "text-warning",
    "error" => "text-error",
    "white" => "text-white",
    "current" => "text-current"
  }

  @sizes %{
    "xs" => "size-5",
    "sm" => "size-7",
    "md" => "size-10",
    "lg" => "size-12",
    "xl" => "size-16"
  }

  @ring_widths %{
    "xs" => "border-2",
    "sm" => "border-[3px]",
    "md" => "border-4",
    "lg" => "border-4",
    "xl" => "border-4"
  }

  @doc """
  Renders a spinner (`role="status"`, labelled by `label`).

      <.spinner color="primary" variant="soft" size="md" elastic />
  """
  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error white current),
    doc: "`white` and `current` (the text color) are for spinners inside filled buttons."
  )

  attr(:variant, :string,
    default: "border",
    values: ~w(border soft grow svg),
    doc: "`border` is the ring with a gap, `soft` the tinted ring, `grow` the pulsing dot."
  )

  attr(:size, :string, default: "sm", values: ~w(xs sm md lg xl))
  attr(:elastic, :boolean, default: false, doc: "LineOne's elastic timing function.")
  attr(:label, :string, default: "Loading")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def spinner(%{variant: "grow"} = assigns) do
    ~H"""
    <div
      role="status"
      aria-label={@label}
      class={merge(["spinner is-grow relative", size(@size), @class])}
      {@rest}
    >
      <span class={["absolute inline-block h-full w-full rounded-full opacity-75", dot(@color)]}></span>
      <span class={["absolute inline-block h-full w-full rounded-full opacity-75", dot(@color)]}></span>
    </div>
    """
  end

  def spinner(%{variant: "svg"} = assigns) do
    ~H"""
    <div
      role="status"
      aria-label={@label}
      class={
        merge([
          "spinner",
          @elastic && "is-elastic",
          size(@size),
          "animate-spin",
          text(@color),
          @class
        ])
      }
      {@rest}
    >
      <svg xmlns="http://www.w3.org/2000/svg" class="h-full w-full" fill="none" viewBox="0 0 28 28">
        <path
          fill="currentColor"
          fill-rule="evenodd"
          d="M28 14c0 7.732-6.268 14-14 14S0 21.732 0 14 6.268 0 14 0s14 6.268 14 14zm-2.764.005c0 6.185-5.014 11.2-11.2 11.2-6.185 0-11.2-5.015-11.2-11.2 0-6.186 5.015-11.2 11.2-11.2 6.186 0 11.2 5.014 11.2 11.2zM8.4 16.8a2.8 2.8 0 100-5.6 2.8 2.8 0 000 5.6z"
          clip-rule="evenodd"
        />
      </svg>
    </div>
    """
  end

  def spinner(assigns) do
    ~H"""
    <div
      role="status"
      aria-label={@label}
      class={
        merge([
          "spinner",
          @elastic && "is-elastic",
          size(@size),
          "animate-spin rounded-full",
          ring_width(@size),
          ring(@variant, @color),
          @class
        ])
      }
      {@rest}
    >
    </div>
    """
  end

  defp size(size), do: @sizes[size]
  defp ring_width(size), do: @ring_widths[size]
  defp ring("soft", color), do: @soft[color]
  defp ring(_variant, color), do: @borders[color]
  defp dot(color), do: @dots[color]
  defp text(color), do: @texts[color]
end
