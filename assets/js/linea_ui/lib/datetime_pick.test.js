import assert from "node:assert/strict"
import test from "node:test"
import {gridTarget, monthOff, yearOff, yearPage} from "./datetime_pick.js"

test("a page of years is twelve long and holds the year asked for", () => {
  assert.equal(yearPage(2026), 2016)
  assert.equal(yearPage(2016), 2016)
  assert.equal(yearPage(2027), 2016)
  assert.equal(yearPage(2028), 2028)
  assert.equal(yearPage(2015), 2004)
})

test("a month or a year is shut out only when all of it is outside min and max", () => {
  const rules = {min: {date: "2026-03-15", time: null}, max: {date: "2026-10-10", time: null}}
  assert.equal(monthOff({year: 2026, month: 1}, rules), true)
  assert.equal(monthOff({year: 2026, month: 2}, rules), false)
  assert.equal(monthOff({year: 2026, month: 9}, rules), false)
  assert.equal(monthOff({year: 2026, month: 10}, rules), true)
  assert.equal(monthOff({year: 2026, month: 10}, {min: null, max: null}), false)
  assert.equal(yearOff(2025, rules), true)
  assert.equal(yearOff(2026, rules), false)
  assert.equal(yearOff(2027, rules), true)
  assert.equal(yearOff(2027, {min: null, max: null}), false)
})

test("arrow keys move over three columns and stop at the edges", () => {
  assert.equal(gridTarget("ArrowRight", 4), 5)
  assert.equal(gridTarget("ArrowLeft", 0), 0)
  assert.equal(gridTarget("ArrowDown", 4), 7)
  assert.equal(gridTarget("ArrowDown", 10), 11)
  assert.equal(gridTarget("ArrowUp", 1), 0)
  assert.equal(gridTarget("Home", 7), 0)
  assert.equal(gridTarget("End", 3), 11)
  assert.equal(gridTarget("a", 3), null)
})
