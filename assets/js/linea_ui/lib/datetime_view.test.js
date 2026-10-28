import assert from "node:assert/strict"
import test from "node:test"
import {bandClass, dayClass, optionClass, renderMonth, renderPanel, renderSuggestions, renderTimeList} from "./datetime_view.js"

const NAMES = {
  months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
  weekdays: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
}

const LABELS = {
  datetime_day: "%{weekday}, %{month} %{day}, %{year}",
  datetime_title: "%{month} %{year}",
  datetime_previous: "Previous month",
  datetime_next: "Next month",
  datetime_choose_month: "Choose month",
  datetime_choose_year: "Choose year",
  datetime_times: "Times",
  datetime_no_times: "No times available",
  datetime_time: "Time",
  datetime_start: "Start",
  datetime_end: "End",
  datetime_select: "Select",
  datetime_select_range: "Select range",
  datetime_cancel: "Cancel",
  datetime_time_placeholder: "hh:mm",
}

const slots = (...times) => times.map((time) => ({time, disabled: false}))

const model = (extra = {}) => ({
  id: "dt",
  mode: "single",
  layout: "desktop",
  timeMode: "list",
  hour12: true,
  view: {year: 2026, month: 9},
  state: {start: {date: "2026-10-14", time: "10:30"}, end: null},
  hover: null,
  focus: "2026-10-14",
  today: "2026-10-14",
  weekStart: 0,
  names: NAMES,
  labels: LABELS,
  icons: "lineone",
  isOff: () => false,
  slots: {start: slots("09:00", "10:30", "12:00"), end: []},
  dateText: (iso) => iso,
  canConfirm: true,
  rules: {min: null, max: null},
  picking: null,
  page: undefined,
  ...extra,
})

const count = (html, needle) => html.split(needle).length - 1

test("a month has its title, 31 days and the days before its first as empty cells", () => {
  const html = renderMonth({year: 2026, month: 9}, {previous: true, next: true}, model())
  assert.equal(count(html, "data-day="), 31)
  assert.equal(count(html, 'role="gridcell"></div>'), 4)
  assert.match(html, /October 2026/)
  assert.match(html, /data-nav="-1"/)
  assert.match(html, /data-nav="1"/)
  assert.match(html, /aria-label="Wednesday, October 14, 2026"/)
})

test("the week starts where week_start says", () => {
  const html = renderMonth({year: 2026, month: 9}, {previous: true, next: true}, model({weekStart: 1}))
  assert.equal(count(html, 'role="gridcell"></div>'), 3)
  assert.ok(html.indexOf('aria-label="Monday"') < html.indexOf('aria-label="Sunday"'))
})

test("only the focused day is in the tab order, today is marked and the chosen day is pressed", () => {
  const html = renderMonth({year: 2026, month: 9}, {previous: false, next: false}, model())
  assert.equal(count(html, 'tabindex="0"'), 1)
  assert.match(html, /data-day="2026-10-14" tabindex="0"/)
  assert.match(html, /aria-current="date"/)
  assert.equal(count(html, 'aria-selected="true"'), 1)
  assert.equal(count(html, "data-nav="), 0)
})

test("a day out of reach is aria-disabled", () => {
  const html = renderMonth({year: 2026, month: 9}, {previous: true, next: true}, model({isOff: (iso) => iso < "2026-10-10"}))
  assert.equal(count(html, 'aria-disabled="true"'), 9)
})

test("a range paints a band between its ends", () => {
  const state = {start: {date: "2026-10-12", time: "09:00"}, end: {date: "2026-10-16", time: "17:00"}}
  const html = renderMonth({year: 2026, month: 9}, {previous: true, next: true}, model({mode: "range", state}))
  assert.equal(count(html, 'class="bg-primary/10'), 5)
  assert.equal(count(html, 'aria-selected="true"'), 5)
})

test("the hover previews the range up to the pointer", () => {
  const state = {start: {date: "2026-10-12", time: "09:00"}, end: null}
  const html = renderMonth({year: 2026, month: 9}, {previous: true, next: true}, model({mode: "range", state, hover: "2026-10-15"}))
  assert.equal(count(html, 'class="bg-primary/10'), 4)
})

test("a single desktop panel is one month and the time list", () => {
  const html = renderPanel(model())
  assert.equal(count(html, "data-month="), 1)
  assert.match(html, /role="listbox" aria-label="Times" data-time-list/)
  assert.equal(count(html, "data-time="), 3)
  assert.equal(count(html, "data-confirm"), 0)
  assert.match(html, /data-time="10:30" aria-selected="true"/)
  assert.match(html, />10:30 AM</)
})

