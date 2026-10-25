/**
 * Turns the ApexCharts-shaped `options` a chart receives into the full configuration the engine reads:
 * the defaults of the chart type, the sparkline overrides, the responsive breakpoints that apply and then
 * the options themselves, merged deeply. Anything the engine does not know stays in the object, unused.
 */

export const PALETTE = ["#008FFB", "#00E396", "#FEB019", "#FF4560", "#775DD0", "#3F51B5", "#03A9F4", "#4CAF50", "#F9CE1D", "#FF9800"]

const isObject = (value) => value !== null && typeof value === "object" && !Array.isArray(value)

/** Deep merge: objects merge key by key, everything else (arrays included) replaces; `undefined` is skipped. */
export const merge = (base, extra) =>
  isObject(base) && isObject(extra)
    ? Object.entries(extra).reduce((result, [key, value]) => (value === undefined ? result : {...result, [key]: merge(result[key], value)}), {...base})
    : extra === undefined
      ? base
      : isObject(extra)
        ? merge({}, extra)
        : extra

/** The entry of `value` for the series `index` when it is a list, else `value` itself. */
export const pick = (value, index) => (Array.isArray(value) ? value[index] : value)

const BASE = {
  chart: {type: "line", height: "auto", stacked: false, stackType: "normal", parentHeightOffset: 15, sparkline: {enabled: false}, animations: {enabled: true, speed: 600}},
  colors: PALETTE,
  series: [],
  labels: [],
  stroke: {show: true, curve: "smooth", lineCap: "butt", width: 2, dashArray: 0},
  fill: {
    type: "solid",
    opacity: 0.85,
    gradient: {shade: "dark", type: "horizontal", shadeIntensity: 0.5, inverseColors: true, opacityFrom: 1, opacityTo: 1, stops: [0, 50, 100]},
  },
  markers: {size: 0, strokeColors: "#fff", strokeWidth: 2, shape: "circle", hover: {sizeOffset: 3}},
  dataLabels: {enabled: true, offsetX: 0, offsetY: 0, style: {fontSize: "12px"}},
  grid: {show: true, strokeDashArray: 0, position: "back", xaxis: {lines: {show: false}}, yaxis: {lines: {show: true}}, padding: {top: 0, right: 10, bottom: 0, left: 12}},
  legend: {show: true, position: "bottom", horizontalAlign: "center", fontSize: "12px", markers: {size: 12}, itemMargin: {horizontal: 5, vertical: 2}, offsetX: 0, offsetY: 0, onItemClick: {toggleDataSeries: true}},
  tooltip: {enabled: true, shared: true, intersect: false, theme: "light", marker: {show: true}, x: {show: true}},
  xaxis: {
    type: "category",
    categories: [],
    show: true,
    position: "bottom",
    labels: {show: true, hideOverlappingLabels: true, offsetX: 0, offsetY: 0},
    axisBorder: {show: true},
    axisTicks: {show: true},
    crosshairs: {show: true},
    tooltip: {enabled: true},
  },
  yaxis: {show: true, labels: {show: true, offsetX: 0, offsetY: 0}, axisBorder: {show: false}, axisTicks: {show: false}, tooltip: {enabled: false}},
  plotOptions: {
    bar: {horizontal: false, columnWidth: "70%", barHeight: "70%", borderRadius: 0, borderRadiusApplication: "around", borderRadiusWhenStacked: "last", distributed: false, dataLabels: {position: "center", hideOverflowingLabels: true}},
    radialBar: {
      startAngle: 0,
      endAngle: 360,
      hollow: {margin: 5, size: "50%"},
      track: {show: true, strokeWidth: "97%", margin: 5, opacity: 1},
      dataLabels: {show: true, name: {show: true, fontSize: "16px", offsetY: 0}, value: {show: true, fontSize: "14px", offsetY: 16}, total: {show: false, label: "Total"}},
    },
    pie: {startAngle: 0, endAngle: 360, offsetX: 0, offsetY: 0, customScale: 1, donut: {size: "65%", labels: {show: false, name: {show: true, offsetY: -10}, value: {show: true, offsetY: 10}, total: {show: false, label: "Total"}}}},
    radar: {offsetX: 0, offsetY: 0, polygons: {strokeWidth: 1}},
  },
}

