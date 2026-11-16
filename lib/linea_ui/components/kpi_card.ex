defmodule LineaUI.Components.KpiCard do
  @moduledoc """
  A metric card made of daisyUI's pieces (`card card-border` with a `stat`): the label and the change (a soft
  `badge`) on top, the figure with its unit and a sparkline beside it.

      <.kpi_card label="Faturamento" value="R$ 248,6" unit="mil" delta="12,4%" trend="up" spark={[8, 12, 9, 14, 11, 16]} />
      <.kpi_card label="Ticket médio" value="R$ 164" delta="2,3%" trend="down" delta_tone="error" spark={[14, 12, 13, 9]} />

  `trend` draws the arrow and `delta_tone` colors the change: a rise is good by default (`success`, the canvas's
  `up`) and a fall is bad (`error`, `down`). `color="primary"` draws the sparkline in the accent; any other color in
  the ink.

  `progress` (0 to 100) swaps the sparkline for daisyUI's `progress`, with `caption` under it:

      <.kpi_card label="Vendas do mês" value="R$ 248,6" unit="mil" delta="12,4%" progress={78}
        caption="78% da meta de R$ 320 mil" />

  `<:icon>` puts an icon chip before the label, `icon_tone` colors it. `caption` is a faint line under
  the figure, with or without `progress`. `value_id` is the id of the figure:

      <.kpi_card label="Automações" value="12" value_id="kpi-auto" caption="3 pausadas" icon_tone="pos">
        <:icon><.icon name="bolt" /></:icon>
      </.kpi_card>

  `gap={false}` drops the 14px space between the top line and the figure (the canvas's single cards).
  """

  use LineaUI.Component

  @w 104
  @h 34
  @pad 4

  @icon_tones %{
    "acc" => "border-primary/25 bg-primary/10 text-primary",
    "pos" => "border-success/25 bg-success/10 text-success",
    "neg" => "border-error/25 bg-error/10 text-error",
    "warn" => "border-warning/25 bg-warning/10 text-warning",
    "info" => "border-info/25 bg-info/10 text-info"
  }

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
    doc: "A faint line under the figure or the meter (`78% da meta de R$ 320 mil`)."
  )

  attr(:icon_tone, :string,
    default: "acc",
    values: ~w(acc pos neg warn info),
    doc: "Colors the `<:icon>` chip."
  )

  attr(:value_id, :string, default: nil, doc: "The `id` of the figure element (`stat-value`).")

  attr(:gap, :boolean,
    default: true,
    doc:
      "The 14px space between the top line and the figure; `false` sets the figure right under it."
  )

  attr(:loading, :boolean, default: false, doc: "Placeholder blocks in place of the content.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:icon, doc: "An icon shown in a tinted chip before the label.")

  def kpi_card(%{loading: true} = assigns) do
    ~H"""
    <div class={merge(["card card-border kpi-card bg-base-100", @class])} aria-busy="true" {@rest}>
      <div class="card-body gap-3 px-5 py-4">
        <div class="skeleton h-3 w-24"></div>
        <div class="skeleton h-8 w-32"></div>
      </div>
    </div>
    """
  end

  def kpi_card(assigns) do
    assigns =
      assigns
      |> assign(:tone, tone(assigns.delta_tone, assigns.trend))
      |> assign(:paths, paths(assigns.spark))
      |> assign(:uid, "kpi-#{:erlang.phash2({assigns.label, assigns.spark})}")
      |> assign(:icon_class, @icon_tones[assigns.icon_tone])

    ~H"""
    <div
      class={
        merge([
          "card card-border kpi-card bg-base-100",
          (!@gap or @progress) && "kpi-tight",
          @progress && "kpi-goal",
          @class
        ])
      }
      {@rest}
    >
      <div class={["stat gap-y-0 px-5 py-4", (@gap and !@progress) && "gap-y-3.5"]}>
        <div class="stat-title flex items-center gap-2.5">
          <span
            :if={@icon != []}
            class={[
              "kpi-icon grid size-7 shrink-0 place-items-center rounded-field border [&_svg]:size-4",
              @icon_class
            ]}
          >
            {render_slot(@icon)}
          </span>
          <span class="kpi-label grow text-[13px] text-base-content/60">{@label}</span>
          <span :if={@delta} class={["kpi-delta badge badge-soft badge-sm gap-1", @tone]}>
            <svg class="size-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <path :if={@trend == "up"} d="M7 17 17 7M9 7h8v8" />
              <path :if={@trend == "down"} d="M7 7l10 10M17 9v8H9" />
              <path :if={@trend == "flat"} d="M5 12h14" />
            </svg>
            {@delta}
          </span>
        </div>
        <div :if={@progress} id={@value_id} class="kpi-value stat-value text-2xl font-semibold">
          {@value}<small :if={@unit} class="ml-1 text-sm font-normal text-base-content/60">{@unit}</small>
        </div>
        <progress
          :if={@progress}
          class="progress progress-primary mt-2.5 h-1.5"
          value={min(max(@progress, 0), 100)}
          max="100"
          aria-label={@label}
        >
        </progress>
        <div :if={!@progress} class="flex items-end justify-between gap-3">
          <span id={@value_id} class="kpi-value stat-value text-2xl font-semibold">
            {@value}<small :if={@unit} class="ml-1 text-sm font-normal text-base-content/60">{@unit}</small>
          </span>
          <svg
            :if={@paths}
            class={["kpi-spark h-[34px] w-[104px]", (@color == "primary" && "text-primary") || "text-base-content"]}
            viewBox="0 0 104 34"
            preserveAspectRatio="none"
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
        <span :if={@caption} class="kpi-caption stat-desc mt-1.5 text-xs">{@caption}</span>
      </div>
    </div>
    """
  end

  defp tone(nil, "up"), do: "badge-success"
  defp tone(nil, "down"), do: "badge-error"
  defp tone("success", _trend), do: "badge-success"
  defp tone("error", _trend), do: "badge-error"
  defp tone(_tone, _trend), do: "badge-ghost"

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
