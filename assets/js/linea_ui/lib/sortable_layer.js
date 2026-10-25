import {scrollStep} from "./kanban_logic.js"

const Z = "var(--linea-z-popover, 1000)"
const EASE = "cubic-bezier(0.2, 0.8, 0.2, 1)"

export const SETTLE_MS = 180
export const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

const px = (value) => Number.parseFloat(value) || 0

const shift = (axis, by) => (axis === "x" ? `translate3d(${by}px, 0, 0)` : `translate3d(0, ${by}px, 0)`)

/** The rect of `el` as laid out, without the translation a gap put on it (also while that is animating). */
export const naturalRect = (el) => {
  const {left, top, width, height} = el.getBoundingClientRect()
  const {m41, m42} = new DOMMatrixReadOnly(getComputedStyle(el).transform)
  return {left: left - m41, top: top - m42, width, height}
}

const textStyle = ["color", "fontFamily", "fontSize", "fontWeight", "lineHeight", "letterSpacing", "textAlign"]

/** Builds the floating copy of `item` in a fixed layer on the body: `root` follows the pointer, `lift` is the card. */
export const makeGhost = (item, box, grab) => {
  const clone = item.cloneNode(true)
  ;[clone, ...clone.querySelectorAll("[id]")].forEach((node) => node.removeAttribute("id"))
  ;["draggable", "data-dragging", "data-slotted", "data-id"].forEach((name) => clone.removeAttribute(name))
  Object.assign(clone.style, {margin: "0", width: "100%", height: "100%", boxSizing: "border-box", transform: "none"})
  const computed = getComputedStyle(item)
  const lift = Object.assign(document.createElement("div"), {className: "linea-drag-lift"})
  Object.assign(lift.style, {
    width: `${box.width}px`,
    height: `${box.height}px`,
    borderRadius: computed.borderRadius,
    transformOrigin: `${grab.x}px ${grab.y}px`,
    ...Object.fromEntries(textStyle.map((name) => [name, computed[name]])),
  })
  lift.append(clone)
  const root = Object.assign(document.createElement("div"), {className: "linea-drag-ghost"})
  Object.assign(root.style, {
    position: "fixed",
    top: "0",
    left: "0",
    width: `${box.width}px`,
    height: `${box.height}px`,
    pointerEvents: "none",
    zIndex: Z,
    willChange: "transform",
    transformOrigin: `${grab.x}px ${grab.y}px`,
  })
  root.append(lift)
  document.body.append(root)
  lift.getBoundingClientRect()
  lift.classList.add("linea-drag-lifted")
  return {root, lift}
}

export const placeGhost = ({root}, {x, y}, tilt) => {
  root.style.transform = `translate3d(${x}px, ${y}px, 0) rotate(${tilt}deg)`
}

/** Glides the ghost into `rect`, laying the card down as it goes. */
export const landGhost = ({root, lift}, rect) => {
  root.style.transition = reduced() ? "none" : `transform ${SETTLE_MS}ms ${EASE}`
  lift.classList.remove("linea-drag-lifted")
  root.style.transform = `translate3d(${rect.left}px, ${rect.top}px, 0) rotate(0deg)`
}

export const makeSlot = () => {
  const slot = Object.assign(document.createElement("div"), {className: "linea-drop-slot", hidden: true})
  Object.assign(slot.style, {position: "fixed", top: "0", left: "0", pointerEvents: "none", zIndex: Z})
  document.body.append(slot)
  return slot
}

/** Puts the drop placeholder on `rect`; it glides there when `glide` is on, else it jumps. */
export const placeSlot = (slot, rect, radius, glide) => {
  const fresh = slot.hidden
  slot.hidden = false
  slot.style.transition = glide && !fresh && !reduced() ? `transform 160ms ${EASE}, width 160ms ${EASE}, height 160ms ${EASE}` : "none"
  Object.assign(slot.style, {
    width: `${rect.width}px`,
    height: `${rect.height}px`,
    borderRadius: radius,
    transform: `translate3d(${rect.left}px, ${rect.top}px, 0)`,
  })
}

const SLIDE = () => (reduced() ? "none" : `transform ${SETTLE_MS - 20}ms ${EASE}`)

const move = (el, axis, by) => {
  el.style.transition = SLIDE()
  const next = by ? shift(axis, by) : ""
  el.style.transform !== next && (next ? (el.style.transform = next) : el.style.removeProperty("transform"))
}

/**
 * Opens a gap in `list`: every item and tail element is moved to the offset of the plan (the ones already there
 * are left alone, so each animates on its own as the insertion index changes), and the list grows to hold it.
 */
export const openGap = (open, {list, axis, items, tail, plan, step}) => {
  const grown = plan.tailBy ? step : 0
  const side = axis === "x" ? "paddingRight" : "paddingBottom"
  open.list === list || (open.list && closeGap(open, true))
  open.list = list
  open.axis = axis
  open.moved = new Set([...(open.moved ?? []), ...items.map(({el}) => el), ...tail])
  open.base ??= {side, value: px(getComputedStyle(list)[side]), inline: list.style[side], transition: list.style.transition}
  plan.shifts.forEach(({by}, at) => move(items[at].el, axis, by))
  tail.forEach((el) => move(el, axis, plan.tailBy))
  list.style.transition = reduced() ? "none" : `${axis === "x" ? "padding-right" : "padding-bottom"} ${SETTLE_MS - 20}ms ${EASE}`
  list.style[side] = `${open.base.value + grown}px`
}

/** Closes the gap: everything slides back (or snaps back when `animate` is off) and the list's padding is restored. */
export const closeGap = (open, animate) => {
  const {list, moved, base, axis} = open
  list && moved.forEach((el) => (animate ? move(el, axis, 0) : (el.style.transition = "none", el.style.removeProperty("transform"))))
  list && Object.assign(list.style, {transition: animate ? list.style.transition : "none"})
  list && (list.style[base.side] = base.inline)
  const done = () => {
    moved?.forEach((el) => el.style.removeProperty("transition"))
    list?.style.setProperty("transition", base.transition)
  }
  animate ? setTimeout(done, SETTLE_MS) : done()
  Object.assign(open, {list: null, moved: null, base: null})
}

const scrollable = (el) => {
  const {overflowX, overflowY} = getComputedStyle(el)
  return /(auto|scroll|overlay)/.test(`${overflowX} ${overflowY}`)
}

const roomOf = (el) => ({
  x: [el.scrollLeft, el.scrollWidth - el.clientWidth - el.scrollLeft],
  y: [el.scrollTop, el.scrollHeight - el.clientHeight - el.scrollTop],
})

const chain = (el) => (el ? [el, ...chain(el.parentElement)] : [])

const viewport = () => ({left: 0, top: 0, right: innerWidth, bottom: innerHeight})

/** Scrolls every scrolling ancestor of what is under the pointer, and the page, when the pointer is near its edges. Tells whether anything moved. */
export const autoScroll = (point) => {
  const under = document.elementFromPoint(point.x, point.y)
  const boxes = chain(under)
    .filter((el) => scrollable(el) && el !== document.body && el !== document.documentElement)
    .map((el) => ({el, rect: el.getBoundingClientRect()}))
  const page = document.scrollingElement
  const steps = [...boxes, {el: page, rect: viewport()}].map(({el, rect}) => ({el, step: scrollStep(point, rect, roomOf(el))}))
  steps.forEach(({el, step}) => ((el.scrollLeft += step.x), (el.scrollTop += step.y)))
  return steps.some(({step}) => step.x !== 0 || step.y !== 0)
}
