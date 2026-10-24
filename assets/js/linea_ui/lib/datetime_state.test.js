import assert from "node:assert/strict"
import test from "node:test"
import {buildRules, parseDefaultTime, slotTimes} from "./datetime_rules.js"
import {anchorDay, fromValues, isComplete, isDayAvailable, pickDay, pickTime, rulesFor, showMonth, slotsFor, toValues, viewFor} from "./datetime_state.js"

const NOW = {date: "2026-10-14", time: "10:12"}

const context = (mode, extra = {}, defaultTime = "") => {
  const rules = buildRules(extra, NOW)
  return {mode, rules, times: slotTimes(extra.interval ?? 30, rules), defaults: parseDefaultTime(defaultTime)}
}

const EMPTY = {start: null, end: null}

test("values become a state and back, a range needs both ends", () => {
  const single = context("single")
  assert.deepEqual(fromValues(["2026-10-14T10:30"], single), {start: {date: "2026-10-14", time: "10:30"}, end: null})
  assert.deepEqual(toValues(fromValues(["2026-10-14T10:30"], single), "single"), ["2026-10-14T10:30"])
  const range = context("range")
  const state = fromValues(["2026-10-14T09:00", "2026-10-20T17:00"], range)
  assert.deepEqual(toValues(state, "range"), ["2026-10-14T09:00", "2026-10-20T17:00"])
  assert.deepEqual(toValues({start: state.start, end: null}, "range"), [])
  assert.deepEqual(toValues(EMPTY, "single"), [])
})

test("a value with only a day gets the default time, or the first open slot", () => {
  assert.equal(fromValues(["2026-10-14"], context("single", {}, "09:30")).start.time, "09:30")
  assert.equal(fromValues(["2026-10-14"], context("single", {minTime: "08:00"})).start.time, "08:00")
  const range = fromValues(["2026-10-14", "2026-10-20"], context("range", {}, "09:00/17:00"))
  assert.deepEqual(range, {start: {date: "2026-10-14", time: "09:00"}, end: {date: "2026-10-20", time: "17:00"}})
})

test("garbage in the values gives an empty state", () => {
  assert.deepEqual(fromValues([], context("single")), EMPTY)
  assert.deepEqual(fromValues(["garbage"], context("single")), EMPTY)
})

test("picking a day in a single picker keeps the time, else takes the default", () => {
  const ctx = context("single", {}, "09:00")
  const first = pickDay(EMPTY, "2026-10-14", ctx)
  assert.deepEqual(first, {start: {date: "2026-10-14", time: "09:00"}, end: null})
  const moved = pickDay(pickTime(first, "start", "15:30"), "2026-10-16", ctx)
  assert.deepEqual(moved.start, {date: "2026-10-16", time: "15:30"})
})

test("a day whose kept time is closed takes the default, then the first open slot", () => {
  const ctx = context("single", {unavailable: "2026-10-16T15:30"}, "09:00")
  const state = {start: {date: "2026-10-14", time: "15:30"}, end: null}
  assert.equal(pickDay(state, "2026-10-16", ctx).start.time, "09:00")
  const blocked = context("single", {unavailable: "2026-10-16T15:30, 2026-10-16T09:00"}, "09:00")
  assert.equal(pickDay(state, "2026-10-16", blocked).start.time, "00:00")
})

test("a day with no open slot cannot be picked", () => {
  const ctx = context("single", {unavailable: "2026-10-16"})
  const state = {start: {date: "2026-10-14", time: "10:00"}, end: null}
  assert.equal(pickDay(state, "2026-10-16", ctx), state)
  assert.equal(isDayAvailable("2026-10-16", state, ctx), false)
  assert.equal(isDayAvailable("2026-10-15", state, ctx), true)
})

