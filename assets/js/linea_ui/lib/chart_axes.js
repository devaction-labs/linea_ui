/**
 * The axes of a cartesian chart: the value domain (with stacking), its ticks and labels, and where the
 * categories (or dates) sit along the other axis.
 */
import {bands, datePattern, decimalsOf, formatDate, linear, niceScale, plain, spread, timeTicks} from "./chart_scale.js"
import {extent, stack} from "./chart_series.js"

const call = (formatter, ...args) => (typeof formatter === "function" ? formatter(...args) : undefined)

const BAND_TYPES = ["bar", "rangeBar", "candlestick"]

export const horizontalOf = (config) => (config.type === "bar" || config.type === "rangeBar") && config.plotOptions.bar.horizontal === true

export const stackedOf = (config) => config.chart.stacked === true && ["bar", "area", "line"].includes(config.type)

const values = (point) => (point.low !== undefined ? [point.low, point.high] : point.start !== undefined ? [point.start, point.end] : [point.value])

/** `[series][slot]` of `{from, to}` for the visible series when the chart is stacked, else `null`. */
export const stacksOf = (config, visible, count) =>
  stackedOf(config)
    ? stack(
        visible.map((series) => Array.from({length: count}, (_, slot) => series.points.find((point) => point.slot === slot)?.value ?? null)),
        config.chart.stackType === "100%"
      )
    : null

const domainOf = (config, visible, stacks) => {
  const flat = stacks ? stacks.flatMap((row) => row.filter(Boolean).flatMap((cell) => [cell.from, cell.to])) : visible.flatMap((series) => series.points.flatMap(values))
  return extent(config.type === "bar" || stacks !== null ? [...flat, 0] : flat)
}

/**
 * The value axis: `{min, max, ticks: [{value, label}], time, percent, text, decimals}`. `size` is the chart's
 * height (its width for rows), which decides how many ticks fit; `time` marks a date axis and `text` formats
 * a value the way the labels are.
 */
export const valueAxis = (config, visible, stacks, {horizontal, size}) => {
  const axis = horizontal ? config.xaxis : config.yaxis
  const percent = stacks !== null && config.chart.stackType === "100%"
  const time = horizontal && axis.type === "datetime"
  const found = percent ? [0, 100] : domainOf(config, visible, stacks)
  const limits = {min: axis.min, max: axis.max, tickAmount: axis.tickAmount}
  const nice = niceScale(found?.[0], found?.[1], {size, limits: percent ? {...limits, min: 0, max: 100} : limits})
  const instants = time ? timeTicks(nice.min, nice.max, axis.tickAmount ?? Math.max(2, Math.floor(size / 70))) : null
  const decimals = decimalsOf(nice.ticks)
  const pattern = datePattern(nice.max - nice.min)
  const text = (value) =>
    time
      ? formatDate(value, axis.labels?.format ?? pattern, config.chart.defaultLocale)
      : (call(axis.labels?.formatter, value, {}) ?? (percent ? `${value}%` : value.toFixed(decimals).replace(/\.0+$/, "")))
  return {min: nice.min, max: nice.max, ticks: (instants ?? nice.ticks).map((value) => ({value, label: String(text(value))})), time, percent, text, decimals}
}

const thinned = (labels, spacing, widest, hide) => {
  const every = hide ? Math.max(1, Math.ceil((widest + 4) / Math.max(spacing, 1))) : 1
  return labels.filter((_, index) => index % every === 0)
}

const timeText = (axis, kind, pattern, locale) => {
  const format = axis.labels?.format ?? pattern
  const options = (value) => ({dateFormatter: (date, text) => formatDate(Number(date), text, locale), timestamp: value})
  return kind === "datetime"
    ? (value) => String(call(axis.labels?.formatter, formatDate(value, format, locale), value, options(value)) ?? formatDate(value, format, locale))
    : (value) => String(call(axis.labels?.formatter, plain(value), value, {}) ?? plain(value))
}

