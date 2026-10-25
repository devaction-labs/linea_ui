/**
 * What the pointer finds on a cartesian chart: the slot or bar under it, the tooltip's title and rows, the
 * crosshair, the hover markers and the bubbles on the axes.
 */
import {pick} from "./chart_config.js"
import {datePattern, formatDate, plain} from "./chart_scale.js"

const call = (formatter, ...args) => (typeof formatter === "function" ? formatter(...args) : undefined)

const inside = (box, x, y) => x >= box.x && x <= box.x + box.w && y >= box.y && y <= box.y + box.h

const sharedOf = (config) => config.tooltip.shared === true || (config.type !== "bar" && config.type !== "rangeBar" && config.tooltip.intersect !== true && config.tooltip.shared !== false)

const clamp = (value, low, high) => Math.min(Math.max(value, low), high)

const slotAt = (p, x, y) => {
  const {plot, cat, horizontal} = p
  const along = horizontal ? y - plot.y : x - plot.x
  const span = horizontal ? plot.h : plot.w
  const out = along < -4 || along > span + 4 || (horizontal ? x < plot.x - 4 || x > plot.x + plot.w + 4 : y < plot.y - 8 || y > plot.y + plot.h + 8)
  const slot =
    cat.kind === "bands"
      ? clamp(Math.floor(along / cat.width), 0, cat.count - 1)
      : cat.timed
        ? null
        : clamp(Math.round(cat.count > 1 ? (along / span) * (cat.count - 1) : 0), 0, cat.count - 1)
  return out ? null : slot
}

const nearestTimed = (p, x) => {
  const series = p.visible[0]
  const points = series?.points ?? []
  const best = points.reduce((found, point) => {
    const distance = Math.abs(p.across(point.slot) - x)
    return found === null || distance < found.distance ? {slot: point.slot, distance} : found
  }, null)
  return best?.slot ?? null
}

const titleOf = (p, slot) => {
  const {config, data} = p
  const first = data.series.find((series) => series.points.some((point) => point.slot === slot))?.points.find((point) => point.slot === slot)
  const raw = data.kind === "category" ? data.labels[slot] : first?.x
  const formatter = config.tooltip.x?.formatter
  const text = data.kind === "datetime" ? formatDate(raw, config.tooltip.x?.format ?? datePattern(p.cat.span ?? 86400000 * 3)) : data.labels[slot] ?? plain(raw)
  return config.tooltip.x?.show === false ? "" : String(call(formatter, raw, {}) ?? text)
}

const valueText = (p, series, point, extra = {}) => {
  const {config} = p
  const formatter = pick(config.tooltip.y, series.index)?.formatter ?? config.tooltip.y?.formatter
  return String(call(formatter, point.value, {series: p.data.series.map((s) => s.points.map((q) => q.value)), seriesIndex: series.index, dataPointIndex: point.slot, w: {config}, ...extra}) ?? plain(point.value))
}

const nameText = (p, series, point) => {
  const formatter = p.config.tooltip.y?.title?.formatter
  return String(call(formatter, series.name, {seriesIndex: series.index, dataPointIndex: point.slot}) ?? series.name)
}

const rowsAt = (p, slot) =>
  p.visible.flatMap((series) => {
    const point = series.points.find((one) => one.slot === slot)
    return !point
      ? []
      : point.high !== undefined
        ? [
            {name: "Open", value: plain(point.open), color: null},
            {name: "High", value: plain(point.high), color: null},
            {name: "Low", value: plain(point.low), color: null},
            {name: "Close", value: plain(point.close), color: null},
          ]
        : point.start !== undefined
          ? [{name: series.name, value: rangeText(p, point), color: point.fill ?? series.color, label: point.label}]
          : point.value === null || point.value === undefined
            ? []
            : [{name: nameText(p, series, point), value: valueText(p, series, point), color: series.color, series: series.index}]
  })

const rangeText = (p, point) => {
  const time = p.value.time
  const format = (value) => (time ? formatDate(value, p.config.tooltip.x?.format ?? "dd MMM yyyy") : plain(value))
  return `${format(point.start)} - ${format(point.end)}`
}

const markerRadius = (config, series) => {
  const size = pick(config.markers.size, series.index) || 0
  const hover = pick(config.markers.hover?.size, series.index)
  return hover ?? size + (config.markers.hover?.sizeOffset ?? 3)
}

const slotPosition = (p, slot) => p.across(slot)

const boxAt = (boxes, x, y) => boxes.find((box) => inside(box, x, y)) ?? null

/**
 * The reaction to the pointer at `(x, y)` (SVG pixels): `null` when it is over nothing, else
 * `{title, rows, anchor, crosshair, markers, band, active, axisTips}`.
 */
export const hover = (p, boxes, x, y) => {
  const {config, plot, horizontal} = p
  const shared = sharedOf(config)
  const bars = config.type === "bar" || config.type === "rangeBar"
  const box = bars && !shared ? boxAt(boxes, x, y) : null
  const slot = bars && !shared ? box?.slot ?? null : p.cat.timed ? nearestTimed(p, horizontal ? y : x) : slotAt(p, x, y)
  const rows = slot === null ? [] : rowsAt(p, slot).filter((row) => !box || row.series === box.series || row.series === undefined)
  const only = box && bars ? rows.filter((row) => row.series === box.series || row.series === undefined) : rows
  const where = slot === null ? 0 : slotPosition(p, slot)
  const line = !bars && slot !== null && config.xaxis.crosshairs?.show !== false
  const band = bars && shared && slot !== null ? (horizontal ? {x: plot.x, y: where - p.cat.width / 2, w: plot.w, h: p.cat.width} : {x: where - p.cat.width / 2, y: plot.y, w: p.cat.width, h: plot.h}) : null
  const axisTip = slot !== null && config.xaxis.tooltip?.enabled !== false && (line || band) && config.type !== "bar" ? {x: where, y: plot.y + plot.h, text: titleOf(p, slot)} : null
  return slot === null || only.length === 0
    ? null
    : {
        slot,
        title: titleOf(p, slot),
        rows: only,
        anchor: {x: box ? box.x + box.w / 2 : horizontal ? x : where, y: box ? (horizontal ? box.y + box.h / 2 : box.y) : horizontal ? where : y},
        crosshair: line ? (horizontal ? {x1: plot.x, x2: plot.x + plot.w, y1: where, y2: where} : {x1: where, x2: where, y1: plot.y, y2: plot.y + plot.h}) : null,
        markers: line && (config.type === "line" || config.type === "area") ? p.visible.flatMap((series, position) => {
          const point = series.points.find((one) => one.slot === slot)
          const cell = p.stacks?.[position]?.[slot]
          const v = cell ? cell.to : point?.value
          return point && v !== null && v !== undefined ? [{x: where, y: p.along(v), color: series.color, r: markerRadius(config, series)}] : []
        }) : [],
        band,
        active: box ? {series: box.series, slot} : null,
        axisTip,
        yTip: config.yaxis.tooltip?.enabled && !horizontal && y >= plot.y && y <= plot.y + plot.h ? {x: plot.x, y, text: String(p.value.text(Number((p.value.min + ((plot.y + plot.h - y) / plot.h) * (p.value.max - p.value.min)).toFixed(p.value.decimals))))} : null,
      }
}
