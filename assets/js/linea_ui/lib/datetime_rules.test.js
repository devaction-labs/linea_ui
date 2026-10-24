import assert from "node:assert/strict"
import test from "node:test"
import {
  buildRules,
  fromMinutes,
  intervalOf,
  isDate,
  isDateAvailable,
  isSlotAvailable,
  joinDateTime,
  nearestTime,
  normalizeTime,
  parseDateTime,
  parseDefaultTime,
  parseUnavailable,
  resolveLimit,
  rulesFrom,
  slotTimes,
  splitList,
  timeSlots,
  toMinutes,
} from "./datetime_rules.js"

const NOW = {date: "2026-10-14", time: "10:12"}
const rules = (extra = {}) => buildRules(extra, NOW)

test("times of day are read and written as HH:MM", () => {
  assert.equal(toMinutes("09:30"), 570)
  assert.equal(toMinutes("9:30"), 570)
  assert.equal(toMinutes("24:00"), null)
  assert.equal(toMinutes("10:75"), null)
  assert.equal(toMinutes("nope"), null)
  assert.equal(fromMinutes(570), "09:30")
  assert.equal(normalizeTime("9:05"), "09:05")
  assert.equal(normalizeTime(undefined), null)
})

test("only days that exist are dates", () => {
  assert.equal(isDate("2026-10-14"), true)
  assert.equal(isDate("2026-02-30"), false)
  assert.equal(isDate("14/10/2026"), false)
})

test("a wall-clock value is read without a time zone and without conversion", () => {
  assert.deepEqual(parseDateTime("2026-10-14T10:30"), {date: "2026-10-14", time: "10:30"})
  assert.deepEqual(parseDateTime("2026-10-14 10:30"), {date: "2026-10-14", time: "10:30"})
  assert.deepEqual(parseDateTime("2026-10-14T10:30:45"), {date: "2026-10-14", time: "10:30"})
  assert.deepEqual(parseDateTime("2026-10-24T09:30:00Z"), {date: "2026-10-24", time: "09:30"})
  assert.deepEqual(parseDateTime("2026-10-14"), {date: "2026-10-14", time: null})
  assert.equal(parseDateTime("2026-10-14T25:00"), null)
  assert.equal(parseDateTime("2026-13-14T10:00"), null)
  assert.equal(parseDateTime(""), null)
  assert.equal(parseDateTime(null), null)
  assert.equal(joinDateTime({date: "2026-10-14", time: "10:30"}), "2026-10-14T10:30")
  assert.equal(joinDateTime({date: "2026-10-14", time: null}), "2026-10-14")
})

test("a list is a comma separated text or an array", () => {
  assert.deepEqual(splitList("2026-10-14, 12:00-13:00 ,,"), ["2026-10-14", "12:00-13:00"])
  assert.deepEqual(splitList(["a", " b "]), ["a", "b"])
  assert.deepEqual(splitList(null), [])
})

test("unavailable entries are sorted by what they are", () => {
  const found = parseUnavailable("2026-10-14, 12:00-13:00, 2026-10-15T10:00, 22:00-02:00, rubbish, 2026-02-30")
  assert.deepEqual([...found.dates], ["2026-10-14"])
  assert.deepEqual(found.daily, [{from: 720, to: 780}, {from: 1320, to: 120}])
  assert.deepEqual([...found.moments], ["2026-10-15T10:00"])
})

test("limits accept now, today and ISO", () => {
  assert.deepEqual(resolveLimit("now", NOW), {date: "2026-10-14", time: "10:12"})
  assert.deepEqual(resolveLimit("Today", NOW), {date: "2026-10-14", time: null})
  assert.deepEqual(resolveLimit("2026-12-01", NOW), {date: "2026-12-01", time: null})
  assert.deepEqual(resolveLimit("2026-12-01T08:00", NOW), {date: "2026-12-01", time: "08:00"})
  assert.equal(resolveLimit("", NOW), null)
  assert.equal(resolveLimit("soon", NOW), null)
  assert.equal(resolveLimit(null, NOW), null)
})

test("the step is a whole number of minutes, 30 by default", () => {
  assert.equal(intervalOf(15), 15)
  assert.equal(intervalOf("45"), 45)
  assert.equal(intervalOf(0), 30)
  assert.equal(intervalOf(2.5), 30)
  assert.equal(intervalOf(undefined), 30)
})

test("slots run every interval from midnight and stay inside min_time and max_time", () => {
  assert.equal(slotTimes(30, rules()).length, 48)
  assert.equal(slotTimes(60, rules()).at(-1), "23:00")
  assert.deepEqual(slotTimes(60, rules({minTime: "09:00", maxTime: "12:00"})), ["09:00", "10:00", "11:00", "12:00"])
})

