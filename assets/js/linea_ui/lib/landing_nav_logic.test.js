import test from "node:test"
import assert from "node:assert/strict"
import {CLOSE_DELAY, DEFAULT_THRESHOLD, OPEN_DELAY, isStuck, opensOnHover, stepIndex, thresholdOf} from "./landing_nav_logic.js"

test("stuck only past the threshold", () => {
  assert.equal(isStuck(0), false)
  assert.equal(isStuck(DEFAULT_THRESHOLD), false)
  assert.equal(isStuck(DEFAULT_THRESHOLD + 1), true)
  assert.equal(isStuck(50, 100), false)
  assert.equal(isStuck(101, 100), true)
})

test("the threshold comes from the attribute, else the default", () => {
  assert.equal(thresholdOf("24"), 24)
  assert.equal(thresholdOf("0"), 0)
  assert.equal(thresholdOf(undefined), DEFAULT_THRESHOLD)
  assert.equal(thresholdOf(""), DEFAULT_THRESHOLD)
  assert.equal(thresholdOf("abc"), DEFAULT_THRESHOLD)
  assert.equal(thresholdOf("-3"), DEFAULT_THRESHOLD)
})

test("hover opens with a mouse or a pen, never with a touch, and only in hover mode", () => {
  assert.equal(opensOnHover("hover", "mouse"), true)
  assert.equal(opensOnHover("hover", "pen"), true)
  assert.equal(opensOnHover("hover", "touch"), false)
  assert.equal(opensOnHover("click", "mouse"), false)
  assert.equal(opensOnHover(undefined, "mouse"), false)
})

test("the arrows walk the items of the panel and wrap, Home and End jump", () => {
  assert.equal(stepIndex("ArrowDown", -1, 3), 0)
  assert.equal(stepIndex("ArrowRight", 0, 3), 1)
  assert.equal(stepIndex("ArrowDown", 2, 3), 0)
  assert.equal(stepIndex("ArrowUp", 0, 3), 2)
  assert.equal(stepIndex("ArrowLeft", 2, 3), 1)
  assert.equal(stepIndex("ArrowUp", -1, 3), 2)
  assert.equal(stepIndex("Home", 2, 3), 0)
  assert.equal(stepIndex("End", 0, 3), 2)
  assert.equal(stepIndex("Tab", 0, 3), null)
  assert.equal(stepIndex("ArrowDown", 0, 0), null)
  assert.ok(CLOSE_DELAY > OPEN_DELAY)
})
