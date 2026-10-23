import {LEAVE_MS, colorOf, durationOf, offsets, positionOf, unseen} from "../lib/notice_logic.js"

const FLASH_KEY = "linea_toast"

/**
 * `Toaster`: LineOne's notifications (Toastify's look). A toast comes from the flash (`put_toast`, read from
 * `data-flash` on mount and on every patch, then cleared with `lv:clear-flash`), from a server push
 * (`send_toast`, the `linea:toast` event) or from the page (`show_toast`, the DOM event `linea:toast` on the
 * toaster or on `window`). It slides in from its edge, the toasts of a corner pile up 15px apart, the pointer
 * over a toast stops its timer, and a click on its close button (or on `[data-toast-dismiss]` in a custom
 * template) removes it.
 */
export default {
  "LineaUI.Toast": {
    mounted() {
      this.seen = new Set()
      this.toasts = []
      this.seq = 0
      this.onLocal = (event) => this.show(event.detail ?? {})
      window.addEventListener("linea:toast", this.onLocal)
      this.handleEvent("linea:toast", (toast) => this.show(toast))
      this.flash()
    },

    updated() {
      this.flash()
    },

    destroyed() {
      window.removeEventListener("linea:toast", this.onLocal)
      this.toasts.forEach((toast) => clearTimeout(toast.timer))
      this.toasts.forEach((toast) => toast.el.remove())
    },

    flash() {
      const fresh = unseen(JSON.parse(this.el.dataset.flash || "[]"), this.seen)
      fresh.forEach((toast) => this.seen.add(String(toast.id)))
      fresh.forEach((toast) => this.show(toast))
      fresh.length > 0 && this.pushEvent("lv:clear-flash", {key: FLASH_KEY})
    },

    show(input) {
      const position = positionOf(input.position, this.el.dataset.position)
      const toast = {
        id: String(input.id ?? `linea-toast-${++this.seq}`),
        position,
        duration: durationOf(input.duration, Number(this.el.dataset.duration || 5000)),
        timer: null,
      }
      toast.el = this.render(input, toast)
      this.el.prepend(toast.el)
      this.toasts.unshift(toast)
      this.start(toast)
      requestAnimationFrame(() => (toast.el.classList.add("on"), this.layout()))
    },

    render(input, toast) {
      const el = document.createElement("div")
      const template = input.template && document.getElementById(input.template)
      el.className = `toastify toastify-${toast.position.x} toastify-${toast.position.y}`
      el.dataset.color = colorOf(input.color)
      el.setAttribute("role", input.color === "error" ? "alert" : "status")
      template ? this.fillTemplate(el, template) : this.fillText(el, input)
      el.querySelectorAll("[data-toast-dismiss]").forEach((button) => button.addEventListener("click", () => this.remove(toast)))
      el.addEventListener("mouseenter", () => clearTimeout(toast.timer))
      el.addEventListener("mouseleave", () => this.start(toast))
      return el
    },

    fillText(el, input) {
      const text = document.createElement("span")
      text.textContent = input.message ?? ""
      el.append(text)
      input.close && el.append(this.closeButton())
    },

    fillTemplate(el, template) {
      el.classList.add("html")
      el.append(template.content.firstElementChild.cloneNode(true))
    },

    closeButton() {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "toast-close"
      button.dataset.toastDismiss = ""
      button.setAttribute("aria-label", this.el.dataset.closeLabel ?? "Close")
      button.textContent = "✖"
      return button
    },

    start(toast) {
      clearTimeout(toast.timer)
      toast.timer = Number.isFinite(toast.duration) ? setTimeout(() => this.remove(toast), toast.duration) : null
    },

    remove(toast) {
      const index = this.toasts.indexOf(toast)
      index >= 0 && this.leave(toast, index)
    },

    leave(toast, index) {
      clearTimeout(toast.timer)
      this.toasts.splice(index, 1)
      toast.el.classList.remove("on")
      setTimeout(() => (toast.el.remove(), this.layout()), LEAVE_MS)
    },

    layout() {
      const groups = Object.groupBy(this.toasts.filter((toast) => toast.el.isConnected), (toast) => toast.position.key)
      Object.values(groups).forEach((group) => {
        const at = offsets(group.map((toast) => toast.el.offsetHeight))
        group.forEach((toast, index) => (toast.el.style[toast.position.y] = `${at[index]}px`))
      })
    },
  },
}
