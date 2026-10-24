/**
 * The date and time picker in flatpickr's shape, without a DOM: the 42 days of a month with their classes, the
 * month and time panels as HTML, the selection after a pick, and the text of a date in flatpickr's format
 * tokens (`Y-m-d`, `F j, Y`, `H:i`...). Dates are ISO strings (`"2026-10-23"`), always in UTC.
 */
import {addDays, daysInMonth, leadingDays, toIso} from "./dates.js"
import {escapeHtml} from "./date_picker_view.js"
import {glyphHtml} from "./glyphs.js"

export const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
export const WEEKDAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

const pad = (number) => String(number).padStart(2, "0")

const weekday = (iso) => new Date(`${iso}T00:00:00Z`).getUTCDay()

/** The text of a date and a time in flatpickr's tokens; `names` gives the month and weekday names. */
export const formatDate = (iso, time, format, names = {}) => {
  const months = names.months ?? MONTHS
  const days = names.weekdays ?? WEEKDAYS
  const [year, month, day] = (iso ?? "1970-01-01").split("-").map(Number)
  const hour = time?.hour ?? 0
  const minute = time?.minute ?? 0
  const tokens = {
    Y: () => String(year),
    y: () => String(year).slice(-2),
    m: () => pad(month),
    n: () => String(month),
    d: () => pad(day),
    j: () => String(day),
    F: () => months[month - 1],
    M: () => months[month - 1].slice(0, 3),
    l: () => days[weekday(iso)],
    D: () => days[weekday(iso)].slice(0, 3),
    H: () => pad(hour),
    G: () => String(hour),
    h: () => String(hour % 12 || 12),
    i: () => pad(minute),
    K: () => (hour < 12 ? "AM" : "PM"),
  }
  return [...format].map((char) => (tokens[char] ? tokens[char]() : char)).join("")
}

/** Whether a day cannot be picked: before `min`, after `max`, one of `dates` or on one of `weekdays` (0 = Sunday). */
export const isDisabled = (iso, {min, max, dates = [], weekdays = []}) =>
  Boolean((min && iso < min) || (max && iso > max) || dates.includes(iso) || weekdays.includes(weekday(iso)))

/** The selection after picking `iso`: one day, a toggled day among several, or a range that starts, closes or restarts. */
export const pickDate = (dates, iso, mode) =>
  ({
    single: () => [iso],
    multiple: () => (dates.includes(iso) ? dates.filter((known) => known !== iso) : [...dates, iso]),
    range: () => (dates.length !== 1 ? [iso] : [dates[0], iso].sort()),
  })[mode]()

/** The classes of one day cell; in range mode with one end picked, `hover` draws the range up to the pointer. */
export const dayClasses = (iso, {view, dates, mode, today, rules, hover}) => {
  const [from, to] = mode === "range" && dates.length === 1 && hover ? [dates[0], hover].sort() : dates
  const ranged = mode === "range" && Boolean(from && to)
  const flags = [
    "flatpickr-day",
    isPrev(iso, view) && "prevMonthDay",
    isNext(iso, view) && "nextMonthDay",
    iso === today && "today",
    mode !== "range" && dates.includes(iso) && "selected",
    mode === "range" && iso === from && "selected startRange",
    ranged && iso === to && "selected endRange",
    ranged && iso > from && iso < to && "inRange",
    isDisabled(iso, rules) && "flatpickr-disabled",
  ]
  return [...new Set(flags.filter(Boolean).join(" ").split(" "))].join(" ")
}

const isPrev = (iso, view) => iso < toIso(view.year, view.month, 1)
const isNext = (iso, view) => iso > toIso(view.year, view.month, daysInMonth(view))

/** The 42 days flatpickr draws for a month: the tail of the month before, the month, the head of the next. */
export const monthDays = (view, weekStart) => {
  const first = toIso(view.year, view.month, 1)
  const start = addDays(first, -leadingDays(view, weekStart))
  return [...Array(42)].map((_, index) => addDays(start, index))
}

const numInput = (className, value, label, extra = "") =>
  `<div class="numInputWrapper"><input class="numInput ${className}" type="number" tabindex="-1" aria-label="${label}" value="${value}" ${extra}><span class="arrowUp" data-step="1"></span><span class="arrowDown" data-step="-1"></span></div>`

