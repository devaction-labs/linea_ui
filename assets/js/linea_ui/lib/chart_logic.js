/**
 * What the chart hook decides before it talks to ApexCharts: reading the options the server sent and
 * telling which update a pushed payload asks for.
 */

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

/** The calls a pushed payload asks for, in order: options first, so new series land on the new config. */
export const updatesFor = (payload) => [
  ...(payload?.options ? [["updateOptions", payload.options]] : []),
  ...(payload?.series ? [["updateSeries", payload.series]] : []),
]
