import test from "node:test"
import assert from "node:assert/strict"
import {dropPayload, flagged, indexAt, joins, lineAt, targetAt} from "./sortable_dnd.js"

const rect = (left, top, right, bottom) => ({left, top, right, bottom})
const column = (key, extra = {}) => ({
  key,
  list: key,
  group: "board",
  disabled: false,
  axis: "y",
  rect: rect(0, 0, 100, 300),
  boxes: [
    {id: "a", left: 0, top: 0, width: 100, height: 40},
    {id: "b", left: 0, top: 50, width: 100, height: 40},
  ],
  ...extra,
})

test("a data flag is on when present and not \"false\"", () => {
  assert.equal(flagged(""), true)
  assert.equal(flagged("true"), true)
  assert.equal(flagged("false"), false)
  assert.equal(flagged(undefined), false)
})

test("an item joins its own list and the lists of its group, never an ungrouped other", () => {
  assert.equal(joins({key: "x", group: "g"}, {key: "x"}), true)
  assert.equal(joins({key: "x", group: "g"}, {key: "y", group: "g"}), true)
  assert.equal(joins({key: "x", group: "g"}, {key: "y", group: "h"}), false)
  assert.equal(joins({key: "x"}, {key: "y"}), false)
  assert.equal(joins({key: "x", group: ""}, {key: "y", group: ""}), false)
})

test("the index follows the middles along the axis", () => {
  const boxes = [
    {left: 0, top: 0, width: 100, height: 40},
    {left: 110, top: 0, width: 100, height: 40},
  ]
  assert.equal(indexAt(boxes, {x: 20, y: 500}, "x"), 0)
  assert.equal(indexAt(boxes, {x: 120, y: 0}, "x"), 1)
  assert.equal(indexAt(boxes, {x: 300, y: 0}, "x"), 2)
  assert.equal(indexAt(boxes, {x: 0, y: 10}, "y"), 0)
  assert.equal(indexAt(boxes, {x: 0, y: 30}, "y"), 2)
})

test("the target is the list under the pointer, with the dragged item out of the count", () => {
  const lists = [column("one"), column("two", {rect: rect(200, 0, 300, 300)})]
  const drag = {id: "a", key: "one", group: "board"}
  const own = targetAt(lists, drag, {x: 50, y: 100})
  assert.equal(own.record.list, "one")
  assert.equal(own.index, 1)
  assert.equal(targetAt(lists, drag, {x: 250, y: 10}).record.list, "two")
  assert.equal(targetAt(lists, drag, {x: 150, y: 10}), null)
})

test("a disabled list or one outside the group takes nothing", () => {
  const drag = {id: "a", key: "one", group: "board"}
  assert.equal(targetAt([column("two", {disabled: true})], drag, {x: 5, y: 5}), null)
  assert.equal(targetAt([column("two", {group: "other"})], drag, {x: 5, y: 5}), null)
})

test("the smallest of overlapping lists wins", () => {
  const drag = {id: "z", key: "outer", group: "board"}
  const lists = [column("outer"), column("inner", {rect: rect(10, 10, 60, 60), boxes: []})]
  assert.equal(targetAt(lists, drag, {x: 20, y: 20}).record.list, "inner")
})

test("the line sits in the middle of the gap, and just outside the ends", () => {
  const list = column("one")
  assert.deepEqual(lineAt({...list, index: 1}), {axis: "y", position: 45, from: 0, to: 100})
  assert.equal(lineAt({...list, index: 0}).position, -4)
  assert.equal(lineAt({...list, index: 2}).position, 94)
})

test("an empty list draws its line at the start, across the list", () => {
  const empty = {rect: rect(10, 20, 110, 80), boxes: [], index: 0, axis: "y"}
  assert.deepEqual(lineAt(empty), {axis: "y", position: 24, from: 10, to: 110})
})

test("the line of a horizontal list is vertical and spans the items' height", () => {
  const boxes = [
    {id: "a", left: 0, top: 5, width: 100, height: 40},
    {id: "b", left: 120, top: 5, width: 100, height: 40},
  ]
  assert.deepEqual(lineAt({rect: rect(0, 0, 300, 60), boxes, index: 1, axis: "x"}), {axis: "x", position: 110, from: 5, to: 45})
})

test("a drop where the item already is says nothing; anywhere else is the payload", () => {
  const drag = {id: "a", list: "todo", key: "k1", index: 0}
  assert.equal(dropPayload(drag, {record: {list: "todo", key: "k1"}, index: 0}), null)
  assert.deepEqual(dropPayload(drag, {record: {list: "todo", key: "k1"}, index: 2}), {id: "a", from: "todo", to: "todo", index: 2})
  assert.deepEqual(dropPayload(drag, {record: {list: "done", key: "k2"}, index: 0}), {id: "a", from: "todo", to: "done", index: 0})
})
