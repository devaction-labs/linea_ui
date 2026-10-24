import {nextValue} from "../lib/input_sync.js"
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
/**
 * `LineaUI.InputSync` (and the mask hook when `data-clear-on-submit` is set): LiveView keeps what is
 * typed in a focused input, so after the surrounding form is submitted the next server render
 * (`data-value`) is written to the input even though it has focus, e.g. to clear a todo field.
 * Typing cancels the pending submit.
 */
const attachSync = (hook) => {
  hook.pending = false
  hook.syncForm = hook.el.dataset.clearOnSubmit === undefined ? null : hook.el.form
  hook.onSubmit = () => (hook.pending = true)
  hook.onType = () => (hook.pending = false)
  hook.syncForm?.addEventListener("submit", hook.onSubmit)
  hook.el.addEventListener("input", hook.onType)
}

const applySync = (hook) => {
  const next = nextValue({pending: hook.pending, current: hook.el.value, server: hook.el.dataset.value})
  hook.pending = false
  next === null || (hook.el.value = next)
}

const detachSync = (hook) => {
  hook.syncForm?.removeEventListener("submit", hook.onSubmit)
  hook.el.removeEventListener("input", hook.onType)
}

const InputMask = {
  mounted() {
    attachSync(this)
    this.read()
    this.onInput = (event) => this.handleInput(event)
    this.el.addEventListener("input", this.onInput)
    this.show(this.el.value, null)
  },

  updated() {
    applySync(this)
    this.read()
    this.show(this.el.value, null)
  },

  destroyed() {
    detachSync(this)
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

const InputSync = {
  mounted() {
    attachSync(this)
  },

  updated() {
    applySync(this)
  },

  destroyed() {
    detachSync(this)
  },
}

export default {"LineaUI.InputMask": InputMask, "LineaUI.InputSync": InputSync}
