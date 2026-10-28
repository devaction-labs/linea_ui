defmodule LineaUI.Components.Chart do
  @moduledoc """
  A chart drawn by the package itself, as SVG, with LineOne's look (axis labels, grid lines, legend,
  tooltips, light and dark). It needs no JavaScript library: the `LineaUI.Chart` hook is all there is.

      <.chart
        id="sales"
        options={%{
          chart: %{type: "area", height: 350, toolbar: %{show: false}},
          colors: ["#34d399", "#ffba1a"],
          series: [%{name: "Series1", data: [31, 40, 28, 51]}],
          xaxis: %{categories: ["Jan", "Feb", "Mar", "Apr"]}
        }}
      />

  `options` is an ApexCharts-shaped options object, as a map or a JSON string (the supported subset is
  listed below; anything else is ignored). The chart fills the width of its element and redraws when
  the element resizes. When `options` changes on the server the chart is redrawn in place. To stream
  data without re-sending the whole options, push an event:

      push_event(socket, "linea:chart", %{id: "sales", series: [%{data: [1, 2, 3]}]})

  `series` is laid over the current series by position (an entry that is a map keeps the name and the
  settings it does not repeat) and `options` is merged into the current options.

  JSON has no functions, so formatters are named and resolved in the browser. `formatters` maps
  an options path to a built-in formatter, and a bare `formatter: "name"` string inside the
  options works too:

      <.chart
        id="sales"
        formatters={%{"yaxis.labels.formatter" => "thousands", "tooltip.y.formatter" => "dollars"}}
        options={%{series: [...], plotOptions: %{radialBar: %{dataLabels: %{total: %{formatter: "total"}}}}}}
      />

  | name | `value` becomes |
  |---|---|
  | `thousands` | `2500` -> `2.5k` (value / 1000, no rounding) |
  | `thousands_round` | `2500` -> `3k` |
  | `thousands_fixed` | `2500` -> `2.50k`, values under 1000 unchanged |
  | `kilo` | `1499` -> `1k`, values under 1000 unchanged |
  | `dollars` | `5` -> `$5` |
  | `dollars_thousands` | `5000` -> `$5k` |
  | `brl` | `1284.9` -> `R$ 1.284,9` (pt-BR grouping) |
  | `brl_thousands` | `6000` -> `R$ 6 mil`, `31500` -> `R$ 31,5 mil`, values under 1000 as `brl` |
  | `number_br` | `1248` -> `1.248` |
  | `percent` | `12.5` -> `12.5%` |
  | `percent_round` | `12.5` -> `13%` |
  | `round` | `2.6` -> `3` |
  | `hours` | `3` -> `3h` |
  | `minutes` | `45` -> `45 min` |
  | `none` | hides the label (empty text) |
  | `total` | for gauges: the sum of the series (takes ApexCharts' `w`, not a value) |

  Names not in the table are left as they are. For anything else, before rendering, the
  chart element dispatches a bubbling `linea:chart:options` event whose `detail.options` may
  be changed.

      window.addEventListener("linea:chart:options", ({target, detail}) => {
        target.id === "sales" && (detail.options.yaxis = {labels: {formatter: (v) => "$" + v}})
      })

  ## Cursor

  The chart tells the page where its cursor is, as the pointer or the arrow keys move it. Three ways,
  each off unless asked for:

    * the `linea:chart:cursor` event, always: bubbling, on the chart element, with `detail` as
      `{index, label, values: [{name, color, value}]}` (the values are the ones the tooltip shows, so
      formatters apply) and a `null` detail when the cursor leaves.
    * `summary`: a line above the plot with the label as a chip and one `name value` per series. It follows
      the cursor and, when the cursor is gone, shows the last point that has a value. It is not a live
      region (`aria-live="off"`): the tooltip and the hidden data table are what assistive technology reads.
    * `on_cursor="event"`: pushes `event` to the LiveView (to `phx-target` when the chart has one) with
      `%{"id" => id, "index" => i, "label" => l, "values" => [%{"name" => ..., "color" => ..., "value" => ...}]}`,
      at most every 100 ms, and with `"index" => nil` and `"values" => []` on leave.

      window.addEventListener("linea:chart:cursor", ({target, detail}) => console.log(target.id, detail))

  A chart whose tooltip lists one series at a time (bars with `tooltip.shared` off) reports that series only.

  ## Supported options

  The engine reads this subset of the ApexCharts options. Everything else is ignored, never an error.
  Colors that belong to the theme (axis text, grid, tooltip card, gauge tracks, radar rings) follow
  LineOne's light and dark skin and cannot be set from the options.

  **Types** (`chart.type`): `line`, `area`, `bar` (columns, or rows with `plotOptions.bar.horizontal`),
  `rangeBar`, `candlestick`, `donut`, `pie`, `radialBar` and `radar`. `polarArea` is drawn as a pie and
  any other type as a line.

  **chart**: `height` (a number, `"200px"`, a share of the width such as `"50%"`, or `"auto"`), `width` (a
  number or text such as `"120px"` that sizes the element; otherwise the chart fills it), `stacked`,
  `stackType` (`normal` or `100%`), `sparkline.enabled`, `dropShadow` (`enabled`, `top`, `left`, `blur`,
  `color`, `opacity`), `animations.enabled`, `parentHeightOffset`, `defaultLocale` (a locale such as `"pt-BR"`: the month and day names of date
  labels and tooltips, `Fev 2026`, come from it; English without). The entry animation is short and
  is skipped under `prefers-reduced-motion`.

  **Data**: `series` (`[%{name, data}]` where `data` is numbers, `null` for a gap, `%{x, y}` or `[x, y]`;
  candlestick `y` is `[open, high, low, close]`, range bar `y` is `[start, end]`; donut, pie and radial
  bar take a list of numbers), `labels` (slice names), `colors`, `xaxis.categories`. Per-series chart
  types (combo charts) and several y axes are not supported; the first `yaxis` entry is the axis.

  **Lines and areas**: `stroke` (`show`, `curve` `smooth`, `straight` or `stepline`, `width`, `colors`,
  `dashArray`, `lineCap`; each may be a list per series), `markers` (`size`, `colors`, `hover.size`,
  `hover.sizeOffset`), `fill` (`type` `solid` or `gradient`, `colors`, `opacity`, and `gradient` with
  `type` `vertical`, `horizontal`, `diagonal1` or `diagonal2`, `shade`, `shadeIntensity`, `opacityFrom`,
  `opacityTo`, `stops`, `inverseColors`, `gradientToColors`). A gradient on a `line` chart paints the
  stroke left to right.

  **Bars**: `plotOptions.bar` with `horizontal`, `columnWidth` and `barHeight` (a share such as `"55%"`,
  a number meaning the same percentage, or pixels as `"24px"`), `borderRadius`, `borderRadiusApplication`,
  `distributed`, `rangeBarOverlap` and `dataLabels.position` (`center` or `top`). A stacked bar rounds
  the ends of the whole pile. `plotOptions.candlestick.colors` takes `upward` and `downward`.

  **Axes**: `xaxis` (`type` `category`, `datetime` or `numeric`, `categories`, `min`, `max`, `tickAmount`,
  `position` `top`, `show`, `labels` with `show`, `formatter`, `format` for dates such as `"dd MMM"`,
  `hideOverlappingLabels`, `offsetX`, `offsetY`, `style.fontSize`, `axisBorder.show`, `axisTicks.show`,
  `crosshairs.show`, `tooltip.enabled`) and `yaxis` (`show`, `min`, `max`, `tickAmount`, `labels` with the
  same keys, `axisBorder.show`, `axisTicks.show`, `tooltip.enabled`). For a horizontal bar the `yaxis`
  options drive the category labels and the `xaxis` ones the value labels. Labels never rotate; the ones
  that would overlap are thinned out.

  **Grid**: `grid.show`, `grid.strokeDashArray`, `grid.xaxis.lines.show`, `grid.yaxis.lines.show` and
  `grid.padding` (`top`, `right`, `bottom`, `left`, negative values allowed, as in ApexCharts).

  **Text**: `dataLabels` (`enabled`, `formatter`, `offsetX`, `offsetY`, `style.fontSize`), `legend`
  (`show`, `showForSingleSeries`, `position`, `horizontalAlign`, `fontSize`, `markers.size`,
  `markers.shape`, `itemMargin`, `onItemClick.toggleDataSeries`; clicking an entry hides its series; pointing at or tabbing to one puts its series in front: the others dim and a slice or ring grows),
  `tooltip` (`enabled`, `shared`, `intersect`, `theme` `light` or `dark`, `fillSeriesColor`, `x.show`,
  `x.format`, `x.formatter`, `y.formatter`, `y.title.formatter`) and `title.text`, which names the chart
  for assistive technology. Each chart also carries a hidden table with its data; the `table_toggle`
  attribute of `chart/1` adds a Chart / Table switch that shows that table in place of the drawing.

  **Legend figures**: for the parts of a whole (donut, pie, radial bar, and stacked bar or area charts),
  `legend.showValue` and `legend.showPercent` write `524 · 42%` after each name: the slice value or the
  series total, and its share of the entries still shown (a hidden entry keeps its value only). Shape them
  with `legend.value.formatter` (any built-in name, such as `number_br` or `brl`) and
  `legend.percent.formatter` (receives 0 to 100; the default is the rounded number plus `%`). The
  percent of a radial bar is not shown, since its values already are percentages.

      legend: %{position: "right", showValue: true, showPercent: true, value: %{formatter: "number_br"}}

  **Keyboard**: a chart that can be walked is a tab stop. On a line, area or bar chart the arrow keys, Home
  and End move the cursor between the points (the tooltip, crosshair and markers follow); on a pie or donut
  they move between the slices (the tooltip, the highlighted slice and the middle text follow); on a radar
  between the spokes (the tooltip lists every series on the spoke). Escape or leaving the chart clears it.

  **Circular charts**: `plotOptions.pie` (`startAngle`, `endAngle`, `offsetX`, `offsetY`, `customScale`,
  `donut.size`, `donut.labels` with `show`, `name`, `value` and `total`, `dataLabels.offset`),
  `plotOptions.radialBar` (`startAngle`, `endAngle`, `hollow.size`, `track.show`,
  `track.margin`, `track.strokeWidth`, `track.opacity`, `dataLabels` with `show`, `name`, `value` and
  `total`, each taking `show`, `fontSize`, `fontWeight`, `color`, `offsetY` and `formatter`) and
  `stroke.lineCap`. Hovering a donut slice shows its name and value in the middle.

  **Radar**: `plotOptions.radar` (`size`, `offsetX`, `offsetY`), `xaxis.categories` for the spokes (their
  labels are `#a8a8a8` unless `xaxis.labels.style.colors` says otherwise) and `yaxis` for the ring labels.

  **responsive**: rules apply while the window is narrower than their `breakpoint`, the smaller
  breakpoints last, as in ApexCharts.

  Formatter functions receive the same arguments they do in ApexCharts: `(value, opts)` for data labels
  and the tooltip's `y`, `(value, timestamp, opts)` for x labels and `(w)` for the gauge total, with
  `w.config` and `w.globals.seriesTotals`.
  """

  use LineaUI.Component

  alias LineaUI.Components.Segmented

  @doc """
  Renders a chart. The `LineaUI.Chart` hook draws it into an inner element LiveView leaves
  alone, and redraws it in place whenever the `options` assign changes.

      <.chart
        id="revenue"
        class="max-w-xl"
        options={%{
          chart: %{type: "bar", height: 350, toolbar: %{show: false}},
          colors: ["#ff9800", "#6366f1"],
          plotOptions: %{bar: %{horizontal: true, borderRadius: 5}},
          series: [%{name: "Net Profit", data: @profit}, %{name: "Revenue", data: @revenue}],
          xaxis: %{categories: @months}
        }}
      />

  Server push (no re-render), from `handle_event/3` or `handle_info/2`; payload
  `%{id: chart_id, series: [...]}` and/or `options: %{...}`, `id` with or without `#`:

      push_event(socket, "linea:chart", %{id: "revenue", series: [%{data: [1, 2, 3]}]})

  Browser events, bubbling on the chart element: `linea:chart:options` fires before each draw with
  `detail.options`, the place to add JavaScript formatters, and `linea:chart:cursor` fires as the cursor
  moves (see Cursor in the module doc).
  """
  attr(:id, :string, required: true, doc: "DOM id; also what `push_event` payloads target.")

  attr(:options, :any,
    required: true,
    doc: "ApexCharts-shaped options, a map (encoded to JSON) or an already encoded JSON string."
  )

  attr(:formatters, :map,
    default: %{},
    doc:
      "Options path to built-in formatter name, e.g. `%{\"yaxis.labels.formatter\" => \"thousands\"}`; see the table in the module doc. Applied before every draw."
  )

  attr(:table_toggle, :any,
    default: false,
    doc:
      "`true` adds a Chart / Table switch above the chart (a `segmented` control, answered in the browser) that shows the data table in place of the drawing. A map renames the texts: `%{chart: \"Gráfico\", table: \"Tabela\", label: \"Visualização\"}`."
  )

  attr(:summary, :boolean,
    default: false,
    doc:
      "Writes a line above the plot with the label and the value of each series at the cursor, falling back to the last point with data. Not a live region."
  )

  attr(:on_cursor, :string,
    default: nil,
    doc:
      "Name of a LiveView event pushed (at most every 100 ms) with `id`, `index`, `label` and `values` as the cursor moves, and with an empty one when it leaves. Off by default."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def chart(assigns) do
    assigns =
      assigns
      |> assign(:json, encode(assigns.options))
      |> assign(:formatters_json, formatters_json(assigns.formatters))
      |> assign(:toggle, toggle(assigns.table_toggle, assigns.id))

    ~H"""
    <div
      id={@id}
      class={merge(["linea-chart", @class])}
      phx-hook="LineaUI.Chart"
      data-options={@json}
      data-formatters={@formatters_json}
      data-on-cursor={@on_cursor}
      phx-mounted={JS.ignore_attributes(["data-view"])}
      {@rest}
    >
      <div :if={@toggle} data-chart-view class="mb-2 flex justify-end">
        <Segmented.segmented
          id={@toggle.id}
          size="sm"
          value="chart"
          aria-label={@toggle.label}
          options={[{@toggle.chart, "chart"}, {@toggle.table, "table"}]}
        />
      </div>
      <div
        :if={@summary}
        id={@id <> "-summary"}
        phx-update="ignore"
        aria-live="off"
        data-chart-summary
        class="linea-chart-summary"
      >
      </div>
      <div id={@id <> "-canvas"} phx-update="ignore" data-chart-canvas></div>
    </div>
    """
  end

  defp toggle(off, _id) when off in [false, nil], do: nil

  defp toggle(spec, id) do
    spec = if is_map(spec), do: spec, else: %{}

    %{
      id: id <> "-view",
      chart: Map.get(spec, :chart, "Chart"),
      table: Map.get(spec, :table, "Table"),
      label: Map.get(spec, :label, "View")
    }
  end

  defp formatters_json(formatters) when map_size(formatters) == 0, do: nil
  defp formatters_json(formatters), do: Jason.encode!(formatters)

  defp encode(options) when is_binary(options), do: options
  defp encode(options), do: Jason.encode!(options)
end
