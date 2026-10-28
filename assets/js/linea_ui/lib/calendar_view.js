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

/** The texts of the calendar and the time row when the server sends none (`picker_*` of `Strings`). */
export const LABELS = {
  picker_previous: "Previous month",
  picker_next: "Next month",
  picker_month: "Month",
  picker_year: "Year",
  picker_year_up: "Next year",
  picker_year_down: "Previous year",
  picker_hour: "Hour",
  picker_minute: "Minute",
  picker_hour_up: "Increase hour",
  picker_hour_down: "Decrease hour",
  picker_minute_up: "Increase minute",
  picker_minute_down: "Decrease minute",
  picker_toggle_period: "Toggle AM/PM",
}

const text = (labels, key) => escapeHtml(labels?.[key] ?? LABELS[key])

/** The day that holds the Tab stop of the grid: the one asked for, else the first chosen one, today or the first of the month, as long as it is in the month shown. */
export const focusDay = (view, {focus, dates = [], today} = {}) => {
  const prefix = toIso(view.year, view.month, 1).slice(0, 7)
  const inMonth = (iso) => typeof iso === "string" && iso.startsWith(prefix)
  return [focus, ...[...dates].sort(), today].find(inMonth) ?? `${prefix}-01`
}

/** The long name of a day in the language of `names`, from a sentence like `"%{weekday}, %{month} %{day}, %{year}"`. */
export const dayName = (iso, template, names = {}) => {
  const [year, month, day] = iso.split("-").map(Number)
  const values = {weekday: (names.weekdays ?? WEEKDAYS)[weekday(iso)], month: (names.months ?? MONTHS)[month - 1], day, year}
  return template.replace(/%\{(\w+)\}/g, (_all, key) => values[key] ?? "")
}

/** Whether a day is part of the choice: one of the days picked or, for a closed range, inside it (not what the pointer previews). */
export const isChosen = (iso, dates, mode) => {
  const [from, to] = [...dates].sort()
  return mode === "range" && dates.length === 2 ? iso >= from && iso <= to : dates.includes(iso)
}

/** An arrow button of the number boxes (the year, the hour, the minute); `aria-disabled` when it cannot move. */
const stepButton = (direction, unit, label, {disabled = false, tabbable = false} = {}) =>
  `<button type="button" class="${direction > 0 ? "arrowUp" : "arrowDown"}" data-step="${direction}" data-unit="${unit}" aria-label="${label}" tabindex="${tabbable ? 0 : -1}"${disabled ? ' aria-disabled="true"' : ""}></button>`

const numInput = (className, value, label, extra, arrows, tabindex = -1) =>
  `<div class="numInputWrapper"><input class="numInput ${className}" type="number" tabindex="${tabindex}" aria-label="${label}" value="${value}" ${extra}>${arrows}</div>`

/**
 * The month header, weekdays and days of the calendar as HTML. The days are a `role="grid"` of rows and
 * gridcells (`aria-selected`, `aria-disabled`, `aria-current="date"`, a long name in `aria-label`) with one Tab
 * stop, the day `focus` points at. `state.labels` has the texts (`LABELS` by default), `state.dayLabel(iso)` the name of a day.
 */
