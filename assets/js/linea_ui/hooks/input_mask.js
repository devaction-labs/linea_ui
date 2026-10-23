import {format, raw, caretFor, significantBefore, dropBefore} from "../lib/mask_logic.js"

/**
 * `LineaUI.InputMask`: formats a text input as it is typed (`data-mask`, `data-mask-options`).
 *
 * The formatting happens in the input's own `input` listener, before the event bubbles to LiveView,
 * so `phx-change` receives the masked text. With `data-mask-submit="raw"` the input has no name: the
 * hidden `#<id>-raw` input carries the field and receives the unmasked value, and the bubbling
 * `input` event is re-dispatched from it only when that value actually changed. A server re-render
 * reformats what it shows without firing anything, so echoes never loop.
 */
const InputMask = {
  mounted() {
    this.read()
    this.onInput = (event) => this.handleInput(event)
    this.el.addEventListener("input", this.onInput)
    this.show(this.el.value, null)
  },

  updated() {
    this.read()
    this.show(this.el.value, null)
  },

  destroyed() {
    this.el.removeEventListener("input", this.onInput)
  },

  read() {
    this.kind = this.el.dataset.mask
    this.submitRaw = this.el.dataset.maskSubmit === "raw"
    try {
      this.options = JSON.parse(this.el.dataset.maskOptions || "{}")
    } catch (_error) {
      this.options = {}
    }
  },

  rawInput() {
    return document.getElementById(`${this.el.id}-raw`)
  },

  handleInput(event) {
    const typed = this.el.value
    const caret = this.el.selectionStart ?? typed.length
    const unchanged = format(typed, this.kind, this.options) === this.shown
    const edit =
      event.inputType === "deleteContentBackward" && unchanged
        ? dropBefore(typed, caret)
        : {text: typed, position: caret}

    const atEnd = edit.position >= edit.text.length
    this.show(edit.text, atEnd ? Infinity : significantBefore(edit.text, edit.position))
    this.submitRaw && this.forward(event)
  },

  forward(event) {
    event.stopPropagation()
    const hidden = this.rawInput()
    const value = raw(this.el.value, this.kind, this.options)
    if (!hidden || hidden.value === value) return
    hidden.value = value
    hidden.dispatchEvent(new Event("input", {bubbles: true}))
  },

  show(value, significant) {
    const formatted = format(value, this.kind, this.options)
    this.shown = formatted
    if (this.el.value !== formatted) this.el.value = formatted
    if (significant === null || document.activeElement !== this.el) return
    const position = significant === Infinity ? formatted.length : caretFor(formatted, significant)
    try {
      this.el.setSelectionRange(position, position)
    } catch (_error) {
      return
    }
  },
}

export default {"LineaUI.InputMask": InputMask}
