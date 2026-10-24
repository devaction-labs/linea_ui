/**
 * `LineaUI.ColorPicker`: a saturation-brightness area (drag it, or use the arrow keys), a hue slider, an optional opacity
 * slider, a hex field and preset swatches. The hidden `[data-value-input]` (named like the form field,
 * `phx-update="ignore"`) holds the hex text; whenever the color changes it fires a bubbling `input` event, so a `phx-change`
 * runs, and pushes `data-on-change` with `%{"id" => id, "value" => hex}` to the `phx-target`. A new `data-value` from the
 * server wins; a patch that did not change it keeps the color in the browser. The inner controls have no name, so their
 * own `input` and `change` events stop here.
 */
import {notify} from "../lib/dom.js"
import {areaKey, areaPoint, areaText, colorOfHex, hexOfColor, parseHex, sameHex, toHex} from "../lib/color_logic.js"
import {runKey} from "../lib/keys.js"

const AREA_KEYS = ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"]
const CHECKER = "repeating-conic-gradient(#cbd5e1 0 25%, #fff 0 50%) 0 0/10px 10px"

const ColorPicker = {
  mounted() {
    this.alpha = this.el.dataset.alpha === "true"
    this.server = this.el.dataset.value
    this.take(this.server)

    this.onInput = (event) => this.input(event)
    this.onChange = (event) => event.target !== this.value() && event.stopPropagation()
    this.onClick = (event) => this.click(event)
    this.onFocusOut = (event) => event.target === this.hexField() && this.settle()
    this.onKeyDown = (event) => this.key(event)
    this.onDown = (event) => this.pointerDown(event)
    this.onMove = (event) => this.dragging && this.pointer(event)
    this.onUp = (event) => this.pointerUp(event)

    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("change", this.onChange)
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("focusout", this.onFocusOut)
    this.area().addEventListener("keydown", this.onKeyDown)
    this.area().addEventListener("pointerdown", this.onDown)
    this.area().addEventListener("pointermove", this.onMove)
    this.area().addEventListener("pointerup", this.onUp)
    this.area().addEventListener("pointercancel", this.onUp)
    this.paint()
  },

  updated() {
    const incoming = this.el.dataset.value
    const changed = incoming !== this.server && !sameHex(incoming, this.hex)
    this.server = incoming
    changed && this.take(incoming)
    this.paint()
  },

  destroyed() {
    this.el.removeEventListener("input", this.onInput)
    this.el.removeEventListener("change", this.onChange)
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("focusout", this.onFocusOut)
  },

  q(selector) {
    return this.el.querySelector(selector)
  },

  area() {
    return this.q("[data-area]")
  },

  value() {
    return this.q("[data-value-input]")
  },

  hexField() {
    return this.q("[data-hex]")
  },

  take(text) {
    const color = colorOfHex(text)
    color && ((this.color = this.alpha ? color : {...color, a: 100}), (this.hex = toHex(parseHex(text), this.alpha)))
  },

  commit(color) {
    const hex = hexOfColor(color, this.alpha)
    this.color = color
    this.change(hex)
  },

  change(hex) {
    const changed = !sameHex(hex, this.hex)
    this.hex = hex
    this.paint()
    changed && (notify(this.value()), this.push())
  },

  push() {
    const event = this.el.dataset.onChange
    event && this.pushEventTo(this.el.getAttribute("phx-target") || this.el, event, {id: this.el.id, value: this.hex})
  },

  input(event) {
    const target = event.target
    target === this.value() || event.stopPropagation()
    const handlers = [
      [target.matches("[data-hue]"), () => this.commit({...this.color, h: Number(target.value)})],
      [target.matches("[data-alpha-input]"), () => this.commit({...this.color, a: Number(target.value)})],
      [target.matches("[data-hex]"), () => this.typed(target.value)],
    ]
    handlers.find(([hit]) => hit)?.[1]()
  },

  typed(text) {
    const parsed = colorOfHex(text)
    parsed && (this.take(text), this.change(toHex(parseHex(text), this.alpha)))
  },

  settle() {
    this.hexField().value = this.hex
  },

  click(event) {
    const preset = event.target.closest("[data-preset]")
    preset && (this.take(preset.dataset.preset), this.change(toHex(parseHex(preset.dataset.preset), this.alpha)))
  },

  pointerDown(event) {
    this.dragging = true
    this.area().setPointerCapture?.(event.pointerId)
    this.area().focus({preventScroll: true})
    this.pointer(event)
  },

  pointer(event) {
    const point = areaPoint(this.area().getBoundingClientRect(), event.clientX, event.clientY)
    this.commit({...this.color, ...point})
  },

  pointerUp(event) {
    this.dragging = false
    this.area().releasePointerCapture?.(event.pointerId)
  },

  key(event) {
    const table = Object.fromEntries(
      AREA_KEYS.map((key) => [
        key,
        () => {
          const next = areaKey(key, this.color, event.shiftKey)
          next && this.commit({...this.color, ...next})
        },
      ]),
    )
    runKey(table, event)
  },

  paint() {
    const {h, s, v, a} = this.color
    const opaque = hexOfColor({h, s, v, a: 100})
    const area = this.area()
    area.style.backgroundColor = `hsl(${h} 100% 50%)`
    area.setAttribute("aria-valuenow", String(s))
    area.setAttribute("aria-valuetext", areaText(this.el.dataset.areaText, this.color))
    const knob = this.q("[data-knob]")
    knob.style.left = `${s}%`
    knob.style.top = `${100 - v}%`
    knob.style.backgroundColor = opaque
    this.q("[data-hue]").value = String(h)
    const alpha = this.q("[data-alpha-input]")
    alpha && ((alpha.value = String(a)), (alpha.style.background = `linear-gradient(90deg, transparent, ${opaque}), ${CHECKER}`))
    const chip = this.q("[data-chip]")
    chip.style.backgroundColor = opaque
    chip.style.opacity = String(a / 100)
    document.activeElement === this.hexField() || (this.hexField().value = this.hex)
    this.value().value = this.hex
    this.el.querySelectorAll("[data-preset]").forEach((button) => button.setAttribute("aria-pressed", String(sameHex(button.dataset.preset, this.hex))))
  },
}

export default {"LineaUI.ColorPicker": ColorPicker}
