import test from "node:test"
import assert from "node:assert/strict"
import {DEFAULT_AFTER_MS, afterOf, begin, shapeOf, step} from "./fab_logic.js"

test("the retract delay is a positive number of ms, else the default", () => {
  assert.equal(afterOf("6000"), 6000)
  assert.equal(afterOf(250), 250)
  assert.equal(afterOf("0"), DEFAULT_AFTER_MS)
  assert.equal(afterOf("-5"), DEFAULT_AFTER_MS)
  assert.equal(afterOf(undefined), DEFAULT_AFTER_MS)
  assert.equal(afterOf("soon"), DEFAULT_AFTER_MS)
})

test("with hover it starts expanded and arms the timer", () => {
  const {state, timer} = begin(true)
  assert.equal(shapeOf(state), "expanded")
  assert.equal(timer, "start")
})

test("on a touch device it starts as the bubble and arms nothing", () => {
  const {state, timer} = begin(false)
  assert.equal(shapeOf(state), "collapsed")
  assert.equal(timer, "clear")
})

test("the timer running out retracts it", () => {
  const {state, timer} = step(begin(true).state, "idle")
  assert.equal(shapeOf(state), "collapsed")
  assert.equal(timer, "clear")
})

test("a scroll retracts it the same way", () => {
  assert.equal(shapeOf(step(begin(true).state, "idle").state), "collapsed")
})

test("hovering expands it and stops the timer", () => {
  const retracted = step(begin(true).state, "idle").state
  const {state, timer} = step(retracted, "enter")
  assert.equal(shapeOf(state), "expanded")
  assert.equal(timer, "clear")
})

test("while hovered, the timer and a scroll keep it open", () => {
  const hovered = step(begin(true).state, "enter").state
  const {state, timer} = step(hovered, "idle")
  assert.equal(shapeOf(state), "expanded")
  assert.equal(timer, "keep")
})

test("leaving starts the timer again and then it retracts", () => {
  const hovered = step(begin(true).state, "enter").state
  const left = step(hovered, "leave")
  assert.equal(shapeOf(left.state), "expanded")
  assert.equal(left.timer, "start")
  assert.equal(shapeOf(step(left.state, "idle").state), "collapsed")
})

test("focus counts like hover, and both must go before the timer starts", () => {
  const both = step(step(begin(true).state, "enter").state, "focus").state
  const hoverGone = step(both, "leave")
  assert.equal(hoverGone.timer, "clear")
  assert.equal(shapeOf(step(hoverGone.state, "idle").state), "expanded")
  const allGone = step(hoverGone.state, "blur")
  assert.equal(allGone.timer, "start")
})

test("an unknown event changes nothing", () => {
  const initial = begin(true)
  assert.deepEqual(step(initial.state, "wheel"), {state: initial.state, timer: "keep"})
})
