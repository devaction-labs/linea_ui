import assert from "node:assert/strict"
import test from "node:test"
import {parseOptions, targets, updatesFor} from "./chart_logic.js"

test("options are read from a JSON object only", () => {
  assert.deepEqual(parseOptions('{"chart":{"type":"bar"}}'), {chart: {type: "bar"}})
  assert.equal(parseOptions("[1,2]"), null)
  assert.equal(parseOptions("null"), null)
  assert.equal(parseOptions("{oops"), null)
  assert.equal(parseOptions(undefined), null)
})

test("a payload targets a chart by id, with or without #", () => {
  assert.equal(targets({id: "sales"}, "sales"), true)
  assert.equal(targets({id: "#sales"}, "sales"), true)
  assert.equal(targets({id: "other"}, "sales"), false)
  assert.equal(targets({}, "sales"), false)
})

test("a payload becomes updateOptions then updateSeries", () => {
  assert.deepEqual(updatesFor({series: [1]}), [["updateSeries", [1]]])
  assert.deepEqual(updatesFor({options: {a: 1}, series: [1]}), [
    ["updateOptions", {a: 1}],
    ["updateSeries", [1]],
  ])
  assert.deepEqual(updatesFor({}), [])
})
