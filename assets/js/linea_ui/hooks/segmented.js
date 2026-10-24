import {Segmented as Roving} from "../lib/controls.js"
import {notify} from "../lib/dom.js"
import {adopt, pressed} from "../lib/segmented_logic.js"
import {runJS} from "./dialog.js"

/**
 * `Segmented`: a group of toggle buttons (`aria-pressed`) where one is chosen. A press chooses without a round trip,
 * writes the value into the hidden input (`[data-value-input]`, named like the field) and fires a bubbling `input`
 * from it, only when the value changes, so a surrounding `phx-change` runs; it also runs `data-on-change` with
 * `%{id, value}`. A new `data-value` from the server wins over the browser's choice; a patch that does not change
 * it leaves the choice alone. Arrow keys, Home and End move the focus (roving tabindex) as in the vendored
 * `Segmented` control.
 */
export default {
  "LineaUI.Segmented": {
    ...Roving,

    mounted() {
      this.server = this.el.dataset.value
      this.value = this.server
      this.onClick = (event) => {
        const segment = event.target.closest("button[data-value]")
        segment && !segment.disabled && this.press(segment.dataset.value)
      }
      this.el.addEventListener("click", this.onClick)
      Roving.mounted.call(this)
      this.paint()
    },

    updated() {
      const server = this.el.dataset.value
      this.value = adopt({value: this.value, lastServer: this.server, server})
      this.server = server
      this.paint()
      Roving.updated.call(this)
    },

    destroyed() {
      this.el.removeEventListener("click", this.onClick)
      Roving.destroyed.call(this)
    },

    press(value) {
      const next = pressed(this.value, value)
      next !== null && this.choose(next)
    },

    choose(value) {
      this.value = value
      this.paint()
      this.sync()
      this.writeHidden()
      runJS(this, this.el.dataset.onChange, {id: this.el.id, value})
    },

    paint() {
      this.segments().forEach((button) => button.setAttribute("aria-pressed", String(button.dataset.value === this.value)))
      const hidden = this.el.querySelector("[data-value-input]")
      hidden && hidden.value !== this.value && (hidden.value = this.value)
    },

    writeHidden() {
      const hidden = this.el.querySelector("[data-value-input]")
      hidden && notify(hidden)
    },
  },
}
