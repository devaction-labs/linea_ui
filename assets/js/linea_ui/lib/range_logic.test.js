import assert from "node:assert/strict"
import test from "node:test"
import {markValue, nearestThumb, sameValue, stepValue} from "./range_logic.js"

const limits = {min: "0", max: "200", step: "5"}

test("a stepper moves one step and stops at the limits", () => {
  assert.equal(stepValue("60", "up", limits), "65")
  assert.equal(stepValue("60", "down", limits), "55")
  assert.equal(stepValue("200", "up", limits), null)
  assert.equal(stepValue("0", "down", limits), null)
  assert.equal(stepValue("198", "up", limits), "200")
})

test("steps are decimal exact", () => {
  assert.equal(stepValue("0.1", "up", {min: "0", max: "1", step: "0.1"}), "0.2")
  assert.equal(stepValue("0.2", "up", {min: "0", max: "1", step: "0.1"}), "0.3")
})

test("the defaults are the browser's: 0 to 100 by 1", () => {
  assert.equal(stepValue("50", "up", {}), "51")
  assert.equal(stepValue("100", "up", {}), null)
})

test("a value that is not a number does not move", () => {
  assert.equal(stepValue("abc", "up", limits), null)
})

test("a mark gives its value held between the limits", () => {
  assert.equal(markValue("50", limits), "50")
  assert.equal(markValue("250", limits), "200")
  assert.equal(markValue("-3", limits), "0")
  assert.equal(markValue("x", limits), null)
})

test("a click moves the nearer thumb, the lower one on a tie", () => {
  assert.equal(nearestThumb("40", "280", "50"), "low")
  assert.equal(nearestThumb("40", "280", "250"), "high")
  assert.equal(nearestThumb("40", "280", "160"), "low")
})

test("values are the same however they are written", () => {
  assert.ok(sameValue("5", "5.0"))
  assert.ok(!sameValue("5", "6"))
  assert.ok(!sameValue("x", "x"))
})