test("the time list marks closed slots and keeps one tab stop", () => {
  const list = renderTimeList([{time: "09:00", disabled: true}, {time: "10:30", disabled: false}], "11:00", model())
  assert.match(list, /data-time="09:00" aria-selected="false" aria-disabled="true"/)
  assert.equal(count(list, 'tabindex="0"'), 1)
  assert.match(list, /data-time="10:30" aria-selected="false" tabindex="0"/)
  assert.match(renderTimeList([], null, model()), /No times available/)
})

test("a 24-hour clock writes the times without AM or PM", () => {
  const html = renderPanel(model({hour12: false}))
  assert.match(html, />10:30</)
  assert.doesNotMatch(html, /AM|PM/)
})

test("a typed-time panel has the field with its suggestions and no list or button", () => {
  const html = renderPanel(model({timeMode: "input"}))
  assert.match(html, /role="combobox"/)
  assert.match(html, /data-time-input="start"/)
  assert.match(html, /value="10:30 AM"/)
  assert.match(html, /data-suggestions="start" aria-label="Times"/)
  assert.equal(count(html, "data-time-list"), 0)
  assert.equal(count(html, "data-confirm"), 0)
})

test("a range on a wide screen shows two months, both ends and Select range", () => {
  const state = {start: {date: "2026-10-12", time: "09:00"}, end: {date: "2026-10-16", time: "17:00"}}
  const html = renderPanel(model({mode: "range", state, slots: {start: slots("09:00"), end: slots("17:00")}}))
  assert.equal(count(html, "data-month="), 2)
  assert.equal(count(html, 'data-nav="-1"'), 1)
  assert.equal(count(html, 'data-nav="1"'), 1)
  assert.equal(count(html, "data-time-select="), 2)
  assert.match(html, /data-time-select="start"/)
  assert.match(html, /data-time-select="end"/)
  assert.match(html, />Select range</)
  assert.equal(count(html, "data-time-list"), 0)
})

test("the confirm button is disabled until the choice is complete", () => {
  assert.equal(count(renderPanel(model({mode: "range", canConfirm: false})), "data-confirm class"), 1)
  assert.match(renderPanel(model({mode: "range", canConfirm: false})), /data-confirm class="[^"]*" disabled>/)
  assert.doesNotMatch(renderPanel(model({mode: "range", canConfirm: true})), /data-confirm class="[^"]*" disabled>/)
})

test("a range before its end is picked disables the end control", () => {
  const state = {start: {date: "2026-10-12", time: "09:00"}, end: null}
  const html = renderPanel(model({mode: "range", state, slots: {start: slots("09:00"), end: []}}))
  assert.match(html, /data-time-select="end" aria-label="End" disabled class=/)
  assert.doesNotMatch(html, /data-time-select="start" aria-label="Start" disabled class=/)
})

test("on a narrow screen it is one month, a dropdown for the time and a Select button", () => {
  const html = renderPanel(model({layout: "mobile", slots: {start: slots("09:00", "10:30"), end: []}}))
  assert.equal(count(html, "data-month="), 1)
  assert.equal(count(html, "data-time-list"), 0)
  assert.equal(count(html, "data-time-select="), 1)
  assert.match(html, /<option value="10:30" selected>10:30 AM<\/option>/)
  assert.match(html, />Select</)
  assert.match(html, /w-\[min\(21rem,calc\(100vw-1rem\)\)\]/)
})

test("a range on a narrow screen is one month with both controls", () => {
  const html = renderPanel(model({layout: "mobile", mode: "range", slots: {start: slots("09:00"), end: slots("17:00")}}))
  assert.equal(count(html, "data-month="), 1)
  assert.equal(count(html, "data-time-select="), 2)
  assert.match(html, />Select range</)
})

test("closed options in the dropdown are disabled", () => {
  const html = renderPanel(model({layout: "mobile", slots: {start: [{time: "09:00", disabled: true}, {time: "10:30", disabled: false}], end: []}}))
  assert.match(html, /<option value="09:00" disabled>/)
})

test("suggestions mark the chosen, the active and the closed ones, and say when there are none", () => {
  const html = renderSuggestions("start", [{time: "09:00", disabled: true}, {time: "10:30", disabled: false}], "10:30", "10:30", model())
  assert.match(html, /data-suggest="09:00"[^>]*aria-disabled="true"/)
  assert.match(html, /data-suggest="10:30"[^>]*aria-selected="true"/)
  assert.match(html, /data-suggest="10:30"[^>]*data-active/)
  assert.match(renderSuggestions("start", [], null, null, model()), /No times available/)
})

test("text from the server is escaped", () => {
  const html = renderPanel(model({names: {...NAMES, months: NAMES.months.map(() => '<b>"x"</b>')}}))
  assert.doesNotMatch(html, /<b>/)
  assert.match(html, /&lt;b&gt;/)
})

