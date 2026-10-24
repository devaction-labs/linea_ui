/**
 * `LineaUI.SignaturePad`: a signature drawn with pointer events (mouse, touch, pen) or typed as a name, exported as
 * SVG text into the hidden `[data-value-input]` (named like the form field, `phx-update="ignore"`). Every change fires
 * a bubbling `input` event, so `phx-change` runs, and pushes `data-on-change` with `%{"id" => id, "value" => svg}` to the
 * `phx-target`; Clear empties the pad and the value. A new `data-value` from the server (an SVG, or empty) replaces what
 * is in the pad; a patch that did not change it keeps the drawing. The drawing surface is client-owned (`phx-update="ignore"`).
 */
import {notify} from "../lib/dom.js"
import {hasInk, incomingValue, modesOf, pathOf, pointIn, svgOf, svgUri} from "../lib/signature_logic.js"

const SignaturePad = {
  mounted() {
    this.modes = modesOf(this.el.dataset.modes)
    this.mode = this.modes.includes(this.el.dataset.mode) ? this.el.dataset.mode : this.modes[0]
    this.text = this.el.dataset.text ?? ""
    this.ink = this.el.dataset.ink
    this.server = this.el.dataset.value ?? ""
    this.svg = this.server
    this.existing = this.server !== ""
    this.strokes = []
    this.size = this.measure()

    this.onDown = (event) => this.down(event)
    this.onMove = (event) => this.drawing && this.move(event)
    this.onUp = (event) => this.up(event)
    this.onClick = (event) => this.click(event)
    this.onInput = (event) => this.input(event)

    const pad = this.pad()
    pad.addEventListener("pointerdown", this.onDown)
    pad.addEventListener("pointermove", this.onMove)
    pad.addEventListener("pointerup", this.onUp)
    pad.addEventListener("pointercancel", this.onUp)
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("input", this.onInput)
    this.paint()
  },

  updated() {
    const server = this.el.dataset.value ?? ""
    const incoming = incomingValue({server, previous: this.server, current: this.svg})
    this.server = server
    incoming !== null && this.replace(incoming)
    this.paint()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("input", this.onInput)
  },

  q(selector) {
    return this.el.querySelector(selector)
  },

  pad() {
    return this.q("[data-pad]")
  },

  value() {
    return this.q("[data-value-input]")
  },

  measure() {
    const {width, height} = this.pad().getBoundingClientRect()
    return {width: Math.round(width), height: Math.round(height)}
  },

  replace(svg) {
    this.strokes = []
    this.text = svg === "" ? "" : this.text
    this.existing = svg !== ""
    this.svg = svg
  },

  down(event) {
    const drawable = this.mode === "draw" && this.el.dataset.disabled !== "true"
    drawable && this.start(event)
  },

  start(event) {
    this.existing && ((this.existing = false), (this.strokes = []))
    this.strokes.length === 0 && (this.size = this.measure())
    this.drawing = true
    this.pad().setPointerCapture?.(event.pointerId)
    this.strokes = [...this.strokes, [pointIn(this.pad().getBoundingClientRect(), event.clientX, event.clientY)]]
    this.commit()
  },

  move(event) {
    const point = pointIn(this.pad().getBoundingClientRect(), event.clientX, event.clientY)
    const last = this.strokes.at(-1)
    this.strokes = [...this.strokes.slice(0, -1), [...last, point]]
    this.paint()
  },

  up(event) {
    const was = this.drawing
    this.drawing = false
    this.pad().releasePointerCapture?.(event.pointerId)
    was && this.commit()
  },

  input(event) {
    const typed = event.target.matches("[data-type-input]")
    event.target === this.value() || event.stopPropagation()
    typed && ((this.existing = false), (this.text = event.target.value), this.commit())
  },

  click(event) {
    const mode = event.target.closest("[data-mode-button]")
    const clear = event.target.closest("[data-clear]")
    mode && this.switch(mode.dataset.modeButton)
    clear && this.clear()
  },

  switch(mode) {
    this.mode = mode
    this.existing = false
    this.commit()
  },

  clear() {
    this.strokes = []
    this.text = ""
    this.existing = false
    this.commit()
  },

  commit() {
    const signature = {mode: this.mode, strokes: this.strokes, text: this.text, size: this.size, ink: this.ink}
    const svg = this.existing ? this.server : svgOf(signature)
    const changed = svg !== this.svg
    this.svg = svg
    this.paint()
    changed && (notify(this.value()), this.push())
  },

  push() {
    const event = this.el.dataset.onChange
    event && this.pushEventTo(this.el.getAttribute("phx-target") || this.el, event, {id: this.el.id, value: this.svg})
  },

  paint() {
    const signature = {mode: this.mode, strokes: this.strokes, text: this.text}
    const ink = this.existing || hasInk(signature)
    const path = this.q("[data-path]")
    path.setAttribute("d", this.mode === "draw" && !this.existing ? pathOf(this.strokes) : "")
    const existing = this.q("[data-existing]")
    existing.hidden = !this.existing
    existing.src = this.existing ? svgUri(this.server) : ""
    const typed = this.q("[data-typed]")
    typed.textContent = this.mode === "type" && !this.existing ? this.text : ""
    this.q("[data-hint]").hidden = ink || this.mode === "type"
    this.pad().dataset.mode = this.mode
    this.q("[data-type-field]").hidden = this.mode !== "type"
    const field = this.q("[data-type-input]")
    document.activeElement === field || (field.value = this.text)
    this.q("[data-status-ready]").hidden = !ink
    this.q("[data-status-empty]").hidden = ink
    this.el.querySelectorAll("[data-mode-button]").forEach((button) => button.setAttribute("aria-pressed", String(button.dataset.modeButton === this.mode)))
    this.value().value = this.svg
  },
}

export default {"LineaUI.SignaturePad": SignaturePad}
