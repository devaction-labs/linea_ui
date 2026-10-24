/**
 * `LineaUI.Range` keeps a slider's extras in step with its input between two server round trips: the filled part
 * (`--p` on the input), the value written in `[data-output]` (the template `data-format`, `%{value}` filled), the
 * marks (`[data-mark]` buttons, pressed when they are the value; a click sets the value) and the stepper buttons
 * (`[data-step-by="up|down"]`, disabled at the limits). A change from a mark or a stepper fires a bubbling `input` event
 * from the input, so `phx-change` runs as when it is dragged.
 *
 * `LineaUI.RangePair` does the same for two inputs on one track (`[data-low]` and `[data-high]`): the thumb being
 * dragged stops at the other one, the filled part `[data-fill]` follows both and a click on a mark moves the nearer
 * thumb.
 */
import {notify} from "../lib/dom.js"
import {clampPair, fillBox, fillStyle, pairText, percent, valueText} from "../lib/numbers.js"
import {markValue, nearestThumb, sameValue, stepValue} from "../lib/range_logic.js"

const limitsOf = (input) => ({min: input.min, max: input.max, step: input.step})

const press = (root, isPressed) =>
  root.querySelectorAll("[data-mark]").forEach((mark) => mark.setAttribute("aria-pressed", String(isPressed(mark.dataset.mark))))

const Range = {
  mounted() {
    this.input = this.el.querySelector("[data-input]")
    this.onInput = () => this.paint()
    this.onClick = (event) => this.click(event)
    this.input.addEventListener("input", this.onInput)
    this.el.addEventListener("click", this.onClick)
    this.paint()
  },

  updated() {
    this.input = this.el.querySelector("[data-input]")
    this.paint()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
  },

  click(event) {
    const mark = event.target.closest("[data-mark]")
    const stepper = event.target.closest("[data-step-by]")
    const next = mark ? markValue(mark.dataset.mark, limitsOf(this.input)) : stepper ? stepValue(this.input.value, stepper.dataset.stepBy, limitsOf(this.input)) : null
    next !== null && this.set(next)
  },

  set(value) {
    this.input.value = value
    notify(this.input)
  },

  paint() {
    const {value, min, max} = this.input
    this.input.style.setProperty("--p", `${percent(value, min || 0, max || 100)}%`)
    const output = this.el.querySelector("[data-output]")
    output && (output.textContent = valueText(this.el.dataset.format, value))
    press(this.el, (mark) => sameValue(mark, value))
    this.el.querySelectorAll("[data-step-by]").forEach((button) => {
      button.disabled = this.input.disabled || stepValue(value, button.dataset.stepBy, limitsOf(this.input)) === null
    })
  },
}

const RangePair = {
  mounted() {
    this.onInput = (event) => this.sync(event.target.matches("[data-low]") ? "low" : "high")
    this.onClick = (event) => this.click(event)
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("click", this.onClick)
    this.sync(null)
  },

  updated() {
    this.sync(null)
  },

  destroyed() {
    this.el.removeEventListener("input", this.onInput)
    this.el.removeEventListener("click", this.onClick)
  },

  inputs() {
    return {low: this.el.querySelector("[data-low]"), high: this.el.querySelector("[data-high]")}
  },

  click(event) {
    const mark = event.target.closest("[data-mark]")
    const {low, high} = this.inputs()
    const value = mark ? markValue(mark.dataset.mark, limitsOf(low)) : null
    const thumb = value === null ? null : nearestThumb(low.value, high.value, value)
    thumb && this.move(thumb, value)
  },

  move(thumb, value) {
    const input = this.inputs()[thumb]
    input.value = value
    notify(input)
  },

  sync(moved) {
    const {low, high} = this.inputs()
    const pair = moved ? clampPair(low.value, high.value, moved) : {low: Number(low.value), high: Number(high.value)}
    low.value = String(pair.low)
    high.value = String(pair.high)
    const fill = this.el.querySelector("[data-fill]")
    Object.assign(fill.style, fillStyle("horizontal", fillBox(pair.low, pair.high, low.min || 0, low.max || 100)))
    const output = this.el.querySelector("[data-output]")
    output && (output.textContent = pairText(this.el.dataset.format, pair.low, pair.high))
    press(this.el, (mark) => sameValue(mark, String(pair.low)) || sameValue(mark, String(pair.high)))
  },
}

export default {"LineaUI.Range": Range, "LineaUI.RangePair": RangePair}
