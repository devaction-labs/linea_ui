/**
 * Where a tooltip goes, the way LineOne's tippy.js puts it: on the side and alignment asked for
 * (`top`, `top-start`, `right-end`...), `offset` pixels away from the trigger, moved to the opposite
 * side when it does not fit there (flip), kept `padding` pixels inside the screen along the trigger
 * (prevent overflow), with the arrow pointing at the middle of the trigger. Arithmetic on rectangles
 * only, so it is tested without a DOM.
 */
import {clamp} from "./numbers.js"

const OPPOSITE = {top: "bottom", bottom: "top", left: "right", right: "left"}
const VERTICAL = {top: true, bottom: true, left: false, right: false}
const ALIGNS = {start: true, end: true}

/** `"top-start"` as `{side: "top", align: "start"}`; an unknown alignment is the center. */
export const parsePlacement = (placement) => {
  const [side, align] = (placement || "top").split("-")
  return {side: OPPOSITE[side] ? side : "top", align: ALIGNS[align] ? align : "center"}
}

/** The pixels free on each side of a rectangle on the screen. */
const room = (ref, viewport) => ({
  top: ref.top,
  bottom: viewport.height - ref.bottom,
  left: ref.left,
  right: viewport.width - ref.right,
})

const extent = (side, box) => (VERTICAL[side] ? box.height : box.width)

/** The side the tooltip opens on: the one asked for, unless it does not fit and the opposite side has more room. */
export const flip = (side, {ref, box, viewport, offset}) => {
  const free = room(ref, viewport)
  const short = free[side] < extent(side, box) + offset
  return short && free[OPPOSITE[side]] > free[side] ? OPPOSITE[side] : side
}

const mainAxis = {
  top: ({ref, box, offset}) => ref.top - offset - box.height,
  bottom: ({ref, offset}) => ref.bottom + offset,
  left: ({ref, box, offset}) => ref.left - offset - box.width,
  right: ({ref, offset}) => ref.right + offset,
}

const crossAxis = {
  start: (start) => start,
  end: (_start, end, size) => end - size,
  center: (start, end, size) => (start + end) / 2 - size / 2,
}

/**
 * The corner of the tooltip and the offset of its arrow.
 *
 * @param {{
 *   placement: string,
 *   ref: {left: number, top: number, right: number, bottom: number},
 *   box: {width: number, height: number},
 *   viewport: {width: number, height: number},
 *   offset?: number, padding?: number, arrow?: number, arrowPadding?: number
 * }} spec
 * @returns {{placement: string, x: number, y: number, arrow: number}} `arrow` is from the left edge of the tooltip
 *   (top and bottom) or from its top edge (left and right)
 */
export const placeTooltip = ({placement, ref, box, viewport, offset = 10, padding = 5, arrow = 16, arrowPadding = 5}) => {
  const wanted = parsePlacement(placement)
  const side = flip(wanted.side, {ref, box, viewport, offset})
  const vertical = VERTICAL[side]
  const along = vertical
    ? {start: ref.left, end: ref.right, size: box.width, limit: viewport.width}
    : {start: ref.top, end: ref.bottom, size: box.height, limit: viewport.height}
  const wantedCross = crossAxis[wanted.align](along.start, along.end, along.size)
  const cross = clamp(wantedCross, padding, Math.max(padding, along.limit - along.size - padding))
  const main = mainAxis[side]({ref, box, offset})
  const center = (along.start + along.end) / 2 - cross
  const arrowAt = clamp(center - arrow / 2, arrowPadding, Math.max(arrowPadding, along.size - arrow - arrowPadding))
  const name = wanted.align === "center" ? side : `${side}-${wanted.align}`
  return {placement: name, x: vertical ? cross : main, y: vertical ? main : cross, arrow: arrowAt}
}

const CURSOR = {
  both: (ref, point) => ({left: point.x, right: point.x, top: point.y, bottom: point.y}),
  initial: (ref, point) => ({left: point.x, right: point.x, top: point.y, bottom: point.y}),
  horizontal: (ref, point) => ({left: point.x, right: point.x, top: ref.top, bottom: ref.bottom}),
  vertical: (ref, point) => ({left: ref.left, right: ref.right, top: point.y, bottom: point.y}),
}

/**
 * The rectangle a tooltip that follows the cursor is placed against: the pointer itself (`both`,
 * `initial`), or the trigger with only one axis taken from the pointer.
 */
export const cursorRect = (mode, ref, point) => (CURSOR[mode] ?? CURSOR.both)(ref, point)
