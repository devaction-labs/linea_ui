import assert from "node:assert/strict"
import test from "node:test"
import {applyUpdate, parseOptions, targets} from "./chart_logic.js"

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

test("a payload merges options, then lays series over the current ones", () => {
  const current = {chart: {type: "line", height: 200}, series: [{name: "Sales", data: [1, 2]}, {name: "Cost", data: [3, 4]}]}
  assert.deepEqual(applyUpdate(current, {series: [{data: [9, 9, 9]}]}).series, [{name: "Sales", data: [9, 9, 9]}])
  assert.deepEqual(applyUpdate(current, {options: {chart: {height: 300}}}).chart, {type: "line", height: 300})
  assert.deepEqual(applyUpdate({series: [1, 2]}, {series: [3, 4, 5]}).series, [3, 4, 5])
  assert.equal(applyUpdate(current, {}), current)
  assert.equal(applyUpdate(current, undefined), current)
})
