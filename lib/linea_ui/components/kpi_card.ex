defmodule LineaUI.Components.KpiCard do
  @moduledoc """
  A metric card: a label, the figure, how it moved since the last period, and, under them, a
  sparkline, a bar series or a progress toward a goal.

      <.kpi_card label="Faturamento" value="R$ 482,3 mil" delta="12,4%" trend="up" hint="vs. setembro"
        spark={[40, 52, 47, 61, 58, 70, 77]} />
      <.kpi_card label="Pedidos" value="1.284" delta="3,1%" trend="down" hint="vs. setembro"
        spark={[8, 12, 9, 16, 11, 10, 13]} spark_type="bar" />
      <.kpi_card label="Inadimplência" value="2,4%" delta="0,6 p.p." trend="up" delta_tone="error"
        hint="pior que o mês anterior" />
      <.kpi_card label="Meta do trimestre" value="78%" goal={78}>
        <:footer>R$ 1,17 mi de R$ 1,5 mi</:footer>
      </.kpi_card>
      <.kpi_card loading />

  `spark_type="area"` lets the series bleed across the bottom of the card, behind the text, as a faded area
  with a thin line on top (the card clips it at its rounded edges):

      <.kpi_card label="Receita" value="R$ 12.345" hint="Últimos 30 dias" spark_type="area"
        spark={[2, 5, 4, 8, 7, 11]} color="info" />

  `trend` draws the arrow and `delta_tone` colors the change: a rise is good by default
  (`success`) and a fall is bad (`error`); pass `delta_tone="error"` for a rise that hurts
  (delinquency, churn) or `"success"` for a fall that helps. `spark` takes the numbers, the
  card draws the SVG itself.
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  @tones %{
    "success" => "bg-success/10 text-success dark:bg-success/15",
    "error" => "bg-error/10 text-error dark:bg-error/15",
    "neutral" => "bg-slate-150 text-slate-600 dark:bg-navy-500 dark:text-navy-100"
  }

  @colors %{
    "neutral" => "text-slate-500 dark:text-navy-300",
    "primary" => "text-primary dark:text-accent-light",
    "secondary" => "text-secondary",
    "info" => "text-info",
    "success" => "text-success",
    "warning" => "text-warning",
    "error" => "text-error"
  }

  @bars %{
    "neutral" => "bg-slate-500 dark:bg-navy-300",
    "primary" => "bg-primary dark:bg-accent",
    "secondary" => "bg-secondary",
    "info" => "bg-info",
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error"
  }

  @width 120
  @height 44
  @pad 4

  @doc """
  Renders a metric card.

      <.kpi_card label="Ticket médio" value="R$ 375" unit=",60" trend="flat" delta="0,0%" hint="estável no mês" />
  """
  attr(:label, :string, default: nil)
  attr(:value, :string, default: nil, doc: "The figure, already formatted.")

  attr(:unit, :string,
    default: nil,
    doc: "A smaller suffix beside the figure (`,60`, `mil`, `un.`)."
  )

  attr(:delta, :string, default: nil, doc: "The change since the last period, already formatted.")

  attr(:trend, :string,
    default: "up",
    values: ~w(up down flat),
    doc: "Direction of the arrow beside `delta`."
  )

  attr(:delta_tone, :string,
    default: nil,
    values: [nil, "success", "error", "neutral"],
    doc:
      "Colors the change. Defaults from `trend`: up is `success`, down is `error`, flat is `neutral`."
  )

  attr(:hint, :string, default: nil, doc: "What the change is measured against (`vs. setembro`).")
  attr(:spark, :list, default: [], doc: "Numbers for the mini chart under the figure.")

  attr(:spark_type, :string,
    default: "line",
    values: ~w(line bar area),
    doc:
      "`line` and `bar` sit under the text; `area` fills the lower half of the card behind the text, edge to edge."
  )

  attr(:color, :string,
    default: "primary",
    values: ~w(neutral primary secondary info success warning error),
    doc: "Color of the sparkline, the bars and the goal bar."
  )

  attr(:goal, :any,
    default: nil,
    doc: "A percentage (0 to 100): draws a progress bar toward the goal."
  )

  attr(:loading, :boolean, default: false, doc: "Placeholder blocks in place of the content.")
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:icon, doc: "A small icon, at the right of the label.")
  slot(:footer, doc: "A line under the goal bar or the sparkline.")

  def kpi_card(%{loading: true} = assigns) do
    ~H"""
    <div
      aria-busy="true"
      aria-label="Carregando métrica"
      class={
        merge(["flex flex-col gap-2.5 rounded-xl bg-white p-5 shadow-soft dark:bg-navy-600 dark:ring-1 dark:ring-navy-450", @class])
      }
      {@rest}
    >
      <div class="h-3.5 w-2/5 animate-pulse rounded-md bg-slate-150 dark:bg-navy-500"></div>
      <div class="h-7 w-3/5 animate-pulse rounded-md bg-slate-150 dark:bg-navy-500"></div>
      <div class="h-5 w-1/3 animate-pulse rounded-md bg-slate-150 dark:bg-navy-500"></div>
      <div class="mt-auto h-11 w-full animate-pulse rounded-md bg-slate-150 dark:bg-navy-500"></div>
    </div>
    """
  end

  def kpi_card(assigns) do
    assigns =
      assign(assigns,
        tone: Map.fetch!(@tones, assigns.delta_tone || default_tone(assigns.trend)),
        spark_color: Map.fetch!(@colors, assigns.color),
        bar_color: Map.fetch!(@bars, assigns.color),
        bleed: assigns.spark_type == "area" and length(assigns.spark) > 1,
        gradient:
          "kpi-#{:erlang.phash2({assigns.label, assigns.value, assigns.spark, assigns.color})}",
        line: if(assigns.spark_type in ~w(line area), do: line(assigns.spark)),
        bars: if(assigns.spark_type == "bar", do: bars(assigns.spark)),
        end_dot: end_dot(assigns.spark),
        goal_percent: assigns.goal && max(0, min(100, assigns.goal))
      )

    ~H"""
    <div
      class={
        merge([
          "flex flex-col gap-2.5 rounded-xl bg-white p-5 shadow-soft dark:bg-navy-600 dark:ring-1 dark:ring-navy-450",
          @bleed && "relative isolate min-h-36 overflow-hidden",
          @class
        ])
      }
      {@rest}
    >
      <svg
        :if={@bleed}
        viewBox="0 0 120 44"
        preserveAspectRatio="none"
        aria-hidden="true"
        data-spark-bleed
        class={[
          "pointer-events-none absolute inset-x-0 bottom-0 -z-10 block h-1/2 w-full opacity-80",
          @spark_color
        ]}
      >
        <defs>
          <linearGradient id={@gradient} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" style="stop-color:currentColor;stop-opacity:0.34" />
            <stop offset="1" style="stop-color:currentColor;stop-opacity:0" />
          </linearGradient>
        </defs>
        <path d={@line.area} fill={"url(##{@gradient})"} />
        <path
          d={@line.stroke}
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          vector-effect="non-scaling-stroke"
        />
      </svg>
      <div
        :if={@label || @icon != []}
        class="flex min-h-[1.875rem] items-center justify-between text-sm+ font-medium text-slate-500 dark:text-navy-200"
      >
        <span>{@label}</span>
        <span
          :if={@icon != []}
          class="flex size-[1.875rem] items-center justify-center rounded-lg bg-primary/10 text-primary dark:bg-accent-light/15 dark:text-accent-light [&>svg]:size-4"
        >
          {render_slot(@icon)}
        </span>
      </div>

      <div class="text-3xl font-semibold leading-tight tabular-nums text-slate-800 dark:text-navy-50">
        {@value}<small :if={@unit} class="ml-1 text-sm font-medium text-slate-500 dark:text-navy-200">{@unit}</small>
      </div>

      <div
        :if={@delta || @hint}
        class="flex flex-wrap items-center gap-2 text-xs+ text-slate-500 dark:text-navy-200"
      >
        <span
          :if={@delta}
          class={[
            "inline-flex h-[1.375rem] items-center gap-0.5 rounded-md px-1.5 text-xs font-semibold",
            @tone
          ]}
        >
          <.glyph name={trend_glyph(@trend)} class="size-3" stroke_width="2.6" />{@delta}
        </span>
        <span :if={@hint}>{@hint}</span>
      </div>

      <div
        :if={@goal_percent}
        role="progressbar"
        aria-valuenow={@goal_percent}
        aria-valuemin="0"
        aria-valuemax="100"
        aria-label={@label}
        class="mt-auto h-2 overflow-hidden rounded bg-slate-150 dark:bg-navy-800"
      >
        <div class={["h-full rounded", @bar_color]} style={"width: #{@goal_percent}%"}></div>
      </div>

      <div :if={@spark != [] and not @bleed} class={["relative mt-auto pt-1.5", @spark_color]}>
        <svg
          viewBox="0 0 120 44"
          preserveAspectRatio="none"
          aria-hidden="true"
          class="block h-11 w-full overflow-visible"
        >
          <path :if={@line} d={@line.area} fill="currentColor" fill-opacity="0.14" />
          <path
            :if={@line}
            d={@line.stroke}
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            vector-effect="non-scaling-stroke"
          />
          <path
            :for={{d, last?} <- @bars || []}
            d={d}
            fill="currentColor"
            fill-opacity={if last?, do: "1", else: "0.32"}
          />
        </svg>
        <i
          :if={@line}
          class="absolute -right-1 mt-0.5 size-[9px] rounded-full bg-current ring-2 ring-white dark:ring-navy-700"
          style={"top: #{@end_dot}%"}
        ></i>
      </div>

      <div
        :if={@footer != []}
        class="flex items-center justify-between gap-2 text-xs+ text-slate-500 dark:text-navy-200"
      >
        {render_slot(@footer)}
      </div>
    </div>
    """
  end

  defp default_tone("up"), do: "success"
  defp default_tone("down"), do: "error"
  defp default_tone("flat"), do: "neutral"

  defp trend_glyph("up"), do: :chevron_up
  defp trend_glyph("down"), do: :chevron_down
  defp trend_glyph("flat"), do: :minus

  # The y of each point, `@pad` from the edges, the highest value at the top.
  defp ys(values) do
    {min, max} = Enum.min_max(values)
    span = if max == min, do: 1, else: max - min

    Enum.map(values, fn v ->
      if max == min,
        do: @height / 2,
        else: @height - @pad - (v - min) / span * (@height - 2 * @pad)
    end)
  end

  defp line([]), do: nil

  defp line([_]), do: nil

  defp line(values) do
    ys = ys(values)
    step = @width / (length(values) - 1)
    points = ys |> Enum.with_index() |> Enum.map(fn {y, i} -> {i * step, y} end)
    [{x0, y0} | rest] = points

    segments =
      points
      |> Enum.zip(rest)
      |> Enum.map_join(" ", fn {{xa, ya}, {xb, yb}} ->
        mid = (xa + xb) / 2
        "C#{f(mid)},#{f(ya)} #{f(mid)},#{f(yb)} #{f(xb)},#{f(yb)}"
      end)

    stroke = "M#{f(x0)},#{f(y0)} #{segments}"
    %{stroke: stroke, area: "#{stroke} L#{@width},#{@height} L0,#{@height} Z"}
  end

  defp bars([]), do: nil

  defp bars(values) do
    n = length(values)
    slot = (@width - 4) / n
    w = max(slot - 4, 2.0)

    values
    |> ys()
    |> Enum.with_index()
    |> Enum.map(fn {y, i} ->
      x = 2 + i * slot
      r = min(3.0, w / 2)
      top = y + r

      d =
        "M#{f(x)},#{@height} V#{f(top)} Q#{f(x)},#{f(y)} #{f(x + r)},#{f(y)} H#{f(x + w - r)} " <>
          "Q#{f(x + w)},#{f(y)} #{f(x + w)},#{f(top)} V#{@height} Z"

      {d, i == n - 1}
    end)
  end

  defp end_dot(values) when length(values) < 2, do: 0
  defp end_dot(values), do: Float.round(List.last(ys(values)) / @height * 100, 1)

  defp f(n), do: :erlang.float_to_binary(n * 1.0, decimals: 1)
end
