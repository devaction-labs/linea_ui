import {afterOf, begin, dialTarget, shapeOf, step} from "../lib/fab_logic.js"

const canHover = () => window.matchMedia("(hover: hover)").matches
const fromPointer = (handler) => (event) => event.pointerType !== "touch" && handler()

/**
 * `Fab`: the client side of `<.fab retract="auto">`. The button starts expanded, retracts to the bubble after
 * `data-retract-after` ms or when the page scrolls (any scroll container), and expands again while the pointer
 * is over it or it has keyboard focus; once both are gone the timer starts over. Without hover (touch) it
 * starts as the bubble. The shape lives in `data-state`, which the component marks as client-owned.
 */
/**
 * `FabDial`: the client side of `<.fab_dial>`. The button opens and closes the actions (`data-state` on the root,
 * `aria-expanded` on the button; both are client-owned). Escape closes and gives the focus back to the button, the
 * arrows (and Home/End) walk the actions, a click on an action, a click outside or the focus leaving the dial closes it.
 */
const ITEMS = '[role="menuitem"]:not([disabled], [aria-disabled="true"])'

export default {
  "LineaUI.FabDial": {
    mounted() {
      this.listeners = [
        [this.el, "click", (event) => this.onClick(event)],
        [this.el, "keydown", (event) => this.onKey(event)],
        [this.el, "focusout", (event) => this.el.contains(event.relatedTarget) || event.relatedTarget === null || this.set(false)],
        [document, "pointerdown", (event) => this.el.contains(event.target) || this.set(false)],
      ]
      this.listeners.forEach(([target, type, fn]) => target.addEventListener(type, fn))
    },

    destroyed() {
      this.listeners.forEach(([target, type, fn]) => target.removeEventListener(type, fn))
    },

    trigger() {
      return this.el.querySelector("[data-fab-dial-trigger]")
    },

    items() {
      return [...this.el.querySelectorAll(ITEMS)]
    },

    isOpen() {
      return this.el.dataset.state === "open"
    },

    set(open) {
      this.el.dataset.state = open ? "open" : "closed"
      this.trigger().setAttribute("aria-expanded", String(open))
    },

    onClick(event) {
      const trigger = event.target.closest("[data-fab-dial-trigger]")
      trigger ? this.set(!this.isOpen()) : event.target.closest(ITEMS) && this.set(false)
    },

    onKey(event) {
      const items = this.items()
      const index = items.indexOf(document.activeElement)
      event.key === "Escape" && this.isOpen() && (event.stopPropagation(), this.set(false), this.trigger().focus())
      const target = event.key === "Escape" ? null : dialTarget(items.length, index, event.key)
      target !== null && (event.preventDefault(), this.isOpen() || this.set(true), items[target]?.focus())
    },
  },

  "LineaUI.Fab": {
    mounted() {
      this.listeners = [
        [this.el, "pointerenter", fromPointer(() => this.send("enter"))],
        [this.el, "pointerleave", fromPointer(() => this.send("leave"))],
        [this.el, "focusin", (event) => event.target.matches(":focus-visible") && this.send("focus")],
        [this.el, "focusout", () => this.send("blur")],
        [window, "scroll", () => this.send("idle"), {passive: true, capture: true}],
      ]
      this.listeners.forEach(([target, type, fn, opts]) => target.addEventListener(type, fn, opts))
      this.apply(begin(canHover()))
    },

    updated() {
      this.apply({state: this.state, timer: "keep"})
    },

    destroyed() {
      this.listeners.forEach(([target, type, fn, opts]) => target.removeEventListener(type, fn, opts))
      clearTimeout(this.timeout)
    },

    send(event) {
      this.apply(step(this.state, event))
    },

    apply({state, timer}) {
      this.state = state
      this.el.dataset.state = shapeOf(state)
      this.schedule(timer)
    },

    schedule(timer) {
      const actions = {
        clear: () => clearTimeout(this.timeout),
        start: () => {
          clearTimeout(this.timeout)
          this.timeout = setTimeout(() => this.send("idle"), afterOf(this.el.dataset.retractAfter))
        },
        keep: () => {},
      }
      actions[timer]()
    },
  },
}