/**
 * The text of the category at `slot` on a slotted axis (bars, candles, and the labels a plan measures): the label
 * through `xaxis.labels.formatter`; on a date axis the time of the slot, formatted with `labels.format` (or the
 * pattern that fits the span) before the formatter sees it, as on a date axis of lines.
 */
export const categoryText = (config, data, slot) => {
  const raw = data.labels[slot] ?? ""
  const axis = config.xaxis
  if (data.kind !== "datetime") return String(call(axis.labels?.formatter, raw, undefined, {}) ?? raw)
  const times = data.series.flatMap((series) => series.points.map((point) => point.x)).filter(Number.isFinite)
  const point = data.series.flatMap((series) => series.points).find((one) => one.slot === slot && Number.isFinite(one.x))
  const span = times.length > 0 ? Math.max(...times) - Math.min(...times) : 0
  return point ? timeText(axis, "datetime", datePattern(span), config.chart.defaultLocale)(point.x) : String(raw)
}

const fontOf = (axis) => parseFloat(axis.labels?.style?.fontSize ?? 12)

const timedAxis = (axis, data, length, {measure, room, locale}) => {
  const found = extent(data.series.filter((series) => !series.hidden).flatMap((series) => series.points.map((point) => point.x))) ?? [0, 1]
  const [low, high] = [axis.min ?? found[0], axis.max ?? found[1]]
  const place = linear(low, high, 0, length)
  const ticks =
    data.kind === "datetime"
      ? timeTicks(low, high, axis.tickAmount ?? Math.max(2, Math.floor(length / 80)))
      : niceScale(low, high, {size: length * 0.7, limits: {tickAmount: axis.tickAmount}}).ticks
  const text = timeText(axis, data.kind, datePattern(high - low), locale)
  const half = (label) => measure(label.text, fontOf(axis)) / 2
  const labels = ticks
    .map((value) => ({slot: null, pos: place(value), text: text(value)}))
    .filter((label) => label.pos - half(label) >= -room.left && label.pos + half(label) <= length + room.right)
  return {kind: "points", timed: true, width: length / Math.max(ticks.length, 1), center: place, count: Math.max(data.count, 1), labels, edges: ticks.map(place)}
}

const slotAxis = (config, axis, data, length, {measure, banded, horizontal}) => {
  const count = Math.max(data.count, 1)
  const grid = bands(count, length)
  const centers = banded ? grid.centers : spread(count, length)
  const spacing = banded ? grid.width : length / Math.max(count - 1, 1)
  const all = Array.from({length: data.count}, (_, slot) => ({slot, pos: centers[slot], text: categoryText(config, data, slot)}))
  // Labels down the side of a row chart collide by their height, not their width.
  const widest = horizontal ? fontOf(axis) : Math.max(0, ...all.map((label) => measure(label.text, fontOf(axis))))
  return {
    kind: banded ? "bands" : "points",
    timed: false,
    width: spacing,
    center: (slot) => centers[slot],
    count,
    labels: thinned(all, spacing, widest, axis.labels?.hideOverlappingLabels !== false),
    edges: banded ? Array.from({length: count + 1}, (_, index) => index * grid.width) : centers,
  }
}

/**
 * Where the categories sit along `length` pixels: `kind` is `bands` (bars, candles) or `points` (lines,
 * areas); `center(slot)` is the position of a slot, `width` the room each has; `labels` are the
 * `{slot, pos, text}` to print, thinned when they would overlap or, on a date axis, dropped when they
 * would run past the `room` left around the plot.
 */
export const categoryAxis = (config, data, length, {measure, horizontal, room = {left: 0, right: 0}}) => {
  const axis = horizontal ? config.yaxis : config.xaxis
  const banded = BAND_TYPES.includes(config.type)
  return !banded && data.kind !== "category" ? timedAxis(axis, data, length, {measure, room, locale: config.chart.defaultLocale}) : slotAxis(config, axis, data, length, {measure, banded, horizontal})
}
