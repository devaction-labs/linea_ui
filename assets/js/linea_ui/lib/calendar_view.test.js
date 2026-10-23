import {test} from "node:test"
import assert from "node:assert/strict"
import {
  clampTime,
  dayClasses,
  formatDate,
  isDisabled,
  monthDays,
  pickDate,
  readTime,
  renderDays,
  renderTime,
  setUnit,
  stepTime,
  timeText,
} from "./calendar_view.js"

test("formatDate writes flatpickr tokens", () => {
  assert.equal(formatDate("2026-10-03", null, "Y-m-d"), "2026-10-03")
  assert.equal(formatDate("2026-10-03", null, "F j, Y"), "October 3, 2026")
  assert.equal(formatDate("2026-10-03", null, "D, M n y"), "Sat, Oct 10 26")
  assert.equal(formatDate("2026-10-03", {hour: 13, minute: 5}, "Y-m-d H:i"), "2026-10-03 13:05")
  assert.equal(formatDate("2026-10-03", {hour: 0, minute: 5}, "h:i K"), "12:05 AM")
  const months = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Outubro", "Nov", "Dez"]
  assert.equal(formatDate("2026-10-03", null, "F", {months}), "Outubro")
})

test("isDisabled reads min, max, dates and weekdays", () => {
  const rules = {min: "2026-10-05", max: "2026-10-20", dates: ["2026-10-07"], weekdays: [0, 6]}
  assert.equal(isDisabled("2026-10-04", rules), true)
  assert.equal(isDisabled("2026-10-21", rules), true)
  assert.equal(isDisabled("2026-10-07", rules), true)
  assert.equal(isDisabled("2026-10-10", rules), true)
  assert.equal(isDisabled("2026-10-08", rules), false)
  assert.equal(isDisabled("2026-10-08", {}), false)
})

test("pickDate in each mode", () => {
  assert.deepEqual(pickDate(["2026-10-01"], "2026-10-02", "single"), ["2026-10-02"])
  assert.deepEqual(pickDate(["2026-10-01"], "2026-10-02", "multiple"), ["2026-10-01", "2026-10-02"])
  assert.deepEqual(pickDate(["2026-10-01", "2026-10-02"], "2026-10-02", "multiple"), ["2026-10-01"])
  assert.deepEqual(pickDate([], "2026-10-05", "range"), ["2026-10-05"])
  assert.deepEqual(pickDate(["2026-10-05"], "2026-10-02", "range"), ["2026-10-02", "2026-10-05"])
  assert.deepEqual(pickDate(["2026-10-02", "2026-10-05"], "2026-10-09", "range"), ["2026-10-09"])
})

test("monthDays draws 42 days from the week start", () => {
  const days = monthDays({year: 2026, month: 9}, 0)
  assert.equal(days.length, 42)
  assert.equal(days[0], "2026-09-27")
  assert.equal(days[4], "2026-10-01")
  assert.equal(monthDays({year: 2026, month: 9}, 1)[0], "2026-09-28")
})

test("dayClasses marks the days like flatpickr", () => {
  const base = {view: {year: 2026, month: 9}, dates: [], mode: "single", today: "2026-10-23", rules: {}}
  assert.equal(dayClasses("2026-09-30", base), "flatpickr-day prevMonthDay")
  assert.equal(dayClasses("2026-11-01", base), "flatpickr-day nextMonthDay")
  assert.equal(dayClasses("2026-10-23", base), "flatpickr-day today")
  assert.equal(dayClasses("2026-10-02", {...base, dates: ["2026-10-02"]}), "flatpickr-day selected")
  const range = {...base, mode: "range", dates: ["2026-10-02", "2026-10-06"]}
  assert.equal(dayClasses("2026-10-02", range), "flatpickr-day selected startRange")
  assert.equal(dayClasses("2026-10-04", range), "flatpickr-day inRange")
  assert.equal(dayClasses("2026-10-06", range), "flatpickr-day selected endRange")
  assert.equal(dayClasses("2026-10-04", {...range, dates: ["2026-10-02"], hover: "2026-10-05"}), "flatpickr-day inRange")
  assert.equal(dayClasses("2026-10-10", {...base, rules: {weekdays: [6]}}), "flatpickr-day flatpickr-disabled")
})

test("renderDays and renderTime build flatpickr's panels", () => {
  const html = renderDays({view: {year: 2026, month: 9}, dates: [], mode: "single", today: "2026-10-23", rules: {}, weekStart: 1})
  assert.match(html, /<span class="flatpickr-weekday">Mon<\/span>/)
  assert.match(html, /value="9" selected>October/)
  assert.match(html, /data-date="2026-10-23">23</)
  assert.match(renderTime({hour: 13, minute: 5, twentyFour: false}), /value="01".*value="05".*PM/s)
  assert.doesNotMatch(renderTime({hour: 13, minute: 5, twentyFour: true}), /flatpickr-am-pm/)
})

test("time arithmetic", () => {
  assert.deepEqual(stepTime({hour: 23, minute: 55}, "minute", 1), {hour: 0, minute: 0})
  assert.deepEqual(stepTime({hour: 10, minute: 0}, "hour", -1), {hour: 9, minute: 0})
  assert.deepEqual(stepTime({hour: 22, minute: 0}, "hour", 1, {max: "22:30"}), {hour: 22, minute: 30})
  assert.deepEqual(clampTime({hour: 9, minute: 0}, {min: "15:00"}), {hour: 15, minute: 0})
  assert.deepEqual(setUnit({hour: 13, minute: 0}, "hour", 3, false), {hour: 15, minute: 0})
  assert.deepEqual(setUnit({hour: 13, minute: 0}, "hour", 3, true), {hour: 3, minute: 0})
  assert.deepEqual(setUnit({hour: 13, minute: 0}, "minute", 75, true), {hour: 13, minute: 59})
  assert.equal(timeText({hour: 9, minute: 5}), "09:05")
  assert.deepEqual(readTime("2026-01-01 13:13", null), {hour: 13, minute: 13})
  assert.equal(readTime("", null), null)
})
