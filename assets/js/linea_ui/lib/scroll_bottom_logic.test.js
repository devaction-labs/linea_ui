import test from "node:test"
import assert from "node:assert/strict"
import {THRESHOLD, afterScroll, distanceFromEnd, endOf, pinned} from "./scroll_bottom_logic.js"

const box = (over = {}) => ({scrollTop: 0, scrollHeight: 1000, clientHeight: 400, ...over})

test("the distance from the end", () => {
  assert.equal(distanceFromEnd(box()), 600)
  assert.equal(distanceFromEnd(box({scrollTop: 600})), 0)
  assert.equal(distanceFromEnd(box({scrollTop: 650})), 0)
  assert.equal(distanceFromEnd(box({scrollHeight: 300})), 0)
})

test("at the end, or within the threshold of it, is pinned", () => {
  assert.equal(pinned(box({scrollTop: 600})), true)
  assert.equal(pinned(box({scrollTop: 600 - THRESHOLD})), true)
  assert.equal(pinned(box({scrollTop: 600 - THRESHOLD - 1})), false)
  assert.equal(pinned(box()), false)
})

test("content that fits is always pinned", () => {
  assert.equal(pinned(box({scrollHeight: 400})), true)
})

test("the threshold can be changed", () => {
  assert.equal(pinned(box({scrollTop: 500}), 100), true)
  assert.equal(pinned(box({scrollTop: 500}), 50), false)
})

test("moving down keeps a pinned box pinned while the end runs away", () => {
  assert.equal(afterScroll({was: true, box: box({scrollTop: 300}), previousTop: 200}), true)
})

test("moving up unpins unless it stays near the end", () => {
  assert.equal(afterScroll({was: true, box: box({scrollTop: 300}), previousTop: 600}), false)
  assert.equal(afterScroll({was: true, box: box({scrollTop: 590}), previousTop: 600}), true)
})

test("moving down does not pin a box the reader left", () => {
  assert.equal(afterScroll({was: false, box: box({scrollTop: 300}), previousTop: 200}), false)
  assert.equal(afterScroll({was: false, box: box({scrollTop: 600}), previousTop: 500}), true)
})

test("the end of the box", () => {
  assert.equal(endOf(box()), 600)
  assert.equal(endOf(box({scrollHeight: 300})), 0)
})
