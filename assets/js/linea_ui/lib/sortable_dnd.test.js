import test from "node:test"
import assert from "node:assert/strict"
import {dropPayload, flagged, gapPlan, indexAt, joins, laneOf, slotRect, targetAt} from "./sortable_dnd.js"

const rect_ = (left, top, right, bottom) => ({left, top, right, bottom})
const column = (key, extra = {}) => ({
  key,
  list: key,
  group: "board",
  disabled: false,
  axis: "y",
  rect: rect_(0, 0, 100, 300),
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
  const lists = [column("one"), column("two", {rect: rect_(200, 0, 300, 300)})]
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
  const lists = [column("outer"), column("inner", {rect: rect_(10, 10, 60, 60), boxes: []})]
  assert.equal(targetAt(lists, drag, {x: 20, y: 20}).record.list, "inner")
})

const stack = [
  {id: "a", left: 0, top: 0, width: 100, height: 40},
  {id: "b", left: 0, top: 50, width: 100, height: 40},
  {id: "c", left: 0, top: 100, width: 100, height: 40},
]

test("a foreign list moves its items from the slot on, and what follows them", () => {
  const plan = gapPlan({boxes: stack, dragId: "x", index: 1, size: 40, gap: 10, axis: "y"})
  assert.deepEqual(plan.shifts, [{id: "a", by: 0}, {id: "b", by: 50}, {id: "c", by: 50}])
  assert.equal(plan.slot, 50)
  assert.equal(plan.tailBy, 50)
})

test("the slot at the end of a foreign list is below the last item; an empty one uses the anchor", () => {
  assert.equal(gapPlan({boxes: stack, dragId: "x", index: 3, size: 40, gap: 10, axis: "y"}).slot, 150)
  assert.deepEqual(gapPlan({boxes: stack, dragId: "x", index: 3, size: 40, gap: 10, axis: "y"}).shifts.map(({by}) => by), [0, 0, 0])
  const empty = gapPlan({boxes: [], dragId: "x", index: 0, size: 40, gap: 10, axis: "y", anchor: 77})
  assert.deepEqual([empty.shifts, empty.slot], [[], 77])
})

test("in its own list the dragged item's hole closes and the gap opens at the slot", () => {
  const stay = gapPlan({boxes: stack, dragId: "a", index: 0, size: 40, gap: 10, axis: "y"})
  assert.deepEqual(stay.shifts.map(({by}) => by), [0, 0, 0])
  assert.equal(stay.slot, 0)
  assert.equal(stay.tailBy, 0)

  const down = gapPlan({boxes: stack, dragId: "a", index: 1, size: 40, gap: 10, axis: "y"})
  assert.deepEqual(down.shifts.map(({by}) => by), [0, -50, 0])
  assert.equal(down.slot, 50)

  const end = gapPlan({boxes: stack, dragId: "a", index: 2, size: 40, gap: 10, axis: "y"})
  assert.deepEqual(end.shifts.map(({by}) => by), [0, -50, -50])
  assert.equal(end.slot, 100)

  const up = gapPlan({boxes: stack, dragId: "c", index: 0, size: 40, gap: 10, axis: "y"})
  assert.deepEqual(up.shifts.map(({by}) => by), [50, 50, 0])
  assert.equal(up.slot, 0)
})

test("a lone item's list keeps its slot where the item is", () => {
  const plan = gapPlan({boxes: [stack[1]], dragId: "b", index: 0, size: 40, gap: 10, axis: "y"})
  assert.equal(plan.slot, 50)
})

test("a row opens its gap sideways", () => {
  const row = [
    {id: "a", left: 0, top: 5, width: 100, height: 40},
    {id: "b", left: 120, top: 5, width: 100, height: 40},
  ]
  const plan = gapPlan({boxes: row, dragId: "x", index: 1, size: 100, gap: 20, axis: "x"})
  assert.deepEqual(plan.shifts.map(({by}) => by), [0, 120])
  assert.equal(plan.slot, 120)
})

test("the lane is the first item's span across the axis, or the list inside its padding", () => {
  const rect = rect_(10, 20, 110, 80)
  assert.deepEqual(laneOf({rect, boxes: stack, axis: "y"}), {start: 0, size: 100})
  assert.deepEqual(laneOf({rect, boxes: [], axis: "y", inset: [10, 10]}), {start: 20, size: 80})
  assert.deepEqual(laneOf({rect, boxes: [], axis: "x", inset: [5, 5]}), {start: 25, size: 50})
})

test("the dropped item takes its height along the slot and the lane's width", () => {
  const lane = {start: 12, size: 252}
  assert.deepEqual(slotRect({slot: 300, lane, box: {width: 200, height: 60}, axis: "y"}), {left: 12, top: 300, width: 252, height: 60})
  assert.deepEqual(slotRect({slot: 300, lane, box: {width: 200, height: 60}, axis: "x"}), {left: 300, top: 12, width: 200, height: 252})
})

test("a drop where the item already is says nothing; anywhere else is the payload", () => {
  const drag = {id: "a", list: "todo", key: "k1", index: 0}
  assert.equal(dropPayload(drag, {record: {list: "todo", key: "k1"}, index: 0}), null)
  assert.deepEqual(dropPayload(drag, {record: {list: "todo", key: "k1"}, index: 2}), {id: "a", from: "todo", to: "todo", index: 2})
  assert.deepEqual(dropPayload(drag, {record: {list: "done", key: "k2"}, index: 0}), {id: "a", from: "todo", to: "done", index: 0})
})
