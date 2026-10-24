/**
 * What `<.number_input>` decides without a DOM: what a person may type, how localized text becomes the machine
 * value (`1.234,56` → `1234.56`) and back, where a step goes, and what the field settles on when it is left. The
 * arithmetic is the scaled integers of `numbers.js`, so steps never drift.
 */
import {add, clampScaled, compare, parseLimit, plain, render, scaled} from "./numbers.js"

const escape = (text) => text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")

/** The options of a field, read from its `data-*` attributes. */
export const numberOptions = (dataset) => ({
  decimal: dataset.decimal || ".",
  group: dataset.group ?? "",
  decimals: dataset.decimals === undefined || dataset.decimals === "" ? null : Number(dataset.decimals),
  maxDecimals: dataset.maxDecimals === undefined || dataset.maxDecimals === "" ? null : Number(dataset.maxDecimals),
  min: parseLimit(dataset.min),
  max: parseLimit(dataset.max),
  step: parseLimit(dataset.step) ?? {int: 1, scale: 0},
  negative: dataset.negative !== "false",
})

const limitOf = ({decimals, maxDecimals}) => decimals ?? maxDecimals

/**
 * What was typed, cleaned: only digits, the separators and (when negatives are allowed) one leading `-`; a single
 * decimal separator, and no more decimals than the field takes.
 */
export const sanitize = (text, options) => {
  const {decimal, group, negative} = options
  const allowed = new RegExp(`[^0-9${escape(decimal)}${escape(group)}-]`, "g")
  const kept = text.replace(allowed, "")
  const sign = negative && kept.trimStart().startsWith("-") ? "-" : ""
  const body = kept.replace(/-/g, "")
  const at = body.indexOf(decimal)
  const whole = at < 0 ? body : body.slice(0, at)
  const fraction = at < 0 ? null : body.slice(at + decimal.length).split(decimal).join("").replaceAll(group, "")
  const limit = limitOf(options)
  const cut = fraction === null || limit === null ? fraction : fraction.slice(0, limit)
  const tail = cut === null || limit === 0 ? "" : `${decimal}${cut}`
  return `${sign}${whole}${tail}`
}

/** Localized text read as a scaled number: `{kind: "empty"}`, `{kind: "number", number}` or `{kind: "invalid"}`. */
export const parse = (text, {decimal, group}) => {
  const stripped = (text ?? "").replace(/\s/g, "")
  const ungrouped = group === "" || group.trim() === "" ? stripped : stripped.replaceAll(group, "")
  const normal = ungrouped.replace(decimal, ".")
  const number = /^[+-]?\d+(\.\d+)?$/.test(normal) ? scaled(normal) : null
  return stripped === "" ? {kind: "empty"} : number === null ? {kind: "invalid"} : {kind: "number", number}
}

const rounded = (number, {decimals, maxDecimals}) => {
  const precision = decimals ?? maxDecimals
  return precision === null || precision === undefined || (decimals === null && number.scale <= precision)
    ? number
    : scaled(render(number, precision))
}

const groupWhole = (whole, group) => (group === "" ? whole : whole.replace(/\B(?=(\d{3})+(?!\d))/g, () => group))

/** The machine text of a number: a dot, no grouping, rounded to the field's decimals. */
export const machine = (number, options) =>
  options.decimals === null ? plain(rounded(number, options)) : render(number, options.decimals)

/** The text a person reads: the machine text with the locale's decimal separator and the whole part grouped. */
export const display = (number, options) => {
  const text = machine(number, options)
  const negative = text.startsWith("-")
  const [whole, fraction] = text.replace("-", "").split(".")
  const body = `${groupWhole(whole, options.group)}${fraction === undefined ? "" : `${options.decimal}${fraction}`}`
  return `${negative ? "-" : ""}${body}`
}

/** What the hidden input holds for typed text: the machine value, `""` for nothing, the text itself when it is not a number. */
export const valueOf = (text, options) => {
  const read = parse(text, options)
  return {empty: "", invalid: text, number: read.kind === "number" ? machine(read.number, options) : null}[read.kind]
}

/** The text shown for a machine value from the server: formatted when it is a number, as it is otherwise. */
export const displayOf = (value, options) => {
  const number = value === null || value === undefined || value === "" ? null : scaled(value)
  return number === null ? (value ?? "") : display(number, options)
}

/** What the field settles on when it is left: clamped, rounded and grouped. */
export const settle = (text, options) => {
  const read = parse(text, options)
  const number = read.kind === "number" ? clampScaled(read.number, options.min, options.max) : null
  return number === null
    ? {display: read.kind === "empty" ? "" : text, value: read.kind === "empty" ? "" : text}
    : {display: display(number, options), value: machine(number, options)}
}

const STEPS = {up: 1, down: -1, ArrowUp: 1, ArrowDown: -1, PageUp: 10, PageDown: -10}

/** The keys (and stepper directions) that move the value. */
export const STEP_KEYS = ["ArrowUp", "ArrowDown", "PageUp", "PageDown"]

/**
 * The field after a step `by` (`"up"`, `"down"` or a key) from the machine `value`: one step (ten for the page keys),
 * clamped. An empty or invalid value starts from `min`, or zero. `null` when it would not move.
 */
export const stepFrom = (value, by, options) => {
  const current = scaled(value ?? "")
  const factor = STEPS[by]
  const start = current ?? clampScaled({int: 0, scale: 0}, options.min, options.max)
  const moved = current === null ? start : add(current, {int: options.step.int * factor, scale: options.step.scale})
  const next = clampScaled(moved, options.min, options.max)
  const same = current !== null && compare(next, current) === 0
  return factor === undefined || same ? null : {display: display(next, options), value: machine(next, options)}
}

/** Whether a stepper can still move: `false` at the limit it moves towards. */
export const canStep = (value, by, options) => {
  const current = scaled(value ?? "")
  const limit = by === "up" ? options.max : options.min
  return current === null || limit === null || compare(current, limit) * STEPS[by] < 0
}

/** Whether two machine values are the same number (or the same text when they are not numbers). */
export const sameNumber = (a, b) => {
  const x = scaled(a ?? "")
  const y = scaled(b ?? "")
  return x !== null && y !== null ? compare(x, y) === 0 : (a ?? "") === (b ?? "")
}
