import {test} from "node:test"
import assert from "node:assert/strict"
import {
  clampTime,
  dayClasses,
  formatDate,
  isDisabled,
  monthDays,
  canStep,
  canToggle,
  dayName,
  focusDay,
  isChosen,
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
  assert.match(html, /<span class="flatpickr-weekday" role="columnheader" aria-label="Monday">Mon<\/span>/)
  assert.match(html, /value="9" selected>October/)
  assert.match(html, /data-date="2026-10-23">23</)
  assert.match(renderTime({hour: 13, minute: 5, twentyFour: false}), /value="01".*value="05".*PM/s)
  assert.doesNotMatch(renderTime({hour: 13, minute: 5, twentyFour: true}), /flatpickr-am-pm/)
})

test("renderDays draws six weeks, or only the weeks of the month when compact", () => {
  const state = {view: {year: 2026, month: 9}, dates: [], mode: "single", today: "2026-10-23", rules: {}, weekStart: 0}
  const weeks = (html) => html.match(/class="flatpickr-week"/g).length
  assert.equal(weeks(renderDays(state)), 6)
  assert.equal(weeks(renderDays({...state, compact: true})), 5)
  assert.equal(weeks(renderDays({...state, compact: true, view: {year: 2026, month: 1}})), 4)
  assert.equal(weeks(renderDays({...state, compact: true, view: {year: 2026, month: 7}})), 6)
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

const STATE = {view: {year: 2026, month: 9}, dates: ["2026-10-12"], mode: "single", today: "2026-10-23", rules: {min: "2026-10-05", weekdays: [0]}, weekStart: 1}

test("renderDays is an accessible grid: rows, cells, a Tab stop, named buttons", () => {
  const html = renderDays({...STATE, labels: {picker_previous: "Mês anterior"}, names: {months: ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"], weekdays: ["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"]}})
  assert.match(html, /<button type="button" class="flatpickr-prev-month" data-month="-1" aria-label="Mês anterior">/)
  assert.match(html, /<button type="button" class="flatpickr-next-month" data-month="1" aria-label="Next month">/)
  assert.match(html, /role="grid" aria-label="Outubro 2026"/)
  assert.equal(html.match(/role="row"/g).length, 7)
  assert.equal(html.match(/role="gridcell"/g).length, 42)
  assert.equal(html.match(/role="columnheader"/g).length, 7)
  assert.match(html, /role="gridcell" aria-label="Segunda, Outubro 12, 2026" aria-selected="true" tabindex="0" data-date="2026-10-12"/)
  assert.match(html, /aria-selected="false" aria-current="date" tabindex="-1" data-date="2026-10-23"/)
  assert.match(html, /aria-selected="false" aria-disabled="true" tabindex="-1" data-date="2026-10-04"/)
  assert.equal(html.match(/tabindex="0" data-date/g).length, 1)
})

test("a day is named by the sentence of the locale, and the focus day stays in the month", () => {
  const names = {months: ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"], weekdays: ["domingo", "segunda", "terça", "quarta", "quinta", "sexta", "sábado"]}
  assert.equal(dayName("2026-10-23", "%{weekday}, %{day} de %{month} de %{year}", names), "sexta, 23 de outubro de 2026")
  assert.equal(dayName("2026-10-23", "%{weekday}, %{month} %{day}, %{year}"), "Friday, October 23, 2026")
  const view = {year: 2026, month: 9}
  assert.equal(focusDay(view, {focus: "2026-10-20"}), "2026-10-20")
  assert.equal(focusDay(view, {focus: "2026-11-02", dates: ["2026-10-03"], today: "2026-10-23"}), "2026-10-03")
  assert.equal(focusDay(view, {focus: null, dates: [], today: "2026-10-23"}), "2026-10-23")
  assert.equal(focusDay(view, {focus: null, dates: [], today: "2026-09-23"}), "2026-10-01")
})

test("a range is chosen between its ends; the other modes by the days picked", () => {
  assert.equal(isChosen("2026-10-14", ["2026-10-20", "2026-10-10"], "range"), true)
  assert.equal(isChosen("2026-10-21", ["2026-10-20", "2026-10-10"], "range"), false)
  assert.equal(isChosen("2026-10-14", ["2026-10-10"], "range"), false)
  assert.equal(isChosen("2026-10-10", ["2026-10-10"], "range"), true)
  assert.equal(isChosen("2026-10-10", ["2026-10-10", "2026-10-12"], "multiple"), true)
})

test("the time row has named, tabbable buttons that are aria-disabled when min or max stop them", () => {
  const open = renderTime({hour: 10, minute: 30, twentyFour: false, hourStep: 1, minuteStep: 5, labels: {picker_hour_up: "Mais uma hora"}})
  assert.match(open, /<button type="button" class="arrowUp" data-step="1" data-unit="hour" aria-label="Mais uma hora" tabindex="0">/)
  assert.match(open, /aria-label="Decrease minute" tabindex="0"><\/button>/)
  assert.match(open, /<button type="button" class="flatpickr-am-pm" aria-label="Toggle AM\/PM: AM" data-ampm>AM<\/button>/)
  assert.doesNotMatch(open, /aria-disabled/)
  const held = renderTime({hour: 22, minute: 30, twentyFour: true, hourStep: 1, minuteStep: 5, min: "15:00", max: "22:30"})
  assert.match(held, /data-step="1" data-unit="hour" aria-label="Increase hour" tabindex="0" aria-disabled="true"/)
  assert.match(held, /data-step="1" data-unit="minute" aria-label="Increase minute" tabindex="0" aria-disabled="true"/)
  assert.doesNotMatch(held, /data-step="-1" data-unit="hour"[^>]*aria-disabled/)
})

test("the stacked time row of the time picker puts each box between its arrows, in Tab order", () => {
  const html = renderTime({hour: 9, minute: 30, twentyFour: false, stacked: true})
  assert.match(html, /class="flatpickr-time stacked"/)
  assert.match(html, /class="numInputWrapper"><button[^>]*class="arrowUp"[^>]*data-unit="hour"[^>]*><\/button><input[^>]*data-hour><button[^>]*class="arrowDown"[^>]*data-unit="hour"/)
  assert.match(html, /<input[^>]*data-minute><button[^>]*class="arrowDown"[^>]*data-unit="minute"/)
  assert.match(renderTime({hour: 9, minute: 30, twentyFour: false}), /<input[^>]*data-hour><button[^>]*class="arrowUp"/)
  assert.doesNotMatch(renderTime({hour: 9, minute: 30, twentyFour: false}), /stacked/)
})

test("canStep and canToggle say when min and max hold a time in place", () => {
  const rules = {min: "15:00", max: "22:30", hourStep: 1, minuteStep: 5}
  assert.equal(canStep({hour: 22, minute: 30}, "minute", 1, rules), false)
  assert.equal(canStep({hour: 22, minute: 30}, "minute", -1, rules), true)
  assert.equal(canStep({hour: 15, minute: 0}, "hour", -1, rules), false)
  assert.equal(canStep({hour: 9, minute: 0}, "hour", 1, {}), true)
  assert.equal(canToggle({hour: 9, minute: 0}, {max: "10:00"}), false)
  assert.equal(canToggle({hour: 9, minute: 0}, {min: "15:00"}), true)
  assert.equal(canToggle({hour: 9, minute: 0}, {}), true)
  assert.equal(canToggle({hour: 17, minute: 0}, {min: "05:00", max: "10:00"}), true)
  assert.equal(canToggle({hour: 17, minute: 0}, {min: "05:30", max: "10:00"}), false)
})
