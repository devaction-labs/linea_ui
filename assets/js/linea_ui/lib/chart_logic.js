/**
 * What the chart hook decides before it draws: reading the options the server sent and applying a pushed
 * update (new options, new series) to them.
 */
import {merge} from "./chart_config.js"

/** The options in a `data-options` string, or `null` when there is none or it is not a JSON object. */
export const parseOptions = (json) => {
  try {
    const value = JSON.parse(json ?? "")
    return value && typeof value === "object" && !Array.isArray(value) ? value : null
  } catch {
    return null
  }
}

/** Whether a `linea:chart` payload is meant for the chart with `id` (`"x"` and `"#x"` both match). */
export const targets = (payload, id) => (payload?.id ?? "").replace(/^#/, "") === id

const isObject = (value) => value !== null && typeof value === "object" && !Array.isArray(value)

const mergeSeries = (current, next) =>
  next.map((item, index) => (isObject(item) && isObject(current?.[index]) ? {...current[index], ...item} : item))

/**
 * `options` with a `linea:chart` payload applied: its `options` merged in, then its `series` laid over the
 * current ones by position (an entry that is an object keeps the name and settings it does not repeat).
 */
export const applyUpdate = (options, payload) => {
  const withOptions = isObject(payload?.options) ? merge(options, payload.options) : options
  return Array.isArray(payload?.series) ? {...withOptions, series: mergeSeries(withOptions.series, payload.series)} : withOptions
}

/** The CSS width a `chart.width` option asks for: a number is pixels, `"120px"` or `"50%"` pass, anything else is none. */
export const widthOf = (spec) =>
  typeof spec === "number" && spec > 0 ? `${spec}px` : /^\d+(\.\d+)?(px|%|rem|em)$/.test(String(spec)) ? String(spec) : ""

/**
 * The slot a key moves the keyboard cursor to: `slots` are the visitable slots in order, `current` the slot
 * now under the cursor (or `null`). Arrows step (Up/Left back, Down/Right forward), Home and End jump, and
 * any other key answers `undefined`. Going back from nothing starts at the end, going forward at the start.
 */
export const stepSlot = (slots, current, key) => {
  const at = slots.indexOf(current)
  const last = slots.length - 1
  const moves = {
    ArrowRight: at < 0 ? 0 : Math.min(at + 1, last),
    ArrowDown: at < 0 ? 0 : Math.min(at + 1, last),
    ArrowLeft: at < 0 ? last : Math.max(at - 1, 0),
    ArrowUp: at < 0 ? last : Math.max(at - 1, 0),
    Home: 0,
    End: last,
  }
  return slots.length > 0 && Object.hasOwn(moves, key) ? slots[moves[key]] : undefined
}

/** The view a toggle button asks for (`"chart"` or `"table"`), or `null` when it asks for nothing new: another value, or the view already shown. */
export const nextView = (current, asked) => ((asked === "chart" || asked === "table") && asked !== current ? asked : null)
