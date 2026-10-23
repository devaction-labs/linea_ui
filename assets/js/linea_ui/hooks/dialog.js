import {COMMANDS, commandOf} from "../lib/anchor_logic.js"
import {runKey, tabExit} from "../lib/keys.js"
import {isTop, lockStyle, stackWith, stackWithout} from "../lib/overlay_logic.js"
import {FOCUSABLE} from "../lib/tooltip_logic.js"

let stack = []
let saved = null

const matches = (el, selector) => {
  try {
    return typeof selector === "string" && el.matches(selector)
  } catch {
    return false
  }
}

/**
 * Wires an overlay to LineaUI's protocol: the DOM events `linea:open|close|toggle` on its element (what
 * `LineaUI.open/close/toggle(id)` dispatch) and the server pushes `linea:open|close|toggle` whose `id` is a
 * selector matching it (what `LineaUI.open(socket, id)` sends). Returns the function that removes them.
 *
 * @param {object} hook the LiveView hook, `hook.el` is the overlay
 * @param {{open: Function, close: Function, toggle: Function}} actions
 */
export const listen = (hook, actions) => {
  const run = (type) => actions[commandOf(type)]?.()
  const local = (event) => (event.stopPropagation(), run(event.type))
  COMMANDS.forEach((name) => hook.el.addEventListener(`linea:${name}`, local))
  COMMANDS.forEach((name) => hook.handleEvent(`linea:${name}`, ({id}) => matches(hook.el, id) && run(name)))
  return () => COMMANDS.forEach((name) => hook.el.removeEventListener(`linea:${name}`, local))
}

/** Runs the `%JS{}` an overlay keeps in a `data-*` attribute (`on_open`, `on_close`), when it has one. */
export const runJS = (hook, encoded) => encoded && encoded !== "[]" && hook.liveSocket.execJS(hook.el, encoded)

const lock = () => {
  const html = document.documentElement
  saved = {overflow: html.style.overflow, paddingRight: html.style.paddingRight}
  Object.assign(html.style, lockStyle(window.innerWidth - html.clientWidth))
}

const unlock = () => {
  saved && Object.assign(document.documentElement.style, saved)
  saved = null
}

const PARTS = ":scope > .drawer-overlay, :scope > .drawer-content"

const PAINT = {
  modal: (el, state) => {
    el.classList.toggle("show", state !== "closed")
    el.classList.toggle("animate:leave", state === "leaving")
  },
  drawer: (el, state) =>
    el.querySelectorAll(PARTS).forEach((part) => {
      part.classList.toggle("hidden", state === "closed")
      part.classList.toggle("animate:leave", state === "leaving")
    }),
}

const reducedMotion = () => window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false

/**
 * `Modal` and `Drawer`. The element carries `data-state` (`closed`, `open`, `leaving`) and LineOne's own classes for
 * it (`show` and `animate:leave` on a modal, `hidden` and `animate:leave` on the parts of a drawer), so LineOne's CSS
 * runs the enter and leave animations. Overlays stack: Esc closes the one on top, a click on the backdrop
 * closes its own (neither with `data-prevent-close="true"`). A modal locks the scroll of the page as LineOne
 * does, focus moves in when it opens, Tab stays inside, and focus returns to what had it on close. The server's
 * `open` (`data-open`) wins when it changes; a close in the browser runs `data-on-close`, so the server can
 * keep its assign in sync.
 */
