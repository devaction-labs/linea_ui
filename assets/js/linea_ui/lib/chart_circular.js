/**
 * Pie, donut and radial bar charts: where the circle goes (with ApexCharts' margins, so options tuned for
 * it land the same), its slices or rings drawn as stroked arcs that sweep in, the labels in the middle and
 * the hit test for slices.
 */
import {colorAt, pick} from "./chart_config.js"
import {arcPath, polar} from "./chart_paths.js"
import {plain} from "./chart_scale.js"
import {h} from "./chart_svg.js"

const LEGEND_ROW = 24
const LEGEND_MARGIN = 10
const SIDE_GAP = 25
const SWEEP = 900
const MIN_LABEL_ANGLE = 10

const call = (formatter, ...args) => (typeof formatter === "function" ? formatter(...args) : undefined)

const percent = (spec, whole) => (parseFloat(spec) / 100) * whole

export const radial = (type) => type === "radialBar"

/** The slices or rings of the chart: `{index, name, value, color, hidden}`. */
export const slicesOf = (config, hidden = []) =>
  (Array.isArray(config.series) ? config.series : []).map((value, index) => ({
    index,
    name: String(config.labels?.[index] ?? `Series ${index + 1}`),
    value: Number.isFinite(Number(value)) ? Number(value) : 0,
    color: colorAt(config, index),
    hidden: hidden.includes(index),
  }))

const sparkOf = (config) => config.chart.sparkline.enabled

const blur = (config) => (sparkOf(config) ? 0 : (config.chart.dropShadow?.blur ?? 4))

const angles = (config) => (radial(config.type) ? config.plotOptions.radialBar : config.plotOptions.pie)

const legendRoom = (legend) => (legend.items.length > 0 ? legend.rows * LEGEND_ROW + LEGEND_MARGIN : 0)

/**
 * Where the circle sits: `{cx, cy, size, extent, height}`. `size` is ApexCharts' base radius for the chart,
 * `extent` its span (a half circle needs half the height) and `height` the height the SVG ends up with.
 */
export const geometry = (config, {width, height, legend}) => {
  const pad = config.grid.padding
  const spec = angles(config)
  const placed = legend.items.length > 0
  const beside = placed && (legend.position === "left" || legend.position === "right")
  const room = legendRoom(legend)
  const gridH = height - pad.top - pad.bottom - (placed && !beside ? room : 0)
  const wide = width - pad.left - pad.right
  const gridW = beside ? wide - legend.width - SIDE_GAP + (legend.position === "right" ? -5 : 0) : placed ? wide : Math.min(wide, gridH)
  const offX = spec.offsetX ?? 0
  const offY = spec.offsetY ?? 0
  const tx = pad.left + offX + (beside ? (legend.position === "right" ? 10 : legend.width + 20) : placed ? 0 : (wide - gridW) / 2)
  const ty = pad.top + offY + (legend.position === "bottom" && placed ? -10 : legend.position === "top" && placed ? room + 10 : 0)
  const base = Math.min(gridW, gridH)
  const spark = sparkOf(config)
  const size = (base / 2.05 - (spark ? 0 : Number(config.stroke.width ?? 0)) - blur(config)) * (spec.customScale ?? 1)
  const total = radial(config.type) && Number(spec.startAngle) < 0 ? Math.abs(spec.endAngle - spec.startAngle) : 360
  const ratio = (360 - total) / 360
  const extent = size - size * ratio
  const tail = legend.position === "top" || legend.position === "bottom" ? room + 7 : 0
  const bottom = (spark ? 1 : 15) + pad.bottom
  const fitted = Math.ceil(extent * 2.05 + ty + tail + bottom)
  return {cx: tx + gridW / 2, cy: ty + base / 2, size, extent, height: placed && beside ? height : Math.max(fitted, 1), gridW, gridH}
}

const sweep = (delay, duration, ease) => `--linea-chart-delay:${Math.round(delay)}ms;--linea-chart-dur:${Math.round(duration)}ms;--linea-chart-ease:${ease}`

const arcNode = (cls, d, color, width, attrs = {}) =>
  h("path", {class: cls, d, fill: "none", stroke: color, "stroke-width": width, pathLength: 100, "stroke-dasharray": 100, ...attrs})

