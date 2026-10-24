/**
 * Floating panels (dropdown, popover, tooltip) are drawn in the browser's top layer: they carry
 * `popover="manual"` and are shown with `showPopover()`, so no ancestor's `overflow` cuts them off and no
 * ancestor's `z-index`, `transform` or `filter` buries or moves them, while they stay where LiveView rendered
 * them in the DOM (patches, events, focus and keyboard handling are untouched). A browser without the Popover
 * API keeps them as `position: fixed` boxes on `--linea-z-popover`, placed from the trigger's rectangle all
 * the same. The functions take the element (or a stand-in with the same methods), so they are tested without
 * a browser.
 */
import {clipsOverflow} from "./anchor_logic.js"

/** Whether the element can go to the top layer: it has a `popover` attribute and the browser knows the API. */
export const canLift = (el) => typeof el?.showPopover === "function" && el.hasAttribute?.("popover") === true

const isLifted = (el) => {
  try {
    return el.matches(":popover-open")
  } catch {
    return false
  }
}

/** Puts the element in the top layer; does nothing when it is there already or cannot go. */
export const lift = (el) => {
  canLift(el) && !isLifted(el) && el.showPopover()
}

/** Takes the element out of the top layer; does nothing when it is not there. */
export const drop = (el) => {
  canLift(el) && isLifted(el) && el.hidePopover()
}

/**
 * The ancestors of `el` that clip what overflows them, nearest first, below `<body>`: the overflow of `<html>`
 * and `<body>` belongs to the viewport, which is checked on its own.
 *
 * @param {Element} el
 * @param {(el: Element) => {overflowX: string, overflowY: string}} styleOf `getComputedStyle` in the browser
 */
export const clippingAncestors = (el, styleOf) => {
  const found = []
  for (let node = el?.parentElement; node?.parentElement?.parentElement; node = node.parentElement) {
    clipsOverflow(styleOf(node)) && found.push(node)
  }
  return found
}
