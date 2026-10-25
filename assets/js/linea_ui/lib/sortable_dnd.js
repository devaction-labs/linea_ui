import {insertionIndex} from "./kanban_logic.js"

/** Whether a `data-*` flag is on: present and not spelled `"false"`. */
export const flagged = (value) => value !== undefined && value !== "false"

/** Whether the dragged item may land in `list`: its own list, or one that shares its (non-empty) group. */
export const joins = (drag, list) => drag.key === list.key || (Boolean(drag.group) && drag.group === list.group)

const contains = (rect, {x, y}) => x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom

const areaOf = ({rect}) => (rect.right - rect.left) * (rect.bottom - rect.top)

const asBox = ({left, top, right, bottom}) => ({left, top, width: right - left, height: bottom - top})

const start = (box, axis) => (axis === "x" ? box.left : box.top)
const end = (box, axis) => (axis === "x" ? box.left + box.width : box.top + box.height)
const across = (axis) => (axis === "x" ? "y" : "x")

/**
 * The slot among `boxes` (the other items of a list, in order) the pointer points at: the number of items whose
 * middle is before it along the list's axis.
 */
export const indexAt = (boxes, point, axis) =>
  axis === "x"
    ? insertionIndex(boxes.map(({left, width}) => ({top: left, height: width})), point.x)
    : insertionIndex(boxes, point.y)

/**
 * Where a dragged item would land: the smallest enabled list that takes it and holds the pointer, and the index
 * it would have there once the item itself is out of the way. `null` when the pointer is over no such list.
 *
 * @param {{key: any, id: string, group?: string}} drag the item in flight
 * @param {{key: any, group?: string, disabled: boolean, axis: "x" | "y", rect: DOMRect, boxes: object[]}[]} lists
 */
export const targetAt = (lists, drag, point) => {
  const hits = lists.filter((list) => !list.disabled && joins(drag, list) && contains(list.rect, point))
  const record = hits.reduce((best, list) => (best && areaOf(best) <= areaOf(list) ? best : list), null)
  return record && {record, index: indexAt(record.boxes.filter(({id}) => id !== drag.id), point, record.axis)}
}

/**
 * How the target list opens a gap for a drop at `index` (among the other items). The items at or after the slot
 * move by the dragged item's `size` plus the `gap` between items; in the dragged item's own list the items after
 * it also close the hole it leaves. `slot` is where the dragged item lands, along the axis (`anchor` is that
 * for a list with no other item); `tailBy` is how far what follows the items (a footer) moves.
 *
 * @param {{id: string, left: number, top: number, width: number, height: number}[]} boxes the list's items, in order
 */
export const gapPlan = ({boxes, dragId, index, size, gap, axis, anchor = 0}) => {
  const step = size + gap
  const origin = boxes.findIndex(({id}) => id === dragId)
  const closes = (at) => (origin >= 0 && at > origin ? -step : 0)
  const others = boxes.map((box, at) => ({box, at})).filter(({box}) => box.id !== dragId)
  const shifts = boxes.map((box, at) => ({
    id: box.id,
    by: box.id === dragId ? 0 : closes(at) + (others.findIndex((other) => other.at === at) >= index ? step : 0),
  }))
  const after = others[index]
  const last = others.at(-1)
  const slot = [
    [after, () => start(after.box, axis) + closes(after.at)],
    [last, () => end(last.box, axis) + closes(last.at) + gap],
    [origin >= 0, () => start(boxes[origin], axis)],
    [true, () => anchor],
  ].find(([applies]) => applies)[1]()
  return {shifts, slot, tailBy: origin >= 0 ? 0 : step}
}

/** The across-axis span `{start, size}` the items of a list occupy: the first item's, or the list's rect inside its padding. */
export const laneOf = ({rect, boxes, axis, inset = [0, 0]}) => {
  const extent = boxes[0] ?? asBox(rect)
  const side = across(axis)
  const [before, after] = boxes[0] ? [0, 0] : inset
  const size = side === "x" ? extent.width : extent.height
  return {start: start(extent, side) + before, size: size - before - after}
}

/** The rectangle a dragged item of size `box` takes at `slot` of a list whose items span `lane`. */
export const slotRect = ({slot, lane, box, axis}) =>
  axis === "x"
    ? {left: slot, top: lane.start, width: box.width, height: lane.size}
    : {left: lane.start, top: slot, width: lane.size, height: box.height}

/**
 * What the server hears for a drop: `%{"id", "from", "to", "index"}`, or `null` when the item lands where it was.
 *
 * @param {{id: string, list: string, key: any, index: number}} drag
 * @param {{record: {list: string, key: any}, index: number}} target
 */
export const dropPayload = (drag, {record, index}) =>
  record.key === drag.key && index === drag.index ? null : {id: drag.id, from: drag.list, to: record.list, index}
