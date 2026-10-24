import test from "node:test"
import assert from "node:assert/strict"
import {colorOf, durationOf, offsets, positionOf, resumeAfter, stack, timeLeft, unseen} from "./notice_logic.js"

test("an unknown color is neutral", () => {
  assert.equal(colorOf("success"), "success")
  assert.equal(colorOf("purple"), "neutral")
})

test("a position is split into its two parts, with LineOne's default", () => {
  assert.deepEqual(positionOf("left-top"), {x: "left", y: "top", key: "left-top"})
  assert.deepEqual(positionOf(undefined), {x: "right", y: "bottom", key: "right-bottom"})
  assert.deepEqual(positionOf("middle", "center-top"), {x: "center", y: "top", key: "center-top"})
})

test("the duration falls back to the toaster's and zero keeps the toast", () => {
  assert.equal(durationOf(3000), 3000)
  assert.equal(durationOf(undefined, 5000), 5000)
  assert.equal(durationOf(0), Infinity)
})

test("toasts pile up from the edge with the same gap between them", () => {
  assert.deepEqual(offsets([44, 60, 44]), [15, 74, 149])
  assert.deepEqual(offsets([]), [])
})

test("a toast already shown is not shown again", () => {
  assert.deepEqual(unseen([{id: 1}, {id: 2}], new Set(["1"])), [{id: 2}])
})

const sizes = [{width: 280, height: 44}, {width: 200, height: 60}, {width: 320, height: 44}, {width: 100, height: 44}]

test("a closed stack shows the newest in full and the rest as slivers behind it", () => {
  const plan = stack(sizes, false)
  assert.deepEqual(plan.map((item) => item.offset), [15, 27, 39, 51])
  assert.deepEqual(plan.map((item) => item.scale), [1, 0.95, 0.9, 0.85])
  assert.ok(plan.every((item) => item.width === 280 && item.height === 44))
  assert.deepEqual(plan.map((item) => item.hidden), [false, false, false, true])
})

test("an open stack lays the toasts out with their own sizes", () => {
  const plan = stack(sizes, true)
  assert.deepEqual(plan.map((item) => item.offset), [15, 74, 149, 208])
  assert.deepEqual(plan.map((item) => item.width), [280, 200, 320, 100])
  assert.ok(plan.every((item) => item.scale === 1 && !item.hidden))
})

test("the scale never goes below 0.8", () => {
  const many = Array.from({length: 8}, () => ({width: 10, height: 10}))
  assert.equal(stack(many, false)[7].scale, 0.8)
})

test("a paused timer keeps what was left and waits at least a second after release", () => {
  assert.equal(timeLeft(5000, 1800), 3200)
  assert.equal(timeLeft(1000, 4000), 0)
  assert.equal(resumeAfter(3200), 3200)
  assert.equal(resumeAfter(200), 1000)
})
