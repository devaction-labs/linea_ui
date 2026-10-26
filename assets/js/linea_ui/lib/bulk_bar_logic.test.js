import test from "node:test"
import assert from "node:assert/strict"
import {clearsOnEscape} from "./bulk_bar_logic.js"

test("Escape clears the selection", () => {
  assert.equal(clearsOnEscape({key: "Escape"}), true)
})

test("other keys do not", () => {
  assert.equal(clearsOnEscape({key: "Enter"}), false)
})

test("an Escape already handled, composing, or for an open list is left alone", () => {
  assert.equal(clearsOnEscape({key: "Escape", defaultPrevented: true}), false)
  assert.equal(clearsOnEscape({key: "Escape", isComposing: true}), false)
  assert.equal(clearsOnEscape({key: "Escape"}, {listOpen: true}), false)
})
