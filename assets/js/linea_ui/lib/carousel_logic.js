/**
 * The carousel's arithmetic, apart from the DOM: which slide a step lands on, where each slide sits
 * relative to the active one, and how big the progress bar and the scrollbar thumb are.
 */

const clamp = (value, min, max) => Math.min(Math.max(value, min), max)

/**
 * The slide a move lands on. With `loop` it wraps past the ends; without, it stops at them.
 *
 * @param {number} index
 * @param {number} count
 * @param {boolean} loop
 */
export const target = (index, count, loop) =>
  count === 0 ? 0 : loop ? ((index % count) + count) % count : clamp(index, 0, count - 1)

/**
 * The slide whose start is closest to `position`.
 *
 * @param {number} position scroll offset of the track
 * @param {number[]} starts offset of each slide's start
 */
export const nearest = (position, starts) =>
  starts.reduce((best, start, index) => (Math.abs(start - position) < Math.abs(starts[best] - position) ? index : best), 0)

/**
 * Where slide `index` sits relative to `active`, the custom properties the stacked effects read:
 * `offset` (clamped to ±4), `distance` (its absolute value), `side` (clamped to ±1), `near` (|side|).
 *
 * @param {number} index
 * @param {number} active
 */
export const placement = (index, active) => {
  const offset = clamp(index - active, -4, 4)
  const side = clamp(offset, -1, 1)
  return {offset, distance: Math.abs(offset), side, near: Math.abs(side)}
}

/**
 * The share of the progress bar that is filled once `index` is active.
 *
 * @param {number} index
 * @param {number} count
 */
export const progress = (index, count) => (count === 0 ? 0 : (index + 1) / count)

/**
 * The scrollbar thumb as fractions of the bar: its `size` and where it `start`s.
 *
 * @param {number} position
 * @param {number} scrollSize
 * @param {number} clientSize
 */
export const thumb = (position, scrollSize, clientSize) => {
  const size = scrollSize <= 0 ? 1 : clamp(clientSize / scrollSize, 0, 1)
  const room = scrollSize - clientSize
  const start = room <= 0 ? 0 : (1 - size) * clamp(position / room, 0, 1)
  return {size, start}
}

/**
 * Turns a drag of the scrollbar thumb (as a fraction of the bar) into a track scroll offset.
 *
 * @param {number} fraction
 * @param {number} scrollSize
 * @param {number} clientSize
 */
export const scrollFor = (fraction, scrollSize, clientSize) => {
  const size = scrollSize <= 0 ? 1 : clamp(clientSize / scrollSize, 0, 1)
  return size >= 1 ? 0 : clamp(fraction / (1 - size), 0, 1) * (scrollSize - clientSize)
}

/**
 * The step a swipe asks for: `1`, `-1`, or `0` when it is too short or goes the other way.
 *
 * @param {number} dx
 * @param {number} dy
 * @param {"horizontal" | "vertical"} direction
 * @param {number} [threshold]
 */
export const swipe = (dx, dy, direction, threshold = 40) => {
  const [main, cross] = direction === "vertical" ? [dy, dx] : [dx, dy]
  return Math.abs(main) < threshold || Math.abs(main) < Math.abs(cross) ? 0 : main < 0 ? 1 : -1
}

/**
 * How far a slide's content (or the parallax background) moves: `value` is LineOne's
 * `data-swiper-parallax` (`"-300"` pixels or `"-23%"`), `amount` the slide's progress.
 *
 * @param {string} value
 * @param {number} amount
 */
export const parallax = (value, amount) => {
  const number = parseFloat(value) || 0
  const unit = String(value).trim().endsWith("%") ? "%" : "px"
  return `${number * amount}${unit}`
}

/**
 * What a key does: `1` next, `-1` previous, `"first"`, `"last"`, or `null`.
 *
 * @param {string} key
 * @param {"horizontal" | "vertical"} direction
 */
export const keyStep = (key, direction) => {
  const keys =
    direction === "vertical" ? {ArrowDown: 1, ArrowUp: -1} : {ArrowRight: 1, ArrowLeft: -1}
  return keys[key] ?? {Home: "first", End: "last"}[key] ?? null
}

/** The fraction pagination text. */
export const fraction = (index, count) => `${index + 1} / ${count}`

/**
 * The slide after a patch: the server's when it changed its `index`, otherwise the one the person is on.
 *
 * @param {{current: number, lastServer: number, server: number, count: number}} state
 */
export const resolveIndex = ({current, lastServer, server, count}) =>
  target(server !== lastServer ? server : current, count, false)

/**
 * Whether a tree branch is open after a patch. `chosen` is the person's choice (`undefined` when
 * none); the server wins when its own value changed.
 *
 * @param {{chosen: boolean | undefined, lastServer: boolean | undefined, server: boolean}} state
 * @returns {{open: boolean, chosen: boolean | undefined, lastServer: boolean}}
 */
export const resolveBranch = ({chosen, lastServer, server}) =>
  chosen !== undefined && (lastServer === undefined || server === lastServer)
    ? {open: chosen, chosen, lastServer: server}
    : {open: server, chosen: undefined, lastServer: server}
