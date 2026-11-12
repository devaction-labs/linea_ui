import {test} from "node:test"
import assert from "node:assert/strict"
import {edgePath} from "./flow_draw.js"

test("a straight edge is one vertical line", () => {
  assert.equal(edgePath(100, 50, 100, 150, 78), "M100 50V150")
})

test("a branch goes down, across with rounded corners and down", () => {
  assert.equal(edgePath(100, 50, 300, 150, 78), "M100 50V68Q100 78 110 78H290Q300 78 300 88V150")
  assert.equal(edgePath(300, 50, 100, 150, 78), "M300 50V68Q300 78 290 78H110Q100 78 100 88V150")
})

test("the corner radius shrinks to fit a short step", () => {
  assert.equal(edgePath(100, 50, 108, 150, 78), "M100 50V74Q100 78 104 78H104Q108 78 108 82V150")
})
