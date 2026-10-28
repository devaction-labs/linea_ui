/**
 * From options to markup: reads the configuration, lays the chart out for a width and draws it as an SVG
 * string, with the legend, the text alternative and the function that answers the pointer.
 */
import {draw, plan} from "./chart_cartesian.js"
import {drawCircular, geometry, hoverText, radial, sliceAt, slicesOf} from "./chart_circular.js"
import {cartesian, configure, heightOf, pick} from "./chart_config.js"
import {hover, slotPoint, slotsOf} from "./chart_hover.js"
import {legendBox, legendHtml, legendStyle} from "./chart_legend.js"
import {drawRadar, radarPlan, vertexAt} from "./chart_radar.js"
import {polar} from "./chart_paths.js"
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
  return {data, legend, layers, defs: drawn.defs, desc: seriesSummary(data), probe: (x, y) => hover(layout, drawn.boxes, x, y), keys: {slots: slotsOf(layout), at: (slot) => slotPoint(layout, slot)}, layout, drawn}
}

const circularHit = (config, slices, arc, at) => {
  const live = slices.filter((slice) => !slice.hidden)
  const total = live.reduce((sum, slice) => sum + slice.value, 0)
  const formatted = String(call(pick(config.tooltip.y, arc.index)?.formatter ?? config.tooltip.y?.formatter, arc.value, {seriesIndex: arc.index, w: {config}}) ?? plain(arc.value))
  return config.tooltip.enabled !== false
    ? {
        slot: arc.index,
        title: "",
        rows: [{name: arc.name, value: formatted, color: config.tooltip.fillSeriesColor ? null : arc.color}],
        anchor: at,
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

const circularProbe = (config, g, slices, drawn) => (x, y) => {
  const arc = radial(config.type) ? null : sliceAt(drawn.hits, g, x, y)
  return arc ? circularHit(config, slices, arc, {x, y}) : null
}

/** The keyboard's way around a pie or donut: the slices with a share, each visited at the middle of its arc. */
const circularKeys = (config, g, slices, drawn) => {
  const arcs = radial(config.type) ? [] : drawn.hits.filter((arc) => arc.share > 0)
  return {
    slots: arcs.map((arc) => arc.index),
    at: (slot) => {
      const arc = arcs.find((one) => one.index === slot)
      return polar(g.cx, g.cy, (arc.inner + arc.outer) / 2, (arc.a0 + arc.a1) / 2)
    },
    hit: (slot) => {
      const arc = arcs.find((one) => one.index === slot)
      return arc ? circularHit(config, slices, arc, polar(g.cx, g.cy, (arc.inner + arc.outer) / 2, (arc.a0 + arc.a1) / 2)) : null
    },
  }
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
  return {legend, layers, defs: [], desc: sliceSummary(slices), probe: circularProbe(config, g, slices, drawn), keys: circularKeys(config, g, slices, drawn), height: g.height, text: drawn.text, slices, g}
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
  const hitFor = (found) => {
    const series = data.series.find((one) => one.index === found.series)
    return {
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
  }
  const probe = (x, y) => {
    const found = config.tooltip.enabled === false ? null : vertexAt(drawn.hits, x, y)
    return found ? hitFor(found) : null
  }
  // The keyboard visits the spokes; the tooltip names the spoke and lists every visible series on it.
  const keys = {
    slots: layout.visible.length > 0 ? Array.from({length: layout.count}, (_, slot) => slot) : [],
    at: (slot) => drawn.hits.find((point) => point.slot === slot) ?? {x: layout.cx, y: layout.cy},
    hit: (slot) => {
      const found = drawn.hits.filter((point) => point.slot === slot)
      const [first] = found
      return config.tooltip.enabled === false || !first
        ? null
        : {
            ...hitFor(first),
            rows: found.map((point) => hitFor(point).rows[0]),
            markers: found.map((point) => ({x: point.x, y: point.y, color: point.color, r: 6})),
          }
    },
  }
  return {data, legend, layers, defs: [], desc: seriesSummary(data), probe, keys, layout}
}

/**
 * Builds the chart for `options` at `env.width` px: `{config, width, height, svg, legendHtml, legendStyle,
 * legend, probe, text}`. `env` carries `width`, the window `viewport` width (for responsive rules),
 * `measure(text, size)` for text widths, `uid` (a prefix for ids inside the SVG) and the indices of the
 * `hidden` series. `probe(x, y)` answers the pointer in SVG pixels with a tooltip description or `null`; `keys` lists the `slots` a keyboard visits (the slots of a cartesian chart, the slices of a pie or donut, the spokes of a radar) and `at(slot)` where each is; `keys.hit(slot)`, when present, answers a slot as the pointer would.
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
  return {config, width, height: finalHeight, svg, legend: parts.legend, legendHtml: legendHtml(parts.legend), legendStyle: legendStyle(parts.legend), table: tableHtml(title, {data: parts.data, slices: parts.slices}), probe: parts.probe, keys: parts.keys ?? null, text: parts.text, slices: parts.slices, layout: parts.layout, drawn: parts.drawn, data: parts.data, g: parts.g}
}

