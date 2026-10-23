import assert from "node:assert/strict"
import test from "node:test"
import {fraction, keyStep, nearest, parallax, placement, progress, resolveBranch, resolveIndex, scrollFor, swipe, target, thumb} from "./carousel_logic.js"

test("a move stops at the ends unless the carousel loops", () => {
  assert.equal(target(4, 4, false), 3)
  assert.equal(target(-1, 4, false), 0)
  assert.equal(target(4, 4, true), 0)
  assert.equal(target(-1, 4, true), 3)
  assert.equal(target(2, 0, true), 0)
})

test("the nearest slide start wins", () => {
  assert.equal(nearest(0, [0, 300, 600]), 0)
  assert.equal(nearest(170, [0, 300, 600]), 1)
  assert.equal(nearest(900, [0, 300, 600]), 2)
})

test("a slide's placement is clamped for the stacked effects", () => {
  assert.deepEqual(placement(1, 0), {offset: 1, distance: 1, side: 1, near: 1})
  assert.deepEqual(placement(0, 2), {offset: -2, distance: 2, side: -1, near: 1})
  assert.deepEqual(placement(9, 0), {offset: 4, distance: 4, side: 1, near: 1})
  assert.deepEqual(placement(3, 3), {offset: 0, distance: 0, side: 0, near: 0})
})

test("the progress bar fills one slide at a time", () => {
  assert.equal(progress(0, 4), 0.25)
  assert.equal(progress(3, 4), 1)
  assert.equal(progress(0, 0), 0)
})

test("the scrollbar thumb follows the track", () => {
  assert.deepEqual(thumb(0, 400, 100), {size: 0.25, start: 0})
  assert.deepEqual(thumb(300, 400, 100), {size: 0.25, start: 0.75})
  assert.deepEqual(thumb(0, 100, 100), {size: 1, start: 0})
  assert.equal(scrollFor(0.375, 400, 100), 150)
  assert.equal(scrollFor(0.5, 100, 100), 0)
})

test("a swipe needs length along the carousel's direction", () => {
  assert.equal(swipe(-80, 5, "horizontal"), 1)
  assert.equal(swipe(80, 5, "horizontal"), -1)
  assert.equal(swipe(20, 0, "horizontal"), 0)
  assert.equal(swipe(10, -90, "horizontal"), 0)
  assert.equal(swipe(0, -90, "vertical"), 1)
})

test("parallax keeps the unit LineOne wrote", () => {
  assert.equal(parallax("-300", 0.5), "-150px")
  assert.equal(parallax("-23%", 1), "-23%")
  assert.equal(parallax("bad", 1), "0px")
})

test("arrow keys follow the direction", () => {
  assert.equal(keyStep("ArrowRight", "horizontal"), 1)
  assert.equal(keyStep("ArrowUp", "vertical"), -1)
  assert.equal(keyStep("ArrowDown", "horizontal"), null)
  assert.equal(keyStep("End", "vertical"), "last")
})

test("the fraction counts from one", () => {
  assert.equal(fraction(0, 4), "1 / 4")
})

test("the server's index wins only when it changed", () => {
  assert.equal(resolveIndex({current: 2, lastServer: 0, server: 0, count: 4}), 2)
  assert.equal(resolveIndex({current: 2, lastServer: 0, server: 1, count: 4}), 1)
  assert.equal(resolveIndex({current: 3, lastServer: 0, server: 0, count: 2}), 1)
})

test("a branch keeps the person's choice until the server changes its own", () => {
  assert.deepEqual(resolveBranch({chosen: true, lastServer: false, server: false}), {open: true, chosen: true, lastServer: false})
  assert.deepEqual(resolveBranch({chosen: true, lastServer: false, server: true}), {open: true, chosen: undefined, lastServer: true})
  assert.deepEqual(resolveBranch({chosen: false, lastServer: false, server: true}), {open: true, chosen: undefined, lastServer: true})
  assert.deepEqual(resolveBranch({chosen: undefined, lastServer: true, server: true}), {open: true, chosen: undefined, lastServer: true})
})
