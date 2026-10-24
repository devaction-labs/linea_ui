/**
 * The text of the date-time picker, without a DOM: a time on a 12 or 24-hour clock and the reading of what a
 * person types in the time field, the text of a value in the input, the sentences that carry the words of the
 * locale, and the suggestions of the time field.
 */
import {formatDate} from "./calendar_view.js"
import {decide} from "./keys.js"
import {normalizeTime, toMinutes} from "./datetime_rules.js"

const pad = (number) => String(number).padStart(2, "0")

/** `"2:30 PM"` on a 12-hour clock, `"14:30"` on a 24-hour one. */
export const formatTime = (time, hour12) => {
  const minutes = toMinutes(time)
  const [hour, minute] = [Math.floor(minutes / 60), minutes % 60]
  return hour12 ? `${hour % 12 || 12}:${pad(minute)} ${hour < 12 ? "AM" : "PM"}` : `${pad(hour)}:${pad(minute)}`
}

const TYPED = /^(\d{1,2})(?:[:.h]?(\d{2}))?\s*([ap])?\.?m?\.?$/i

const twentyFour = (hour, meridiem) =>
  decide(
    [
      [(period) => period === undefined, () => hour],
      [() => hour < 1 || hour > 12, () => null],
      [(period) => period === "a", () => hour % 12],
      [() => true, () => (hour % 12) + 12],
    ],
    meridiem?.toLowerCase(),
  )

/**
 * The `"HH:MM"` a person meant by `"9"`, `"930"`, `"9:30"`, `"9.30"`, `"9:30 pm"`, `"9pm"` or `"21:30"`; `null` for text that is
 * not a time. Without AM or PM the hour is the 24-hour one, so `"9"` is 09:00.
 */
export const parseTimeText = (text) => {
  const compact = String(text ?? "").trim().replace(/^(\d)(\d{2})(\s*[ap]?\.?m?\.?)$/i, "$1:$2$3")
  const match = TYPED.exec(compact)
  const hour = match ? twentyFour(Number(match[1]), match[3]) : null
  return hour === null ? null : normalizeTime(`${hour}:${match[2] ?? "00"}`)
}

/** The suggestions that contain what was typed (digits and letters, ignoring `:` and spaces); all of them for no text. */
export const suggestSlots = (slots, typed, hour12) => {
  const needle = String(typed ?? "").toLowerCase().replace(/[\s:.]/g, "")
  const shown = (slot) => formatTime(slot.time, hour12).toLowerCase().replace(/[\s:.]/g, "")
  return needle === "" ? slots : slots.filter((slot) => shown(slot).includes(needle))
}

/** The slot a suggestion list should scroll to or start from: the one nearest to `time`. */
export const nearestSlot = (slots, time) => {
  const target = toMinutes(time)
  const distance = (slot) => Math.abs(toMinutes(slot.time) - (target ?? 0))
  return slots.reduce((best, slot) => (best === null || distance(slot) < distance(best) ? slot : best), null)
}

/** The text of a moment (`{date, time}`) in flatpickr's tokens, `""` for nothing. */
export const formatMoment = (moment, format, names) =>
  moment?.date ? formatDate(moment.date, timeParts(moment.time), format, names) : ""

const timeParts = (time) => {
  const minutes = toMinutes(time)
  return minutes === null ? null : {hour: Math.floor(minutes / 60), minute: minutes % 60}
}

/** The text of the input: the moment, or the two ends of a range joined by `separator`; `""` when nothing is chosen. */
export const formatValue = ({start, end}, {mode, format, names, separator}) =>
  decide(
    [
      [() => mode !== "range", () => formatMoment(start, format, names)],
      [() => !start?.date || !end?.date, () => ""],
      [() => true, () => `${formatMoment(start, format, names)}${separator}${formatMoment(end, format, names)}`],
    ],
  )

/** Fills `%{name}` in a sentence of the locale. */
export const fill = (template, values) =>
  Object.entries(values).reduce((text, [key, value]) => text.replaceAll(`%{${key}}`, String(value)), template)
