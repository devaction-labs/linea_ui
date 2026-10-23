/**
 * LineOne's dark mode and monochrome mode toggles. Dark mode is the `dark` class of `<html>` kept in
 * `localStorage["dark-mode"]` (`"dark"` or `""`), as LineOne's `services/darkMode.js` does; monochrome mode is the
 * `is-monochrome` class of `<body>`, kept the same way in `localStorage["monochrome-mode"]`.
 */
import {DARK_KEY, DARK_VALUE, MONOCHROME_KEY, MONOCHROME_VALUE, modeOn, modeValue} from "../lib/shell_logic.js"

const read = (key) => {
  try {
    return localStorage.getItem(key)
  } catch {
    return null
  }
}

const write = (key, value) => {
  try {
    localStorage.setItem(key, value)
  } catch {}
}

const notify = (hook, payload) => {
  const event = hook.el.dataset.changeEvent
  const js = hook.el.getAttribute("data-on-change")
  event && hook.pushEventTo(hook.el.dataset.target || hook.el, event, payload)
  js && hook.liveSocket.execJS(hook.el, js)
}

const mode = ({key, value, element, className, event, payload}) => ({
  isOn: () => element().classList.contains(className),
  set(on) {
    element().classList.toggle(className, on)
    write(key, modeValue(on, value))
    window.dispatchEvent(new CustomEvent(event, {detail: {currentMode: on ? value : ""}}))
  },
  restore() {
    modeOn(read(key), value) && element().classList.add(className)
  },
  event,
  payload,
})

const dark = mode({
  key: DARK_KEY,
  value: DARK_VALUE,
  element: () => document.documentElement,
  className: "dark",
  event: "change:darkmode",
  payload: (on) => ({dark: on}),
})

const monochrome = mode({
  key: MONOCHROME_KEY,
  value: MONOCHROME_VALUE,
  element: () => document.body,
  className: "is-monochrome",
  event: "change:monochrome",
  payload: (on) => ({monochrome: on}),
})

const toggleHook = (service) => ({
  mounted() {
    service.restore()
    this.sync()
    this.trigger = this.el.type === "checkbox" ? "change" : "click"
    this.onTrigger = () => {
      const on = this.el.type === "checkbox" ? this.el.checked : !service.isOn()
      service.set(on)
      notify(this, service.payload(on))
    }
    this.el.addEventListener(this.trigger, this.onTrigger)
    this.onChange = () => this.sync()
    window.addEventListener(service.event, this.onChange)
  },

  updated() {
    this.sync()
  },

  destroyed() {
    this.el.removeEventListener(this.trigger, this.onTrigger)
    window.removeEventListener(service.event, this.onChange)
  },

  sync() {
    const on = service.isOn()
    this.el.type === "checkbox" ? (this.el.checked = on) : this.el.setAttribute("aria-pressed", String(on))
  },
})

export default {
  "LineaUI.ThemeToggle": toggleHook(dark),
  "LineaUI.MonochromeToggle": toggleHook(monochrome),
}
