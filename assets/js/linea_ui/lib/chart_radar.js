/**
 * Radar charts: the rings and spokes, the category labels around them, the value labels up the first
 * spoke and one filled polygon per series, laid out like ApexCharts lays them out.
 */
import {colorAt, pick} from "./chart_config.js"
import {polygonPath} from "./chart_paths.js"
import {niceScale, plain} from "./chart_scale.js"
import {h} from "./chart_svg.js"

const call = (formatter, ...args) => (typeof formatter === "function" ? formatter(...args) : undefined)

const SIDE = 2
const TOP = 30
const BOTTOM = 5
const LABEL_OFFSET = 10

const vertices = (radius, count) => Array.from({length: count}, (_, index) => ({x: radius * Math.sin((index * 2 * Math.PI) / count), y: -radius * Math.cos((index * 2 * Math.PI) / count)}))

/**
 * The geometry of a radar chart: `{cx, cy, size, ticks, count, domain}`; `ticks` are the values of the
 * rings, `count` the spokes.
 */
export const radarPlan = (config, data, {width, height, legend, measure}) => {
  const pad = config.grid.padding
  const visible = data.series.filter((series) => !series.hidden)
  const count = Math.max(data.count, 0)
  const values = visible.flatMap((series) => series.points.map((point) => point.value)).filter((value) => value !== null)
  const scale = niceScale(Math.min(0, ...values), Math.max(...values, 0), {size: height, limits: {min: config.yaxis.min, max: config.yaxis.max, tickAmount: config.yaxis.tickAmount}})
  const top = TOP + pad.top + (legend.position === "top" ? legend.height : 0)
  const bottom = BOTTOM + pad.bottom + (legend.position === "bottom" ? legend.height : 0)
  const plot = {x: SIDE + pad.left, y: top, w: width - 2 * SIDE - pad.left - pad.right - (legend.position === "left" || legend.position === "right" ? legend.width : 0), h: height - top - bottom}
  const base = height < width ? plot.h : plot.w
  const labelFont = parseFloat(config.xaxis.labels?.style?.fontSize ?? 11)
  const widest = config.xaxis.labels?.show === false ? 0 : Math.max(0, ...Array.from({length: count}, (_, slot) => measure(data.labels[slot] ?? "", labelFont)))
  const size = config.plotOptions.radar.size ?? base / 2.1 - Number(config.stroke.width ?? 0) - Number(config.chart.dropShadow?.blur ?? 4) - widest / 1.75
  return {cx: plot.x + plot.w / 2 + (config.plotOptions.radar.offsetX ?? 0) + (legend.position === "left" ? legend.width : 0), cy: plot.y + plot.h / 2 + (config.plotOptions.radar.offsetY ?? 0), size, ticks: scale.ticks, count, domain: [scale.min, scale.max], visible, labelFont}
}

const anchorOf = (point, size) => {
  const side = Math.abs(point.x) >= LABEL_OFFSET ? (point.x > 0 ? "start" : "end") : "middle"
  const shift = Math.abs(point.y) >= size - LABEL_OFFSET ? Math.sign(point.y) * LABEL_OFFSET : 0
  return {anchor: side, x: point.x + (side === "start" ? LABEL_OFFSET : side === "end" ? -LABEL_OFFSET : 0), y: point.y + shift}
}

/** The SVG for a radar plan: `{layers, hits}`; `hits` are the vertices the pointer can find. */
export const drawRadar = (config, p, data) => {
  const {cx, cy, size, ticks, count, domain, visible} = p
  const range = Math.abs(domain[1] - domain[0]) || 1
  const rings = ticks.map((_, index) => (size / Math.max(ticks.length - 1, 1)) * index).reverse()
  const polygons = rings.map((radius) => h("path", {class: "linea-chart-polygon", d: polygonPath(vertices(radius, count).map((point) => ({x: cx + point.x, y: cy + point.y})))}))
  const spokes = vertices(size, count).map((point) => h("line", {class: "linea-chart-spoke", x1: cx, y1: cy, x2: cx + point.x, y2: cy + point.y}))
  const names = config.xaxis.labels?.show === false
    ? []
    : vertices(size, count).map((point, slot) => {
        const spot = anchorOf(point, size)
        const text = call(config.xaxis.labels?.formatter, data.labels[slot] ?? "", {seriesIndex: -1, dataPointIndex: slot}) ?? data.labels[slot] ?? ""
        return h("text", {class: "linea-chart-radar-label", fill: pick(config.xaxis.labels?.style?.colors, slot) ?? "#a8a8a8", x: cx + spot.x, y: cy + spot.y, "text-anchor": spot.anchor, "dominant-baseline": "central", "font-size": p.labelFont}, String(text))
      })
  const axis = config.yaxis.show === false ? [] : ticks.slice().reverse().map((tick, index) => h("text", {class: "linea-chart-radar-value", x: cx + (config.yaxis.labels?.offsetX ?? 0), y: cy - rings[index] + (config.yaxis.labels?.offsetY ?? 6), "text-anchor": "middle", "font-size": 11}, String(call(config.yaxis.labels?.formatter, tick, index) ?? plain(tick))))
  const hits = []
  const shapes = visible.map((series) => {
    const points = Array.from({length: count}, (_, slot) => {
      const value = series.points.find((point) => point.slot === slot)?.value ?? 0
      const radius = (((value ?? 0) - domain[0]) / range) * size
      return {x: cx + radius * Math.sin((slot * 2 * Math.PI) / count), y: cy - radius * Math.cos((slot * 2 * Math.PI) / count), slot, value, series: series.index, color: series.color}
    })
    hits.push(...points)
    const width = pick(config.stroke.width, series.index)
    const fill = pick(config.fill.colors, series.index) ?? series.color
    const marker = pick(config.markers.size, series.index)
    return h(
      "g",
      {class: "linea-chart-series linea-chart-pop", "data-series": series.index},
      h("path", {class: "linea-chart-area", d: polygonPath(points), fill, "fill-opacity": pick(config.fill.opacity, series.index), stroke: "none"}),
      width ? h("path", {class: "linea-chart-line", d: polygonPath(points), fill: "none", stroke: pick(config.stroke.colors, series.index) ?? series.color, "stroke-width": width, "stroke-linejoin": "round"}) : null,
      marker > 0 ? points.map((point) => h("circle", {class: "linea-chart-marker", cx: point.x, cy: point.y, r: marker, fill: pick(config.markers.colors, series.index) ?? series.color})) : null
    )
  })
  const labels = config.dataLabels.enabled
    ? hits.map((point) => h("text", {class: "linea-chart-datalabel", x: point.x, y: point.y - 8, "text-anchor": "middle", "font-size": parseFloat(config.dataLabels.style?.fontSize ?? 11)}, String(call(config.dataLabels.formatter, point.value, {seriesIndex: point.series, dataPointIndex: point.slot}) ?? plain(point.value))))
    : []
  return {layers: {grid: [polygons, spokes], axes: [names, axis], series: shapes, labels}, hits}
}

/** The vertex nearest to `(x, y)` within `reach` pixels, or `null`. */
export const vertexAt = (hits, x, y, reach = 14) =>
  hits.reduce((best, point) => {
    const distance = Math.hypot(point.x - x, point.y - y)
    return distance <= reach && (best === null || distance < best.distance) ? {point, distance} : best
  }, null)?.point ?? null
