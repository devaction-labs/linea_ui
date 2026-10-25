/**
 * From options to markup: reads the configuration, lays the chart out for a width and draws it as an SVG
 * string, with the legend and the text alternative that go with it.
 */
import {draw, plan} from "./chart_cartesian.js"
import {cartesian, configure, heightOf} from "./chart_config.js"
import {legendBox, legendHtml, legendStyle} from "./chart_legend.js"
import {estimateWidth} from "./chart_scale.js"
import {prepare} from "./chart_series.js"
import {escape, h, render} from "./chart_svg.js"

const TITLES = {line: "Line chart", area: "Area chart", bar: "Bar chart", rangeBar: "Range bar chart", candlestick: "Candlestick chart", donut: "Donut chart", pie: "Pie chart", radialBar: "Radial bar chart", radar: "Radar chart"}

const describe = (config, data) =>
  `${data.series.map((series) => series.name).join(", ")}${data.labels.length > 0 ? `: ${data.labels.slice(0, 12).join(", ")}${data.labels.length > 12 ? "…" : ""}` : ""}`

const cartesianLayers = (config, data, env, uid) => {
  const legend = legendBox(config, data, env)
  const layout = plan(config, data, {...env, legend})
  const drawn = draw(layout, uid)
  return {legend, layout, drawn}
}

const root = (config, env, uid, title, desc, defs, layers, classes) =>
  h(
    "svg",
    {class: `linea-chart-svg ${classes}`, xmlns: "http://www.w3.org/2000/svg", width: env.width, height: env.height, viewBox: `0 0 ${env.width} ${env.height}`, role: "img", "aria-labelledby": `${uid}-title ${uid}-desc`},
    h("title", {id: `${uid}-title`}, title),
    h("desc", {id: `${uid}-desc`}, desc),
    h("defs", {}, defs),
    layers
  )

/**
 * Builds the chart for `options` at `env.width` px: `{config, height, svg, legend, legendStyle, layout}`.
 * `env` carries `width`, the window `viewport` width (for responsive rules), `measure(text, size)` for text
 * widths, `uid` (a prefix for ids inside the SVG) and the indices of the `hidden` series.
 */
export const build = (options, env) => {
  const config = configure(options, {viewport: env.viewport})
  const width = env.width
  const height = heightOf(config, width)
  const measure = env.measure ?? estimateWidth
  const hidden = env.hidden ?? []
  const data = prepare(config, hidden)
  const full = {width, height, measure, hidden, uid: env.uid ?? "chart"}
  const title = config.title?.text ?? TITLES[config.type] ?? "Chart"
  const desc = describe(config, data)
  const parts = cartesian(config.type) ? cartesianLayers(config, data, full, full.uid) : null
  const layers = parts
    ? [
        h("g", {class: "linea-chart-grid", "aria-hidden": "true"}, parts.drawn.layers.grid),
        h("g", {class: "linea-chart-axes", "aria-hidden": "true"}, parts.drawn.layers.axes),
        h("g", {class: "linea-chart-plot"}, parts.drawn.layers.series),
        h("g", {class: "linea-chart-datalabels", "aria-hidden": "true"}, parts.drawn.layers.labels),
        h("g", {class: "linea-chart-hover", "aria-hidden": "true"}),
      ]
    : []
  const svg = render(root(config, full, full.uid, title, desc, parts?.drawn.defs ?? [], layers, `linea-chart-${config.type}`))
  return {config, data, width, height, svg, legend: parts?.legend, legendHtml: parts ? legendHtml(parts.legend) : "", legendStyle: parts ? legendStyle(parts.legend) : "", layout: parts?.layout, drawn: parts?.drawn, title: escape(title)}
}
