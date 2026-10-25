import {notify} from "../lib/dom.js"
import {execWithPayload} from "../lib/js_payload.js"
import {runKey} from "../lib/keys.js"
import {cellsOf, complete, erase, firstOpen, joined, reconcile, spread, startOf, target} from "../lib/otp_logic.js"

/**
 * `LineaUI.Otp`: a one-time code of single-character boxes (`[data-otp-box]`). Typing moves to the next box,
 * Backspace on an empty box goes back and empties the previous one, the arrows, Home and End move, and a paste
 * or an autofill spreads its characters over the boxes (a text as long as the whole code always starts at the
 * first). The code is joined into the hidden `[data-otp-value]` input named like the field, which fires a
 * bubbling `input` when it changes so a surrounding `phx-change` runs; a filled box carries `data-filled`.
 *
 * `data-on-complete` (an encoded `%JS{}`) runs with `%{id, name, value}` each time the code changes while every
 * box is filled. A `data-value` the server sends wins, but the echo of what the browser sent a moment before
 * does not undo what was typed since; a patch that changes nothing leaves the boxes alone.
 */
export default {
  "LineaUI.Otp": {
    mounted() {
      this.sent = []
      this.cells = cellsOf(this.el.dataset.value, this.length(), this.mode())
      this.keys = {
        Backspace: (event) => this.back(event),
        ArrowLeft: (event) => this.go(event),
        ArrowRight: (event) => this.go(event),
        Home: (event) => this.go(event),
        End: (event) => this.go(event),
      }

      this.onInput = (event) => event.target.matches("[data-otp-box]") && this.typed(event)
      this.onPaste = (event) => event.target.matches("[data-otp-box]") && this.pasted(event)
      this.onKeyDown = (event) => event.target.matches("[data-otp-box]") && runKey(this.keys, event)
      this.onFocus = (event) => event.target.matches("[data-otp-box]") && event.target.select()

      this.el.addEventListener("input", this.onInput)
      this.el.addEventListener("paste", this.onPaste)
      this.el.addEventListener("keydown", this.onKeyDown)
      this.el.addEventListener("focusin", this.onFocus)

      this.write()
      this.el.hasAttribute("data-autofocus") && this.focusBox(firstOpen(this.cells))
    },

    updated() {
      const incoming = joined(cellsOf(this.el.dataset.value, this.length(), this.mode()))
      const next = reconcile({incoming, current: joined(this.cells), sent: this.sent})
      this.sent = next.sent
      next.adopt && (this.cells = cellsOf(incoming, this.length(), this.mode()))
      this.write()
    },

    destroyed() {
      this.el.removeEventListener("input", this.onInput)
      this.el.removeEventListener("paste", this.onPaste)
      this.el.removeEventListener("keydown", this.onKeyDown)
      this.el.removeEventListener("focusin", this.onFocus)
    },

    length() {
      return Number(this.el.dataset.length)
    },

    mode() {
      return this.el.dataset.mode
    },

    boxes() {
      return [...this.el.querySelectorAll("[data-otp-box]")]
    },

    hidden() {
      return this.el.querySelector("[data-otp-value]")
    },

    at(event) {
      return this.boxes().indexOf(event.target)
    },

    typed(event) {
      const text = event.target.value
      this.apply(spread(this.cells, startOf(this.at(event), text, this.length(), this.mode()), text, this.mode()))
    },

    pasted(event) {
      const text = event.clipboardData.getData("text")
      event.preventDefault()
      this.apply(spread(this.cells, startOf(this.at(event), text, this.length(), this.mode()), text, this.mode()))
    },

    back(event) {
      const erased = erase(this.cells, this.at(event))
      return erased ? (this.apply(erased), true) : false
    },

    go(event) {
      const to = target(event.key, this.at(event), this.length())
      return to === null ? false : (this.focusBox(to), true)
    },

    apply({cells, focus}) {
      const before = joined(this.cells)
      this.cells = cells
      this.write()
      this.focusBox(focus)
      before !== joined(cells) && this.changed()
    },

    changed() {
      const value = joined(this.cells)
      this.sent = [...this.sent, value]
      notify(this.hidden())
      complete(this.cells) && execWithPayload(this.liveSocket, this.el, this.el.dataset.onComplete, {id: this.el.id, name: this.hidden().name, value})
    },

    write() {
      this.boxes().forEach((box, index) => {
        const cell = this.cells[index] ?? ""
        box.value !== cell && (box.value = cell)
        box.toggleAttribute("data-filled", cell !== "")
      })
      this.hidden().value = joined(this.cells)
    },

    focusBox(index) {
      this.boxes()[index]?.focus()
    },
  },
}
