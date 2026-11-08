import {execWithPayload} from "../lib/js_payload.js"
/**
 * LineOne's dark mode and monochrome mode toggles. Dark mode is the `dark` class of `<html>` kept in
 * `localStorage["dark-mode"]` (`"dark"` or `""`), as LineOne's `services/darkMode.js` does; monochrome mode is the
 * `is-monochrome` class of `<body>`, kept the same way in `localStorage["monochrome-mode"]`.
 *
 * The theme switch adds the choice `localStorage["theme"]` (`"light"`, `"dark"` or `"system"`). It keeps `dark-mode` in
 * step with what the choice resolves to, so LineOne's code that only knows `dark-mode` keeps working, and the toggle
 * writes `theme` too. Every change (toggle or switch) is announced on `window` as `change:darkmode`.
 */
import {
  DARK_KEY,
  DARK_VALUE,
  MONOCHROME_KEY,
  MONOCHROME_VALUE,
  THEME_KEY,
  arrowTarget,
  choiceIsDark,
  modeOn,
  modeValue,
  shownChoice,
  themeChoice,
} from "../lib/shell_logic.js"

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
  execWithPayload(hook.liveSocket, hook.el, js, payload)
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

const media = () => window.matchMedia("(prefers-color-scheme: dark)")
const choice = () => themeChoice(read(THEME_KEY), read(DARK_KEY))
const root = () => document.documentElement

/** Puts the `dark` class on `<html>` for a choice, without touching the storage. */
const paint = (value) => root().classList.toggle("dark", choiceIsDark(value, media().matches))

const announce = () =>
  window.dispatchEvent(new CustomEvent("change:darkmode", {detail: {currentMode: root().classList.contains("dark") ? DARK_VALUE : "", theme: choice()}}))

/** Stores a choice and applies it: `theme` is the choice, `dark-mode` what it resolves to. */
const choose = (value) => {
  paint(value)
  write(THEME_KEY, value)
  write(DARK_KEY, modeValue(root().classList.contains("dark"), DARK_VALUE))
  announce()
}

let watching = false

/** While the choice is "system", follows the browser's color scheme live (one listener for the whole page). */
const watchSystem = () => {
  if (watching) return
  watching = true
  media().addEventListener("change", () => {
    if (choice() !== "system") return
    paint("system")
    write(DARK_KEY, modeValue(root().classList.contains("dark"), DARK_VALUE))
    announce()
  })
}

const dark = {
  isOn: () => root().classList.contains("dark"),
  set: (on) => choose(on ? "dark" : "light"),
  restore() {
    paint(choice())
    watchSystem()
  },
  event: "change:darkmode",
  payload: (on) => ({dark: on}),
}

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

const OPTIONS = '[role="radio"]'

/**
 * The light / dark / system choice. The element is a `radiogroup` of buttons (`data-value` says which is chosen, the
 * CSS slides the thumb) or a single `switch` button (`aria-checked` is dark mode). Without `data-system` a stored
 * "system" is shown as the light or dark it resolves to.
 */
const themeSwitch = {
  mounted() {
    dark.restore()
    this.isSwitch = this.el.getAttribute("role") === "switch"
    this.sync()
    this.onClick = (event) => {
      if (this.isSwitch) return choose(root().classList.contains("dark") ? "light" : "dark")
      const option = event.target.closest(OPTIONS)
      option && choose(option.dataset.themeValue)
    }
    this.onKey = (event) => {
      const options = [...this.el.querySelectorAll(OPTIONS)]
      const target = arrowTarget(event.key, options.indexOf(document.activeElement), options.length)
      if (target === null || this.isSwitch) return
      event.preventDefault()
      options[target].focus()
      choose(options[target].dataset.themeValue)
    }
    this.onChange = () => this.sync()
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    window.addEventListener("change:darkmode", this.onChange)
  },

  updated() {
    this.sync()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    window.removeEventListener("change:darkmode", this.onChange)
  },

  sync() {
    if (this.isSwitch) return this.el.setAttribute("aria-checked", String(root().classList.contains("dark")))
    const value = shownChoice(choice(), this.el.dataset.system !== "false", media().matches)
    this.el.dataset.value = value
    this.el.querySelectorAll(OPTIONS).forEach((option) => {
      const on = option.dataset.themeValue === value
      option.setAttribute("aria-checked", String(on))
      option.tabIndex = on ? 0 : -1
    })
  },
}

export default {
  "LineaUI.ThemeToggle": toggleHook(dark),
  "LineaUI.ThemeSwitch": themeSwitch,
  "LineaUI.MonochromeToggle": toggleHook(monochrome),
}
