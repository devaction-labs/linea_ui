defmodule LineaUI.Components.Sparkline do
  @moduledoc """
  The canvas's sparkline (`sg-spark`): a line with a soft fill under it, drawn from a list of numbers, the
  highest at the top. The one the KPI card has beside its figure, for a card that lays its own figure out
  (the balance of a bank account).

      <.sparkline id="bb" values={[8, 12, 9, 14, 11, 16]} />
      <.sparkline id="itau" values={@balances} color="primary" />

  `color="primary"` draws it in the accent, any other value in the ink. The SVG stretches to the width of
  the box it is in (`preserveAspectRatio="none"`), as the canvas draws it.
  """

  use LineaUI.Component

  @w 104
  @h 34
  @pad 4

  attr(:id, :string, required: true, doc: "Names the gradient of the fill, so it must be unique.")
  attr(:values, :list, required: true, doc: "Numbers for the line.")

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary),
    doc: "`primary` draws the line in the accent, `neutral` in the ink."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def sparkline(assigns) do
    assigns = assign(assigns, :paths, paths(assigns.values))

    ~H"""
    <svg
      :if={@paths}
      class={merge(["sg-spark", @class])}
      viewBox="0 0 104 34"
      preserveAspectRatio="none"
      style={"color:" <> ((@color == "primary" && "var(--accent)") || "var(--ink)")}
      aria-hidden="true"
      {@rest}
    >
      <defs>
        <linearGradient id={@id <> "-fill"} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stop-color="currentColor" stop-opacity=".16" />
          <stop offset="1" stop-color="currentColor" stop-opacity="0" />
        </linearGradient>
      </defs>
      <path d={elem(@paths, 0)} fill={"url(##{@id}-fill)"} />
      <path
        d={elem(@paths, 1)}
        fill="none"
        stroke="currentColor"
        stroke-width="1.4"
        stroke-linejoin="round"
      />
    </svg>
    """
  end

  # {area path, line path}: the points spread over the width, the highest at the top.
  defp paths([_, _ | _] = values) do
    {min, max} = Enum.min_max(values)
    span = if max == min, do: 1, else: max - min
    step = @w / (length(values) - 1)

    points =
      values
      |> Enum.with_index()
      |> Enum.map(fn {v, i} ->
        y = @pad + (1 - (v - min) / span) * (@h - 2 * @pad)
        "#{Float.round(i * step, 1)} #{Float.round(y, 1)}"
      end)

    line = "M" <> Enum.join(points, " L")
    {line <> " L#{@w} #{@h} L0 #{@h}Z", line}
  end

  defp paths(_values), do: nil
end
