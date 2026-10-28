/**
 * What the cursor of a chart tells the page: the `linea:chart:cursor` detail, the line of figures a chart
 * can write above its plot (`summary`), and the throttle in front of the server push (`on_cursor`).
 */
import {escape} from "./chart_svg.js"

/** The slot (or slice) a hover result points at, or `null` when it does not say. */
const indexOf = (hit) => hit.slot ?? hit.active?.slot ?? hit.active?.slice ?? null

/** The detail of a cursor event for a hover result: its place, its label and one entry per row, already formatted. `null` for no hover. */
export const cursorDetail = (hit) =>
  hit ? {index: indexOf(hit), label: hit.title ?? "", values: hit.rows.map((row) => ({name: row.name ?? "", color: row.color ?? null, value: row.value}))} : null

/** The same detail as a flat payload for `pushEvent`: a leave is an empty one, since a payload must be a map. */
export const cursorPayload = (id, detail) => ({id, index: detail?.index ?? null, label: detail?.label ?? "", values: detail?.values ?? []})

/** Whether two details say the same thing, so a move inside one slot sends nothing. */
export const sameCursor = (a, b) => JSON.stringify(a ?? null) === JSON.stringify(b ?? null)

const valued = (hit) => hit.rows.filter((row) => row.value !== "" && row.value !== undefined && row.value !== null).length

/**
 * The hover result of the slot for the summary to rest on: the last one where `count` series (all the visible ones) have a value, else
 * the last one where any has. `answer(slot)` is a hover result or `null`.
 */
export const lastWithData = (slots, answer, count = 1) => {
  let partial = null
  for (let at = slots.length - 1; at >= 0; at--) {
    const hit = answer(slots[at])
    const have = hit ? valued(hit) : 0
    if (have >= count) return hit
    partial = partial ?? (have > 0 ? hit : null)
  }
  return partial
}

/** The inside of the summary line: a chip with the label, then a colored `name value` per series. */
export const summaryHtml = (detail) =>
  detail
    ? `${detail.label ? `<span class="linea-chart-summary-chip">${escape(detail.label)}</span>` : ""}${detail.values
        .map(
          (item) =>
            `<span class="linea-chart-summary-item">${item.color ? `<span class="linea-chart-summary-marker" style="background:${escape(item.color)}"></span>` : ""}${item.name ? `<span class="linea-chart-summary-name">${escape(item.name)}</span> ` : ""}<b>${escape(item.value)}</b></span>`
        )
        .join("")}`
    : ""

/** `send` at most once per `wait` ms, with the last call that came in between delivered at the end. `flush(...)` sends now and drops what waited, `cancel()` drops it. */
export const throttled = (send, wait, timers = {set: setTimeout, clear: clearTimeout, now: () => Date.now()}) => {
  let last = -Infinity
  let timer = null
  let pending = null
  const stop = () => timer !== null && (timers.clear(timer), (timer = null))
  const deliver = (args) => ((last = timers.now()), (pending = null), send(...args))
  const call = (...args) => {
    const left = last + wait - timers.now()
    stop()
    if (left <= 0) return deliver(args)
    pending = args
    timer = timers.set(() => ((timer = null), deliver(pending)), left)
  }
  call.flush = (...args) => (stop(), deliver(args))
  call.cancel = stop
  return call
}