const centerNodes = (config, g, items, spec) => {
  const x = g.cx
  const total = spec.total?.show === true
  const anchor = spec.total?.label ? g.cy : g.cy - g.cy / 6
  const label = total ? spec.total : spec.name
  const name = (text) =>
    spec.name?.show !== false
      ? h("text", {class: "linea-chart-center-label", "data-center": "name", x, y: anchor + Number(spec.name?.offsetY ?? 0), "text-anchor": "middle", "font-size": parseFloat(label?.fontSize ?? 16), "font-weight": label?.fontWeight ?? 600, fill: label?.color}, text)
      : null
  const value = (text) =>
    spec.value?.show !== false
      ? h("text", {class: "linea-chart-center-value", "data-center": "value", x, y: anchor + Number(spec.value?.offsetY ?? 16) + (spec.name?.show !== false ? 16 : 0), "text-anchor": "middle", "font-size": parseFloat(spec.value?.fontSize ?? 14), "font-weight": spec.value?.fontWeight ?? 400, fill: spec.value?.color}, text)
      : null
  return h("g", {class: "linea-chart-center", opacity: items.opacity}, name(items.name), value(items.value))
}

const world = (config, slices) => ({
  config,
  globals: {series: slices.map((slice) => slice.value), seriesTotals: slices.map((slice) => slice.value), seriesNames: slices.map((slice) => slice.name), labels: slices.map((slice) => slice.name)},
})

/** The `{name, value, opacity}` the middle of a donut or radial chart reads when nothing is hovered. */
export const centerText = (config, slices) => {
  const radialType = radial(config.type)
  const labels = radialType ? config.plotOptions.radialBar.dataLabels : config.plotOptions.pie.donut.labels
  const total = labels.total ?? {}
  const live = slices.filter((slice) => !slice.hidden)
  const w = world(config, live)
  const sum = live.reduce((acc, slice) => acc + slice.value, 0)
  const single = live.length === 1
  const format = labels.value?.formatter
  const value = total.show ? (call(total.formatter, w) ?? plain(sum)) : single ? (call(format, live[0].value, w) ?? (radialType ? `${live[0].value}%` : plain(live[0].value))) : ""
  const name = total.show ? (total.label ?? "") : single ? live[0].name : ""
  const shown = radialType ? total.show || live.length === 1 : labels.show === true
  return {spec: labels, name: String(call(labels.name?.formatter, name, total.show, w) ?? name), value: String(value), opacity: shown ? 1 : 0, show: labels.show !== false}
}

/** The center text for a hovered slice. */
export const hoverText = (config, slice, slices) => {
  const labels = radial(config.type) ? config.plotOptions.radialBar.dataLabels : config.plotOptions.pie.donut.labels
  const w = world(config, slices.filter((one) => !one.hidden))
  const value = call(labels.value?.formatter, slice.value, w) ?? (radial(config.type) ? `${slice.value}%` : plain(slice.value))
  return {name: String(call(labels.name?.formatter, slice.name, false, w) ?? slice.name), value: String(value)}
}

const donutDraw = (config, g, slices) => {
  const spec = config.plotOptions.pie
  const live = slices.filter((slice) => !slice.hidden)
  const total = live.reduce((sum, slice) => sum + Math.max(slice.value, 0), 0)
  const span = Math.abs(spec.endAngle - spec.startAngle)
  const hole = config.type === "pie" ? 0 : percent(spec.donut.size, g.size)
  const arcs = live.reduce((done, slice) => {
    const share = total > 0 ? Math.max(slice.value, 0) / total : 0
    const a0 = done.length === 0 ? spec.startAngle : done.at(-1).a1
    const before = done.reduce((sum, arc) => sum + arc.share, 0)
    return [...done, {index: slice.index, share, a0, a1: a0 + share * span, before, inner: hole, outer: g.size, name: slice.name, value: slice.value, color: slice.color}]
  }, [])
  const nodes = arcs.map((arc) =>
    arc.share > 0
      ? arcNode("linea-chart-arc linea-chart-slice", arcPath(g.cx, g.cy, (g.size + hole) / 2, arc.a0, arc.a1), arc.color, g.size - hole, {
          style: sweep(arc.before * SWEEP, arc.share * SWEEP, "linear"),
          "data-series": arc.index,
          "stroke-opacity": pick(config.fill.opacity, arc.index),
        })
      : null
  )
  const labels = config.dataLabels.enabled === false ? [] : arcs.filter((arc) => arc.share * span >= MIN_LABEL_ANGLE).map((arc) => sliceLabel(config, g, arc, hole, world(config, live)))
  return {nodes, arcs, labels, hole}
}

