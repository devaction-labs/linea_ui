import assert from "node:assert/strict"
import test from "node:test"
import {calendarMove, rovingStops} from "./calendar_nav.js"

const month = {columns: 7, total: 35}

test("the arrows move a day or a week inside the grid", () => {
  assert.deepEqual(calendarMove(10, "ArrowRight", month), {focus: 11})
  assert.deepEqual(calendarMove(10, "ArrowLeft", month), {focus: 9})
  assert.deepEqual(calendarMove(10, "ArrowDown", month), {focus: 17})
  assert.deepEqual(calendarMove(10, "ArrowUp", month), {focus: 3})
})

test("an arrow past the first or the last cell asks for the previous or the next period", () => {
  assert.deepEqual(calendarMove(0, "ArrowLeft", month), {page: "prev"})
  assert.deepEqual(calendarMove(3, "ArrowUp", month), {page: "prev"})
  assert.deepEqual(calendarMove(34, "ArrowRight", month), {page: "next"})
  assert.deepEqual(calendarMove(30, "ArrowDown", month), {page: "next"})
})

test("Home and End go to the ends of the row", () => {
  assert.deepEqual(calendarMove(10, "Home", month), {focus: 7})
  assert.deepEqual(calendarMove(10, "End", month), {focus: 13})
})

test("the page keys change period", () => {
  assert.deepEqual(calendarMove(10, "PageUp", month), {page: "prev"})
  assert.deepEqual(calendarMove(10, "PageDown", month), {page: "next"})
})

test("a key the grid does not use is left alone", () => {
  assert.equal(calendarMove(10, "a", month), null)
  assert.equal(calendarMove(10, "Enter", month), null)
})

test("a week grid walks its own columns", () => {
  const week = {columns: 5, total: 30}
  assert.deepEqual(calendarMove(2, "ArrowDown", week), {focus: 7})
  assert.deepEqual(calendarMove(29, "End", week), {focus: 29})
})

test("one cell is in the Tab order", () => {
  assert.deepEqual(rovingStops(4, 2), [-1, -1, 0, -1])
  assert.deepEqual(rovingStops(2, -1), [-1, -1])
})
