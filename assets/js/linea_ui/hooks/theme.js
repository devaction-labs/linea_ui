import {execWithPayload} from "../lib/js_payload.js"
/**
 * LineOne's dark mode and monochrome mode toggles. Dark mode is the `dark` class of `<html>` kept in
 * `localStorage["dark-mode"]` (`"dark"` or `""`), as LineOne's `services/darkMode.js` does; monochrome mode is the
 * `is-monochrome` class of `<body>`, kept the same way in `localStorage["monochrome-mode"]`.
 */
import {DARK_KEY, DARK_VALUE, MONOCHROME_KEY, MONOCHROME_VALUE, THEME_KEY, modeOn, modeValue, themeChoice, themeDark} from "../lib/shell_logic.js"

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

/**
 * The theme switch (`theme_switch/1`): light, dark or system. The choice goes to `localStorage["theme"]`; the dark
 * class and the dark mode key follow it, so `theme_toggle/1` and `theme_script/1` stay in step. With `system` the page
 * follows `prefers-color-scheme`, live. Every switch on the page shows the same choice.
 */
const media = () => window.matchMedia?.("(prefers-color-scheme: dark)")

const applyTheme = (choice) => {
  const on = themeDark(choice, media()?.matches)
  write(THEME_KEY, choice)
  dark.set(on)
  window.dispatchEvent(new CustomEvent("change:theme", {detail: {theme: choice, dark: on}}))
}

const themeSwitch = {
  mounted() {
    this.choice = themeChoice(read(THEME_KEY), read(DARK_KEY))
    this.sync()

    this.onClick = (e) => {
      const button = e.target.closest("[data-theme-value]")
      const choice = this.el.dataset.variant === "switch" ? (this.choice === "dark" ? "light" : "dark") : button?.dataset.themeValue
      if (!choice) return
      applyTheme(choice)
      notify(this, {theme: choice, dark: themeDark(choice, media()?.matches)})
    }

    this.onKey = (e) => {
      if (this.el.dataset.variant === "switch" || !["ArrowLeft", "ArrowRight"].includes(e.key)) return
      const buttons = [...this.el.querySelectorAll("[data-theme-value]")]
      const i = buttons.findIndex((b) => b.dataset.themeValue === this.choice)
      const next = buttons[(i + (e.key === "ArrowRight" ? 1 : buttons.length - 1)) % buttons.length]
      next.focus()
      next.click()
    }

    this.onTheme = (e) => {
      this.choice = e.detail.theme
      this.sync()
    }
    // a theme_toggle elsewhere on the page picks light or dark
    this.onDark = (e) => {
      const choice = e.detail.currentMode ? "dark" : "light"
      if (themeDark(this.choice, media()?.matches) === Boolean(e.detail.currentMode)) return
      this.choice = choice
      write(THEME_KEY, choice)
      this.sync()
    }
    this.onSystem = () => this.choice === "system" && dark.set(themeDark("system", media()?.matches))

    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    window.addEventListener("change:theme", this.onTheme)
    window.addEventListener("change:darkmode", this.onDark)
    media()?.addEventListener?.("change", this.onSystem)
  },

  updated() {
    this.sync()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    window.removeEventListener("change:theme", this.onTheme)
    window.removeEventListener("change:darkmode", this.onDark)
    media()?.removeEventListener?.("change", this.onSystem)
  },

  sync() {
    this.el.dataset.value = this.choice
    if (this.el.dataset.variant === "switch") {
      this.el.setAttribute("aria-checked", String(themeDark(this.choice, media()?.matches)))
      return
    }
    this.el.querySelectorAll("[data-theme-value]").forEach((b) => {
      const on = b.dataset.themeValue === this.choice
      b.setAttribute("aria-checked", String(on))
      b.tabIndex = on ? 0 : -1
    })
  },
}

export default {
  "LineaUI.ThemeSwitch": themeSwitch,
  "LineaUI.ThemeToggle": toggleHook(dark),
  "LineaUI.MonochromeToggle": toggleHook(monochrome),
}
