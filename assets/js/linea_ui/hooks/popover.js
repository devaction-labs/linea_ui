import {anchorBox, referenceHidden} from "../lib/anchor_logic.js"
import {runKey} from "../lib/keys.js"
import {screenSize} from "../lib/placement.js"
import {FOCUSABLE} from "../lib/tooltip_logic.js"
import {clippingAncestors, drop, lift} from "../lib/top_layer.js"
import {listen, runJS} from "./dialog.js"

const list = (value) => (value ? value.split(",").map((side) => side.trim()).filter(Boolean) : [])

/**
 * What a dropdown and a popover share: a trigger (`[data-trigger]`, the first control inside it gets the ARIA
 * state) and a panel (`[data-panel]`, LineOne's `popper-root`, shown with its `show` class and `data-popper-placement` as Popper sets them) placed next to it from `data-placement`,
 * `data-offset`, `data-padding` and `data-fallbacks`, the way LineOne's Popper setups do.
 *
 * The panel floats free of the page's boxes: it is `position: fixed` with `popover="manual"`, and opening it
 * puts it in the browser's top layer (`showPopover()`), so a table's horizontal scroll area, a drawer's
 * scrolling body, an ancestor's `z-index` or `transform` neither cut it off nor cover it. It stays where
 * LiveView rendered it in the DOM, so patches, `phx-*` events, focus and keys work as before. Its coordinates
 * come from the trigger's rectangle on the screen and follow any scroll (of the window or of a box around the
 * trigger), the window's resize and the panel's own (a `ResizeObserver`, for content that settles or changes); when the trigger scrolls out of sight the panel closes, as Popper's `hide` modifier
 * hides tippy's. Without the Popover API it is a fixed box on `--linea-z-popover`.
 *
 * Opening and closing follow LineaUI's protocol; a click outside closes, as in LineOne, and Esc closes and
 * gives the focus back. `data-on-open` and `data-on-close` run on every open and close, whoever caused it.
 */
