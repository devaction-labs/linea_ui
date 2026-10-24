/**
 * What the range sliders decide without a DOM: the value a stepper button or a click on a mark gives, and which of
 * the two thumbs of a range a click on the track moves. Values are decimal text (`"0.25"`), exact like the number
 * input's.
 */
import {add, clampScaled, compare, parseLimit, plain, scaled} from "./numbers.js"

const ONE = {int: 1, scale: 0}

/**
 * The text of the value one `step` up or down from `raw`, held between `min` and `max`; `null` when it does not
 * move (the value is not a number, or it is already at the limit).
 *
 * @param {string} raw the current value
 * @param {"up" | "down"} direction
 * @param {{min?: string, max?: string, step?: string}} limits as in the input's attributes
 */
export const stepValue = (raw, direction, {min, max, step}) => {
  const current = scaled(raw)
  const size = scaled(step) ?? ONE
  const signed = direction === "down" ? {...size, int: -size.int} : size
  const next = current === null ? null : clampScaled(add(current, signed), parseLimit(min) ?? {int: 0, scale: 0}, parseLimit(max) ?? {int: 100, scale: 0})
  return next === null || compare(next, current) === 0 ? null : plain(next)
}

/** The mark's value held between `min` and `max`, as the text the input takes. */
export const markValue = (mark, {min, max}) => {
  const value = scaled(mark)
  return value === null ? null : plain(clampScaled(value, parseLimit(min) ?? {int: 0, scale: 0}, parseLimit(max) ?? {int: 100, scale: 0}))
}

/** Which thumb of a pair a target value moves: the nearer one, the lower one when they are equally near. */
export const nearestThumb = (low, high, target) => {
  const [a, b, t] = [Number(low), Number(high), Number(target)]
  return Math.abs(t - a) <= Math.abs(t - b) ? "low" : "high"
}

/** Whether two values are the same number, however they are written (`"5"` and `"5.0"`). */
export const sameValue = (a, b) => {
  const [x, y] = [scaled(a), scaled(b)]
  return x !== null && y !== null && compare(x, y) === 0
}