export const renderDays = (state) => {
  const {view, weekStart, names = {}, labels, dates, mode} = state
  const months = names.months ?? MONTHS
  const weekdays = names.weekdays ?? WEEKDAYS
  const order = [...Array(7)].map((_, index) => weekdays[(index + weekStart) % 7])
  const monthOptions = months
    .map((name, index) => `<option class="flatpickr-monthDropdown-month" value="${index}"${index === view.month ? " selected" : ""}>${escapeHtml(name)}</option>`)
    .join("")
  const stop = focusDay(view, state)
  const cells = monthDays(view, weekStart).map((iso) => {
    const label = state.dayLabel ? state.dayLabel(iso) : dayName(iso, "%{weekday}, %{month} %{day}, %{year}", names)
    const classes = dayClasses(iso, state)
    const off = classes.includes("flatpickr-disabled")
    return (
      `<span class="${classes}" role="gridcell" aria-label="${escapeHtml(label)}" aria-selected="${isChosen(iso, dates, mode)}"` +
      `${off ? ' aria-disabled="true"' : ""}${iso === state.today ? ' aria-current="date"' : ""} tabindex="${iso === stop ? 0 : -1}" data-date="${iso}">${Number(iso.slice(8))}</span>`
    )
  })
  const rows = [...Array(6)].map((_, row) => `<div role="row" class="flatpickr-week">${cells.slice(row * 7, row * 7 + 7).join("")}</div>`)
  const yearArrows = stepButton(1, "year", text(labels, "picker_year_up")) + stepButton(-1, "year", text(labels, "picker_year_down"))
  return (
    `<div class="flatpickr-months"><button type="button" class="flatpickr-prev-month" data-month="-1" aria-label="${text(labels, "picker_previous")}">${glyphHtml("angle_left", state.icons)}</button>` +
    `<div class="flatpickr-month"><div class="flatpickr-current-month">` +
    `<select class="flatpickr-monthDropdown-months" aria-label="${text(labels, "picker_month")}" tabindex="-1" data-month-select>${monthOptions}</select>` +
    numInput("cur-year", view.year, text(labels, "picker_year"), "data-year", yearArrows) +
    `</div></div><button type="button" class="flatpickr-next-month" data-month="1" aria-label="${text(labels, "picker_next")}">${glyphHtml("angle_right", state.icons)}</button></div>` +
    `<div class="flatpickr-innerContainer"><div class="flatpickr-rContainer" role="grid" aria-label="${escapeHtml(`${months[view.month]} ${view.year}`)}">` +
    `<div class="flatpickr-weekdays"><div class="flatpickr-weekdaycontainer" role="row">${order.map((day) => `<span class="flatpickr-weekday" role="columnheader" aria-label="${escapeHtml(day)}">${escapeHtml(day.slice(0, 3))}</span>`).join("")}</div></div>` +
    `<div class="flatpickr-days"><div class="dayContainer">${rows.join("")}</div></div>` +
    `</div></div>`
  )
}

/** Whether `unit` could be moved by `delta` steps from `time` without being held in place by `min` and `max`. */
export const canStep = (time, unit, delta, rules) => {
  const next = stepTime(time, unit, delta, rules)
  return next.hour !== time.hour || next.minute !== time.minute
}

/** Whether the AM/PM toggle would leave the time inside `min`–`max`. */
export const canToggle = ({hour, minute}, rules) => {
  const flipped = {hour: (hour + 12) % 24, minute}
  const held = clampTime(flipped, rules)
  return held.hour === flipped.hour && held.minute === flipped.minute
}

/**
 * The hour, minute and AM/PM row as HTML: boxes you can Tab to, with arrow buttons that are named and, when `min`/`max`
 * stop a step, `aria-disabled` (dimmed by the CSS).
 */
export const renderTime = ({hour, minute, twentyFour, hourStep = 1, minuteStep = 5, min, max, labels}) => {
  const rules = {hourStep, minuteStep, min, max}
  const at = {hour, minute}
  const shown = twentyFour ? pad(hour) : pad(hour % 12 || 12)
  const hours = twentyFour ? 'min="0" max="23"' : 'min="1" max="12"'
  const arrows = (unit) =>
    stepButton(1, unit, text(labels, `picker_${unit}_up`), {tabbable: true, disabled: !canStep(at, unit, 1, rules)}) +
    stepButton(-1, unit, text(labels, `picker_${unit}_down`), {tabbable: true, disabled: !canStep(at, unit, -1, rules)})
  const period = hour < 12 ? "AM" : "PM"
  const toggle = `${text(labels, "picker_toggle_period")}: ${period}`
  return (
    `<div class="flatpickr-time${twentyFour ? " time24hr" : ""}" tabindex="-1">` +
    numInput("flatpickr-hour", shown, text(labels, "picker_hour"), `step="${hourStep}" ${hours} maxlength="2" data-hour`, arrows("hour"), 0) +
    `<span class="flatpickr-time-separator">:</span>` +
    numInput("flatpickr-minute", pad(minute), text(labels, "picker_minute"), `step="${minuteStep}" min="0" max="59" maxlength="2" data-minute`, arrows("minute"), 0) +
    (twentyFour ? "" : `<button type="button" class="flatpickr-am-pm" aria-label="${toggle}"${canToggle(at, rules) ? "" : ' aria-disabled="true"'} data-ampm>${period}</button>`) +
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
