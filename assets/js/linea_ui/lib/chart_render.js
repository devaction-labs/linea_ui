/**
 * From options to markup: reads the configuration, lays the chart out for a width and draws it as an SVG
 * string, with the legend, the text alternative and the function that answers the pointer.
 */
import {draw, plan} from "./chart_cartesian.js"
import {drawCircular, geometry, hoverText, radial, sliceAt, slicesOf} from "./chart_circular.js"
import {cartesian, configure, heightOf, pick} from "./chart_config.js"
import {hover} from "./chart_hover.js"
import {legendBox, legendHtml, legendStyle} from "./chart_legend.js"
import {drawRadar, radarPlan, vertexAt} from "./chart_radar.js"
import {estimateWidth, plain} from "./chart_scale.js"
import {prepare} from "./chart_series.js"
import {tableHtml} from "./chart_table.js"
import {h, render} from "./chart_svg.js"

const TITLES = {line: "Line chart", area: "Area chart", bar: "Bar chart", rangeBar: "Range bar chart", candlestick: "Candlestick chart", donut: "Donut chart", pie: "Pie chart", radialBar: "Radial bar chart", radar: "Radar chart"}

const call = (formatter, ...args) => (typeof formatter === "function" ? formatter(...args) : undefined)

const shell = (env, uid, title, desc, defs, layers, type) =>
  h(
    "svg",
    {class: `linea-chart-svg linea-chart-type-${type}`, xmlns: "http://www.w3.org/2000/svg", width: env.width, height: env.height, viewBox: `0 0 ${env.width} ${env.height}`, role: "img", "aria-labelledby": `${uid}-title ${uid}-desc`},
    h("title", {id: `${uid}-title`}, title),
    h("desc", {id: `${uid}-desc`}, desc),
    h("defs", {}, defs),
    layers
  )

const overlay = h("g", {class: "linea-chart-hover", "aria-hidden": "true"})

const seriesSummary = (data) => `${data.series.map((series) => series.name).join(", ")}${data.labels.length > 0 ? `: ${data.labels.slice(0, 12).join(", ")}${data.labels.length > 12 ? "…" : ""}` : ""}`

const sliceSummary = (slices) => slices.map((slice) => `${slice.name} ${plain(slice.value)}`).join(", ")

const axisBuild = (config, env, uid) => {
  const data = prepare(config, env.hidden)
  const legend = legendBox(config, data, env)
  const layout = plan(config, data, {...env, legend})
  const drawn = draw(layout, uid)
  const layers = [
    h("g", {class: "linea-chart-grid", "aria-hidden": "true"}, drawn.layers.grid),
    h("g", {class: "linea-chart-axes", "aria-hidden": "true"}, drawn.layers.axes),
    h("g", {class: "linea-chart-plot"}, drawn.layers.series),
    h("g", {class: "linea-chart-datalabels", "aria-hidden": "true"}, drawn.layers.labels),
    overlay,
  ]
  return {data, legend, layers, defs: drawn.defs, desc: seriesSummary(data), probe: (x, y) => hover(layout, drawn.boxes, x, y), layout, drawn}
}

const circularProbe = (config, g, slices, drawn) => (x, y) => {
  const live = slices.filter((slice) => !slice.hidden)
  const arc = radial(config.type) ? null : sliceAt(drawn.hits, g, x, y)
  const total = live.reduce((sum, slice) => sum + slice.value, 0)
  const formatted = arc ? String(call(pick(config.tooltip.y, arc.index)?.formatter ?? config.tooltip.y?.formatter, arc.value, {seriesIndex: arc.index, w: {config}}) ?? plain(arc.value)) : null
  return arc && config.tooltip.enabled !== false
    ? {
        slot: arc.index,
        title: "",
        rows: [{name: arc.name, value: formatted, color: config.tooltip.fillSeriesColor ? null : arc.color}],
        anchor: {x, y},
        crosshair: null,
        markers: [],
        band: null,
        active: {slice: arc.index},
        axisTip: null,
        yTip: null,
        fill: config.tooltip.fillSeriesColor ? arc.color : null,
        theme: config.tooltip.theme,
        center: hoverText(config, {...arc, name: arc.name, value: arc.value}, slices),
        share: total > 0 ? arc.value / total : 0,
      }
    : null
}

