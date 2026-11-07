defmodule LineaUI.Components.KpiCard do
  @moduledoc """
  The canvas's metric card (`sg-card sg-kpi`): the label and the change on top, the figure with its unit and a
  sparkline beside it.

      <.kpi_card label="Faturamento" value="R$ 248,6" unit="mil" delta="12,4%" trend="up" spark={[8, 12, 9, 14, 11, 16]} />
      <.kpi_card label="Ticket médio" value="R$ 164" delta="2,3%" trend="down" delta_tone="error" spark={[14, 12, 13, 9]} />

  `trend` draws the arrow and `delta_tone` colors the change: a rise is good by default (`success`, the canvas's
  `up`) and a fall is bad (`error`, `down`). `color="primary"` draws the sparkline in the accent; any other color in
  the ink.

  `progress` (0 to 100) swaps the sparkline for the canvas goal meter, with `caption` under it:

      <.kpi_card label="Vendas do mês" value="R$ 248,6" unit="mil" delta="12,4%" progress={78}
        caption="78% da meta de R$ 320 mil" />

  `gap={false}` drops the 14px space between the top line and the figure (the canvas's single cards).
  """

  use LineaUI.Component

  @w 104
  @h 34
  @pad 4

  attr(:label, :string, default: nil)
  attr(:value, :string, default: nil, doc: "The figure, already formatted.")

  attr(:unit, :string,
    default: nil,
    doc: "A smaller suffix beside the figure (`mil`, `%`, `dias`)."
  )

  attr(:delta, :string, default: nil, doc: "The change since the last period, already formatted.")
  attr(:trend, :string, default: "up", values: ~w(up down flat), doc: "Direction of the arrow.")

  attr(:delta_tone, :string,
    default: nil,
    values: [nil, "success", "error", "neutral"],
    doc:
      "Colors the change. Defaults from `trend`: up is `success`, down is `error`, flat is `neutral`."
  )

  attr(:spark, :list, default: [], doc: "Numbers for the sparkline.")

  attr(:color, :string,
    default: "primary",
    values: ~w(neutral primary secondary info success warning error),
    doc: "`primary` draws the sparkline in the accent, the others in the ink."
  )

  attr(:layout, :string,
    default: "inline",
    values: ~w(stack inline),
    doc: "Kept for compatibility; the canvas card is one layout."
  )

  attr(:progress, :integer,
    default: nil,
    doc:
      "How much of a goal is done (0 to 100): an accent meter under the figure, in place of the sparkline."
  )

  attr(:caption, :string,
    default: nil,
    doc: "A faint line under the meter (`78% da meta de R$ 320 mil`)."
  )

  attr(:gap, :boolean,
    default: true,
    doc:
      "The 14px space between the top line and the figure; `false` sets the figure right under it."
  )

  attr(:loading, :boolean, default: false, doc: "Placeholder blocks in place of the content.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def kpi_card(%{loading: true} = assigns) do
    ~H"""
    <div class={merge(["sg-card sg-kpi", @class])} aria-busy="true" {@rest}>
      <div class="sg-skel h-3 w-24"></div>
      <div class="sg-skel h-8 w-32"></div>
    </div>
    """
  end

  def kpi_card(assigns) do
    assigns =
      assigns
      |> assign(:tone, tone(assigns.delta_tone, assigns.trend))
      |> assign(:paths, paths(assigns.spark))
      |> assign(:uid, "kpi-#{:erlang.phash2({assigns.label, assigns.spark})}")

    ~H"""
    <div
      class={
        merge([
          "sg-card sg-kpi",
          (!@gap or @progress) && "sg-kpi-tight",
          @progress && "sg-kpi-goal",
          @class
        ])
      }
      {@rest}
    >
      <div class="row" style="justify-content:space-between">
        <span class="sg-kpi-l">{@label}</span>
        <span :if={@delta} class={["sg-delta", @tone]}>
          <svg class="i" viewBox="0 0 24 24" aria-hidden="true">
            <path :if={@trend == "up"} d="M7 17 17 7M9 7h8v8" />
            <path :if={@trend == "down"} d="M7 7l10 10M17 9v8H9" />
            <path :if={@trend == "flat"} d="M5 12h14" />
          </svg>
          {@delta}
        </span>
      </div>
      <div :if={@progress} class="sg-kpi-v">{@value}<small>{@unit}</small></div>
      <div
        :if={@progress}
        class="sg-meter acc"
        role="progressbar"
        aria-valuenow={@progress}
        aria-valuemin="0"
        aria-valuemax="100"
        aria-label={@label}
      >
        <i style={"width:#{min(max(@progress, 0), 100)}%"}></i>
      </div>
      <span :if={@progress && @caption} class="sg-kpi-c">{@caption}</span>
      <div :if={!@progress} class="sg-kpi-row">
        <span class="sg-kpi-v">{@value}<small>{@unit}</small></span>
        <svg
          :if={@paths}
          class="sg-spark"
          viewBox="0 0 104 34"
          preserveAspectRatio="none"
          style={"color:" <> ((@color == "primary" && "var(--accent)") || "var(--ink)")}
          aria-hidden="true"
        >
          <defs>
            <linearGradient id={@uid} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stop-color="currentColor" stop-opacity=".16" />
              <stop offset="1" stop-color="currentColor" stop-opacity="0" />
            </linearGradient>
          </defs>
          <path d={elem(@paths, 0)} fill={"url(##{@uid})"} />
          <path
            d={elem(@paths, 1)}
            fill="none"
            stroke="currentColor"
            stroke-width="1.4"
            stroke-linejoin="round"
          />
        </svg>
      </div>
    </div>
    """
  end

  defp tone(nil, "up"), do: "up"
  defp tone(nil, "down"), do: "down"
  defp tone("success", _trend), do: "up"
  defp tone("error", _trend), do: "down"
  defp tone(_tone, _trend), do: nil

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