const BY_TYPE = {
  line: {stroke: {width: 5, curve: "straight"}, dataLabels: {enabled: false}},
  area: {stroke: {width: 4}, fill: {type: "gradient", gradient: {inverseColors: false, shade: "light", type: "vertical", opacityFrom: 0.65, opacityTo: 0.5, stops: [0, 100, 100]}}},
  bar: {stroke: {width: 0, lineCap: "square"}, legend: {markers: {shape: "square"}}, tooltip: {shared: false, intersect: true}, dataLabels: {style: {colors: ["#fff"]}}},
  rangeBar: {stroke: {width: 0, lineCap: "square"}, legend: {markers: {shape: "square"}}, tooltip: {shared: false, intersect: true}, dataLabels: {style: {colors: ["#fff"]}}},
  candlestick: {stroke: {width: 1}, fill: {opacity: 1}, dataLabels: {enabled: false}, tooltip: {shared: true}},
  pie: {
    stroke: {colors: ["#fff"]},
    fill: {opacity: 1, gradient: {shade: "light", stops: [0, 100]}},
    dataLabels: {style: {colors: ["#fff"]}},
    tooltip: {theme: "dark", fillSeriesColor: true},
    legend: {position: "right"},
    grid: {padding: {top: 0, right: 0, bottom: 0, left: 0}},
  },
  radialBar: {legend: {show: false, position: "right"}, tooltip: {enabled: false}, grid: {padding: {top: 0, right: 0, bottom: 0, left: 0}}},
  radar: {
    dataLabels: {enabled: false, style: {fontSize: "11px"}},
    stroke: {width: 2},
    markers: {size: 5, strokeWidth: 1},
    fill: {opacity: 0.2},
    tooltip: {shared: false, intersect: true},
    grid: {show: false, padding: {top: 0, right: 0, bottom: 0, left: 0}},
    xaxis: {tooltip: {enabled: false}, crosshairs: {show: false}},
  },
}

BY_TYPE.donut = BY_TYPE.pie
BY_TYPE.polarArea = BY_TYPE.pie

const SPARKLINE = {
  grid: {show: false, padding: {top: 0, right: 0, bottom: 0, left: 0}},
  legend: {show: false},
  xaxis: {labels: {show: false}, tooltip: {enabled: false}, axisBorder: {show: false}, axisTicks: {show: false}},
  yaxis: {show: false, axisBorder: {show: false}, axisTicks: {show: false}},
  dataLabels: {enabled: false},
}

const first = (value) => (Array.isArray(value) ? (value[0] ?? {}) : (value ?? {}))

const sparklined = (options) => options?.chart?.sparkline?.enabled === true

const shrunk = (options, viewport) =>
  (Array.isArray(options.responsive) ? options.responsive : [])
    .filter((rule) => typeof rule?.breakpoint === "number" && viewport < rule.breakpoint)
    .sort((a, b) => b.breakpoint - a.breakpoint)
    .reduce((merged, rule) => merge(merged, rule.options ?? {}), options)

/**
 * The configuration for `options`, seen from a window `viewport` px wide. The first `yaxis` entry is the
 * axis; `series`, `colors` and the rest keep their shape.
 */
export const configure = (options, {viewport = Infinity} = {}) => {
  const given = shrunk(options ?? {}, viewport)
  const type = given.chart?.type ?? BASE.chart.type
  const defaults = merge(merge(BASE, BY_TYPE[type] ?? {}), sparklined(given) ? SPARKLINE : {})
  const config = merge(defaults, {...given, yaxis: first(given.yaxis)})
  return {...config, type}
}

/** The pixel height of the chart for its `width`: a number, `"200px"`, a percentage of the width, or `auto`. */
export const heightOf = (config, width) => {
  const height = config.chart.height
  const text = String(height)
  return typeof height === "number"
    ? height
    : /^\d+(\.\d+)?(px)?$/.test(text)
      ? parseFloat(text)
      : /%$/.test(text)
        ? (parseFloat(text) / 100) * width
        : width / 1.618
}

/** The color of series (or slice, or point) `index`: an entry of `colors`, cycling. */
export const colorAt = (config, index) => {
  const colors = Array.isArray(config.colors) && config.colors.length > 0 ? config.colors : PALETTE
  return colors[index % colors.length]
}

/** Whether the chart draws on x and y axes. */
export const cartesian = (type) => ["line", "area", "bar", "rangeBar", "candlestick"].includes(type)
