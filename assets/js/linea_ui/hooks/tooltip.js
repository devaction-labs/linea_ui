import {runKey} from "../lib/keys.js"
import {cursorRect, placeTooltip} from "../lib/tip_place.js"
import {FOCUSABLE, withDescription} from "../lib/tooltip_logic.js"

/**
 * LineOne's tippy.js tooltip without tippy: shows the hint on hover and focus, on click or on focus
 * only, after `data-delay`, with the shift-away animation lasting `data-duration`; places it on any of
 * the twelve placements (flipping and staying on the screen), optionally following the cursor; keeps an
 * interactive hint (HTML content) open while the pointer is on it. It closes on Esc, on a click of the
 * trigger (hover) or outside it (click), answers `LineaUI.open/close/toggle` and `data-open` from the
 * server (the server wins when it changes it), and runs `data-on-open` / `data-on-close`.
 */

const HIDE_GRACE = 100

const TRIGGERS = {
  hover: {pointerenter: "enter", pointerleave: "leave", focusin: "focusShow", focusout: "hide", pointerdown: "pressHide"},
  click: {click: "toggle"},
  focus: {focusin: "show", focusout: "hide"},
  manual: {},
}

const Tooltip = {
  mounted() {
    this.open = false
    this.timers = {}
    this.point = {x: 0, y: 0}
    this.read()
    this.serverOpen = this.config.open
    this.listen()
    this.describe()
    this.serverOpen && this.show()
  },

  updated() {
    this.read()
    this.describe()
    this.config.open !== this.serverOpen && ((this.serverOpen = this.config.open), this.config.open ? this.reveal() : this.conceal())
    this.open && this.place()
  },

  destroyed() {
    Object.values(this.timers).forEach(clearTimeout)
    this.unlisten.forEach((off) => off())
  },

  read() {
    const data = this.el.dataset
    this.config = {
      placement: data.placement || "top",
      trigger: TRIGGERS[data.trigger] ? data.trigger : "hover",
      delay: Number(data.delay || 0),
      duration: Number(data.duration || 300),
      follow: data.followCursor || "",
      interactive: data.interactive === "true",
      open: data.open === "true",
    }
  },

  tip() {
    return document.getElementById(`${this.el.id}-tip`)
  },

  box() {
    return this.tip()?.querySelector(".tippy-box")
  },

  on(target, event, handler, options) {
    target.addEventListener(event, handler, options)
    this.unlisten.push(() => target.removeEventListener(event, handler, options))
  },

  listen() {
    this.unlisten = []
    const actions = {
      enter: () => (this.cancel("hide"), this.show()),
      leave: () => ((this.fromPointer = false), this.config.interactive ? this.later("hide", HIDE_GRACE, () => this.conceal()) : this.hide()),
      focusShow: () => this.fromPointer || this.show(),
      pressHide: (event) => ((this.fromPointer = true), this.tip()?.contains(event.target) || this.hide()),
      show: () => this.show(),
      hide: () => this.hide(),
      toggle: (event) => this.tip()?.contains(event.target) || (this.open ? this.hide() : this.show()),
    }
    Object.keys({...TRIGGERS.hover, ...TRIGGERS.click}).forEach((event) =>
      this.on(this.el, event, (e) => {
        const action = TRIGGERS[this.config.trigger][event]
        action && actions[action](e)
      }),
    )
    this.on(this.el, "pointermove", (event) => this.follow(event))
    this.on(this.el, "linea:open", () => this.reveal())
    this.on(this.el, "linea:close", () => this.conceal())
    this.on(this.el, "linea:toggle", () => (this.open ? this.conceal() : this.reveal()))
    ;["open", "close", "toggle"].forEach((action) =>
      this.on(window, `phx:linea:${action}`, (event) => this.el.matches(event.detail?.id || "#") && this.el.dispatchEvent(new CustomEvent(`linea:${action}`))),
    )
    this.on(document, "keydown", (event) => this.open && runKey({Escape: () => (this.conceal(), false)}, event))
    this.on(document, "pointerdown", (event) => this.open && !this.el.contains(event.target) && this.conceal())
    this.on(window, "scroll", () => this.open && this.place(), {capture: true, passive: true})
    this.on(window, "resize", () => this.open && this.place())
  },

  describe() {
    const tip = this.tip()
    const control = [...this.el.querySelectorAll(FOCUSABLE)].find((node) => !tip?.contains(node))
    control?.setAttribute("aria-describedby", withDescription(control.getAttribute("aria-describedby"), `${this.el.id}-tip`))
  },

  later(name, ms, fn) {
    this.cancel(name)
    this.timers[name] = setTimeout(fn, ms)
  },

  cancel(name) {
    clearTimeout(this.timers[name])
  },

  show() {
    this.cancel("hide")
    this.later("show", this.config.delay, () => this.reveal())
  },

  hide() {
    this.cancel("show")
    this.later("hide", this.config.delay, () => this.conceal())
  },

  follow(event) {
    this.point = {x: event.clientX, y: event.clientY}
    const moving = this.config.follow && this.config.follow !== "initial"
    moving && this.open && this.place()
  },

  reveal() {
    const tip = this.tip()
    const box = this.box()
    const already = this.open
    this.cancel("show")
    this.cancel("hide")
    this.cancel("unmount")
    tip.hidden = false
    tip.style.pointerEvents = this.config.interactive ? "" : "none"
    box.style.transitionDuration = `${this.config.duration}ms`
    this.open = true
    this.place()
    requestAnimationFrame(() => requestAnimationFrame(() => this.open && (box.dataset.state = "visible")))
    already || this.run("onOpen")
  },

  conceal() {
    const box = this.box()
    const was = this.open
    this.cancel("show")
    this.cancel("hide")
    this.open = false
    box && (box.dataset.state = "hidden")
    this.later("unmount", this.config.duration, () => this.open || (this.tip().hidden = true))
    was && this.run("onClose")
  },

  run(name) {
    const js = this.el.dataset[name]
    js && js !== "[]" && this.liveSocket.execJS(this.el, js)
  },

  place() {
    const tip = this.tip()
    const box = this.box()
    const arrow = box.querySelector(".tippy-svg-arrow")
    const trigger = this.el.getBoundingClientRect()
    const ref = this.config.follow ? cursorRect(this.config.follow, trigger, this.point) : trigger
    const placed = placeTooltip({
      placement: this.config.placement,
      ref,
      box: {width: box.offsetWidth, height: box.offsetHeight},
      viewport: {width: document.documentElement.clientWidth, height: window.innerHeight},
    })
    tip.style.transform = `translate(${Math.round(placed.x)}px, ${Math.round(placed.y)}px)`
    box.dataset.placement = placed.placement
    const vertical = /^(top|bottom)/.test(placed.placement)
    arrow && (arrow.style.left = vertical ? `${placed.arrow}px` : "")
    arrow && (arrow.style.top = vertical ? "" : `${placed.arrow}px`)
  },
}

export default {"LineaUI.Tooltip": Tooltip}
