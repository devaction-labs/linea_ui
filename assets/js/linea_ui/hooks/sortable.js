import {HOLD, approach, ghostOffset, moveIntent, tiltOf} from "../lib/kanban_logic.js"
import {dropPayload, flagged, gapPlan, laneOf, slotRect, targetAt} from "../lib/sortable_dnd.js"
import {
  SETTLE_MS,
  autoScroll,
  closeGap,
  landGhost,
  makeGhost,
  makeSlot,
  naturalRect,
  openGap,
  placeGhost,
  placeSlot,
  reduced,
} from "../lib/sortable_layer.js"

const SELF = '[phx-hook="LineaUI.Sortable"]'
const EDITABLE = "input, textarea, select, [contenteditable='true']"
const SERVER_MS = 800
const SWALLOW_MS = 150
const MARK = "data-linea-dragging"

const instances = new Set()
const state = {drag: null, over: null, ghost: null, slot: null, open: {}, landing: null, settle: null, point: null, dirty: false, raf: 0, swallow: false}

const elementOf = (node) => (node instanceof Element ? node : node?.parentElement)

const itemIn = (lists, node) => {
  const item = elementOf(node)?.closest("[data-id]")
  return !item || lists.includes(item.parentElement) ? item : itemIn(lists, item.parentElement)
}

const pointOf = ({clientX, clientY}) => ({x: clientX, y: clientY})

const px = (value) => Number.parseFloat(value) || 0

const boxOf = (el) => ({id: el.dataset.id, el, ...naturalRect(el)})

const markOver = (target) => {
  const next = target?.record.el ?? null
  state.over !== next && (state.over?.removeAttribute("data-over"), next?.setAttribute("data-over", ""), (state.over = next))
}

const startOf = (rect, horizontal) => (horizontal ? rect.left : rect.top)
const endOf = (rect, horizontal) => (horizontal ? rect.left + rect.width : rect.top + rect.height)

const tailOf = (children, boxes) => {
  const lastItem = children.findLastIndex((child) => child.matches("[data-id]"))
  const empty = children.findIndex((child) => child.matches("[data-empty]"))
  return boxes.length ? children.slice(lastItem + 1) : empty < 0 ? [] : children.slice(empty)
}

const measure = ({el, axis, boxes, rect}) => {
  const style = getComputedStyle(el)
  const horizontal = axis === "x"
  const children = Array.from(el.children)
  const tail = tailOf(children, boxes)
  const [first, second] = boxes
  const gap = second ? startOf(second, horizontal) - endOf(first, horizontal) : px(horizontal ? style.columnGap : style.rowGap)
  const last = children.at(-1)
  const anchors = [
    [tail[0], () => startOf(naturalRect(tail[0]), horizontal)],
    [last, () => endOf(naturalRect(last), horizontal) + gap],
    [true, () => startOf(rect, horizontal) + px(horizontal ? style.paddingLeft : style.paddingTop)],
  ]
  const inset = horizontal ? [px(style.paddingTop), px(style.paddingBottom)] : [px(style.paddingLeft), px(style.paddingRight)]
  return {gap, tail, anchor: anchors.find(([applies]) => applies)[1](), lane: laneOf({rect, boxes, axis, inset})}
}

const hit = (point) =>
  state.drag?.live && targetAt([...instances].flatMap((instance) => instance.snapshot()), state.drag, point)

const openAt = (target) => {
  const {record, index} = target
  const {drag} = state
  const info = measure(record)
  const size = record.axis === "x" ? drag.box.width : drag.box.height
  const plan = gapPlan({boxes: record.boxes, dragId: drag.id, index, size, gap: info.gap, axis: record.axis, anchor: info.anchor})
  openGap(state.open, {list: record.el, axis: record.axis, items: record.boxes, tail: info.tail, plan, step: size + info.gap})
  state.landing = slotRect({slot: plan.slot, lane: info.lane, box: drag.box, axis: record.axis})
  placeSlot(state.slot, state.landing, drag.radius, true)
  drag.item.toggleAttribute("data-slotted", record.key === drag.key)
}

const shut = () => {
  closeGap(state.open, true)
  state.slot && (state.slot.hidden = true)
  state.landing = null
  state.drag?.item.removeAttribute("data-slotted")
}

const show = (target) => {
  markOver(target)
  target ? openAt(target) : shut()
}

