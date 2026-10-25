/**
 * The marks of a cartesian chart: lines and areas with their markers, columns and rows, range bars and
 * candles, and the data labels. Each mark that answers the pointer is also recorded as a `box`.
 */
import {colorAt, pick} from "./chart_config.js"
import {paintFor} from "./chart_defs.js"
import {areaPath, bandPath, barPath, columnPath, linePath, segments} from "./chart_paths.js"
import {plain} from "./chart_scale.js"
import {h} from "./chart_svg.js"

const CANDLE_COLORS = {upward: "#00B746", downward: "#EF403C"}

const call = (formatter, ...args) => (typeof formatter === "function" ? formatter(...args) : undefined)

const fraction = (spec, whole, stacked = false) =>
  typeof spec === "string" && spec.endsWith("px")
    ? parseFloat(spec)
    : typeof spec === "number" && !stacked
      ? spec
      : (parseFloat(spec) / 100) * whole

const pointsOf = (p, series, row) =>
  series.points.map((point) => {
    const cell = row?.[point.slot]
    const v = cell ? cell.to : point.value
    return v === null || v === undefined ? null : p.horizontal ? {x: p.along(v), y: p.at(point), slot: point.slot, v} : {x: p.at(point), y: p.along(v), slot: point.slot, v}
  })

const lowerPoints = (p, series, row) => series.points.map((point) => (row?.[point.slot] ? {x: p.at(point), y: p.along(row[point.slot].from), slot: point.slot} : null))

/** A line (or area) series: the area under it, the stroke, the markers. */
export const lineMark = (p, series, row, uid, defs) => {
  const {config, plot} = p
  const curve = pick(config.stroke.curve, series.index)
  const width = pick(config.stroke.width, series.index)
  const dash = pick(config.stroke.dashArray, series.index)
  const points = pointsOf(p, series, row)
  const base = Math.min(plot.y + plot.h, Math.max(plot.y, p.along(0)))
  const strokeColor = pick(config.stroke.colors, series.index) ?? series.color
  const gradientStroke = config.type === "line" && pick(config.fill.type, series.index) === "gradient"
  const stroke = gradientStroke
    ? paintFor(config, {index: series.index, color: pick(config.fill.colors, series.index) ?? series.color, key: `stroke${series.index}`, uid, defs, direction: {x1: 0, y1: 0, x2: 1, y2: 0}}).fill
    : strokeColor
  const area = config.type === "area" ? paintFor(config, {index: series.index, color: pick(config.fill.colors, series.index) ?? series.color, key: `area${series.index}`, uid, defs}) : null
  const lower = row ? segments(lowerPoints(p, series, row)) : []
  const shape = (run, index) => (row && lower[index] ? bandPath(run, lower[index], curve) : areaPath(run, base, curve))
  const markers = pick(config.markers.size, series.index)
  const markerColor = pick(config.markers.colors, series.index) ?? series.color
  return h(
    "g",
    {class: "linea-chart-series linea-chart-reveal", "data-series": series.index},
    area ? h("path", {class: "linea-chart-area", d: segments(points).map(shape).join(" "), fill: area.fill, "fill-opacity": area.opacity}) : null,
    config.stroke.show === false || !width
      ? null
      : h("path", {
          class: "linea-chart-line",
          d: linePath(points, curve),
          fill: "none",
          stroke,
          "stroke-width": width,
          "stroke-linecap": config.stroke.lineCap,
          "stroke-linejoin": "round",
          "stroke-dasharray": dash ? String(dash) : null,
          filter: config.chart.dropShadow?.enabled ? `url(#${uid}-shadow)` : null,
        }),
    markers > 0 ? points.filter(Boolean).map((point) => h("circle", {class: "linea-chart-marker", cx: point.x, cy: point.y, r: markers, fill: markerColor, "data-i": point.slot})) : null
  )
}

