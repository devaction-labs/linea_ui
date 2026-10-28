import {glyphElement, iconSet} from "../lib/glyphs.js"
import {
  LEAVE_MS,
  actionPayload,
  auraOf,
  closeFor,
  colorFor,
  durationFor,
  encodedJS,
  failedOf,
  invertFor,
  isRich,
  kindOf,
  mergeToast,
  positionOf,
  progressKind,
  progressOf,
  resumeAfter,
  stack,
  stepsOf,
  surfaceFor,
  timeLeft,
  timerFor,
  unseen,
  withKindColor,
} from "../lib/notice_logic.js"

const FLASH_KEY = "linea_toast"

/** The icon a plain note draws at its left, by color; the neutral, light and dark notes have none. */
const NOTE_ICONS = {primary: "info", secondary: "info", info: "info", success: "success", warning: "warning", error: "error"}

/**
 * `Toaster`: LineOne's notifications (Toastify's look). A toast comes from the flash (`put_toast`, read from
 * `data-flash` on mount and on every patch, then cleared with `lv:clear-flash`), from a server push
 * (`send_toast`, the `linea:toast` event) or from the page (`show_toast`, the DOM event `linea:toast` on the
 * toaster or on `window`). It slides in from its edge. The toasts of a corner are stacked: the newest in full,
 * the others behind it, smaller, showing as slivers (`data-stack="false"` lays them out one above the other
 * instead). The pointer over any toast of a corner opens its stack and stops the timers of the whole stack;
 * when it leaves they go on with the time they had left. A click on a close button (or on
 * `[data-toast-dismiss]` in a custom template) removes a toast.
 *
 * A toast with a `kind`, a `description` or `actions` is drawn with the kind's icon (cloned from the toaster's
 * `<template data-toast-icon>`), a title, a second line and a row of buttons. A toast whose `id` is already on the
 * screen replaces it in place (`send_toast` again, the loading-then-answer pattern); `linea:toast-update` changes
 * only the keys it carries, `linea:toast-dismiss` removes one toast (`id`) or all (`all`), from the server or as a
 * DOM event. An action pushes its `event` (to its `target` when given) with `value` and `toast_id`, runs its `js`,
 * or follows its `href`, then closes the toast unless `dismiss` is false.
 *
 * A rich toast is a surface card with a tile for the icon (tinted by the color or kind) and its actions on the right.
 * `aura` (with `aura_size`, `aura_color`) runs a ring of light around the card. A numeric `value` makes a progress
 * toast: a fill grows behind it (a 3px bar at the bottom with `bar`), a spinner turns until 100, then it becomes a
 * success and leaves by itself; `linea:toast-update` with a new `value` moves it, and a `kind` of `error` on a toast that
 * had a `value` turns it into a failure.
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
      this.onLocalDismiss = (event) => this.dismiss(event.detail ?? {})
      this.onLocalUpdate = (event) => this.change(event.detail ?? {})
      window.addEventListener("linea:toast", this.onLocal)
      window.addEventListener("linea:toast-dismiss", this.onLocalDismiss)
      window.addEventListener("linea:toast-update", this.onLocalUpdate)
      this.handleEvent("linea:toast", (toast) => this.show(toast))
      this.handleEvent("linea:toast-dismiss", (payload) => this.dismiss(payload))
      this.handleEvent("linea:toast-update", (payload) => this.change(payload))
      this.flash()
    },

    updated() {
      this.flash()
    },

    destroyed() {
      window.removeEventListener("linea:toast", this.onLocal)
      window.removeEventListener("linea:toast-dismiss", this.onLocalDismiss)
      window.removeEventListener("linea:toast-update", this.onLocalUpdate)
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

    find(id) {
      return this.toasts.find((toast) => toast.id === String(id))
    },

    durationOf(input) {
      return durationFor(input, Number(this.el.dataset.duration || 5000), this.el.dataset.persistErrors === "true")
    },

    show(input) {
      const existing = input.id !== undefined && input.id !== null && this.find(input.id)
      existing ? this.replace(existing, input) : this.add(input)
    },

    change(changes) {
      const toast = this.find(changes.id)
      toast && this.replace(toast, mergeToast(toast.input, withKindColor(changes)))
    },

    dismiss({id, all}) {
      const targets = all ? [...this.toasts] : [this.find(id)].filter(Boolean)
      targets.forEach((toast) => this.remove(toast))
    },

    replace(toast, input) {
      toast.input = input
      toast.duration = this.durationOf(input)
      toast.left = toast.duration
      const el = this.render(input, toast)
      el.style.cssText = toast.el.style.cssText
      el.style.width = ""
      el.style.height = ""
      el.classList.add("on")
      toast.el.replaceWith(el)
      toast.el = el
      const box = el.getBoundingClientRect()
      toast.size = {width: Math.ceil(box.width) + 1, height: Math.ceil(box.height)}
      this.expanded.has(toast.position.key) ? this.pause(toast) : this.start(toast)
      this.layout()
    },

    add(input) {
      const position = positionOf(input.position, this.el.dataset.position)
      const toast = {
        id: String(input.id ?? `linea-toast-${++this.seq}`),
        position,
        input,
        timer: null,
      }
      toast.duration = this.durationOf(input)
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
      const rich = !template && isRich(input)
      const color = colorFor(input)
      el.className = `toastify toastify-${toast.position.x} toastify-${toast.position.y}`
      el.dataset.toastId = toast.id
      rich ? (el.dataset.tone = color) : color === "neutral" || el.classList.add(color)
      el.setAttribute("role", color === "error" ? "alert" : "status")
      const fill = template ? () => this.fillTemplate(el, template) : rich ? () => this.fillRich(el, input, toast) : () => this.fillText(el, input, toast)
      fill()
      this.decorate(el, input, toast)
      template || this.invert(el, input)
      this.fillTimer(el, input, toast)
      el.querySelectorAll("[data-toast-dismiss]").forEach((button) => button.addEventListener("click", () => this.remove(toast)))
      el.addEventListener("mouseenter", () => this.hover(toast.position.key, true))
      el.addEventListener("mouseleave", () => this.hover(toast.position.key, false))
      return el
    },

    decorate(el, input, toast) {
      const aura = auraOf(input)
      const progress = progressOf(input)
      el.classList.toggle("linea-aura", aura !== null)
      aura ? Object.assign(el.dataset, {aura: aura.variant, auraSize: aura.size, auraColor: aura.color}) : ["aura", "auraSize", "auraColor"].forEach((key) => delete el.dataset[key])
      progress === null || this.fillProgress(el, progress, toast, Boolean(input.bar))
      failedOf(input) && this.fillFailed(el)
    },

    invert(el, input) {
      const surface = surfaceFor(invertFor(input, this.el.dataset.invert === "true"), this.el.closest(".dark") !== null)
      surface ? (el.dataset.surface = surface) : delete el.dataset.surface
    },

    fillTimer(el, input, toast) {
      const show = timerFor(input, toast.duration, this.el.dataset.timer !== "false")
      show && el.append(this.part("span", "toast-timer", document.createElement("i")))
      show && el.querySelector(":scope > .toast-timer").setAttribute("aria-hidden", "true")
    },

    timerBar(toast) {
      return toast.el.querySelector(":scope > .toast-timer > i")
    },

    runTimer(toast) {
      const bar = this.timerBar(toast)
      const ratio = toast.left / toast.duration
      bar && Object.assign(bar.style, {animation: "none", transform: `scaleX(${ratio})`})
      bar && bar.style.setProperty("--timer-from", String(ratio))
      bar && bar.getBoundingClientRect()
      bar && (bar.style.animation = `linea-toast-timer ${toast.left}ms linear forwards`)
    },

    holdTimer(toast) {
      const bar = this.timerBar(toast)
      bar && Object.assign(bar.style, {animation: "none", transform: `scaleX(${toast.left / toast.duration})`})
    },

    fillProgress(el, progress, toast, bar) {
      const meter = bar ? document.createElement("i") : this.part("span", "toast-fill")
      const track = bar ? this.part("span", "toast-bar", meter) : meter
      track.setAttribute("aria-hidden", "true")
      meter.style.width = `${toast.progress ?? 0}%`
      el.classList.add("has-progress")
      el.dataset.state = progress >= 100 ? "done" : "running"
      bar && (el.dataset.bar = "")
      el.prepend(track)
      requestAnimationFrame(() => (meter.style.width = `${progress}%`))
      toast.progress = progress
    },

    fillFailed(el) {
      const fill = this.part("span", "toast-fill")
      fill.setAttribute("aria-hidden", "true")
      fill.style.width = "100%"
      el.classList.add("has-progress")
      el.dataset.state = "failed"
      el.prepend(fill)
    },

    fillText(el, input, toast) {
      const text = document.createElement("span")
      text.textContent = input.message ?? ""
      const icon = this.el.querySelector(`template[data-toast-icon="${NOTE_ICONS[colorFor(input)]}"]`)
      icon && el.append(this.part("span", "toast-note-icon", icon.content.firstElementChild.cloneNode(true)))
      el.append(text)
      closeFor(input, toast.duration) && el.append(this.closeButton())
    },

    fillRich(el, input, toast) {
      const kind = kindOf(progressKind(input))
      const progress = progressOf(input)
      el.classList.add("rich")
      kind && el.setAttribute("aria-busy", String(kind === "loading"))
      const icon = kind && this.el.querySelector(`template[data-toast-icon="${kind}"]`)
      icon && el.append(this.part("span", "toast-icon", icon.content.firstElementChild.cloneNode(true)))
      const steps = stepsOf(input)
      const body = steps ? this.stepsBody(el, input, steps) : this.textBody(input)
      const actions = (input.actions ?? []).map((action) => this.action(action, toast))
      el.append(body)
      actions.length > 0 && el.append(this.part("div", "toast-actions", ...actions))
      progress === null || input.bar || el.append(this.part("span", "toast-pct", `${Math.round(progress)}%`))
      closeFor(input, toast.duration) && el.append(this.closeButton())
    },

    stepsBody(el, input, steps) {
      el.classList.add("has-steps")
      el.dataset.state = steps.done ? "done" : "running"
      const body = this.part("div", "toast-body")
      const head = this.part("div", "toast-steps-head", this.part("p", "toast-title", input.message ?? ""), this.part("span", "toast-steps-count", `${steps.step}/${steps.total}`))
      const segs = this.part("span", "toast-segs", ...Array.from({length: steps.total}, (_, index) => this.seg(index, steps)))
      segs.style.setProperty("--toast-steps", String(steps.total))
      segs.setAttribute("role", "progressbar")
      Object.entries({"aria-valuemin": 0, "aria-valuemax": steps.total, "aria-valuenow": steps.step, "aria-label": input.message ?? ""}).forEach(([name, value]) => segs.setAttribute(name, String(value)))
      body.append(head, segs)
      input.description && body.append(this.part("p", "toast-desc", input.description))
      return body
    },

    seg(index, steps) {
      const seg = document.createElement("span")
      seg.dataset.seg = index < steps.step || steps.done ? "done" : index === steps.step ? "current" : "todo"
      return seg
    },

    textBody(input) {
      const body = this.part("div", "toast-body")
      input.message && body.append(this.part("p", "toast-title", input.message))
      input.description && body.append(this.part("p", "toast-desc", input.description))
      return body
    },

    part(tag, className, ...children) {
      const node = document.createElement(tag)
      node.className = className
      node.append(...children)
      return node
    },

    action(action, toast) {
      const node = document.createElement(action.href ? "a" : "button")
      node.className = "toast-action"
      action.variant && (node.dataset.variant = action.variant)
      action.color && (node.dataset.color = action.color)
      node.textContent = action.label ?? ""
      action.href ? (node.href = action.href) : (node.type = "button")
      node.addEventListener("click", () => this.runAction(action, toast))
      return node
    },

    runAction(action, toast) {
      const payload = actionPayload(action, toast.id)
      const js = encodedJS(action.js)
      action.event && (action.target ? this.pushEventTo(action.target, action.event, payload) : this.pushEvent(action.event, payload))
      js && this.liveSocket.execJS(this.el, js)
      action.dismiss === false || this.remove(toast)
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
      button.append(this.cross())
      return button
    },

    cross() {
      return glyphElement("close", iconSet(this.el), {})
    },

    start(toast) {
      clearTimeout(toast.timer)
      toast.startedAt = Date.now()
      toast.timer = Number.isFinite(toast.duration) ? setTimeout(() => this.remove(toast), toast.left) : null
      Number.isFinite(toast.duration) && this.runTimer(toast)
    },

    pause(toast) {
      clearTimeout(toast.timer)
      toast.timer = null
      toast.left = Number.isFinite(toast.duration) ? timeLeft(toast.left, Date.now() - toast.startedAt) : toast.left
      Number.isFinite(toast.duration) && this.holdTimer(toast)
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
        const open = !stacked || this.expanded.has(key)
        const plan = stack(group.map((toast) => toast.size), open)
        group.forEach((toast, index) => this.place(toast, plan[index], index, !open && index > 0))
      })
    },

    place({el, position}, {offset, scale, width, height, hidden}, index, behind) {
      // a card behind the newest of a closed pile is a sliver: its text is not drawn, so it never overlaps the front one
      el.toggleAttribute("data-behind", behind)
      el.style[position.y] = `${offset}px`
      el.style.width = `${width}px`
      el.style.height = `${height}px`
      el.style.transform = `scale(${scale})`
      el.style.transformOrigin = `${position.y} ${position.x}`
      el.style.zIndex = `calc(var(--linea-z-toast, 10010) - ${index})`
      el.style.opacity = hidden ? "0" : ""
      el.style.pointerEvents = hidden ? "none" : ""
    },
  },
}
