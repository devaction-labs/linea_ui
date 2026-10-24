import assert from "node:assert/strict"
import test from "node:test"
import {adopt, pressed} from "./segmented_logic.js"

test("the choice made in the browser survives a patch that did not change the server's value", () => {
  assert.equal(adopt({value: "week", lastServer: "month", server: "month"}), "week")
})

test("the server wins when its own value changed", () => {
  assert.equal(adopt({value: "week", lastServer: "month", server: "quarter"}), "quarter")
})

test("pressing another segment chooses it", () => {
  assert.equal(pressed("week", "month"), "month")
})

test("pressing the chosen segment changes nothing", () => {
  assert.equal(pressed("week", "week"), null)
})
