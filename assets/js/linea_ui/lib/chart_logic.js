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