const circularBuild = (config, env) => {
  const slices = slicesOf(config, env.hidden)
  const legend = legendBox(config, {series: []}, env)
  const g = geometry(config, {width: env.width, height: env.height, legend})
  const drawn = drawCircular(config, g, slices)
  const layers = [
    h("g", {class: "linea-chart-plot"}, drawn.layers.tracks, drawn.layers.series),
    h("g", {class: "linea-chart-datalabels", "aria-hidden": "true"}, drawn.layers.labels),
    drawn.layers.center,
    overlay,
  ]
  return {legend, layers, defs: [], desc: sliceSummary(slices), probe: circularProbe(config, g, slices, drawn), height: g.height, text: drawn.text, slices, g}
}

const radarBuild = (config, env, uid) => {
  const data = prepare(config, env.hidden)
  const legend = legendBox(config, data, env)
  const layout = radarPlan(config, data, {...env, legend})
  const drawn = drawRadar(config, layout, data)
  const layers = [
    h("g", {class: "linea-chart-grid", "aria-hidden": "true"}, drawn.layers.grid),
    h("g", {class: "linea-chart-axes", "aria-hidden": "true"}, drawn.layers.axes),
    h("g", {class: "linea-chart-plot"}, drawn.layers.series),
    h("g", {class: "linea-chart-datalabels", "aria-hidden": "true"}, drawn.layers.labels),
    overlay,
  ]
  const probe = (x, y) => {
    const found = config.tooltip.enabled === false ? null : vertexAt(drawn.hits, x, y)
    const series = found ? data.series.find((one) => one.index === found.series) : null
    return found
      ? {
          slot: found.slot,
          title: data.labels[found.slot] ?? "",
          rows: [{name: series.name, value: String(call(config.tooltip.y?.formatter, found.value, {seriesIndex: found.series, dataPointIndex: found.slot, w: {config}}) ?? plain(found.value)), color: series.color}],
          anchor: {x: found.x, y: found.y},
          crosshair: null,
          markers: [{x: found.x, y: found.y, color: series.color, r: 6}],
          band: null,
          active: null,
          axisTip: null,
          yTip: null,
        }
      : null
  }
  return {data, legend, layers, defs: [], desc: seriesSummary(data), probe, layout}
}

/**
 * Builds the chart for `options` at `env.width` px: `{config, width, height, svg, legendHtml, legendStyle,
 * legend, probe, text}`. `env` carries `width`, the window `viewport` width (for responsive rules),
 * `measure(text, size)` for text widths, `uid` (a prefix for ids inside the SVG) and the indices of the
 * `hidden` series. `probe(x, y)` answers the pointer in SVG pixels with a tooltip description or `null`.
 */
export const build = (options, env) => {
  const config = configure(options, {viewport: env.viewport})
  const width = env.width
  const uid = env.uid ?? "chart"
  const full = {width, height: 0, measure: env.measure ?? estimateWidth, hidden: env.hidden ?? []}
  const height = heightOf(config, width)
  const sized = {...full, height}
  const parts = cartesian(config.type) ? axisBuild(config, sized, uid) : config.type === "radar" ? radarBuild(config, sized, uid) : circularBuild(config, sized)
  const finalHeight = parts.height ?? height
  const title = config.title?.text ?? TITLES[config.type] ?? "Chart"
  const svg = render(shell({width, height: finalHeight}, uid, title, parts.desc, parts.defs, parts.layers, config.type))
  return {config, width, height: finalHeight, svg, legend: parts.legend, legendHtml: legendHtml(parts.legend), legendStyle: legendStyle(parts.legend), table: tableHtml(title, {data: parts.data, slices: parts.slices}), probe: parts.probe, text: parts.text, slices: parts.slices, layout: parts.layout, drawn: parts.drawn, data: parts.data, g: parts.g}
}