const barSizes = (p, perGroup) => {
  const spec = p.config.plotOptions.bar
  const group = Math.min(fraction(p.horizontal ? spec.barHeight : spec.columnWidth, p.cat.width, p.stacks !== null), p.cat.width)
  return {group, width: group / perGroup}
}

const barColor = (p, series, point) => {
  const {config} = p
  return config.plotOptions.bar.distributed ? (pick(config.fill.colors, point.slot) ?? colorAt(config, point.slot)) : (point.fill ?? pick(config.fill.colors, series.index) ?? series.color)
}

const stackEnds = (stacks, position, slot) => {
  const present = stacks.map((row, index) => (row[slot] && row[slot].to !== row[slot].from ? index : -1)).filter((index) => index >= 0)
  return {first: present[0] === position, last: present.at(-1) === position}
}

const barNode = (p, point, series, d, direction, uid, defs) => {
  const paint = paintFor(p.config, {index: series.index, color: barColor(p, series, point), key: `bar${series.index}-${point.slot}`, uid, defs})
  return h("path", {class: "linea-chart-bar", d, fill: paint.fill, "fill-opacity": paint.opacity, "data-series": series.index, "data-i": point.slot, "data-dir": direction, style: `--linea-chart-i:${point.slot}`})
}

const box = (p, series, point, start, size, from, to) => ({
  series: series.index,
  slot: point.slot,
  color: barColor(p, series, point),
  ...(p.horizontal ? {x: Math.min(from, to), y: start, w: Math.abs(to - from), h: size} : {x: start, y: Math.min(from, to), w: size, h: Math.abs(to - from)}),
})

const inset = (stroke, {from, to, start, size}) => {
  const half = stroke / 2
  const sign = Math.sign(to - from)
  return {from: from + sign * half, to: to - sign * half, start: start + half, size: Math.max(size - stroke, 0)}
}

const strokeOf = (config, series) => (config.stroke.show === false ? 0 : Number(pick(config.stroke.width, series.index)) || 0)

/** A bar series: columns (or rows), grouped, stacked or one per point. A stroke insets the bar, as in ApexCharts. */
export const barMark = (p, series, position, uid, defs, boxes) => {
  const {config, stacks, visible} = p
  const spec = config.plotOptions.bar
  const row = stacks?.[position]
  const single = stacks !== null || spec.distributed
  const {group, width} = barSizes(p, single ? 1 : visible.length)
  const offset = -group / 2 + (single ? 0 : position * width)
  const radius = Number(spec.borderRadius) || 0
  const zero = p.along(Math.min(Math.max(0, p.value.min), p.value.max))
  const stroke = strokeOf(config, series)
  const nodes = series.points.map((point) => {
    const cell = row?.[point.slot]
    const base = cell ? p.along(cell.from) : zero
    const end = cell ? p.along(cell.to) : point.value === null ? null : p.along(point.value)
    const solid = end !== null && Math.abs(end - base) > 0.01
    const {from, to, start, size} = solid ? inset(stroke, {from: base, to: end, start: p.across(point.slot) + offset, size: width}) : {}
    const ends = stacks ? stackEnds(stacks, position, point.slot) : spec.borderRadiusApplication === "end" ? "end" : "both"
    solid && boxes.push(box(p, series, point, start, size, from, to))
    const d = !solid ? null : p.horizontal ? barPath(start, from, to, size, radius, ends) : columnPath(start, from, to, size, radius, ends)
    return solid && barNode(p, point, series, d, p.horizontal ? (to >= from ? "right" : "left") : to <= from ? "up" : "down", uid, defs)
  })
  return h("g", {class: "linea-chart-series", "data-series": series.index}, nodes)
}

