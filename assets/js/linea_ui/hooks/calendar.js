/**
 * `LineaUI.Calendar`: the keyboard of the calendar grid. Tab lands on one cell (roving tabindex); the arrows move
 * between cells, Home and End go to the ends of the row, Enter and Space click the cell (select the day), and
 * Page Up and Page Down, or an arrow past the first or the last cell, press the toolbar's previous and next
 * buttons, which push `on_navigate` to the server; when the new period arrives the focus lands on its cell.
 * The period itself, the events and the toolbar are rendered by the server.
 */
import {calendarMove, rovingStops} from "../lib/calendar_nav.js"
import {runKey} from "../lib/keys.js"

const Calendar = {
  mounted() {
    this.onKey = (event) => event.target.matches("[data-cell]") && this.key(event)
    this.onFocusIn = (event) => event.target.matches("[data-cell]") && this.rove(this.cells().indexOf(event.target))
    this.el.addEventListener("keydown", this.onKey)
    this.el.addEventListener("focusin", this.onFocusIn)
  },

  updated() {
    const focused = this.cells().indexOf(document.activeElement)
    this.refocus ? this.land() : focused >= 0 && this.rove(focused)
  },

  destroyed() {
    this.el.removeEventListener("keydown", this.onKey)
    this.el.removeEventListener("focusin", this.onFocusIn)
  },

  cells() {
    return [...this.el.querySelectorAll("[data-cell]")]
  },

  rove(active) {
    const cells = this.cells()
    rovingStops(cells.length, active).forEach((stop, index) => (cells[index].tabIndex = stop))
  },

  land() {
    this.refocus = false
    this.el.querySelector('[data-cell][tabindex="0"]')?.focus()
  },

  key(event) {
    const cells = this.cells()
    const index = cells.indexOf(event.target)
    const grid = {columns: Number(this.el.dataset.columns), total: cells.length}
    const click = () => event.target.click()
    const move = calendarMove(index, event.key, grid)
    const table = {Enter: click, " ": click}
    move && (table[event.key] = () => this.go(move, cells))
    runKey(table, event)
  },

  go(move, cells) {
    move.focus === undefined ? this.page(move.page) : (this.rove(move.focus), cells[move.focus].focus())
  },

  page(direction) {
    const button = this.el.querySelector(`[data-nav="${direction}"]`)
    const available = button && !button.disabled
    available && ((this.refocus = true), button.click())
    return available
  },
}

export default {"LineaUI.Calendar": Calendar}
