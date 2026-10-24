/**
 * What the date-time picker allows, without a DOM: the reading of a wall-clock value (`"2026-10-14T10:30"`, no
 * time zone), the limits (`min`, `max`, `min_time`, `max_time`), the unavailable dates, daily time ranges and
 * date-times, and the time slots of a day. A time is `"HH:MM"`, a date is ISO, both read as the clock on the wall.
 */
import {toIso} from "./dates.js"
import {decide} from "./keys.js"

const pad = (number) => String(number).padStart(2, "0")

const DATE = /^(\d{4})-(\d{2})-(\d{2})$/
const TIME = /^(\d{1,2}):(\d{2})$/
const MOMENT = /^(\d{4}-\d{2}-\d{2})(?:[T ](\d{1,2}:\d{2})(?::\d{2}(?:\.\d+)?)?(?:Z|[+-]\d{2}:?\d{2})?)?$/
const DAILY = /^(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})$/

/** Minutes since midnight of `"H:MM"` or `"HH:MM"`, or `null` when it is not a time of day. */
export const toMinutes = (time) => {
  const match = TIME.exec(String(time ?? "").trim())
  const [hour, minute] = match ? [Number(match[1]), Number(match[2])] : [24, 0]
  return hour < 24 && minute < 60 ? hour * 60 + minute : null
}

/** `"HH:MM"` of minutes since midnight. */
export const fromMinutes = (minutes) => `${pad(Math.floor(minutes / 60))}:${pad(minutes % 60)}`

/** The time as `"HH:MM"`, or `null` when it is not a time of day. */
export const normalizeTime = (time) => {
  const minutes = toMinutes(time)
  return minutes === null ? null : fromMinutes(minutes)
}

/** Whether `iso` is a day that exists (`2026-02-30` is not). */
export const isDate = (iso) => {
  const match = DATE.exec(String(iso ?? ""))
  return match !== null && toIso(Number(match[1]), Number(match[2]) - 1, Number(match[3])) === iso
}

/**
 * `{date, time}` of `"2026-10-14T10:30"`, `"2026-10-14 10:30"` or `"2026-10-14"` (then `time` is `null`); seconds
 * and a time zone suffix are dropped, never converted. `null` for text that is not a day and time.
 */
export const parseDateTime = (text) => {
  const match = MOMENT.exec(String(text ?? "").trim())
  const time = match ? normalizeTime(match[2]) : null
  const valid = match !== null && isDate(match[1]) && (match[2] === undefined || time !== null)
  return valid ? {date: match[1], time} : null
}

/** `"2026-10-14T10:30"` of a moment; just the date when it has no time. */
export const joinDateTime = ({date, time}) => (time ? `${date}T${time}` : date)

/** The entries of a comma separated text, or of a list, trimmed and without blanks. */
export const splitList = (input) =>
  []
    .concat(typeof input === "string" ? input.split(",") : (input ?? []))
    .map((entry) => String(entry).trim())
    .filter(Boolean)

const classifyRules = [
  [(entry) => DAILY.test(entry), (entry) => {
    const [, from, to] = DAILY.exec(entry)
    return normalizeTime(from) && normalizeTime(to) ? {kind: "daily", from: toMinutes(from), to: toMinutes(to)} : null
  }],
  [(entry) => parseDateTime(entry) !== null, (entry) => {
    const {date, time} = parseDateTime(entry)
    return time ? {kind: "moment", key: `${date}T${time}`} : {kind: "date", date}
  }],
  [() => true, () => null],
]

/**
 * The unavailable entries sorted by what they are: `{dates: Set, daily: [{from, to}] (minutes), moments: Set}`.
 * A date (`2026-10-14`) is closed all day, a range (`12:00-13:00`) is closed every day from its start up to but
 * not including its end (`22:00-02:00` crosses midnight), a date-time (`2026-10-14T10:00`) is one closed slot.
 * Entries that are none of them are ignored.
 */
export const parseUnavailable = (input) => {
  const entries = splitList(input).map((entry) => decide(classifyRules, entry)).filter(Boolean)
  const ofKind = (kind) => entries.filter((entry) => entry.kind === kind)
  return {
    dates: new Set(ofKind("date").map(({date}) => date)),
    daily: ofKind("daily").map(({from, to}) => ({from, to})),
    moments: new Set(ofKind("moment").map(({key}) => key)),
  }
}