const finish = () => {
  clearTimeout(state.settle)
  cancelAnimationFrame(state.raf)
  state.settle = null
  state.drag?.item.removeAttribute("data-dragging")
  state.drag?.item.removeAttribute("data-slotted")
  state.drag = null
  markOver(null)
  closeGap(state.open, false)
  state.slot && (state.slot.hidden = true)
  state.ghost?.root.remove()
  state.ghost = null
  state.landing = null
  document.documentElement.removeAttribute(MARK)
}

const tick = (now) => {
  const {drag} = state
  drag?.live && step(drag, now)
}

const step = (drag, now) => {
  const elapsed = Math.min(Math.max(now - drag.at, 1), 48)
  const goal = ghostOffset(state.point, drag.grab)
  const calm = reduced()
  const next = calm ? goal : {x: approach(drag.pos.x, goal.x, elapsed, 32), y: approach(drag.pos.y, goal.y, elapsed, 32)}
  drag.vx = approach(drag.vx, ((next.x - drag.pos.x) / elapsed) * 1000, elapsed, 90)
  drag.pos = next
  drag.at = now
  placeGhost(state.ghost, next, calm ? 0 : tiltOf(drag.vx))
  const scrolled = autoScroll(state.point)
  const refresh = scrolled || state.dirty
  state.dirty = false
  refresh && show(hit(state.point))
  state.raf = requestAnimationFrame(tick)
}

const sent = (target, payload) => {
  target.record.owner.push(target.record.el, payload)
  landGhost(state.ghost, state.landing)
  setTimeout(() => state.slot && (state.slot.hidden = true), SETTLE_MS)
  state.settle = setTimeout(finish, SERVER_MS)
}

const cancel = () => {
  const {drag} = state
  const home = drag.item.getBoundingClientRect()
  cancelAnimationFrame(state.raf)
  drag.live = false
  markOver(null)
  shut()
  landGhost(state.ghost, home)
  state.settle = setTimeout(finish, SETTLE_MS + 30)
}

const drop = () => {
  const target = hit(state.point)
  const payload = target && dropPayload(state.drag, target)
  cancelAnimationFrame(state.raf)
  target && payload && show(target)
  state.drag.live = false
  markOver(null)
  payload ? sent(target, payload) : cancel()
  setTimeout(() => (state.swallow = false), SWALLOW_MS)
}

const begin = (owner, item, point) => {
  finish()
  const list = item.parentElement
  const box = item.getBoundingClientRect()
  const computed = getComputedStyle(item)
  state.drag = {
    id: item.dataset.id,
    key: list,
    list: list.dataset.list,
    group: owner.cfg(list, "group"),
    index: owner.items(list).indexOf(item),
    item,
    box: {width: box.width, height: box.height},
    grab: {x: point.x - box.left, y: point.y - box.top},
    radius: computed.borderRadius,
    pos: {x: box.left, y: box.top},
    vx: 0,
    at: performance.now(),
    live: true,
  }
  state.point = point
  state.dirty = true
  state.swallow = true
  state.slot ??= makeSlot()
  state.ghost = makeGhost(item, box, state.drag.grab)
  placeGhost(state.ghost, state.drag.pos, 0)
  item.setAttribute("data-dragging", "")
  document.documentElement.setAttribute(MARK, "")
  getSelection()?.removeAllRanges()
  state.raf = requestAnimationFrame(tick)
}

const onClick = (event) => state.swallow && (event.preventDefault(), event.stopPropagation(), (state.swallow = false))

const onSelect = (event) => state.drag?.live && event.preventDefault()

const documentListeners = [
  ["click", onClick, true],
  ["selectstart", onSelect],
]

const attach = () => documentListeners.forEach(([type, fn, opts]) => document.addEventListener(type, fn, opts))

const detach = () => {
  documentListeners.forEach(([type, fn, opts]) => document.removeEventListener(type, fn, opts))
  state.slot?.remove()
  state.slot = null
}

