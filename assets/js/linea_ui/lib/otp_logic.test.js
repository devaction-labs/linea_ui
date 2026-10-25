import test from "node:test"
import assert from "node:assert/strict"
import {cellsOf, complete, erase, firstOpen, joined, reconcile, sanitize, spread, startOf, target} from "./otp_logic.js"

test("startOf sends a whole code to the first box", () => {
  assert.equal(startOf(3, "482913", 6, "numeric"), 0)
  assert.equal(startOf(3, "48-29-13", 6, "numeric"), 0)
  assert.equal(startOf(3, "48", 6, "numeric"), 3)
  assert.equal(startOf(-1, "4", 6, "numeric"), 0)
})

test("sanitize keeps what the mode allows", () => {
  assert.equal(sanitize("12 3-4a", "numeric"), "1234")
  assert.equal(sanitize("a1-B2 c", "alphanumeric"), "a1B2c")
  assert.equal(sanitize(null, "numeric"), "")
  assert.equal(sanitize("12", "unknown"), "12")
})

test("cellsOf cuts and pads", () => {
  assert.deepEqual(cellsOf("482", 6, "numeric"), ["4", "8", "2", "", "", ""])
  assert.deepEqual(cellsOf("12345678", 4, "numeric"), ["1", "2", "3", "4"])
  assert.deepEqual(cellsOf("", 3, "numeric"), ["", "", ""])
  assert.deepEqual(cellsOf("4-8x2", 4, "numeric"), ["4", "8", "2", ""])
})

test("joined and complete", () => {
  assert.equal(joined(["1", "", "3"]), "13")
  assert.equal(complete(["1", "2"]), true)
  assert.equal(complete(["1", ""]), false)
  assert.equal(complete([]), false)
})

test("spread types one character and moves on", () => {
  assert.deepEqual(spread(["", "", ""], 0, "7", "numeric"), {cells: ["7", "", ""], focus: 1})
  assert.deepEqual(spread(["1", "2", "3"], 2, "9", "numeric"), {cells: ["1", "2", "9"], focus: 2})
})

test("spread empties the box when nothing usable was written", () => {
  assert.deepEqual(spread(["1", "2", "3"], 1, "x", "numeric"), {cells: ["1", "", "3"], focus: 1})
  assert.deepEqual(spread(["1", "2", "3"], 1, "", "numeric"), {cells: ["1", "", "3"], focus: 1})
})

test("spread lays a paste over the boxes from the start", () => {
  assert.deepEqual(spread(["", "", "", "", "", ""], 0, "482 913", "numeric"), {cells: ["4", "8", "2", "9", "1", "3"], focus: 5})
  assert.deepEqual(spread(["1", "", "", "", ""], 1, "23", "numeric"), {cells: ["1", "2", "3", "", ""], focus: 3})
  assert.deepEqual(spread(["", "", ""], 1, "98765", "numeric"), {cells: ["", "9", "8"], focus: 2})
})

test("erase clears the previous box when the current one is empty", () => {
  assert.deepEqual(erase(["1", "2", ""], 2), {cells: ["1", "", ""], focus: 1})
  assert.equal(erase(["1", "2", "3"], 2), null)
  assert.equal(erase(["", "2"], 0), null)
})

test("target maps navigation keys inside the boxes", () => {
  assert.equal(target("ArrowLeft", 2, 6), 1)
  assert.equal(target("ArrowRight", 2, 6), 3)
  assert.equal(target("ArrowLeft", 0, 6), null)
  assert.equal(target("ArrowRight", 5, 6), null)
  assert.equal(target("Home", 4, 6), 0)
  assert.equal(target("End", 1, 6), 5)
  assert.equal(target("a", 1, 6), null)
})

test("firstOpen is the first empty box or the last", () => {
  assert.equal(firstOpen(["1", "", ""]), 1)
  assert.equal(firstOpen(["", ""]), 0)
  assert.equal(firstOpen(["1", "2"]), 1)
})

test("reconcile ignores echoes and adopts the server's own value", () => {
  assert.deepEqual(reconcile({incoming: "48", current: "48", sent: ["4", "48"]}), {adopt: false, sent: []})
  assert.deepEqual(reconcile({incoming: "4", current: "482", sent: ["4", "48", "482"]}), {adopt: false, sent: ["48", "482"]})
  assert.deepEqual(reconcile({incoming: "", current: "482", sent: []}), {adopt: true, sent: []})
  assert.deepEqual(reconcile({incoming: "999", current: "482", sent: ["4"]}), {adopt: true, sent: []})
})