/**
 * A limit as `{date, time}` (`time` is `null` for a whole day): `"now"` is the moment `now`, `"today"` its day,
 * anything else is read as a day or a day and time. `null` for no limit or text that is neither.
 */
export const resolveLimit = (spec, now) => {
  const text = String(spec ?? "").trim()
  return decide(
    [
      [(known) => known === "", () => null],
      [(known) => known.toLowerCase() === "now", () => ({date: now.date, time: now.time})],
      [(known) => known.toLowerCase() === "today", () => ({date: now.date, time: null})],
      [() => true, (known) => parseDateTime(known)],
    ],
    text,
  )
}

/**
 * The rules the helpers below read, from the picker's settings:
 * `{min, max, minTime, maxTime, unavailable}` and the moment `now` (`{date, time}`) that `"now"` and `"today"` mean.
 */
export const buildRules = ({min, max, minTime, maxTime, unavailable}, now) => ({
  min: resolveLimit(min, now),
  max: resolveLimit(max, now),
  minTime: normalizeTime(minTime),
  maxTime: normalizeTime(maxTime),
  ...parseUnavailable(unavailable),
})

const afterLimit = (limit, date, minutes) =>
  !limit || date > limit.date || (date === limit.date && (limit.time === null || minutes >= toMinutes(limit.time)))

const beforeLimit = (limit, date, minutes) =>
  !limit || date < limit.date || (date === limit.date && (limit.time === null || minutes <= toMinutes(limit.time)))

const inDaily = ({from, to}, minutes) => (from <= to ? minutes >= from && minutes < to : minutes >= from || minutes < to)

const inWindow = (rules, minutes) =>
  (rules.minTime === null || minutes >= toMinutes(rules.minTime)) && (rules.maxTime === null || minutes <= toMinutes(rules.maxTime))

/** Whether the slot of `time` on `date` can be chosen. */
export const isSlotAvailable = (date, time, rules) => {
  const minutes = toMinutes(time)
  return (
    minutes !== null &&
    !rules.dates.has(date) &&
    !rules.moments.has(`${date}T${fromMinutes(minutes)}`) &&
    !rules.daily.some((range) => inDaily(range, minutes)) &&
    inWindow(rules, minutes) &&
    afterLimit(rules.min, date, minutes) &&
    beforeLimit(rules.max, date, minutes)
  )
}

/** The step in minutes: a whole number of at least one, 30 for anything else. */
export const intervalOf = (interval) => (Number.isInteger(Number(interval)) && Number(interval) >= 1 ? Number(interval) : 30)

/** The times of a day every `interval` minutes from midnight that fall inside `min_time` and `max_time`. */
export const slotTimes = (interval, rules) => {
  const step = intervalOf(interval)
  return Array.from({length: Math.ceil(1440 / step)}, (_, index) => index * step)
    .filter((minutes) => inWindow(rules, minutes))
    .map(fromMinutes)
}

/** The slots of `date` as `{time, disabled}`; a slot closed by any rule is disabled. */
export const timeSlots = (date, times, rules) => times.map((time) => ({time, disabled: !isSlotAvailable(date, time, rules)}))

/** Whether `date` has a slot that can be chosen. */
export const isDateAvailable = (date, times, rules) => times.some((time) => isSlotAvailable(date, time, rules))

/** `time` if it is open on `date`, else the first open slot, else `null`. */
export const nearestTime = (date, time, times, rules) =>
  decide(
    [
      [() => time && isSlotAvailable(date, time, rules), () => time],
      [() => true, () => times.find((slot) => isSlotAvailable(date, slot, rules)) ?? null],
    ],
  )

/** `{start, end}` of a `default_time` such as `"09:00"` or `"09:00/17:00"`; a missing end is the start. */
export const parseDefaultTime = (text) => {
  const [first, second] = String(text ?? "").split("/").map(normalizeTime)
  return {start: first ?? null, end: second ?? first ?? null}
}

const momentKey = ({date, time}) => `${date}T${time ?? "00:00"}`

/** The rules for the end of a range that starts at `start`: nothing before it can be chosen. */
export const rulesFrom = (rules, start) =>
  start?.date
    ? {...rules, min: rules.min && momentKey(rules.min) > momentKey(start) ? rules.min : {date: start.date, time: start.time}}
    : rules
