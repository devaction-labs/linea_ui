/**
 * `LineaUI.NumberInput`: the visible input shows the localized number, the hidden `[data-value-input]` (named like the
 * field, `phx-update="ignore"`) holds the machine value. Typing writes the machine value and fires a bubbling `input`
 * from the hidden input only when it changed; the visible input's own `input` event is stopped so `phx-change` runs
 * once. Leaving the field clamps and groups it; the arrow keys and the steppers move by `data-step`. A new
 * `data-value` from the server wins; a patch that did not change it keeps what is in the browser.
 */
import {notify} from "../lib/dom.js"
import {canStep, displayOf, numberOptions, sameNumber, sanitize, settle, STEP_KEYS, stepFrom, valueOf} from "../lib/number_input_logic.js"
import {caretAfter} from "../lib/numbers.js"

const NumberInput = {
  mounted() {
    this.options = numberOptions(this.el.dataset)
    this.server = this.el.dataset.value ?? ""
    this.value = this.server

    this.onInput = (event) => event.target.matches("[data-display]") && this.typed(event)
    this.onBlur = (event) => event.target.matches("[data-display]") && this.leave()
    this.onKeyDown = (event) => event.target.matches("[data-display]") && this.key(event)
    this.onClick = (event) => {
      const button = event.target.closest("[data-step-by]")
      button && this.step(button.dataset.stepBy)
    }

    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("focusout", this.onBlur)
    this.el.addEventListener("keydown", this.onKeyDown)
    this.el.addEventListener("click", this.onClick)
    this.paintSteppers()
    this.paintSuffix()
  },

  updated() {
    this.options = numberOptions(this.el.dataset)
    const incoming = this.el.dataset.value ?? ""
    const changed = incoming !== this.server && !sameNumber(incoming, this.value)
    this.server = incoming
    changed && (this.value = incoming)
    this.writeHidden()
    const focused = document.activeElement === this.display()
    ;(changed || !focused) && (this.display().value = displayOf(this.value, this.options))
    this.paintSteppers()
    this.paintSuffix()
  },

  display() {
    return this.el.querySelector("[data-display]")
  },

  hidden() {
    return this.el.querySelector("[data-value-input]")
  },

  typed(event) {
    event.stopPropagation()
    const input = this.display()
    const before = input.value
    const caret = input.selectionStart ?? before.length
    const clean = sanitize(before, this.options)
    clean !== before && ((input.value = clean), this.placeCaret(caretAfter(before, caret, clean)))
    this.commit(valueOf(clean, this.options))
  },

  placeCaret(position) {
    try {
      this.display().setSelectionRange(position, position)
    } catch (_error) {
      return
    }
  },

  leave() {
    const {display, value} = settle(this.display().value, this.options)
    this.display().value = display
    this.commit(value)
    this.paintSuffix()
  },

  key(event) {
    const moves = STEP_KEYS.includes(event.key)
    moves && (event.preventDefault(), this.step(event.key))
  },

  step(by) {
    const next = this.display().readOnly || this.display().disabled ? null : stepFrom(this.value, by, this.options)
    next && ((this.display().value = next.display), this.commit(next.value))
  },

  commit(value) {
    const changed = value !== this.value
    this.value = value
    this.writeHidden()
    this.display().setAttribute("aria-valuenow", value)
    this.paintSteppers()
    this.paintSuffix()
    changed && notify(this.hidden())
  },

  /** A centered value keeps its suffix next to it: the field measures the value in characters (the value is set in mono). */
  paintSuffix() {
    const field = this.el.querySelector("[data-field]")
    const input = this.display()
    field && field.style.getPropertyValue("--nlen") !== "" &&
      field.style.setProperty("--nlen", String((input.value || input.placeholder || "").length))
  },

  writeHidden() {
    const hidden = this.hidden()
    hidden.value !== this.value && (hidden.value = this.value)
  },

  paintSteppers() {
    const disabled = this.display().disabled
    this.el.querySelectorAll("[data-step-by]").forEach((button) => {
      button.disabled = disabled || !canStep(this.value, button.dataset.stepBy, this.options)
    })
  },
}

export default {"LineaUI.NumberInput": NumberInput}
