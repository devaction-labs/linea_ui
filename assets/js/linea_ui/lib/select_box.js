/**
 * What the select and tag listbox decide without a DOM: which options show for a search, how a label is split
 * around the typed term, where the arrow keys move, what a choice, a removal or a typed delimiter does to the
 * values, whether the control is full, what a full tag input shows and how many chips of a pillbox fit.
 */
import {matches} from "./text.js"

/** `label` cut into the parts before, at and after the first place `term` appears (ignoring case). */
export const highlight = (label, term) => {
  const at = term.trim() === "" ? -1 : label.toLowerCase().indexOf(term.trim().toLowerCase())
  const size = term.trim().length
  return at < 0
    ? [{text: label, hit: false}]
    : [
        {text: label.slice(0, at), hit: false},
        {text: label.slice(at, at + size), hit: true},
        {text: label.slice(at + size), hit: false},
      ].filter((part) => part.text !== "")
}

/**
 * Whether an option shows: a multiple listbox hides what is already chosen, and the typed term filters the rest
 * (by the label or by the option's `keywords`) unless the server does the search (`local` false).
 */
export const shows = ({value, label, keywords = ""}, {values, multiple, term, local}) =>
  !(multiple && values.includes(value)) && (!local || matches(label, term) || (keywords !== "" && matches(keywords, term)))

/** The row the arrow keys move to among `count` rows, from `index` (-1 for none); it stops at both ends. */
export const moveIndex = (index, key, count) =>
  count === 0 ? -1 : ({ArrowDown: Math.min(index + 1, count - 1), ArrowUp: Math.max(index - 1, 0)}[key] ?? index)

/** Whether the listbox takes no more choices. */
export const isFull = (count, multiple, max) => (multiple ? max != null && count >= max : count >= 1)

/** The values after choosing `value`: a single listbox holds only it; a multiple one adds it unless it is there or full. */
export const choose = (values, value, {multiple, max}) =>
  multiple ? (values.includes(value) || isFull(values.length, true, max) ? values : [...values, value]) : [value]

/** The values without `value`. */
export const removeValue = (values, value) => values.filter((known) => known !== value)

/** Backspace in an empty input: the last value goes, and is returned so it can be put back as text. */
export const removeLast = (values) => ({values: values.slice(0, -1), removed: values.at(-1) ?? null})

/** Typed text cut at the delimiter: the finished tags before it and what is still being typed. */
export const splitTags = (text, delimiter = ",") => {
  const parts = text.split(delimiter)
  return {done: parts.slice(0, -1).map((part) => part.trim()).filter((part) => part !== ""), rest: parts.at(-1)}
}

/** Whether two lists hold the same values in the same order. */
export const sameValues = (a, b) => a.length === b.length && a.every((value, index) => value === b[index])

/** Whether Tab in a tag input turns the typed text into a tag (with nothing typed it moves on). */
export const createsOnTab = (mode, term) => mode === "tags" && term.trim() !== ""

/**
 * What a tag input shows at its limit: the input is off, the placeholder says so and a `3 / 3` counter appears.
 * Without a `max` nothing changes.
 */
export const limitState = ({count, max, placeholder, limitPlaceholder}) => {
  const full = isFull(count, true, max)
  return {
    full,
    disabled: full,
    placeholder: full && limitPlaceholder ? limitPlaceholder : placeholder,
    counter: max == null ? null : `${count} / ${max}`,
    showCounter: full,
  }
}

/** The create row's parts: the key hint (none when empty), the label and the term between curly quotes. */
export const createRow = (hint, label, term) => ({hint: hint || null, label, quoted: `“${term}”`})

/**
 * How many chips stay on the one line of a pillbox: all when their `widths` fit in `room`, else the most that fit
 * together with the `+N` badge, whose width `badgeWidth(hidden)` depends on how many are hidden.
 */
export const fitCount = (widths, room, badgeWidth) => {
  const total = widths.reduce((sum, width) => sum + width, 0)
  const keep = (n, used) => (n === 0 || used + badgeWidth(widths.length - n) <= room ? n : keep(n - 1, used - widths[n - 1]))
  return total <= room ? widths.length : keep(widths.length, total)
}
