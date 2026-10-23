defmodule LineaUI.Components.Chart do
  @moduledoc """
  An ApexCharts chart with LineOne's skin (axis labels, grid lines, legend, tooltips, light
  and dark).

      <.chart
        id="sales"
        options={%{
          chart: %{type: "area", height: 350, toolbar: %{show: false}},
          colors: ["#34d399", "#ffba1a"],
          series: [%{name: "Series1", data: [31, 40, 28, 51]}],
          xaxis: %{categories: ["Jan", "Feb", "Mar", "Apr"]}
        }}
      />

  The app provides the library: install `apexcharts` and set `window.ApexCharts` before the
  LiveView connects.

      import ApexCharts from "apexcharts"
      window.ApexCharts = ApexCharts

  `options` is any ApexCharts options object, as a map or a JSON string. When it changes on
  the server the chart is updated in place. To stream data without re-sending the whole
  options, push an event:

      push_event(socket, "linea:chart", %{id: "sales", series: [%{data: [1, 2, 3]}]})

  `series` and/or `options` in the payload are applied with `updateSeries`/`updateOptions`.

  JSON has no functions, so formatters are attached in the browser: before rendering, the
  chart element dispatches a bubbling `linea:chart:options` event whose `detail.options` may
  be changed.

      window.addEventListener("linea:chart:options", ({target, detail}) => {
        target.id === "sales" && (detail.options.yaxis = {labels: {formatter: (v) => "$" + v}})
      })
  """

  use LineaUI.Component

  @doc """
  Renders a chart. The `LineaUI.Chart` hook draws it into an inner element LiveView leaves
  alone, and redraws it in place (`updateOptions`) whenever the `options` assign changes.

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

  Browser event: `linea:chart:options` (bubbling, on the chart element) fires before each
  draw with `detail.options`, the place to add JavaScript formatters. `data-state` on the
  element is `ready`, or `waiting` until `window.ApexCharts` exists.
  """
  attr(:id, :string, required: true, doc: "DOM id; also what `push_event` payloads target.")

  attr(:options, :any,
    required: true,
    doc: "ApexCharts options, a map (encoded to JSON) or an already encoded JSON string."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def chart(assigns) do
    assigns = assign(assigns, :json, encode(assigns.options))

    ~H"""
    <div
      id={@id}
      class={merge(["linea-chart", @class])}
      phx-hook="LineaUI.Chart"
      data-options={@json}
      {@rest}
    >
      <div id={@id <> "-canvas"} phx-update="ignore" data-chart-canvas></div>
    </div>
    """
  end

  defp encode(options) when is_binary(options), do: options
  defp encode(options), do: Jason.encode!(options)
end
