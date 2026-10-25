import {insertionIndex} from "./kanban_logic.js"

const HALF_GAP = 4

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
 * The insertion indicator for a drop at `index` among `boxes`: its position along the list's axis (halfway
 * through the gap between the neighbours) and the span `from` to `to` it covers across it.
 */
export const lineAt = ({rect, boxes, index, axis}) => {
  const [before, after] = [boxes[index - 1], boxes[index]]
  const frame = asBox(rect)
  const position = [
    [before && after, () => (end(before, axis) + start(after, axis)) / 2],
    [after, () => start(after, axis) - HALF_GAP],
    [before, () => end(before, axis) + HALF_GAP],
    [true, () => start(frame, axis) + HALF_GAP],
  ].find(([applies]) => applies)[1]()
  const extent = boxes[0] ?? frame
  return {axis, position, from: start(extent, across(axis)), to: end(extent, across(axis))}
}

/**
 * What the server hears for a drop: `%{"id", "from", "to", "index"}`, or `null` when the item lands where it was.
 *
 * @param {{id: string, list: string, key: any, index: number}} drag
 * @param {{record: {list: string, key: any}, index: number}} target
 */
export const dropPayload = (drag, {record, index}) =>
  record.key === drag.key && index === drag.index ? null : {id: drag.id, from: drag.list, to: record.list, index}