export default {
  /**
   * `Collapse` (and every accordion item): a `<details>` whose `open` belongs to the browser, with the server's
   * `open` (`data-open`) winning when it changes. Inside an exclusive accordion (`data-accordion` with
   * `data-exclusive="true"`) it takes the accordion's id as its `name`, so opening one closes the others. It
   * answers LineaUI's protocol and runs `data-on-open` / `data-on-close` on every toggle.
   */
  "LineaUI.Collapse": {
    mounted() {
      this.serverOpen = this.el.dataset.open
      this.group()
      this.unlisten = listen(this, {
        open: () => (this.el.open = true),
        close: () => (this.el.open = false),
        toggle: () => (this.el.open = !this.el.open),
      })
      this.onToggle = () => runJS(this, this.el.open ? this.el.dataset.onOpen : this.el.dataset.onClose)
      this.el.addEventListener("toggle", this.onToggle)
    },

    updated() {
      this.group()
      const now = this.el.dataset.open
      const changed = now !== this.serverOpen
      this.serverOpen = now
      changed && (this.el.open = now === "true")
    },

    destroyed() {
      this.unlisten()
      this.el.removeEventListener("toggle", this.onToggle)
    },

    group() {
      const accordion = this.el.parentElement?.closest("[data-accordion]")
      const exclusive = accordion?.dataset.exclusive === "true"
      exclusive ? this.el.setAttribute("name", accordion.id) : this.el.removeAttribute("name")
    },
  },

  "LineaUI.Dialog": {
    mounted() {
      this.serverOpen = this.el.dataset.open
      this.unlisten = listen(this, {open: () => this.open(), close: () => this.close(), toggle: () => this.toggle()})
      this.onKey = (event) => runKey({Escape: () => this.dismiss(event)}, event)
      this.onTab = (event) => event.key === "Tab" && this.isOpen() && this.trap(event)
      this.onBackdrop = (event) => event.target.closest("[data-backdrop]") && this.dismiss(event)
      document.addEventListener("keydown", this.onKey)
      this.el.addEventListener("keydown", this.onTab)
      this.el.addEventListener("click", this.onBackdrop)
      this.serverOpen === "true" && this.open()
    },

    updated() {
      const now = this.el.dataset.open
      const changed = now !== this.serverOpen
      this.serverOpen = now
      changed && (now === "true" ? this.open() : this.close())
    },

    destroyed() {
      this.unlisten()
      document.removeEventListener("keydown", this.onKey)
      clearTimeout(this.leaving)
      const wasOpen = stack.includes(this.el.id)
      stack = stackWithout(stack, this.el.id)
      wasOpen && stack.length === 0 && unlock()
    },

    isOpen() {
      return this.el.dataset.state === "open"
    },

    locks() {
      return this.el.dataset.lock === "true"
    },

    panel() {
      return this.el.querySelector("[data-panel]") ?? this.el
    },

    toggle() {
      this.isOpen() ? this.close() : this.open()
    },

    dismiss(event) {
      const mine = this.isOpen() && isTop(stack, this.el.id) && this.el.dataset.preventClose !== "true"
      mine && (event.stopPropagation(), this.close())
      return mine
    },

    open() {
      const opens = !this.isOpen()
      opens && this.show()
    },

    show() {
      clearTimeout(this.leaving)
      this.returnTo = document.activeElement
      this.locks() && !stack.some((id) => document.getElementById(id)?.dataset.lock === "true") && lock()
      stack = stackWith(stack, this.el.id)
      this.paint("open")
      this.el.setAttribute("aria-hidden", "false")
      const panel = this.panel()
      const target = panel.querySelector("[autofocus]") ?? panel
      requestAnimationFrame(() => target.focus({preventScroll: true}))
      runJS(this, this.el.dataset.onOpen)
    },

    close() {
      const closes = this.isOpen()
      closes && this.hide()
    },

    hide() {
      stack = stackWithout(stack, this.el.id)
      this.paint("leaving")
      this.el.setAttribute("aria-hidden", "true")
      const wait = reducedMotion() ? 0 : Number(this.el.dataset.leaveMs ?? 300)
      this.leaving = setTimeout(() => this.finish(), wait)
      this.returnTo?.isConnected && this.returnTo.focus({preventScroll: true})
      runJS(this, this.el.dataset.onClose)
    },

    finish() {
      this.paint("closed")
      const anyLocked = stack.some((id) => document.getElementById(id)?.dataset.lock === "true")
      this.locks() && !anyLocked && unlock()
    },

    paint(state) {
      this.el.dataset.state = state
      PAINT[this.el.dataset.kind ?? "modal"](this.el, state)
    },

    trap(event) {
      const items = [...this.panel().querySelectorAll(FOCUSABLE)].filter((item) => item.offsetParent !== null)
      const exit = tabExit({shift: event.shiftKey, active: document.activeElement, first: items[0], last: items.at(-1)})
      const wraps = {back: () => items.at(-1)?.focus(), forward: () => items[0]?.focus()}
      const handler = wraps[exit] ?? (items.length === 0 ? () => true : null)
      handler && (event.preventDefault(), handler())
    },
  },
}
