/**
 * Reads the `series` of a chart into points, lines them up on the x axis (categories, numbers or dates),
 * stacks them and finds the extent of the values.
 */
import {colorAt} from "./chart_config.js"
import {toTime} from "./chart_scale.js"

const isNumber = (value) => typeof value === "number" && Number.isFinite(value)

const numeric = (value) => (isNumber(value) ? value : value === null || value === undefined || value === "" ? null : Number.isFinite(Number(value)) ? Number(value) : null)

const entry = (item, index) =>
  Array.isArray(item) && item.length === 2
    ? {x: item[0], y: item[1], fill: undefined}
    : item !== null && typeof item === "object" && !Array.isArray(item)
      ? {x: item.x, y: item.y, fill: item.fillColor}
      : {x: undefined, y: item, fill: undefined, index}

const tuple = (value, size) =>
  Array.isArray(value) && value.length >= size && value.slice(0, size).every((part) => numeric(part) !== null) ? value.slice(0, size).map(Number) : null

const measure = (type, y) =>
  type === "candlestick"
    ? ((box) => (box ? {open: box[0], high: box[1], low: box[2], close: box[3], value: box[3]} : {value: null}))(tuple(y, 4))
    : type === "rangeBar"
      ? ((range) => (range ? {start: range[0], end: range[1], value: range[1]} : {value: null}))(tuple(y, 2))
      : {value: numeric(y)}

const kindOf = (config) => (config.xaxis.type === "datetime" || config.xaxis.type === "numeric" ? config.xaxis.type : "category")

const labelText = (value) => (value === undefined || value === null ? "" : Array.isArray(value) ? value.join(" ") : String(value))

const xValue = (kind, raw, index) =>
  kind === "datetime" ? toTime(raw ?? index) : kind === "numeric" ? (isNumber(Number(raw)) && raw !== undefined && raw !== null ? Number(raw) : index + 1) : index

const base = (config) => (Array.isArray(config.xaxis.categories) && config.xaxis.categories.length > 0 ? config.xaxis.categories : config.labels)

const namedRows = (entries) => [...new Set(entries.flatMap((list) => list.map((item) => item.x)).filter((x) => typeof x === "string"))]

const rowsOf = (config, entries) => {
  const given = base(config)
  return given.length > 0 ? given : namedRows(entries)
}

const slotOf = (config, rows, item, position) => (config.type === "rangeBar" && typeof item.x === "string" && rows.includes(item.x) ? rows.indexOf(item.x) : position)

const pointOf = (config, kind, rows, item, position) => {
  const slot = slotOf(config, rows, item, position)
  const raw = kind === "category" ? undefined : (item.x ?? (kind === "datetime" ? rows[slot] : undefined))
  const label = rows[slot] ?? (typeof item.x === "string" ? item.x : item.x === undefined ? slot + 1 : item.x)
  return {...measure(config.type, item.y), x: xValue(kind, raw, slot), slot, label: labelText(label), fill: item.fill}
}

/**
 * The series of `config` as points. Returns `{kind, labels, series, count}`: `kind` is `category`, `numeric`
 * or `datetime`; `labels` the category text; each series has `name`, `index` (in the options, which keeps
 * its color when others are hidden), `color` and `points` of `{x, slot, label, value, ...}`; `null` values
 * stay as gaps.
 */
export const prepare = (config, hidden = []) => {
  const kind = kindOf(config)
  const list = Array.isArray(config.series) ? config.series : []
  const entries = list.map((series) => (Array.isArray(series?.data) ? series.data : []).map(entry))
  const rows = rowsOf(config, entries)
  const series = list.map((source, index) => ({
    name: source?.name ?? `series-${index + 1}`,
    index,
    color: colorAt(config, index),
    hidden: hidden.includes(index),
    points: entries[index].map((item, position) => pointOf(config, kind, rows, item, position)),
  }))
  const points = series.flatMap((one) => one.points)
  const count = Math.max(rows.length, 0, ...points.map((point) => point.slot + 1))
  const labels = Array.from({length: count}, (_, slot) => labelText(rows[slot] ?? points.find((point) => point.slot === slot)?.label ?? slot + 1))
  return {kind, labels, series, count}
}

/**
 * Stacks the `values` (`values[series][slot]`, numbers or null): positives pile up, negatives pile down;
 * `percent` rescales every slot to 0..100. Returns `[{from, to}|null]` per series and slot.
 */
export const stack = (values, percent = false) => {
  const slots = Math.max(0, ...values.map((row) => row.length))
  const totals = Array.from({length: slots}, (_, slot) => values.reduce((sum, row) => sum + Math.abs(row[slot] ?? 0), 0))
  const above = Array(slots).fill(0)
  const below = Array(slots).fill(0)
  return values.map((row) =>
    row.map((value, slot) => {
      const amount = value === null || value === undefined ? null : percent ? (totals[slot] === 0 ? 0 : (value / totals[slot]) * 100) : value
      return amount === null
        ? null
        : amount >= 0
          ? {from: above[slot], to: (above[slot] += amount)}
          : {from: below[slot], to: (below[slot] += amount)}
    })
  )
}

/** The lowest and highest of `numbers`, ignoring anything that is not a number; `null` when there are none. */
export const extent = (numbers) => {
  const valid = numbers.filter(isNumber)
  return valid.length === 0 ? null : [Math.min(...valid), Math.max(...valid)]
}
