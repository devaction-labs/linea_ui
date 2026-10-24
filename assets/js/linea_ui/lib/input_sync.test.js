import assert from "node:assert/strict"
import test from "node:test"
import {nextValue} from "./input_sync.js"

test("after a submit the server value replaces what is typed", () => {
  assert.equal(nextValue({pending: true, current: "buy milk", server: ""}), "")
  assert.equal(nextValue({pending: true, current: "a", server: "b"}), "b")
})

test("nothing changes without a pending submit or when the values already match", () => {
  assert.equal(nextValue({pending: false, current: "typing", server: ""}), null)
  assert.equal(nextValue({pending: true, current: "", server: ""}), null)
  assert.equal(nextValue({pending: true, current: "x", server: undefined}), null)
})
