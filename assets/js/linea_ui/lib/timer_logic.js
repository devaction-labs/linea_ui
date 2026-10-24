/**
 * What a timer decides without a DOM. The clock is a reference, not a counter: `{base, at, running}` says the timer
 * showed `base` seconds at the monotonic instant `at` (milliseconds) and has counted since then when it runs, so a
 * throttled tab, a late timeout or a skipped frame never loses a second.
 */

const pad = (n) => String(n).padStart(2, "0")

/** The state of a timer that shows `base` seconds at `at`. */
export const clock = ({base, at, running}) => ({base: Math.max(0, base), at, running})

/** The seconds elapsed at the instant `now`, fractions included. */
export const elapsedAt = ({base, at, running}, now) => (running ? base + Math.max(0, now - at) / 1000 : base)

/** The state after pausing at `now`: the elapsed time is kept. */
export const pausedAt = (state, now) => clock({base: elapsedAt(state, now), at: now, running: false})

/** The state after resuming at `now`. */
export const resumedAt = (state, now) => clock({base: state.base, at: now, running: true})

/** The state after adding `seconds` (negative ones take time away, never below zero), still running or paused. */
export const added = (state, now, seconds) => clock({base: elapsedAt(state, now) + seconds, at: now, running: state.running})

/**
 * The clock after a patch: the server's when it differs from the one it sent last time, otherwise the one the
 * browser has been counting.
 *
 * @param {{client: object, lastServer: object, server: object, now: number}} state
 */
export const adopt = ({client, lastServer, server, now}) =>
  sameServer(lastServer, server) ? client : clock({base: server.elapsed, at: now, running: server.running})

/** Whether two things the server sent (`elapsed`, `running`, `total`, `direction`) are the same. */
export const sameServer = (a, b) =>
  a.elapsed === b.elapsed && a.running === b.running && a.total === b.total && a.direction === b.direction

/** The whole seconds the timer shows: those elapsed counting up, those left counting down (never below zero). */
export const shownSeconds = ({elapsed, total, direction}) =>
  Math.floor(direction === "down" ? Math.max(0, total - elapsed) : Math.max(0, elapsed))

/** `03:12:45` for `hms`, `3h12` for `hm`. */
export const formatTime = (seconds, format = "hms") => {
  const s = Math.max(0, Math.floor(seconds))
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  return format === "hm" ? `${h}h${pad(m)}` : `${pad(h)}:${pad(m)}:${pad(s % 60)}`
}

/** The fraction of the ring that is drawn: the elapsed time counting up, the time left counting down; 0 to 1. */
export const arcFraction = ({elapsed, total, direction}) => {
  const done = total > 0 ? Math.min(1, Math.max(0, elapsed) / total) : 0
  return direction === "down" ? 1 - done : done
}

/** The `stroke-dashoffset` that draws `fraction` of a circle of `circumference`, to one decimal as the server renders it. */
export const dashOffset = (fraction, circumference) => Number((circumference * (1 - fraction)).toFixed(1))

/** Milliseconds until the shown second changes. */
export const nextDelay = (elapsed) => Math.max(1, Math.round((1 - (elapsed - Math.floor(elapsed))) * 1000))

/**
 * Whether the timer has reached its end: counting down at zero, or counting up at `total` when `stopAtTotal`.
 */
export const reachedEnd = ({elapsed, total, direction, stopAtTotal}) =>
  total > 0 && (direction === "down" || stopAtTotal) && elapsed >= total

/**
 * Whether `on_finish` fires now: the end is reached and it had not fired for this stretch of time. Time added
 * after the end (or a new server value) starts a new stretch, so `fired` is reset by the caller when the end is
 * no longer reached.
 */
export const shouldFinish = ({reached, fired}) => reached && !fired
