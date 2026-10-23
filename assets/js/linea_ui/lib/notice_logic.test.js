import test from "node:test"
import assert from "node:assert/strict"
import {colorOf, durationOf, offsets, positionOf, unseen} from "./notice_logic.js"

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
