/**
 * Where the keyboard goes in the calendar grid, with no DOM. The cells are numbered row by row; the arrows
 * move a day (or a week) and, past the first or the last cell, ask for the previous or the next period;
 * Home and End go to the ends of the row; Page Up and Page Down change period.
 */
import {gridTarget} from "./keys.js"

const STEPS = {
  ArrowLeft: (_columns) => -1,
  ArrowRight: (_columns) => 1,
  ArrowUp: (columns) => -columns,
  ArrowDown: (columns) => columns,
}

/**
 * What a key does from the cell `index`: `{focus: index}`, `{page: "prev" | "next"}`, or `null` for a key the
 * grid does not use.
 *
 * @param {number} index the focused cell
 * @param {string} key
 * @param {{columns: number, total: number}} grid
 */
export const calendarMove = (index, key, {columns, total}) => {
  const step = STEPS[key]?.(columns)
  const target = step === undefined ? gridTarget(index, key, {columns, total}) : index + step
  return [
    [target === null, () => null],
    [target === "prev" || target === "next", () => ({page: target})],
    [target < 0, () => ({page: "prev"})],
    [target >= total, () => ({page: "next"})],
    [true, () => ({focus: target})],
  ].find(([hit]) => hit)[1]()
}

/** The tabindex of each of `count` cells when cell `active` is the one in the Tab order. */
export const rovingStops = (count, active) => Array.from({length: count}, (_, index) => (index === active ? 0 : -1))