export const Floating = {
  setupFloating() {
    this.serverOpen = this.el.dataset.open
    this.unlisten = listen(this, {open: () => this.open(), close: () => this.close(false), toggle: () => this.toggle()})
    this.onOutside = (event) => this.isOpen() && !this.el.contains(event.target) && this.close(false)
    this.onEscape = (event) => runKey({Escape: () => this.isOpen() && (event.stopPropagation(), this.close(true))}, event)
    this.reflow = () => this.isOpen() && !this.frame && (this.frame = requestAnimationFrame(() => this.follow()))
    this.resizer = typeof ResizeObserver === "function" ? new ResizeObserver(this.reflow) : null
    document.addEventListener("click", this.onOutside)
    this.el.addEventListener("keydown", this.onEscape)
    this.announce()
    this.serverOpen === "true" && this.open()
  },

  updatedFloating() {
    this.announce()
    this.isOpen() && this.place()
    const now = this.el.dataset.open
    const changed = now !== this.serverOpen
    this.serverOpen = now
    changed && (now === "true" ? this.open() : this.close(false))
  },

  destroyedFloating() {
    this.unlisten()
    document.removeEventListener("click", this.onOutside)
    this.unfollow()
    this.resizer?.disconnect()
  },

  trigger() {
    return this.el.querySelector("[data-trigger]")
  },

  control() {
    const trigger = this.trigger()
    return trigger.querySelector("button, a[href], input, [tabindex]") ?? trigger
  },

  panel() {
    return this.el.querySelector("[data-panel]")
  },

  isOpen() {
    return this.panel().classList.contains("show")
  },

  announce() {
    const control = this.control()
    control === this.trigger() && !control.hasAttribute("tabindex") && (control.tabIndex = 0, control.setAttribute("role", "button"))
    control.setAttribute("aria-haspopup", this.el.dataset.popup ?? "dialog")
    control.setAttribute("aria-controls", this.panel().id)
    control.setAttribute("aria-expanded", String(this.isOpen()))
    control.classList.toggle("is-active", this.isOpen())
  },

  toggle() {
    this.isOpen() ? this.close(true) : this.open()
  },

  open() {
    const opens = !this.isOpen()
    opens && this.reveal()
    return opens
  },

  reveal() {
    const panel = this.panel()
    lift(panel)
    this.clips = clippingAncestors(this.el, (node) => getComputedStyle(node))
    this.place()
    panel.classList.add("show")
    panel.setAttribute("aria-hidden", "false")
    this.announce()
    window.addEventListener("resize", this.reflow)
    window.addEventListener("scroll", this.reflow, {capture: true, passive: true})
    this.resizer?.observe(panel)
    runJS(this, this.el.dataset.onOpen)
  },

  follow() {
    this.frame = null
    const hidden = this.isOpen() && referenceHidden(this.control().getBoundingClientRect(), this.clipRects(), screenSize())
    hidden ? this.close(false) : this.isOpen() && this.place()
  },

  clipRects() {
    return (this.clips ?? []).filter((node) => node.isConnected).map((node) => node.getBoundingClientRect())
  },

  unfollow() {
    cancelAnimationFrame(this.frame)
    this.frame = null
    this.resizer?.disconnect()
    window.removeEventListener("resize", this.reflow)
    window.removeEventListener("scroll", this.reflow, {capture: true, passive: true})
  },

  close(returnFocus) {
    const closes = this.isOpen()
    closes && this.conceal(returnFocus)
    return closes
  },

  conceal(returnFocus) {
    const panel = this.panel()
    const hadFocus = panel.contains(document.activeElement)
    panel.classList.remove("show")
    panel.setAttribute("aria-hidden", "true")
    drop(panel)
    this.announce()
    this.unfollow()
    ;(returnFocus || hadFocus) && this.control().focus({preventScroll: true})
    runJS(this, this.el.dataset.onClose)
  },

  place() {
    const panel = this.panel()
    const arrow = panel.querySelector("[data-popper-arrow]")
    const box = anchorBox({
      placement: this.el.dataset.placement,
      anchor: this.control().getBoundingClientRect(),
      panel: {width: panel.offsetWidth, height: panel.offsetHeight},
      screen: screenSize(),
      offset: Number(this.el.dataset.offset ?? 4),
      padding: Number(this.el.dataset.padding ?? 0),
      fallbacks: list(this.el.dataset.fallbacks),
    })
    panel.style.left = `${box.left}px`
    panel.style.top = `${box.top}px`
    const drawn = panel.getBoundingClientRect()
    panel.style.left = `${2 * box.left - drawn.left}px`
    panel.style.top = `${2 * box.top - drawn.top}px`
    panel.dataset.popperPlacement = box.align === "center" ? box.side : `${box.side}-${box.align}`
    const vertical = box.side === "top" || box.side === "bottom"
    arrow && Object.assign(arrow.style, {position: "absolute"}, vertical ? {left: `${box.arrow}px`, top: ""} : {top: `${box.arrow}px`, left: ""})
  },

  focusInside() {
    const panel = this.panel()
    const target = panel.querySelector("[autofocus]") ?? panel.querySelector(FOCUSABLE)
    target?.focus({preventScroll: true})
  },
}

/**
 * `Popover`: a card next to its trigger. `data-trigger-on="click"` toggles it on click (and on Enter or Space
 * on a trigger that is not a button); `hover` opens it while the pointer is over the trigger or the card, and
 * on focus. Opened with the keyboard, the focus goes to the first control inside.
 */
export default {
  "LineaUI.Popover": {
    ...Floating,

    mounted() {
      this.setupFloating()
      const hover = this.el.dataset.triggerOn === "hover"
      const trigger = this.trigger()
      this.onClick = (event) => (this.toggle(), event.detail === 0 && this.isOpen() && this.focusInside())
      this.onKey = (event) => {
        const own = () => (event.target === this.control() && this.control() === trigger ? this.onClick({detail: 0}) : false)
        runKey({Enter: own, " ": own}, event)
      }
      this.onEnter = () => this.open()
      this.onLeave = () => this.close(false)
      this.onFocusOut = (event) => this.el.contains(event.relatedTarget) || this.close(false)
      hover
        ? (this.el.addEventListener("mouseenter", this.onEnter),
          this.el.addEventListener("mouseleave", this.onLeave),
          this.el.addEventListener("focusin", this.onEnter),
          this.el.addEventListener("focusout", this.onFocusOut))
        : (trigger.addEventListener("click", this.onClick), trigger.addEventListener("keydown", this.onKey))
    },

    updated() {
      this.updatedFloating()
    },

    destroyed() {
      this.destroyedFloating()
    },
  },
}