const sliceLabel = (config, g, arc, hole, w) => {
  const radius = config.type === "pie" ? g.size / 1.25 : (g.size + hole) / 2
  const at = polar(g.cx, g.cy, radius + Number(config.plotOptions.pie.dataLabels?.offset ?? 0), (arc.a0 + arc.a1) / 2)
  const text = call(config.dataLabels.formatter, arc.share * 100, {seriesIndex: arc.index, w}) ?? `${(arc.share * 100).toFixed(1)}%`
  return h(
    "text",
    {class: "linea-chart-slice-label", x: at.x + config.dataLabels.offsetX, y: at.y + config.dataLabels.offsetY, "text-anchor": "middle", "dominant-baseline": "central", "font-size": parseFloat(config.dataLabels.style?.fontSize ?? 12)},
    String(text)
  )
}

const radialDraw = (config, g, slices) => {
  const spec = config.plotOptions.radialBar
  const margin = Number(spec.track.margin)
  const count = slices.length
  const stroke = (g.size * (100 - parseFloat(spec.hollow.size))) / 100 / (count + 1) - margin
  const total = Math.abs(spec.endAngle - spec.startAngle)
  const trackFrom = spec.track.startAngle ?? spec.startAngle
  const trackTo = spec.track.endAngle ?? spec.endAngle
  const capped = (angle) => (Math.abs(angle) + Math.abs(spec.startAngle) >= 360 ? angle - 0.01 : angle)
  const rings = slices.map((slice, position) => ({slice, position, radius: g.size - stroke / 2 - (position + 1) * (stroke + margin)}))
  const tracks = spec.track.show === false ? [] : rings.map((ring) => arcNode("linea-chart-track", arcPath(g.cx, g.cy, ring.radius, trackFrom, trackTo >= 360 ? trackTo - 0.01 : trackTo), null, (stroke * parseFloat(spec.track.strokeWidth)) / 100, {"stroke-opacity": spec.track.opacity, "stroke-linecap": config.stroke.lineCap === "butt" ? "butt" : config.stroke.lineCap, "pathLength": null, "stroke-dasharray": null}))
  const arcs = rings.map((ring) => {
    const value = Math.min(Math.max(ring.slice.value, 0), 100) / 100
    const end = capped(Math.round(total * value) + spec.startAngle)
    return ring.slice.hidden || value === 0
      ? null
      : arcNode("linea-chart-arc linea-chart-ring", arcPath(g.cx, g.cy, ring.radius, spec.startAngle, end), pick(config.fill.colors, ring.slice.index) ?? ring.slice.color, stroke, {
          "stroke-linecap": config.stroke.lineCap,
          "stroke-opacity": pick(config.fill.opacity, ring.slice.index),
          "data-series": ring.slice.index,
          style: sweep(ring.position * 120, SWEEP, "cubic-bezier(0.22,0.61,0.36,1)"),
        })
  })
  const hollow = g.size - stroke / 2 - count * (stroke + margin) - (stroke * parseFloat(spec.track.strokeWidth)) / 200 - Number(spec.hollow.margin)
  return {nodes: arcs, tracks, rings, hollow, stroke}
}

/** The SVG layers of a circular chart and what the pointer can hit: `{layers, hits, center}`. */
export const drawCircular = (config, g, slices) => {
  const live = slices.filter((slice) => !slice.hidden)
  const radialType = radial(config.type)
  const drawn = radialType ? radialDraw(config, g, live) : donutDraw(config, g, live)
  const text = centerText(config, slices)
  const center = text.show && (radialType || config.type === "donut") ? centerNodes(config, g, text, text.spec) : null
  return {
    layers: {tracks: radialType ? drawn.tracks : [], series: drawn.nodes, labels: radialType ? [] : drawn.labels, center},
    hits: radialType ? [] : drawn.arcs,
    text,
    hole: drawn.hollow ?? drawn.hole,
  }
}

const normalized = (angle) => ((angle % 360) + 360) % 360

/** The slice under `(x, y)`, or `null`. */
export const sliceAt = (hits, g, x, y) => {
  const dx = x - g.cx
  const dy = y - g.cy
  const radius = Math.hypot(dx, dy)
  const angle = normalized((Math.atan2(dy, dx) * 180) / Math.PI + 90)
  return (
    hits.find((arc) => {
      const start = normalized(arc.a0)
      const span = arc.a1 - arc.a0
      return arc.share > 0 && radius >= arc.inner && radius <= arc.outer && normalized(angle - start) <= span
    }) ?? null
  )
}
