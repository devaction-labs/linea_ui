import {LEAVE_MS, colorOf, durationOf, positionOf, resumeAfter, stack, timeLeft, unseen} from "../lib/notice_logic.js"

const FLASH_KEY = "linea_toast"

/**
 * `Toaster`: LineOne's notifications (Toastify's look). A toast comes from the flash (`put_toast`, read from
 * `data-flash` on mount and on every patch, then cleared with `lv:clear-flash`), from a server push
 * (`send_toast`, the `linea:toast` event) or from the page (`show_toast`, the DOM event `linea:toast` on the
 * toaster or on `window`). It slides in from its edge. The toasts of a corner are stacked: the newest in full,
 * the others behind it, smaller, showing as slivers (`data-stack="false"` lays them out one above the other
 * instead). The pointer over any toast of a corner opens its stack and stops the timers of the whole stack;
 * when it leaves they go on with the time they had left. A click on a close button (or on
 * `[data-toast-dismiss]` in a custom template) removes a toast.
 */
const COLLAPSE_MS = 150

export default {
  "LineaUI.Toast": {
    mounted() {
      this.seen = new Set()
      this.toasts = []
      this.seq = 0
      this.expanded = new Set()
      this.collapsing = {}
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
      Object.values(this.collapsing).forEach(clearTimeout)
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
      toast.left = toast.duration
      toast.el = this.render(input, toast)
      this.el.prepend(toast.el)
      const box = toast.el.getBoundingClientRect()
      toast.size = {width: Math.ceil(box.width) + 1, height: Math.ceil(box.height)}
      this.toasts.unshift(toast)
      this.start(toast)
      requestAnimationFrame(() => (toast.el.classList.add("on"), this.layout()))
    },

    render(input, toast) {
      const el = document.createElement("div")
      const template = input.template && document.getElementById(input.template)
      const color = colorOf(input.color)
      el.className = `toastify toastify-${toast.position.x} toastify-${toast.position.y}`
      color === "neutral" || el.classList.add(color)
      el.setAttribute("role", input.color === "error" ? "alert" : "status")
      template ? this.fillTemplate(el, template) : this.fillText(el, input)
      el.querySelectorAll("[data-toast-dismiss]").forEach((button) => button.addEventListener("click", () => this.remove(toast)))
      el.addEventListener("mouseenter", () => this.hover(toast.position.key, true))
      el.addEventListener("mouseleave", () => this.hover(toast.position.key, false))
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
      toast.startedAt = Date.now()
      toast.timer = Number.isFinite(toast.duration) ? setTimeout(() => this.remove(toast), toast.left) : null
    },

    pause(toast) {
      clearTimeout(toast.timer)
      toast.timer = null
      toast.left = Number.isFinite(toast.duration) ? timeLeft(toast.left, Date.now() - toast.startedAt) : toast.left
    },

    resume(toast) {
      toast.left = Number.isFinite(toast.duration) ? resumeAfter(toast.left) : toast.left
      this.start(toast)
    },

    group(key) {
      return this.toasts.filter((toast) => toast.position.key === key)
    },

    hover(key, inside) {
      clearTimeout(this.collapsing[key])
      inside ? this.open(key) : (this.collapsing[key] = setTimeout(() => this.close(key), COLLAPSE_MS))
    },

    open(key) {
      this.expanded.has(key) || (this.expanded.add(key), this.group(key).forEach((toast) => this.pause(toast)), this.layout())
    },

    close(key) {
      this.expanded.has(key) && (this.expanded.delete(key), this.group(key).forEach((toast) => this.resume(toast)), this.layout())
    },

    settle(key) {
      setTimeout(() => this.group(key).some((toast) => toast.el.matches(":hover")) || this.close(key), COLLAPSE_MS)
    },

    remove(toast) {
      const index = this.toasts.indexOf(toast)
      index >= 0 && this.leave(toast, index)
    },

    leave(toast, index) {
      clearTimeout(toast.timer)
      this.toasts.splice(index, 1)
      toast.el.classList.remove("on")
      this.layout()
      this.settle(toast.position.key)
      setTimeout(() => toast.el.remove(), LEAVE_MS)
    },

    layout() {
      const stacked = this.el.dataset.stack !== "false"
      const groups = Object.groupBy(this.toasts.filter((toast) => toast.el.isConnected), (toast) => toast.position.key)
      Object.entries(groups).forEach(([key, group]) => {
        const plan = stack(group.map((toast) => toast.size), !stacked || this.expanded.has(key))
        group.forEach((toast, index) => this.place(toast, plan[index], index))
      })
    },

    place({el, position}, {offset, scale, width, height, hidden}, index) {
      el.style[position.y] = `${offset}px`
      el.style.width = `${width}px`
      el.style.height = `${height}px`
      el.style.transform = `scale(${scale})`
      el.style.transformOrigin = `${position.y} ${position.x}`
      el.style.zIndex = String(10010 - index)
      el.style.opacity = hidden ? "0" : ""
      el.style.pointerEvents = hidden ? "none" : ""
    },
  },
}
