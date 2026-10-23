import {test} from "node:test"
import assert from "node:assert/strict"
import {indeterminate} from "./data_table_logic.js"

test("mixed only when some rows are selected and the box is not checked", () => {
  assert.equal(indeterminate("true", false), true)
  assert.equal(indeterminate("true", true), false)
  assert.equal(indeterminate("false", false), false)
  assert.equal(indeterminate(undefined, false), false)
})