/** A range bar series: one bar between two values per point. */
export const rangeMark = (p, series, position, uid, defs, boxes) => {
  const {config, cat} = p
  const spec = config.plotOptions.bar
  const overlap = spec.rangeBarOverlap !== false
  const group = Math.min(fraction(spec.barHeight, cat.width), cat.width)
  const size = group / (overlap ? 1 : p.visible.length)
  const radius = Number(spec.borderRadius) || 0
  const nodes = series.points.map((point) => {
    const start = p.across(point.slot) - group / 2 + (overlap ? 0 : position * size)
    const [a, b] = [p.along(point.start), p.along(point.end)]
    const solid = point.start !== undefined
    solid && boxes.push(box(p, series, point, start, size, a, b))
    const d = !solid ? null : p.horizontal ? barPath(start, Math.min(a, b), Math.max(a, b), size, radius, "both") : columnPath(start, Math.max(a, b), Math.min(a, b), size, radius, "both")
    return solid && barNode(p, point, series, d, p.horizontal ? "right" : "up", uid, defs)
  })
  return h("g", {class: "linea-chart-series", "data-series": series.index}, nodes)
}

/** A candlestick series: a wick and a body per point, green when it closes up. */
export const candleMark = (p, series, boxes) => {
  const {config} = p
  const colors = {...CANDLE_COLORS, ...config.plotOptions.candlestick?.colors}
  const width = Math.min(fraction(config.plotOptions.bar.columnWidth, p.cat.width), p.cat.width)
  const strokeWidth = pick(config.stroke.width, series.index)
  const nodes = series.points.map((point) => {
    const solid = point.high !== undefined
    const x = p.across(point.slot)
    const [high, low, open, close] = solid ? [point.high, point.low, point.open, point.close].map((value) => p.along(value)) : []
    const color = point.close >= point.open ? colors.upward : colors.downward
    solid && boxes.push({series: series.index, slot: point.slot, x: x - width / 2, y: Math.min(high, low), w: width, h: Math.abs(low - high)})
    return (
      solid &&
      h(
        "g",
        {class: "linea-chart-candle", "data-i": point.slot, style: `--linea-chart-i:${point.slot}`},
        h("line", {x1: x, x2: x, y1: high, y2: low, stroke: color, "stroke-width": strokeWidth}),
        h("rect", {x: x - width / 2, y: Math.min(open, close), width, height: Math.max(Math.abs(close - open), 1), fill: color, stroke: color, "stroke-width": strokeWidth})
      )
    )
  })
  return h("g", {class: "linea-chart-series", "data-series": series.index}, nodes)
}

const anchors = (p, boxes) =>
  p.config.type === "bar"
    ? boxes.map((one) => ({...one, v: p.data.series.find((series) => series.index === one.series).points.find((point) => point.slot === one.slot).value, box: one}))
    : p.config.type === "line" || p.config.type === "area"
      ? p.visible.flatMap((series, position) =>
          pointsOf(p, series, p.stacks?.[position])
            .filter(Boolean)
            .map((point) => ({series: series.index, slot: point.slot, v: series.points.find((one) => one.slot === point.slot).value, x: point.x, y: point.y}))
        )
      : []

/** The data labels: on each bar (at its center, or its end with `position: "top"`) or above each point. */
export const dataLabels = (p, boxes) => {
  const {config} = p
  const size = parseFloat(config.dataLabels.style?.fontSize ?? 12)
  const top = config.plotOptions.bar.dataLabels.position === "top"
  const format = (value, meta) => String(call(config.dataLabels.formatter, value, meta) ?? plain(value))
  return config.dataLabels.enabled === false
    ? []
    : anchors(p, boxes).map(({series, slot, v, x, y, box: bar}) => {
        const at = bar
          ? {x: top && p.horizontal ? bar.x + bar.w - 10 : bar.x + bar.w / 2, y: top && !p.horizontal ? bar.y + 10 : bar.y + bar.h / 2}
          : {x, y: y - 10}
        return h(
          "text",
          {class: "linea-chart-datalabel", x: at.x + config.dataLabels.offsetX, y: at.y + config.dataLabels.offsetY, "text-anchor": "middle", "dominant-baseline": "central", "font-size": size},
          format(v, {seriesIndex: series, dataPointIndex: slot, w: {config}})
        )
      })
}