test("a closed day, a daily range and a date-time close their slots", () => {
  const closed = rules({unavailable: "2026-10-20, 12:00-13:00, 2026-10-21T10:00"})
  assert.equal(isSlotAvailable("2026-10-20", "09:00", closed), false)
  assert.equal(isSlotAvailable("2026-10-19", "11:30", closed), true)
  assert.equal(isSlotAvailable("2026-10-19", "12:00", closed), false)
  assert.equal(isSlotAvailable("2026-10-19", "12:30", closed), false)
  assert.equal(isSlotAvailable("2026-10-19", "13:00", closed), true)
  assert.equal(isSlotAvailable("2026-10-21", "10:00", closed), false)
  assert.equal(isSlotAvailable("2026-10-21", "10:30", closed), true)
})

test("a daily range can cross midnight", () => {
  const night = rules({unavailable: ["22:00-02:00"]})
  assert.equal(isSlotAvailable("2026-10-19", "23:30", night), false)
  assert.equal(isSlotAvailable("2026-10-19", "01:00", night), false)
  assert.equal(isSlotAvailable("2026-10-19", "02:00", night), true)
})

test("min now closes the earlier times of today and every earlier day", () => {
  const future = rules({min: "now"})
  assert.equal(isSlotAvailable("2026-10-13", "23:00", future), false)
  assert.equal(isSlotAvailable("2026-10-14", "10:00", future), false)
  assert.equal(isSlotAvailable("2026-10-14", "10:30", future), true)
  assert.equal(isSlotAvailable("2026-10-15", "00:00", future), true)
})

test("min today keeps the whole day and max closes what follows", () => {
  const window = rules({min: "today", max: "2026-10-16T15:00"})
  assert.equal(isSlotAvailable("2026-10-14", "00:00", window), true)
  assert.equal(isSlotAvailable("2026-10-13", "23:30", window), false)
  assert.equal(isSlotAvailable("2026-10-16", "15:00", window), true)
  assert.equal(isSlotAvailable("2026-10-16", "15:30", window), false)
  assert.equal(isSlotAvailable("2026-10-17", "09:00", window), false)
})

test("time slots mark the closed ones disabled", () => {
  const closed = rules({unavailable: "12:00-13:00", minTime: "11:00", maxTime: "14:00"})
  const times = slotTimes(30, closed)
  assert.deepEqual(
    timeSlots("2026-10-19", times, closed).map(({time, disabled}) => `${time}${disabled ? "x" : ""}`),
    ["11:00", "11:30", "12:00x", "12:30x", "13:00", "13:30", "14:00"],
  )
})

test("a date is available when one slot is", () => {
  const closed = rules({unavailable: "2026-10-20", min: "now"})
  const times = slotTimes(30, closed)
  assert.equal(isDateAvailable("2026-10-20", times, closed), false)
  assert.equal(isDateAvailable("2026-10-13", times, closed), false)
  assert.equal(isDateAvailable("2026-10-14", times, closed), true)
  assert.equal(isDateAvailable("2026-10-14", times, rules({min: "now", minTime: "08:00", maxTime: "10:00"})), false)
})

test("the nearest time is the wanted one, else the first open slot, else nothing", () => {
  const closed = rules({unavailable: "09:00-12:00"})
  const times = slotTimes(30, closed)
  assert.equal(nearestTime("2026-10-19", "13:00", times, closed), "13:00")
  assert.equal(nearestTime("2026-10-19", "10:00", times, closed), "00:00")
  assert.equal(nearestTime("2026-10-19", null, times, rules({minTime: "08:30"})), "08:30")
  assert.equal(nearestTime("2026-10-19", "10:00", times, rules({unavailable: "2026-10-19"})), null)
})

test("default_time reads a time or a start/end pair", () => {
  assert.deepEqual(parseDefaultTime("09:00"), {start: "09:00", end: "09:00"})
  assert.deepEqual(parseDefaultTime("09:00/17:00"), {start: "09:00", end: "17:00"})
  assert.deepEqual(parseDefaultTime("9:00/bad"), {start: "09:00", end: "09:00"})
  assert.deepEqual(parseDefaultTime(""), {start: null, end: null})
  assert.deepEqual(parseDefaultTime(undefined), {start: null, end: null})
})

test("the end of a range cannot be before its start", () => {
  const ends = rulesFrom(rules(), {date: "2026-10-14", time: "10:00"})
  assert.equal(isSlotAvailable("2026-10-13", "12:00", ends), false)
  assert.equal(isSlotAvailable("2026-10-14", "09:30", ends), false)
  assert.equal(isSlotAvailable("2026-10-14", "10:00", ends), true)
  assert.equal(isSlotAvailable("2026-10-15", "08:00", ends), true)
  assert.equal(rulesFrom(rules(), null).min, null)
})

test("a later min than the start keeps winning for the end of a range", () => {
  const ends = rulesFrom(rules({min: "2026-10-20"}), {date: "2026-10-14", time: "10:00"})
  assert.equal(isSlotAvailable("2026-10-19", "12:00", ends), false)
  assert.equal(isSlotAvailable("2026-10-20", "00:00", ends), true)
})
