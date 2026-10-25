import {HOLD, ghostOffset, moveIntent} from "../lib/kanban_logic.js"
import {dropPayload, flagged, lineAt, targetAt} from "../lib/sortable_dnd.js"

const SELF = '[phx-hook="LineaUI.Sortable"]'
const LINE_CLASS = "pointer-events-none fixed rounded-full bg-primary dark:bg-accent"
const SETTLE_MS = 800

const instances = new Set()
const state = {drag: null, over: null, line: null, ghost: null, settle: null}

const elementOf = (node) => (node instanceof Element ? node : node?.parentElement)

const itemIn = (lists, node) => {
  const item = elementOf(node)?.closest("[data-id]")
  return !item || lists.includes(item.parentElement) ? item : itemIn(lists, item.parentElement)
}

const pointOf = ({clientX, clientY}) => ({x: clientX, y: clientY})

const boxOf = (el) => {
  const {left, top, width, height} = el.getBoundingClientRect()
  return {id: el.dataset.id, left, top, width, height}
}

const lineElement = () => {
  state.line ??= Object.assign(document.createElement("div"), {className: LINE_CLASS, hidden: true})
  state.line.style.zIndex = "var(--linea-z-popover, 1000)"
  state.line.isConnected || document.body.append(state.line)
  return state.line
}

const lineStyle = ({axis, position, from, to}) =>
  axis === "x"
    ? {left: `${position - 1.5}px`, top: `${from}px`, width: "3px", height: `${to - from}px`}
    : {left: `${from}px`, top: `${position - 1.5}px`, width: `${to - from}px`, height: "3px"}

const hideLine = () => state.line && (state.line.hidden = true)

const drawLine = (line) => {
  const element = lineElement()
  Object.assign(element.style, lineStyle(line))
  element.hidden = false
}

const placeLine = ({record, index}) => {
  const boxes = record.boxes.filter(({id}) => id !== state.drag.id)
  boxes.length === 0 ? hideLine() : drawLine(lineAt({rect: record.rect, boxes, index, axis: record.axis}))
}

const markOver = (target) => {
  const next = target?.record.el ?? null
  state.over !== next && (state.over?.removeAttribute("data-over"), next?.setAttribute("data-over", ""), (state.over = next))
}

const show = (target) => {
  markOver(target)
  target ? placeLine(target) : hideLine()
}

const hit = (point) =>
  state.drag && !state.settle && targetAt([...instances].flatMap((instance) => instance.snapshot()), state.drag, point)

const dropGhost = () => {
  state.ghost?.remove()
  state.ghost = null
}

const finish = () => {
  clearTimeout(state.settle)
  state.settle = null
  state.drag?.item.removeAttribute("data-dragging")
  state.drag = null
  show(null)
  dropGhost()
}

const commit = (target) => {
  const payload = target && dropPayload(state.drag, target)
  markOver(null)
  dropGhost()
  payload ? sent(target, payload) : finish()
}

const sent = (target, payload) => {
  target.record.owner.push(target.record.el, payload)
  state.settle = setTimeout(finish, SETTLE_MS)
}

const lift = (owner, item, list) => {
  finish()
  state.drag = {
    id: item.dataset.id,
    key: list,
    list: list.dataset.list,
    group: owner.cfg(list, "group"),
    index: owner.items(list).indexOf(item),
    item,
  }
}

const ghostFor = (item, box) => {
  const ghost = item.cloneNode(true)
  ;[ghost, ...ghost.querySelectorAll("[id]")].forEach((node) => node.removeAttribute("id"))
  ghost.removeAttribute("draggable")
  Object.assign(ghost.style, {
    position: "fixed",
    top: "0",
    left: "0",
    margin: "0",
    width: `${box.width}px`,
    pointerEvents: "none",
    opacity: ".92",
    rotate: "2deg",
    filter: "drop-shadow(0 12px 18px rgb(16 24 64 / .25))",
    zIndex: "var(--linea-z-popover, 1000)",
  })
  return ghost
}

const onDragOver = (event) => {
  const target = hit(pointOf(event))
  show(target)
  target && (event.preventDefault(), (event.dataTransfer.dropEffect = "move"))
}

const onDrop = (event) => {
  const target = hit(pointOf(event))
  target && (event.preventDefault(), commit(target))
}

const onDragEnd = () => state.settle || finish()

const documentListeners = [
  ["dragover", onDragOver],
  ["drop", onDrop],
  ["dragend", onDragEnd],
]

const attach = () => documentListeners.forEach(([type, fn]) => document.addEventListener(type, fn))

const detach = () => {
  documentListeners.forEach(([type, fn]) => document.removeEventListener(type, fn))
  state.line?.remove()
  state.line = null
}

/**
 * `LineaUI.Sortable`: drag and drop of items between and within lists, on the browser's own drag and drop (no
 * library). The hook element is a list, or holds several lists (a board): a list is an element with `data-list`,
 * its items are the children with `data-id`. Lists with the same `data-group` exchange items; without a group an
 * item moves only inside its list.
 *
 * Config, read from the list and, when it has none, from the hook element: `data-event` (the server event),
 * `data-target` (its `phx-target`; without it the event goes to the hook's LiveView), `data-group`,
 * `data-handle` (a selector inside the item: only it starts a drag), `data-axis` (`"x"` for a row of items,
 * `"y"` by default) and `data-disabled` (the list neither gives nor takes items).
 *
 * A drop pushes `%{"id", "from", "to", "index"}`: the item's `data-id`, the `data-list` it came from and went
 * to, and its index there once it is placed. A drop where the item already was pushes nothing. The browser never
 * moves anything: the dragged item is dimmed (`data-dragging`), the list under the pointer gets `data-over` and a
 * line shows the slot, and the server's render is the new order.
 *
 * A finger cannot use the browser's drag and drop, so touch is handled with pointer events: hold an item still for
 * a moment, then drag it (a floating copy follows the finger); moving before that scrolls as usual. The board does
 * not auto-scroll under a finger. For the keyboard, and for a touch screen where this is not enough, give the item
 * a button that pushes the same event with the destination.
 */
