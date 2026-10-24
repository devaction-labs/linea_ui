/**
 * What a pick does to the value of the date-time picker, without a DOM. The value is `{start, end}`, each a
 * moment `{date, time}` or `null`; a single picker only uses `start`. Every function gets the context `ctx`:
 * `{mode, rules, times, defaults: {start, end}}` (the rules and the time slots of `datetime_rules.js`, the
 * `default_time` of each end).
 */
import {monthOf, pick, shiftMonth} from "./dates.js"
import {isDateAvailable, isSlotAvailable, joinDateTime, nearestTime, parseDateTime, rulesFrom, timeSlots} from "./datetime_rules.js"

const complete = (moment) => Boolean(moment?.date && moment?.time)

const firstOpen = (date, candidates, ctx, rules) =>
  candidates.find((time) => time && isSlotAvailable(date, time, rules)) ?? nearestTime(date, null, ctx.times, rules)

const settleOne = (moment, candidates, ctx, rules) =>
  moment?.date ? {date: moment.date, time: moment.time ?? firstOpen(moment.date, candidates, ctx, rules)} : null

/** The state of a list of values (`["2026-10-14T10:30"]`, or two for a range); a day without a time gets the default one. */
export const fromValues = (values, ctx) => {
  const start = settleOne(parseDateTime(values[0]), [ctx.defaults.start], ctx, ctx.rules)
  const end = settleOne(parseDateTime(values[1]), [ctx.defaults.end], ctx, rulesFrom(ctx.rules, start))
  return {start, end: ctx.mode === "range" ? end : null}
}

/** The values the form gets: one moment, or two for a range, and none until the choice is complete. */
export const toValues = (state, mode) => {
  const moments = mode === "range" ? [state.start, state.end] : [state.start]
  return moments.every(complete) ? moments.map(joinDateTime) : []
}

/** Whether the choice is complete: a day and time, and for a range both ends. */
export const isComplete = (state, mode) => toValues(state, mode).length > 0

/** The state after picking the day `iso`: a single picker takes it with a fitting time; a range starts, closes or restarts. */
export const pickDay = (state, iso, ctx) =>
  ctx.mode === "range" ? pickRangeDay(state, iso, ctx) : pickSingleDay(state, iso, ctx)

const pickSingleDay = (state, iso, ctx) => {
  const time = firstOpen(iso, [state.start?.time, ctx.defaults.start], ctx, ctx.rules)
  return time ? {start: {date: iso, time}, end: null} : state
}

const pickRangeDay = (state, iso, ctx) => {
  const {from, to} = pick({from: state.start?.date ?? null, to: state.end?.date ?? null}, iso, "range")
  const startTime = firstOpen(from, [state.start?.time, ctx.defaults.start], ctx, ctx.rules)
  const start = startTime ? {date: from, time: startTime} : null
  const endTime = to && start ? firstOpen(to, [state.end?.time, ctx.defaults.end], ctx, rulesFrom(ctx.rules, start)) : null
  return start ? {start, end: endTime ? {date: to, time: endTime} : null} : state
}

/** The state after choosing `time` for `which` end (`"start"` or `"end"`); a range end before the start is moved to it. */
export const pickTime = (state, which, time) => (which === "end" ? withEnd(state, time) : withStart(state, time))

const withEnd = (state, time) => (state.end ? {...state, end: {...state.end, time}} : state)

const withStart = (state, time) => {
  const start = state.start ? {...state.start, time} : state.start
  const behind = start && state.end && state.end.date === start.date && state.end.time < time
  return {start, end: behind ? {...state.end, time} : state.end}
}

/** The rules for the time of `which` end: the end of a range cannot be before its start. */
export const rulesFor = (state, which, rules) => (which === "end" ? rulesFrom(rules, state.start) : rules)

/** The slots of the time control of `which` end of the state. */
export const slotsFor = (state, which, ctx) => {
  const moment = which === "end" ? state.end : state.start
  return moment?.date ? timeSlots(moment.date, ctx.times, rulesFor(state, which, ctx.rules)) : []
}

/**
 * Whether a day can be picked in the calendar: a slot is open on it. With only the start of a range chosen, a day
 * from the start on also needs a slot from the start's time on; a day before it restarts the range.
 */
export const isDayAvailable = (iso, state, ctx) => {
  const closing = ctx.mode === "range" && state.start && !state.end && iso >= state.start.date
  return isDateAvailable(iso, ctx.times, closing ? rulesFrom(ctx.rules, state.start) : ctx.rules)
}

/** The day the calendar starts at: the start of the choice, else `today` held inside the date limits. */
export const anchorDay = (state, today, rules) => {
  const day = state.start?.date ?? today
  const low = rules.min && day < rules.min.date ? rules.min.date : day
  return rules.max && low > rules.max.date ? rules.max.date : low
}

/** The first month to show for the state. */
export const viewFor = (state, today, rules) => monthOf(anchorDay(state, today, rules))

/** The view that shows the month of `iso` among `count` months from `view`: moved by the least it takes. */
export const showMonth = (view, count, iso) => {
  const target = monthOf(iso)
  const index = (target.year - view.year) * 12 + (target.month - view.month)
  return index < 0 ? target : index >= count ? shiftMonth(target, -(count - 1)) : view
}
