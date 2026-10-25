/**
 * What the pointer finds on a cartesian chart: the slot or bar under it, the tooltip's title and rows, the
 * crosshair, the hover markers and the bubbles on the axes.
 */
import {pick} from "./chart_config.js"
import {datePattern, formatDate, plain} from "./chart_scale.js"

const call = (formatter, ...args) => (typeof formatter === "function" ? formatter(...args) : undefined)

const BAND_REACH = 4
const EDGE_REACH = 8

const inside = (box, x, y) => x >= box.x && x <= box.x + box.w && y >= box.y && y <= box.y + box.h

const clamp = (value, low, high) => Math.min(Math.max(value, low), high)

const barred = (config) => config.type === "bar" || config.type === "rangeBar"

const sharedOf = (config) => config.tooltip.shared === true || (!barred(config) && config.tooltip.intersect !== true && config.tooltip.shared !== false)

const slotAt = (p, x, y) => {
  const {plot, cat, horizontal} = p
  const along = horizontal ? y - plot.y : x - plot.x
  const span = horizontal ? plot.h : plot.w
  const across = horizontal ? x - plot.x : y - plot.y
  const wide = horizontal ? plot.w : plot.h
  const out = along < -BAND_REACH || along > span + BAND_REACH || across < -EDGE_REACH || across > wide + EDGE_REACH
  const index = cat.kind === "bands" ? Math.floor(along / cat.width) : Math.round(cat.count > 1 ? (along / span) * (cat.count - 1) : 0)
  return out ? null : clamp(index, 0, cat.count - 1)
}

const nearestSlot = (p, position) =>
  (p.visible[0]?.points ?? []).reduce((best, point) => {
    const distance = Math.abs(p.at(point) - position)
    return best === null || distance < best.distance ? {slot: point.slot, distance} : best
  }, null)?.slot ?? null

const pointAt = (series, slot) => series.points.find((point) => point.slot === slot)

const titleOf = (p, slot) => {
  const {config, data} = p
  const spec = config.tooltip.x ?? {}
  const point = data.series.map((series) => pointAt(series, slot)).find(Boolean)
  const raw = data.kind === "category" ? data.labels[slot] : point?.x
  const text = data.kind === "datetime" ? formatDate(raw, spec.format ?? datePattern(p.cat.span ?? 3 * 86400000)) : (data.labels[slot] ?? plain(raw))
  return spec.show === false ? "" : String(call(spec.formatter, raw, {}) ?? text)
}

const valueText = (p, series, point) => {
  const spec = pick(p.config.tooltip.y, series.index)
  const context = {series: p.data.series.map((one) => one.points.map((item) => item.value)), seriesIndex: series.index, dataPointIndex: point.slot, w: {config: p.config}}
  return String(call(spec?.formatter, point.value, context) ?? plain(point.value))
}

const nameText = (p, series, point) =>
  String(call(p.config.tooltip.y?.title?.formatter, series.name, {seriesIndex: series.index, dataPointIndex: point.slot}) ?? series.name)

const rangeText = (p, point) => {
  const format = (value) => (p.value.time ? formatDate(value, p.config.tooltip.x?.format ?? "dd MMM yyyy") : plain(value))
  return `${format(point.start)} - ${format(point.end)}`
}

const candleRows = (point) => [
  {name: "Open", value: plain(point.open), color: null},
  {name: "High", value: plain(point.high), color: null},
  {name: "Low", value: plain(point.low), color: null},
  {name: "Close", value: plain(point.close), color: null},
]

const rowsFor = (p, series, point) =>
  point.high !== undefined
    ? candleRows(point)
    : point.start !== undefined
      ? [{name: series.name, value: rangeText(p, point), color: series.color, series: series.index}]
      : point.value === null || point.value === undefined
        ? []
        : [{name: nameText(p, series, point), value: valueText(p, series, point), color: series.color, series: series.index}]

const rowsAt = (p, slot, only) =>
  p.visible
    .filter((series) => only === null || series.index === only)
    .flatMap((series) => {
      const point = pointAt(series, slot)
      return point ? rowsFor(p, series, point) : []
    })

const markerRadius = (config, series) => {
  const size = pick(config.markers.size, series.index) || 0
  return pick(config.markers.hover?.size, series.index) ?? size + (config.markers.hover?.sizeOffset ?? 3)
}

const markersAt = (p, slot, where) =>
  p.visible.flatMap((series, position) => {
    const point = pointAt(series, slot)
    const cell = p.stacks?.[position]?.[slot]
    const value = cell ? cell.to : point?.value
    return point && value !== null && value !== undefined ? [{x: where, y: p.along(value), color: series.color, r: markerRadius(p.config, series)}] : []
  })

const bandAt = (p, where) =>
  p.horizontal ? {x: p.plot.x, y: where - p.cat.width / 2, w: p.plot.w, h: p.cat.width} : {x: where - p.cat.width / 2, y: p.plot.y, w: p.cat.width, h: p.plot.h}

const crosshairAt = (p, where) =>
  p.horizontal ? {x1: p.plot.x, x2: p.plot.x + p.plot.w, y1: where, y2: where} : {x1: where, x2: where, y1: p.plot.y, y2: p.plot.y + p.plot.h}

const yTipAt = (p, y) => {
  const {plot, value} = p
  const level = value.min + ((plot.y + plot.h - y) / plot.h) * (value.max - value.min)
  return p.config.yaxis.tooltip?.enabled && !p.horizontal && y >= plot.y && y <= plot.y + plot.h
    ? {x: plot.x, y, text: String(value.text(Number(level.toFixed(value.decimals))))}
    : null
}

/**
 * The reaction to the pointer at `(x, y)` (SVG pixels) given the `boxes` of the bars: `null` when it is over
 * nothing, else `{slot, title, rows, anchor, crosshair, markers, band, active, axisTip, yTip}`.
 */
export const hover = (p, boxes, x, y) => {
  const {config, plot, horizontal} = p
  const shared = sharedOf(config)
  const single = barred(config) && !shared
  const box = single ? (boxes.find((one) => inside(one, x, y)) ?? null) : null
  const slot = single ? (box?.slot ?? null) : p.cat.timed ? nearestSlot(p, horizontal ? y : x) : slotAt(p, x, y)
  const rows = slot === null ? [] : rowsAt(p, slot, box ? box.series : null).map((row) => (box && row.color ? {...row, color: box.color} : row))
  const where = slot === null ? 0 : p.across(slot)
  const line = !barred(config) && config.xaxis.crosshairs?.show !== false
  const band = barred(config) && shared ? bandAt(p, where) : null
  const tip = config.xaxis.tooltip?.enabled !== false && (line || band) && config.type !== "bar"
  return rows.length === 0
    ? null
    : {
        slot,
        title: titleOf(p, slot),
        rows,
        anchor: box ? {x: box.x + box.w / 2, y: horizontal ? box.y + box.h / 2 : box.y} : horizontal ? {x, y: where} : {x: where, y},
        crosshair: line ? crosshairAt(p, where) : null,
        markers: line && (config.type === "line" || config.type === "area") ? markersAt(p, slot, where) : [],
        band,
        active: box ? {series: box.series, slot} : null,
        axisTip: tip ? {x: where, y: plot.y + plot.h, text: titleOf(p, slot)} : null,
        yTip: yTipAt(p, y),
      }
}
