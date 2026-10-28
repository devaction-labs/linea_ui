/**
 * The month and year pickers of the date-time picker's header, without a DOM: the page of twelve years a year
 * grid shows, which months and years the `min`/`max` rules shut out, and where an arrow key moves in a grid of
 * three columns.
 */
import {daysInMonth, toIso} from "./dates.js"

export const COLUMNS = 3
export const PAGE = 12

/** The first year of the page of twelve years that holds `year` (2026 → 2016, shown as 2016–2027). */
export const yearPage = (year) => year - (((year % PAGE) + PAGE) % PAGE)

/** Whether a whole month lies before the `min` limit or after the `max` one (`{date, time}` or `null`). */
export const monthOff = ({year, month}, rules) => {
  const first = toIso(year, month, 1)
  const last = toIso(year, month, daysInMonth({year, month}))
  return Boolean((rules.min && last < rules.min.date) || (rules.max && first > rules.max.date))
}

/** Whether a whole year lies before the `min` limit or after the `max` one. */
export const yearOff = (year, rules) =>
  Boolean((rules.min && toIso(year, 11, 31) < rules.min.date) || (rules.max && toIso(year, 0, 1) > rules.max.date))

/** The index an arrow key (or Home/End) moves to in a grid of `count` items, or `null` for another key. */
export const gridTarget = (key, index, count = PAGE) => {
  const moves = {
    ArrowLeft: index - 1,
    ArrowRight: index + 1,
    ArrowUp: index - COLUMNS,
    ArrowDown: index + COLUMNS,
    Home: 0,
    End: count - 1,
  }
  return key in moves ? Math.min(Math.max(moves[key], 0), count - 1) : null
}
