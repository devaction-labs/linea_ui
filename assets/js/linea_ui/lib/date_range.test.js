import {test} from "node:test"
import assert from "node:assert/strict"
import {presetActive, presetDates, rangeInputs} from "./date_range.js"

test("rangeInputs names the two ends and leaves a missing end empty", () => {
  assert.deepEqual(rangeInputs(["2026-10-01", "2026-10-31"], "from", "to"), [
    {name: "from", value: "2026-10-01"},
    {name: "to", value: "2026-10-31"},
  ])
  assert.deepEqual(rangeInputs(["2026-10-01"], "from", "to")[1], {name: "to", value: ""})
  assert.deepEqual(rangeInputs([], "from", "to").map((input) => input.value), ["", ""])
})

test("presetDates sets both ends in range mode and the first day otherwise", () => {
  assert.deepEqual(presetDates({from: "2026-10-31", to: "2026-10-01"}, "range"), ["2026-10-01", "2026-10-31"])
  assert.deepEqual(presetDates({from: "2026-10-01", to: "2026-10-31"}, "single"), ["2026-10-01"])
})

test("presetActive matches the current choice exactly", () => {
  const month = {from: "2026-10-01", to: "2026-10-31"}
  assert.equal(presetActive(month, ["2026-10-31", "2026-10-01"], "range"), true)
  assert.equal(presetActive(month, ["2026-10-01"], "range"), false)
  assert.equal(presetActive(month, ["2026-10-01", "2026-10-30"], "range"), false)
  assert.equal(presetActive({from: "2026-10-24", to: "2026-10-24"}, ["2026-10-24"], "single"), true)
})
