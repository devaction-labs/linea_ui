import {afterOf, begin, shapeOf, step} from "../lib/fab_logic.js"

const canHover = () => window.matchMedia("(hover: hover)").matches
const fromPointer = (handler) => (event) => event.pointerType !== "touch" && handler()

/**
 * `Fab`: the client side of `<.fab retract="auto">`. The button starts expanded, retracts to the bubble after
 * `data-retract-after` ms or when the page scrolls (any scroll container), and expands again while the pointer
 * is over it or it has keyboard focus; once both are gone the timer starts over. Without hover (touch) it
 * starts as the bubble. The shape lives in `data-state`, which the component marks as client-owned.
 */
export default {
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