/** The month header, weekdays and days of the calendar as HTML. */
export const renderDays = (state) => {
  const {view, weekStart, names = {}} = state
  const months = names.months ?? MONTHS
  const weekdays = names.weekdays ?? WEEKDAYS
  const order = [...Array(7)].map((_, index) => weekdays[(index + weekStart) % 7].slice(0, 3))
  const monthOptions = months
    .map((name, index) => `<option class="flatpickr-monthDropdown-month" value="${index}"${index === view.month ? " selected" : ""}>${escapeHtml(name)}</option>`)
    .join("")
  const days = monthDays(view, weekStart)
    .map((iso) => {
      const classes = dayClasses(iso, state)
      const label = formatDate(iso, null, "F j, Y", names)
      return `<span class="${classes}" aria-label="${escapeHtml(label)}" tabindex="-1" data-date="${iso}">${Number(iso.slice(8))}</span>`
    })
    .join("")
  return (
    `<div class="flatpickr-months"><span class="flatpickr-prev-month" data-month="-1">${glyphHtml("angle_left", state.icons)}</span>` +
    `<div class="flatpickr-month"><div class="flatpickr-current-month">` +
    `<select class="flatpickr-monthDropdown-months" aria-label="Month" tabindex="-1" data-month-select>${monthOptions}</select>` +
    numInput("cur-year", view.year, "Year", "data-year") +
    `</div></div><span class="flatpickr-next-month" data-month="1">${glyphHtml("angle_right", state.icons)}</span></div>` +
    `<div class="flatpickr-innerContainer"><div class="flatpickr-rContainer">` +
    `<div class="flatpickr-weekdays"><div class="flatpickr-weekdaycontainer">${order.map((day) => `<span class="flatpickr-weekday">${escapeHtml(day)}</span>`).join("")}</div></div>` +
    `<div class="flatpickr-days" tabindex="-1"><div class="dayContainer">${days}</div></div>` +
    `</div></div>`
  )
}

/** The hour, minute and AM/PM row as HTML. */
export const renderTime = ({hour, minute, twentyFour, hourStep = 1, minuteStep = 5}) => {
  const shown = twentyFour ? pad(hour) : pad(hour % 12 || 12)
  const hours = twentyFour ? 'min="0" max="23"' : 'min="1" max="12"'
  return (
    `<div class="flatpickr-time${twentyFour ? " time24hr" : ""}" tabindex="-1">` +
    numInput("flatpickr-hour", shown, "Hour", `step="${hourStep}" ${hours} maxlength="2" data-hour`) +
    `<span class="flatpickr-time-separator">:</span>` +
    numInput("flatpickr-minute", pad(minute), "Minute", `step="${minuteStep}" min="0" max="59" maxlength="2" data-minute`) +
    (twentyFour ? "" : `<span class="flatpickr-am-pm" title="Click to toggle" tabindex="-1" data-ampm>${hour < 12 ? "AM" : "PM"}</span>`) +
    `</div>`
  )
}

const toMinutes = (text) => {
  const [hour, minute] = (text ?? "").split(":").map(Number)
  return text ? hour * 60 + minute : null
}

/** A time moved by `delta` steps of `unit` ("hour" or "minute"), wrapped around the day and held inside `min`–`max` ("HH:MM"). */
export const stepTime = ({hour, minute}, unit, delta, {minuteStep = 5, hourStep = 1, min, max} = {}) => {
  const step = unit === "hour" ? hourStep * 60 : minuteStep
  const total = (((hour * 60 + minute + delta * step) % 1440) + 1440) % 1440
  return clampTime({hour: Math.floor(total / 60), minute: total % 60}, {min, max})
}

/** A time held inside `min`–`max` ("HH:MM", either may be missing). */
export const clampTime = ({hour, minute}, {min, max} = {}) => {
  const total = hour * 60 + minute
  const low = toMinutes(min) ?? 0
  const high = toMinutes(max) ?? 1439
  const held = Math.min(Math.max(total, low), high)
  return {hour: Math.floor(held / 60), minute: held % 60}
}

/** A time typed into the hour or minute box: a 12-hour clock keeps its half of the day. */
export const setUnit = ({hour, minute}, unit, typed, twentyFour) => {
  const number = Number.isFinite(typed) ? typed : 0
  const pm = hour >= 12
  const hour24 = twentyFour ? number % 24 : (number % 12) + (pm ? 12 : 0)
  return unit === "hour" ? {hour: hour24, minute} : {hour, minute: Math.min(Math.max(number, 0), 59)}
}

/** "HH:MM" of a time. */
export const timeText = ({hour, minute}) => `${pad(hour)}:${pad(minute)}`

/** `{hour, minute}` of "HH:MM", or `fallback` for nothing. */
export const readTime = (text, fallback) => {
  const match = /(\d{1,2}):(\d{2})/.exec(text ?? "")
  return match ? {hour: Number(match[1]), minute: Number(match[2])} : fallback
}
