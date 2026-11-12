import {test} from "node:test"
import assert from "node:assert/strict"
import {bendY, edgePath} from "./flow_draw.js"

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

test("the bend stays between the two ends of a short gap", () => {
  assert.equal(bendY(50, 150), 78)
  assert.equal(bendY(50, 56), 53)
  assert.equal(edgePath(100, 50, 300, 56, bendY(50, 56)), "M100 50V50Q100 53 103 53H297Q300 53 300 56V56")
})

test("an edge to a node above goes down a step, across and back up", () => {
  assert.equal(bendY(150, 50), 162)
  assert.equal(edgePath(100, 150, 300, 50, 162), "M100 150V152Q100 162 110 162H290Q300 162 300 152V50")
})