/**
 * `LineaUI.Sortable`: drag and drop of items between and within lists, on pointer events (no library, no browser
 * drag image). The hook element is a list, or holds several lists (a board): a list is an element with
 * `data-list`, its items are the children with `data-id`. Lists with the same `data-group` exchange items;
 * without a group an item moves only inside its list.
 *
 * Config, read from the list and, when it has none, from the hook element: `data-event` (the server event),
 * `data-target` (its `phx-target`; without it the event goes to the hook's LiveView), `data-group`,
 * `data-handle` (a selector inside the item: only it starts a drag), `data-axis` (`"x"` for a row of items,
 * `"y"` by default) and `data-disabled` (the list neither gives nor takes items).
 *
 * A drop pushes `%{"id", "from", "to", "index"}`: the item's `data-id`, the `data-list` it came from and went
 * to, and its index there once it is placed. A drop where the item already was pushes nothing. The hook never
 * moves the DOM, the server's render is the new order; everything it draws is visual:
 *
 *   * the item stays where it is as a quiet placeholder (`data-dragging`; `data-slotted` too while the gap is in
 *     its own list, so the placeholder of the gap stands for it);
 *   * a floating copy of the item (`.linea-drag-ghost`, on the body) follows the pointer, lifted, leaning
 *     towards the movement, and glides into the slot on a drop or back to the item on a cancel;
 *   * the list under the pointer gets `data-over` (it draws nothing by itself), and its items at or after the
 *     insertion index slide out of the way with a `transform` so a gap opens, with a dashed placeholder
 *     (`.linea-drop-slot`) in it. The gap follows the pointer from item to item and closes when the pointer
 *     leaves the lists;
 *   * near the edges of any scrolling box under the pointer (a board, a list), it scrolls.
 *
 * Mouse, pen and finger share this path. A mouse or a pen starts a drag after the pointer moves a few pixels
 * (a plain click on the item, a link or a button inside it still works; the click that ends a drag is
 * swallowed); a finger holds the item for a moment first (moving before that scrolls as usual). Escape cancels.
 * For the keyboard, give the item a button that pushes the same event with the destination.
 */
export default {
  "LineaUI.Sortable": {
    mounted() {
      this.track = null
      this.lifted = false
      this.pressed = null
      this.tracking = [
        ["pointermove", (event) => this.move(event)],
        ["pointerup", (event) => this.up(event)],
        ["pointercancel", (event) => this.track?.id === event.pointerId && this.release()],
        ["keydown", (event) => event.key === "Escape" && this.release()],
      ]
      this.listeners = [
        [this.el, "dragstart", (event) => this.itemAt(event.target) && event.preventDefault()],
        [this.el, "pointerdown", (event) => this.down(event)],
        [this.el, "touchmove", (event) => this.lifted && event.preventDefault(), {passive: false}],
        [this.el, "touchend", (event) => this.unlift(event), {passive: false}],
        [this.el, "touchcancel", (event) => this.unlift(event)],
        [this.el, "contextmenu", (event) => this.track?.type === "touch" && event.preventDefault()],
      ]
      this.listeners.forEach(([target, type, fn, opts]) => target.addEventListener(type, fn, opts))
      instances.add(this)
      instances.size === 1 && attach()
    },

    updated() {
      state.settle ? finish() : state.drag?.item.setAttribute("data-dragging", "")
      state.dirty = true
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

    down(event) {
      this.release()
      this.pressed = elementOf(event.target)
      const item = this.itemAt(event.target)
      const allowed =
        Boolean(item) && event.button === 0 && !this.pressed.closest(EDITABLE) && this.mayDrag(item.parentElement, item)
      allowed && this.arm(event, item)
    },

    arm(event, item) {
      const type = event.pointerType
      const hold = HOLD[type]
      this.track = {
        id: event.pointerId,
        item,
        type,
        origin: pointOf(event),
        point: pointOf(event),
        active: false,
        timer: hold && setTimeout(() => this.raise(), hold),
      }
      this.tracking.forEach(([name, fn]) => document.addEventListener(name, fn))
    },

    raise() {
      const {item, point, type} = this.track
      begin(this, item, point)
      this.track.active = true
      this.lifted = type === "touch"
    },

    move(event) {
      const track = this.track
      const mine = track?.id === event.pointerId
      mine && (track.point = pointOf(event))
      mine && (track.active ? this.follow(track.point) : this.intent(track))
    },

    follow(point) {
      state.point = point
      state.dirty = true
    },

    intent({type, origin, point}) {
      const verdict = moveIntent(type, Math.hypot(point.x - origin.x, point.y - origin.y))
      verdict === "start" ? this.raise() : verdict === "cancel" && this.end()
    },

    up(event) {
      const track = this.track
      const mine = track?.id === event.pointerId
      mine && track.active && drop()
      mine && this.end()
    },

    end() {
      clearTimeout(this.track?.timer)
      this.track && this.tracking.forEach(([name, fn]) => document.removeEventListener(name, fn))
      this.track = null
    },

    release() {
      this.track?.active && state.drag?.live && cancel()
      this.end()
    },

    unlift(event) {
      this.lifted && event.cancelable && event.preventDefault()
      this.lifted = false
    },
  },
}