test("class helpers: the ends are inverted, closed days dimmed, today ringed", () => {
  assert.match(dayClass({edge: true, off: false, today: false}), /bg-primary/)
  assert.match(dayClass({edge: false, off: true, today: false}), /cursor-not-allowed/)
  assert.match(dayClass({edge: false, off: false, today: true}), /after:size-1 after:rounded-full/)
  assert.doesNotMatch(dayClass({edge: false, off: false, today: true}), /ring-1/)
  assert.doesNotMatch(dayClass({edge: true, off: false, today: true}), /after:size-1/)
  assert.match(optionClass({selected: true, disabled: false}), /bg-primary/)
  assert.match(optionClass({selected: false, disabled: true}), /cursor-not-allowed/)
  assert.match(optionClass({selected: false, disabled: true}), /line-through opacity-50/)
  assert.doesNotMatch(optionClass({selected: false, disabled: false}), /line-through/)
  assert.equal(bandClass({paints: false, roundStart: false, roundEnd: false}), "")
  assert.match(bandClass({paints: true, roundStart: true, roundEnd: false}), /rounded-l-lg/)
})

test("a range footer has Cancel before the confirm button; a single desktop panel has neither", () => {
  const range = renderPanel(model({mode: "range", state: {start: null, end: null}, slots: {start: slots("09:00"), end: slots("17:00")}}))
  assert.match(range, /data-cancel class="[^"]*">Cancel<\/button><button type="button" data-confirm/)
  assert.equal(count(renderPanel(model()), "data-cancel"), 0)
  assert.equal(count(renderPanel(model({layout: "mobile"})), "data-cancel"), 1)
})

test("the header of a month has a month button and a year button, named by labels", () => {
  const html = renderMonth({year: 2026, month: 9}, {previous: true, next: true, index: 0}, model({labels: {...LABELS, datetime_choose_month: "Escolher mês"}}))
  assert.match(html, /<button type="button" id="dt-pick-month-0" data-pick="month" aria-label="Escolher mês" aria-haspopup="true" aria-expanded="false"[^>]*>October<svg/)
  assert.match(html, /data-pick="year" aria-label="Choose year" aria-haspopup="true" aria-expanded="false"[^>]*>2026<\/button>/)
  assert.match(html, /role="grid" aria-labelledby="dt-title-2026-9"/)
  assert.match(html, /id="dt-title-2026-9" aria-live="polite" class="sr-only">October 2026/)
})

test("picking a month swaps the days of that month for a grid of twelve months with one Tab stop", () => {
  const html = renderMonth({year: 2026, month: 9}, {previous: true, next: true, index: 0}, model({picking: {kind: "month", index: 0}}))
  assert.equal(count(html, "data-pick-month="), 12)
  assert.equal(count(html, "data-day="), 0)
  assert.equal(count(html, 'role="grid"'), 0)
  assert.match(html, /data-pick-grid="month"/)
  assert.match(html, /aria-expanded="true"/)
  assert.equal(count(html, 'tabindex="0"'), 1)
  assert.match(html, /data-pick-month="9" tabindex="0" aria-label="October" aria-pressed="true"[^>]*>Oct</)
  assert.match(html, /data-pick-month="0" tabindex="-1" aria-label="January" aria-pressed="false"[^>]*>Jan</)
})

test("the year grid is a page of twelve years and the rules dim the months and years they close", () => {
  const years = renderMonth({year: 2026, month: 9}, {previous: true, next: true, index: 0}, model({picking: {kind: "year", index: 0}, rules: {min: {date: "2020-06-01", time: null}, max: null}}))
  assert.equal(count(years, "data-pick-year="), 12)
  assert.match(years, /data-pick-year="2016"[^>]*aria-disabled="true"/)
  assert.doesNotMatch(years, /data-pick-year="2020"[^>]*aria-disabled/)
  assert.match(years, /data-pick-year="2026" tabindex="0" aria-label="2026" aria-pressed="true"/)
  assert.match(years, /aria-label="Choose year \(2016\u20132027\)"/)
  const next = renderMonth({year: 2026, month: 9}, {previous: true, next: true, index: 0}, model({picking: {kind: "year", index: 0}, page: 2028}))
  assert.match(next, /data-pick-year="2028" tabindex="0"/)
  assert.match(next, /data-pick-year="2039"/)
  const months = renderMonth({year: 2026, month: 9}, {previous: true, next: true, index: 0}, model({picking: {kind: "month", index: 0}, rules: {min: {date: "2026-10-05", time: null}, max: null}}))
  assert.match(months, /data-pick-month="8"[^>]*aria-disabled="true"/)
  assert.doesNotMatch(months, /data-pick-month="9"[^>]*aria-disabled/)
})

test("in a range only the month that was asked for shows its grid", () => {
  const html = renderPanel(model({mode: "range", state: {start: null, end: null}, picking: {kind: "month", index: 1}}))
  assert.equal(count(html, "data-pick-month="), 12)
  assert.equal(count(html, "data-day="), 31)
})
