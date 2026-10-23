/**
 * Where an anchored panel (dropdown, popover) goes, the way LineOne's Popper setups place them: a placement
 * such as `bottom-start` or `right-start`, a distance from the trigger, the fallback sides tried when there is
 * no room, a shift that keeps the panel inside the screen and the arrow that keeps pointing at the trigger.
 * Beside it, the names of the `linea:*` overlay commands. Nothing here reads the DOM.
 */
import {clampShift, roomAround} from "./placement.js"
import {clamp} from "./numbers.js"

const OPPOSITE = {top: "bottom", bottom: "top", left: "right", right: "left"}
const VERTICAL = {top: true, bottom: true, left: false, right: false}

/** The size of LineOne's popover arrow, in pixels. */
export const ARROW = 16

/** The commands every overlay answers. */
export const COMMANDS = ["open", "close", "toggle"]

/** The command of an event type: `linea:open` and `phx:linea:open` are both `open`. */
export const commandOf = (type) => type.split(":").at(-1)

/**
 * The side and the alignment of a placement name; an unknown side is `bottom` and an unknown alignment is
 * `center`.
 *
 * @param {string} placement e.g. `"bottom-start"`, `"top"`, `"right-end"`
 * @returns {{side: "top" | "bottom" | "left" | "right", align: "start" | "center" | "end"}}
 */
export const parsePlacement = (placement = "bottom") => {
  const [side, align] = String(placement).split("-")
  return {
    side: OPPOSITE[side] ? side : "bottom",
    align: ["start", "end"].includes(align) ? align : "center",
  }
}

/** The sides tried in order: the one asked for, then the fallbacks (the opposite side when none are given). */
export const sidesToTry = (side, fallbacks = []) => [...new Set([side, ...(fallbacks.length > 0 ? fallbacks : [OPPOSITE[side]])])]

const fits = (side, panel, room, offset) => room[side] >= (VERTICAL[side] ? panel.height : panel.width) + offset

/**
 * The side a panel opens on: the first of `sidesToTry` with room for the panel and the offset, or the one asked
 * for when none has.
 */
export const pickSide = (side, {panel, room, offset, fallbacks}) =>
  sidesToTry(side, fallbacks).find((candidate) => fits(candidate, panel, room, offset)) ?? side

const along = (align, start, size, panelSize) =>
  ({start: () => start, center: () => start + (size - panelSize) / 2, end: () => start + size - panelSize})[align]()

const corner = (side, align, anchor, panel, offset) =>
  ({
    top: () => ({left: along(align, anchor.left, anchor.width, panel.width), top: anchor.top - offset - panel.height}),
    bottom: () => ({left: along(align, anchor.left, anchor.width, panel.width), top: anchor.bottom + offset}),
    left: () => ({left: anchor.left - offset - panel.width, top: along(align, anchor.top, anchor.height, panel.height)}),
    right: () => ({left: anchor.right + offset, top: along(align, anchor.top, anchor.height, panel.height)}),
  })[side]()

/**
 * Where the panel goes, in the coordinates of the screen, and where its arrow sits along its edge.
 *
 * @param {{
 *   placement: string,
 *   anchor: {left: number, top: number, right: number, bottom: number, width: number, height: number},
 *   panel: {width: number, height: number},
 *   screen: {width: number, height: number},
 *   offset?: number,
 *   padding?: number,
 *   fallbacks?: string[],
 * }} spec `padding` is the room kept from the edge of the screen
 * @returns {{side: string, align: string, top: number, left: number, arrow: number}} `arrow` is the distance of
 *   the arrow from the start of the panel's edge
 */
export const anchorBox = ({placement, anchor, panel, screen, offset = 0, padding = 0, fallbacks = []}) => {
  const asked = parsePlacement(placement)
  const side = pickSide(asked.side, {panel, room: roomAround(anchor, screen), offset, fallbacks})
  const vertical = VERTICAL[side]
  const align = asked.align
  const at = corner(side, align, anchor, panel, offset)
  const shiftX = vertical ? clampShift(at.left, panel.width, screen.width, padding) : 0
  const shiftY = vertical ? 0 : clampShift(at.top, panel.height, screen.height, padding)
  const left = Math.round(at.left + shiftX)
  const top = Math.round(at.top + shiftY)
  const center = vertical ? anchor.left + anchor.width / 2 - left : anchor.top + anchor.height / 2 - top
  const size = vertical ? panel.width : panel.height
  const arrow = Math.round(clamp(center - ARROW / 2, 0, Math.max(0, size - ARROW)))
  return {side, align, top, left, arrow}
}

/** The position of a box in coordinates of the screen, moved into the coordinates of an element that holds it. */
export const toLocal = ({top, left}, origin) => ({top: top - origin.top, left: left - origin.left})
