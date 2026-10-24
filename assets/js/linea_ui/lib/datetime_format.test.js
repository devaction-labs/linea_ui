import assert from "node:assert/strict"
import test from "node:test"
import {fill, formatMoment, formatTime, formatValue, nearestSlot, parseTimeText, suggestSlots} from "./datetime_format.js"

const NAMES = {months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"], weekdays: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]}

test("a time is written on a 12 or a 24-hour clock", () => {
  assert.equal(formatTime("00:00", true), "12:00 AM")
  assert.equal(formatTime("09:05", true), "9:05 AM")
  assert.equal(formatTime("12:30", true), "12:30 PM")
  assert.equal(formatTime("23:45", true), "11:45 PM")
  assert.equal(formatTime("09:05", false), "09:05")
  assert.equal(formatTime("23:45", false), "23:45")
})

test("typed times are read in the ways people write them", () => {
  assert.equal(parseTimeText("9"), "09:00")
  assert.equal(parseTimeText("930"), "09:30")
  assert.equal(parseTimeText("0930"), "09:30")
  assert.equal(parseTimeText("9:30"), "09:30")
  assert.equal(parseTimeText("9.30"), "09:30")
  assert.equal(parseTimeText("21:15"), "21:15")
  assert.equal(parseTimeText("9:30 pm"), "21:30")
  assert.equal(parseTimeText("9pm"), "21:00")
  assert.equal(parseTimeText("12 am"), "00:00")
  assert.equal(parseTimeText("12:15 PM"), "12:15")
  assert.equal(parseTimeText(" 7:05 a.m. "), "07:05")
})

test("text that is not a time is refused", () => {
  assert.equal(parseTimeText(""), null)
  assert.equal(parseTimeText("25:00"), null)
  assert.equal(parseTimeText("9:75"), null)
  assert.equal(parseTimeText("13 pm"), null)
  assert.equal(parseTimeText("0 am"), null)
  assert.equal(parseTimeText("noon"), null)
  assert.equal(parseTimeText(null), null)
})

test("suggestions keep the slots that contain what was typed", () => {
  const slots = ["08:00", "08:30", "09:00", "13:00", "20:30"].map((time) => ({time, disabled: false}))
  assert.equal(suggestSlots(slots, "", true).length, 5)
  assert.deepEqual(suggestSlots(slots, "8:30", true).map(({time}) => time), ["08:30", "20:30"])
  assert.deepEqual(suggestSlots(slots, "pm", true).map(({time}) => time), ["13:00", "20:30"])
  assert.deepEqual(suggestSlots(slots, "13", false).map(({time}) => time), ["13:00"])
  assert.deepEqual(suggestSlots(slots, "zzz", true), [])
})

test("the nearest slot to a time", () => {
  const slots = ["08:00", "09:00", "10:00"].map((time) => ({time, disabled: false}))
  assert.equal(nearestSlot(slots, "09:20").time, "09:00")
  assert.equal(nearestSlot(slots, "09:40").time, "10:00")
  assert.equal(nearestSlot(slots, null).time, "08:00")
  assert.equal(nearestSlot([], "09:00"), null)
})

test("a moment is written in flatpickr tokens", () => {
  assert.equal(formatMoment({date: "2026-10-14", time: "14:30"}, "M j, Y, h:i K", NAMES), "Oct 14, 2026, 2:30 PM")
  assert.equal(formatMoment({date: "2026-10-14", time: "09:05"}, "d/m/Y H:i", NAMES), "14/10/2026 09:05")
  assert.equal(formatMoment(null, "d/m/Y H:i", NAMES), "")
})

test("the text of a value: one moment, or a range joined by the separator", () => {
  const spec = {mode: "single", format: "d/m/Y H:i", names: NAMES, separator: " – "}
  const start = {date: "2026-10-14", time: "09:00"}
  const end = {date: "2026-10-20", time: "17:30"}
  assert.equal(formatValue({start, end: null}, spec), "14/10/2026 09:00")
  assert.equal(formatValue({start: null, end: null}, spec), "")
  assert.equal(formatValue({start, end}, {...spec, mode: "range"}), "14/10/2026 09:00 – 20/10/2026 17:30")
  assert.equal(formatValue({start, end: null}, {...spec, mode: "range"}), "")
})

test("sentences are filled with their values", () => {
  assert.equal(fill("%{weekday}, %{month} %{day}, %{year}", {weekday: "Wednesday", month: "October", day: 14, year: 2026}), "Wednesday, October 14, 2026")
  assert.equal(fill("%{a} and %{a}", {a: "x"}), "x and x")
})
