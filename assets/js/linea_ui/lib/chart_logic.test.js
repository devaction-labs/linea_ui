import assert from "node:assert/strict"
import test from "node:test"
import {applyUpdate, nextView, parseOptions, stepSlot, targets, widthOf} from "./chart_logic.js"

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

test("chart.width sizes the element when it is a number or a CSS length", () => {
  assert.equal(widthOf(120), "120px")
  assert.equal(widthOf("50%"), "50%")
  assert.equal(widthOf("12.5rem"), "12.5rem")
  assert.equal(widthOf("auto"), "")
  assert.equal(widthOf(undefined), "")
  assert.equal(widthOf(-3), "")
})

test("arrows, Home and End move the keyboard cursor along the slots", () => {
  const slots = [0, 1, 2, 3]
  assert.equal(stepSlot(slots, null, "ArrowRight"), 0)
  assert.equal(stepSlot(slots, null, "ArrowLeft"), 3)
  assert.equal(stepSlot(slots, 1, "ArrowRight"), 2)
  assert.equal(stepSlot(slots, 1, "ArrowLeft"), 0)
  assert.equal(stepSlot(slots, 3, "ArrowRight"), 3)
  assert.equal(stepSlot(slots, 0, "ArrowLeft"), 0)
  assert.equal(stepSlot(slots, 2, "Home"), 0)
  assert.equal(stepSlot(slots, 1, "End"), 3)
  assert.equal(stepSlot(slots, 1, "Enter"), undefined)
  assert.equal(stepSlot([], null, "ArrowRight"), undefined)
})

test("the view toggle only changes to the other known view", () => {
  assert.equal(nextView("chart", "table"), "table")
  assert.equal(nextView("table", "chart"), "chart")
  assert.equal(nextView("chart", "chart"), null)
  assert.equal(nextView("chart", "grid"), null)
  assert.equal(nextView("chart", undefined), null)
})