export default {
  "LineaUI.Sortable": {
    mounted() {
      this.touch = null
      this.lifted = false
      this.pressed = null
      this.listeners = [
        [this.el, "dragstart", (event) => this.dragstart(event)],
        [this.el, "pointerdown", (event) => this.press(event)],
        [this.el, "pointermove", (event) => this.move(event)],
        [this.el, "pointerup", (event) => this.up(event)],
        [this.el, "pointercancel", () => this.release()],
        [this.el, "touchmove", (event) => this.lifted && event.preventDefault(), {passive: false}],
        [this.el, "touchend", (event) => this.unlift(event), {passive: false}],
        [this.el, "touchcancel", (event) => this.unlift(event)],
        [this.el, "contextmenu", (event) => this.touch && event.preventDefault()],
      ]
      this.listeners.forEach(([target, type, fn, opts]) => target.addEventListener(type, fn, opts))
      instances.add(this)
      instances.size === 1 && attach()
    },

    updated() {
      state.settle ? finish() : state.drag?.item.setAttribute("data-dragging", "")
    },

    destroyed() {
      this.listeners.forEach(([target, type, fn, opts]) => target.removeEventListener(type, fn, opts))
      this.release()
      instances.delete(this)
      state.drag && !state.drag.item.isConnected && finish()
      instances.size === 0 && detach()
    },

    cfg(list, key) {
      return list.dataset[key] ?? this.el.dataset[key]
    },

    lists() {
      return [this.el, ...this.el.querySelectorAll("[data-list]")].filter(
        (list) => list.matches("[data-list]") && list.closest(SELF) === this.el,
      )
    },

    items(list) {
      return Array.from(list.children).filter((child) => child.matches("[data-id]"))
    },

    snapshot() {
      return this.lists().map((list) => ({
        key: list,
        el: list,
        owner: this,
        list: list.dataset.list,
        group: this.cfg(list, "group"),
        axis: this.cfg(list, "axis") === "x" ? "x" : "y",
        disabled: flagged(this.cfg(list, "disabled")),
        rect: list.getBoundingClientRect(),
        boxes: this.items(list).map(boxOf),
      }))
    },

    itemAt(node) {
      return elementOf(node)?.closest(SELF) === this.el ? itemIn(this.lists(), node) : null
    },

    mayDrag(list, item) {
      const handle = this.cfg(list, "handle")
      const grip = handle && this.pressed?.closest?.(handle)
      return !flagged(this.cfg(list, "disabled")) && (!handle || Boolean(grip && item.contains(grip)))
    },

    push(list, payload) {
      const event = this.cfg(list, "event")
      const target = this.cfg(list, "target")
      event && (target ? this.pushEventTo(target, event, payload) : this.pushEvent(event, payload))
    },

    press(event) {
      this.pressed = elementOf(event.target)
      const item = this.itemAt(event.target)
      const allowed = Boolean(item) && this.mayDrag(item.parentElement, item)
      const touch = event.pointerType === "touch"
      item && (item.draggable = allowed && !touch)
      allowed && touch && this.hold(event, item)
    },

    dragstart(event) {
      const item = this.itemAt(event.target)
      const allowed = Boolean(item) && this.mayDrag(item.parentElement, item)
      allowed ? this.pick(event, item) : item && event.preventDefault()
    },

    pick(event, item) {
      lift(this, item, item.parentElement)
      const box = item.getBoundingClientRect()
      event.dataTransfer.effectAllowed = "move"
      event.dataTransfer.setData("text/plain", item.dataset.id)
      event.dataTransfer.setDragImage(item, event.clientX - box.left, event.clientY - box.top)
      setTimeout(() => state.drag?.item === item && item.setAttribute("data-dragging", ""))
    },

    hold(event, item) {
      this.release()
      this.touch = {
        id: event.pointerId,
        item,
        origin: pointOf(event),
        grab: null,
        active: false,
        timer: setTimeout(() => this.raise(pointOf(event)), HOLD.touch),
      }
    },

    raise(point) {
      const {item} = this.touch
      const box = item.getBoundingClientRect()
      lift(this, item, item.parentElement)
      this.touch.active = true
      this.touch.grab = {x: point.x - box.left, y: point.y - box.top}
      this.lifted = true
      state.ghost = ghostFor(item, box)
      document.body.append(state.ghost)
      item.setAttribute("data-dragging", "")
      getSelection()?.removeAllRanges()
      this.follow(point)
    },

    follow(point) {
      const {x, y} = ghostOffset(point, this.touch.grab)
      state.ghost.style.translate = `${x}px ${y}px`
      show(hit(point))
    },

    move(event) {
      const touch = this.touch
      const distance = touch && Math.hypot(event.clientX - touch.origin.x, event.clientY - touch.origin.y)
      touch?.id === event.pointerId &&
        (touch.active ? this.follow(pointOf(event)) : moveIntent("touch", distance) === "cancel" && this.release())
    },

    up(event) {
      const touch = this.touch
      const mine = touch?.id === event.pointerId
      mine && touch.active && commit(hit(pointOf(event)))
      mine && this.end()
    },

    end() {
      clearTimeout(this.touch?.timer)
      this.touch = null
    },

    release() {
      this.touch?.active && finish()
      this.end()
    },

    unlift(event) {
      this.lifted && event.cancelable && event.preventDefault()
      this.lifted = false
    },
  },
}
