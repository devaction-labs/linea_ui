import test from "node:test"
import assert from "node:assert/strict"
import {DEFAULT_THRESHOLD, isStuck, thresholdOf} from "./landing_nav_logic.js"

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
