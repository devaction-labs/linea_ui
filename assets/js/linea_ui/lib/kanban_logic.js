/** Whether a column with a work-in-progress limit takes one more card from another column. */
export const isFull = ({count, wip, sameColumn}) => !sameColumn && Number.isInteger(wip) && wip > 0 && count >= wip

/**
 * Where a dragged card would land: the number of cards (the dragged one left out) whose middle is above the
 * pointer, so a pointer below them all means the end.
 *
 * @param {{top: number, height: number}[]} boxes the other cards of the column, top to bottom
 * @param {number} y the pointer's vertical position
 */
export const insertionIndex = (boxes, y) => boxes.filter((box) => y >= box.top + box.height / 2).length

/** `wip` as the column carries it in `data-wip`: a number, or `NaN` when it has no limit. */
export const parseWip = (text) => Number.parseInt(text ?? "", 10)

/**
 * How far the pointer may travel (in pixels) before a press turns into a drag (`start`) or is given up because
 * the person is scrolling (`cancel`). A mouse or a pen starts by moving; a finger starts by holding still (see
 * `HOLD`) and moving before that is a scroll, which the page keeps.
 */
const travel = {mouse: {start: 4, cancel: Infinity}, pen: {start: 4, cancel: Infinity}, touch: {start: Infinity, cancel: 10}}

/** How long (ms) a finger must hold still on a card before the card can be dragged. */
export const HOLD = {mouse: null, pen: null, touch: 220}

/** What a pointer that has moved `distance` pixels since it pressed means: `"start"`, `"cancel"` or `"wait"`. */
export const moveIntent = (pointerType, distance) => {
  const limits = travel[pointerType] ?? travel.touch
  const rules = [
    [distance >= limits.start, "start"],
    [distance > limits.cancel, "cancel"],
  ]
  return rules.find(([applies]) => applies)?.[1] ?? "wait"
}

/**
 * How many pixels to scroll along one axis when the pointer is near an edge of the scrolling area: nothing in
 * the middle, up to `speed` at the edge (and beyond it), towards that edge. Negative scrolls back.
 *
 * @param {number} position the pointer on this axis
 * @param {{start: number, end: number}} area the visible part of the scrolling area on this axis
 */
export const edgeDelta = (position, {start, end}, {edge = 56, speed = 18} = {}) => {
  const pull = (depth) => Math.round(speed * smooth(Math.min(Math.max(depth / edge, 0), 1)))
  return pull(start + edge - position) * -1 + pull(position - (end - edge))
}

const smooth = (t) => t * t * (3 - 2 * t)

const within = (value, back, forward) => Math.min(Math.max(value, -back), forward)

/**
 * The scroll step `{x, y}` of one scrolling box for a pointer near its edges, held back by the room it has left:
 * `room.x` and `room.y` are `[back, forward]` pixels still scrollable on each axis.
 *
 * @param {{x: number, y: number}} point
 * @param {{left: number, top: number, right: number, bottom: number}} rect the visible part of the box
 */
export const scrollStep = (point, rect, room, options) => ({
  x: within(edgeDelta(point.x, {start: rect.left, end: rect.right}, options), ...room.x),
  y: within(edgeDelta(point.y, {start: rect.top, end: rect.bottom}, options), ...room.y),
})

/** Where the floating copy of a dragged card goes so it stays under the pointer where the card was grabbed. */
export const ghostOffset = (pointer, grab) => ({x: pointer.x - grab.x, y: pointer.y - grab.y})

/** How far (degrees) the floating card leans for a horizontal speed in pixels per second: towards the movement, clamped. */
export const tiltOf = (speed, {gain = 0.004, max = 6} = {}) => Math.min(Math.max(speed * gain, -max), max)

/** Moves `value` towards `target` like a spring that settles in about `tau` ms, whatever the frame time. */
export const approach = (value, target, elapsed, tau = 45) => value + (target - value) * (1 - Math.exp(-elapsed / tau))