test("a range starts, closes and restarts, each end with its default time", () => {
  const ctx = context("range", {}, "09:00/17:00")
  const started = pickDay(EMPTY, "2026-10-14", ctx)
  assert.deepEqual(started, {start: {date: "2026-10-14", time: "09:00"}, end: null})
  const closed = pickDay(started, "2026-10-20", ctx)
  assert.deepEqual(closed, {start: {date: "2026-10-14", time: "09:00"}, end: {date: "2026-10-20", time: "17:00"}})
  const restarted = pickDay(closed, "2026-10-25", ctx)
  assert.deepEqual(restarted, {start: {date: "2026-10-25", time: "09:00"}, end: null})
  const before = pickDay(started, "2026-10-10", ctx)
  assert.deepEqual(before, {start: {date: "2026-10-10", time: "09:00"}, end: null})
})

test("a range closed on its first day gets an end after the start", () => {
  const ctx = context("range", {}, "09:00/09:00")
  const started = pickTime(pickDay(EMPTY, "2026-10-14", ctx), "start", "15:00")
  const closed = pickDay(started, "2026-10-14", ctx)
  assert.deepEqual(closed.end, {date: "2026-10-14", time: "15:00"})
})

test("moving the start time past the end of the same day drags the end with it", () => {
  const ctx = context("range")
  const state = {start: {date: "2026-10-14", time: "09:00"}, end: {date: "2026-10-14", time: "10:00"}}
  assert.equal(pickTime(state, "start", "12:00", ctx).end.time, "12:00")
  assert.equal(pickTime(state, "end", "18:00", ctx).end.time, "18:00")
  const later = {start: {date: "2026-10-14", time: "09:00"}, end: {date: "2026-10-15", time: "08:00"}}
  assert.equal(pickTime(later, "start", "23:00", ctx).end.time, "08:00")
})

test("with only the start picked, days before it restart and days from it close", () => {
  const ctx = context("range", {min: "now"})
  const state = {start: {date: "2026-10-14", time: "10:30"}, end: null}
  assert.equal(isDayAvailable("2026-10-14", state, ctx), true)
  assert.equal(isDayAvailable("2026-10-13", state, ctx), false)
  const late = {start: {date: "2026-10-20", time: "23:30"}, end: null}
  assert.equal(isDayAvailable("2026-10-20", late, ctx), true)
  assert.equal(isDayAvailable("2026-10-19", late, ctx), true)
})

test("the slots of the end of a range start at the start", () => {
  const ctx = context("range")
  const state = {start: {date: "2026-10-14", time: "12:00"}, end: {date: "2026-10-14", time: "13:00"}}
  const open = slotsFor(state, "end", ctx).filter((slot) => !slot.disabled)
  assert.equal(open[0].time, "12:00")
  assert.equal(slotsFor(state, "start", ctx).filter((slot) => !slot.disabled).length, 48)
  assert.deepEqual(slotsFor(EMPTY, "end", ctx), [])
  assert.equal(rulesFor(state, "start", ctx.rules), ctx.rules)
})

test("a choice is complete with a day and time on every end", () => {
  assert.equal(isComplete({start: {date: "2026-10-14", time: "10:00"}, end: null}, "single"), true)
  assert.equal(isComplete({start: {date: "2026-10-14", time: "10:00"}, end: null}, "range"), false)
  assert.equal(isComplete(EMPTY, "single"), false)
})

test("the calendar starts at the start, else today held inside the limits", () => {
  const rules = buildRules({min: "2026-11-05", max: "2026-12-10"}, NOW)
  assert.equal(anchorDay(EMPTY, "2026-10-14", rules), "2026-11-05")
  assert.equal(anchorDay(EMPTY, "2027-01-01", rules), "2026-12-10")
  assert.equal(anchorDay({start: {date: "2026-11-20", time: "10:00"}, end: null}, "2026-10-14", rules), "2026-11-20")
  assert.deepEqual(viewFor(EMPTY, "2026-10-14", buildRules({}, NOW)), {year: 2026, month: 9})
})

test("showing a month moves the view by the least it takes", () => {
  const view = {year: 2026, month: 9}
  assert.equal(showMonth(view, 2, "2026-11-03"), view)
  assert.deepEqual(showMonth(view, 2, "2026-12-03"), {year: 2026, month: 10})
  assert.deepEqual(showMonth(view, 2, "2026-08-31"), {year: 2026, month: 7})
  assert.deepEqual(showMonth({year: 2026, month: 11}, 1, "2027-01-02"), {year: 2027, month: 0})
})
