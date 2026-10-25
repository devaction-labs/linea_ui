/**
 * The axes of a cartesian chart: the value domain (with stacking), its ticks and labels, and where the
 * categories (or dates) sit along the other axis.
 */
import {bands, datePattern, decimalsOf, formatDate, linear, niceScale, plain, spread, timeTicks} from "./chart_scale.js"
import {extent, stack} from "./chart_series.js"

export const horizontalOf = (config) => (config.type === "bar" || config.type === "rangeBar") && config.plotOptions.bar.horizontal === true

export const stackedOf = (config) => config.chart.stacked === true && ["bar", "area", "line"].includes(config.type)

const call = (formatter, ...args) => (typeof formatter === "function" ? formatter(...args) : undefined)

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
  const flat = stacks
    ? stacks.flatMap((row) => row.filter(Boolean).flatMap((cell) => [cell.from, cell.to]))
    : visible.flatMap((series) => series.points.flatMap(values))
  const bars = config.type === "bar" || stacks !== null
  return extent(bars ? [...flat, 0] : flat)
}

/**
 * The value axis: `{min, max, ticks: [{value, label}], scale, time}` where `scale` maps a value to the
 * coordinate along the axis between `from` and `to` (pixels), `time` tells a date axis.
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
      ? formatDate(value, axis.labels?.format ?? pattern)
      : (call(axis.labels?.formatter, value, {}) ?? (percent ? `${value}%` : value.toFixed(decimals).replace(/\.0+$/, "")))
  const ticks = (instants ?? nice.ticks).map((value) => ({value, label: String(text(value))}))
  return {min: nice.min, max: nice.max, ticks, time, percent, text, decimals}
}

const thinned = (labels, spacing, widest, hide) => {
  const every = hide ? Math.max(1, Math.ceil((widest + 10) / Math.max(spacing, 1))) : 1
  return labels.filter((_, index) => index % every === 0)
}

const categoryText = (config, data, slot) => {
  const raw = data.labels[slot] ?? ""
  return String(call(config.xaxis.labels?.formatter, raw, undefined, {}) ?? raw)
}

/**
 * Where the categories sit along `length` pixels: `kind` is `bands` (bars, candles) or `points` (lines,
 * areas); `center(slot)` is the position of a slot, `width` the room each has; `labels` are the
 * `{slot, pos, text}` to print, thinned when they would overlap.
 */
export const categoryAxis = (config, data, length, {measure, horizontal, room = {left: 0, right: 0}}) => {
  const axis = horizontal ? config.yaxis : config.xaxis
  const byBand = config.type === "bar" || config.type === "rangeBar" || config.type === "candlestick"
  const timed = !byBand && data.kind !== "category"
  const count = Math.max(data.count, 1)
  const hide = axis.labels?.hideOverlappingLabels !== false
  const font = parseFloat(axis.labels?.style?.fontSize ?? 12)
  if (timed) {
    const xs = data.series.filter((series) => !series.hidden).flatMap((series) => series.points.map((point) => point.x))
    const found = extent(xs) ?? [0, 1]
    const [lo, hi] = [axis.min ?? found[0], axis.max ?? found[1]]
    const place = linear(lo, hi, 0, length)
    const instants = data.kind === "datetime" ? timeTicks(lo, hi, axis.tickAmount ?? Math.max(2, Math.floor(length / 80))) : niceScale(lo, hi, {size: length * 0.7, limits: {tickAmount: axis.tickAmount}}).ticks
    const pattern = datePattern(hi - lo)
    const text = (value) => (data.kind === "datetime" ? formatDate(value, axis.labels?.format ?? pattern) : String(call(axis.labels?.formatter, value, undefined, {}) ?? plain(value)))
    const labels = instants
      .map((value) => ({slot: null, pos: place(value), text: text(value)}))
      .filter((label) => label.pos - measure(label.text, font) / 2 >= -room.left && label.pos + measure(label.text, font) / 2 <= length + room.right)
    return {kind: "points", timed: true, width: length / Math.max(instants.length, 1), center: place, count, labels, edges: instants.map(place)}
  }
  const grid = byBand ? bands(count, length) : null
  const centers = byBand ? grid.centers : spread(count, length)
  const at = (slot) => centers[slot]
  const spacing = byBand ? grid.width : length / Math.max(count - 1, 1)
  const all = Array.from({length: data.count}, (_, slot) => ({slot, pos: at(slot), text: categoryText(config, data, slot)}))
  const widest = Math.max(0, ...all.map((label) => measure(label.text, font)))
  return {
    kind: byBand ? "bands" : "points",
    timed: false,
    width: spacing,
    center: at,
    count,
    labels: thinned(all, spacing, widest, hide),
    edges: byBand ? Array.from({length: count + 1}, (_, index) => index * grid.width) : spread(count, length),
    widest,
  }
}
