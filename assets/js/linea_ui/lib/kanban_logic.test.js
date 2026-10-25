import test from "node:test"
import assert from "node:assert/strict"
import {HOLD, approach, edgeDelta, ghostOffset, insertionIndex, isFull, moveIntent, parseWip, scrollStep, tiltOf} from "./kanban_logic.js"

test("a column is full only when it has a limit, is at it and the card comes from outside", () => {
  assert.equal(isFull({count: 2, wip: 2, sameColumn: false}), true)
  assert.equal(isFull({count: 1, wip: 2, sameColumn: false}), false)
  assert.equal(isFull({count: 5, wip: 2, sameColumn: true}), false)
  assert.equal(isFull({count: 5, wip: NaN, sameColumn: false}), false)
  assert.equal(isFull({count: 5, wip: 0, sameColumn: false}), false)
})

test("the limit is read from the attribute, and absent means none", () => {
  assert.equal(parseWip("3"), 3)
  assert.ok(Number.isNaN(parseWip(undefined)))
  assert.ok(Number.isNaN(parseWip("")))
})

test("the pointer picks the slot by the middles of the cards", () => {
  const boxes = [{top: 0, height: 40}, {top: 50, height: 40}, {top: 100, height: 40}]
  assert.equal(insertionIndex(boxes, 5), 0)
  assert.equal(insertionIndex(boxes, 30), 1)
  assert.equal(insertionIndex(boxes, 75), 2)
  assert.equal(insertionIndex(boxes, 500), 3)
  assert.equal(insertionIndex([], 10), 0)
})

test("a mouse and a pen start dragging after a few pixels and never give up", () => {
  for (const type of ["mouse", "pen"]) {
    assert.equal(moveIntent(type, 0), "wait")
    assert.equal(moveIntent(type, 3), "wait")
    assert.equal(moveIntent(type, 4), "start")
    assert.equal(moveIntent(type, 400), "start")
  }
})

test("a finger that moves before the hold is scrolling, and one that holds still waits for the timer", () => {
  assert.equal(moveIntent("touch", 0), "wait")
  assert.equal(moveIntent("touch", 10), "wait")
  assert.equal(moveIntent("touch", 11), "cancel")
  assert.equal(moveIntent("unknown", 50), "cancel")
})

test("only a finger has to hold", () => {
  assert.equal(HOLD.mouse, null)
  assert.equal(HOLD.pen, null)
  assert.ok(HOLD.touch > 0)
})

test("the board scrolls only near an edge, harder the closer, towards that edge", () => {
  const area = {start: 0, end: 1000}
  assert.equal(edgeDelta(500, area), 0)
  assert.equal(edgeDelta(100, area), 0)
  assert.equal(edgeDelta(900, area), 0)
  assert.ok(edgeDelta(20, area) < 0)
  assert.ok(edgeDelta(980, area) > 0)
  assert.ok(edgeDelta(10, area) < edgeDelta(40, area))
  assert.ok(edgeDelta(990, area) > edgeDelta(960, area))
})

test("the speed tops out at the edge and beyond it", () => {
  const area = {start: 100, end: 900}
  assert.equal(edgeDelta(100, area, {speed: 20}), -20)
  assert.equal(edgeDelta(-500, area, {speed: 20}), -20)
  assert.equal(edgeDelta(900, area, {speed: 20}), 20)
  assert.equal(edgeDelta(5000, area, {speed: 20}), 20)
})

test("an area narrower than two edges still pulls to the nearer side", () => {
  const area = {start: 0, end: 80}
  assert.ok(edgeDelta(10, area) < 0)
  assert.ok(edgeDelta(70, area) > 0)
})

test("the floating card stays where it was grabbed", () => {
  assert.deepEqual(ghostOffset({x: 300, y: 200}, {x: 20, y: 10}), {x: 280, y: 190})
})

test("the edge speed eases in: gentle at the start of the zone, full at the edge", () => {
  const area = {start: 0, end: 1000}
  assert.ok(edgeDelta(960, area) < 9)
  assert.ok(edgeDelta(990, area) > 9)
  assert.equal(edgeDelta(1000, area), 18)
})

test("a scrolling box steps on both axes and never past the room it has", () => {
  const rect = {left: 0, top: 0, right: 1000, bottom: 600}
  const room = {x: [100, 100], y: [0, 0]}
  assert.deepEqual(scrollStep({x: 500, y: 300}, rect, room), {x: 0, y: 0})
  assert.deepEqual(scrollStep({x: 1000, y: 300}, rect, room), {x: 18, y: 0})
  assert.deepEqual(scrollStep({x: 1000, y: 600}, rect, room), {x: 18, y: 0})
  assert.deepEqual(scrollStep({x: 0, y: 300}, rect, {x: [5, 100], y: [0, 0]}), {x: -5, y: 0})
  assert.deepEqual(scrollStep({x: 500, y: 600}, rect, {x: [0, 0], y: [0, 200]}), {x: 0, y: 18})
})

test("the floating card leans towards the movement, within the limit", () => {
  assert.equal(tiltOf(0), 0)
  assert.ok(tiltOf(500) > 0)
  assert.ok(tiltOf(-500) < 0)
  assert.equal(tiltOf(-500), -tiltOf(500))
  assert.equal(tiltOf(100000), 6)
  assert.equal(tiltOf(-100000), -6)
  assert.equal(tiltOf(100000, {max: 3}), 3)
})

test("the follower closes in on its target, faster for a longer frame, never past it", () => {
  assert.equal(approach(0, 100, 0), 0)
  const short = approach(0, 100, 8)
  const long = approach(0, 100, 32)
  assert.ok(short > 0 && short < long && long < 100)
  assert.ok(Math.abs(approach(0, 100, 5000) - 100) < 1e-6)
  assert.equal(approach(40, 40, 16), 40)
})
