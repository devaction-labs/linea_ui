import assert from "node:assert/strict"
import test from "node:test"
import {focusClass, grown, legendFocus} from "./chart_focus.js"

test("the series in front is focused and the others dim; with none in front nothing changes", () => {
  assert.equal(focusClass(1, 1), "is-focus")
  assert.equal(focusClass("1", 1), "is-focus")
  assert.equal(focusClass(0, 1), "is-dim")
  assert.equal(focusClass(0, null), null)
  assert.equal(focusClass(0, undefined), null)
  assert.equal(focusClass(0, 0), "is-focus")
})

test("a focused slice is drawn thicker than its own width", () => {
  assert.equal(grown("40") > 40, true)
  assert.equal(grown(0), null)
  assert.equal(grown(null), null)
  assert.equal(grown("abc"), null)
})

test("only a shown legend entry puts its series in front", () => {
  const item = (pressed, series) => ({dataset: {series}, getAttribute: () => pressed})
  assert.equal(legendFocus(item("true", "2")), 2)
  assert.equal(legendFocus(item("false", "2")), null)
  assert.equal(legendFocus(null), null)
})
