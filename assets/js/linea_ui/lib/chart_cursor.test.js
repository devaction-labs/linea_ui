import assert from "node:assert/strict"
import test from "node:test"
import {cursorDetail, cursorPayload, lastWithData, sameCursor, summaryHtml, throttled} from "./chart_cursor.js"

const hit = {slot: 3, title: "14:00", rows: [{name: "Hoje", value: "R$ 1.284,9", color: "#34d399"}, {name: "Ontem", value: "R$ 900", color: null}]}

test("a hover result becomes the cursor detail, with the formatted values", () => {
  assert.deepEqual(cursorDetail(hit), {
    index: 3,
    label: "14:00",
    values: [{name: "Hoje", color: "#34d399", value: "R$ 1.284,9"}, {name: "Ontem", color: null, value: "R$ 900"}],
  })
  assert.equal(cursorDetail(null), null)
})

test("the index is the slot, else the active bar or slice", () => {
  assert.equal(cursorDetail({title: "", rows: [], active: {slice: 2}}).index, 2)
  assert.equal(cursorDetail({title: "", rows: [], active: {series: 0, slot: 5}}).index, 5)
  assert.equal(cursorDetail({title: "", rows: []}).index, null)
})

test("the pushed payload is a map, empty on leave", () => {
  assert.equal(cursorPayload("c", cursorDetail(hit)).values.length, 2)
  assert.deepEqual(cursorPayload("c", null), {id: "c", index: null, label: "", values: []})
})

test("two details are the same when every field is", () => {
  assert.equal(sameCursor(cursorDetail(hit), cursorDetail({...hit})), true)
  assert.equal(sameCursor(cursorDetail(hit), cursorDetail({...hit, slot: 4})), false)
  assert.equal(sameCursor(null, null), true)
  assert.equal(sameCursor(null, cursorDetail(hit)), false)
})

test("the resting point is the last slot with a value", () => {
  const rows = {0: [{value: "1"}], 1: [{value: "2"}], 2: [{value: ""}], 3: []}
  const answer = (slot) => ({slot, rows: rows[slot]})
  assert.equal(lastWithData([0, 1, 2, 3], answer).slot, 1)
  assert.equal(lastWithData([2, 3], answer), null)
  assert.equal(lastWithData([], answer), null)
  assert.equal(lastWithData([0], () => null), null)
})

test("the resting point prefers the last slot where every series has a value", () => {
  const rows = {0: [{value: "1"}, {value: "2"}], 1: [{value: "3"}, {value: "4"}], 2: [{value: "5"}]}
  const answer = (slot) => ({slot, rows: rows[slot]})
  assert.equal(lastWithData([0, 1, 2], answer, 2).slot, 1)
  assert.equal(lastWithData([0, 1, 2], answer).slot, 2)
  assert.equal(lastWithData([2], answer, 2).slot, 2)
})

test("the summary has a chip and a figure per series, escaped", () => {
  const html = summaryHtml(cursorDetail({...hit, title: "<b>"}))
  assert.equal(html.includes('summary-chip">&lt;b&gt;<'), true)
  assert.equal(html.includes('style="background:#34d399"'), true)
  assert.equal(html.includes("<b>R$ 1.284,9</b>"), true)
  assert.equal(html.match(/summary-item/g).length, 2)
  assert.equal(html.match(/summary-marker/g).length, 1)
  assert.equal(summaryHtml(null), "")
  assert.equal(summaryHtml({index: 0, label: "", values: []}), "")
})

const clock = () => {
  const state = {t: 0, jobs: []}
  return {
    timers: {now: () => state.t, set: (fn, ms) => (state.jobs.push({at: state.t + ms, fn}), state.jobs.length), clear: (id) => (state.jobs[id - 1] = null)},
    advance(ms) {
      state.t += ms
      state.jobs.forEach((job, i) => job && job.at <= state.t && ((state.jobs[i] = null), job.fn()))
    },
  }
}

test("the throttle sends the first call, delays the next ones and ends on the last", () => {
  const sent = []
  const time = clock()
  const send = throttled((value) => sent.push(value), 100, time.timers)
  send("a")
  send("b")
  send("c")
  assert.deepEqual(sent, ["a"])
  time.advance(100)
  assert.deepEqual(sent, ["a", "c"])
  time.advance(500)
  send("d")
  assert.deepEqual(sent, ["a", "c", "d"])
})

test("a flush sends at once and drops what waited", () => {
  const sent = []
  const time = clock()
  const send = throttled((value) => sent.push(value), 100, time.timers)
  send("a")
  send("b")
  send.flush("leave")
  time.advance(200)
  assert.deepEqual(sent, ["a", "leave"])
})

test("a cancel drops the call that waited", () => {
  const sent = []
  const time = clock()
  const send = throttled((value) => sent.push(value), 100, time.timers)
  send("a")
  send("b")
  send.cancel()
  time.advance(200)
  assert.deepEqual(sent, ["a"])
})
