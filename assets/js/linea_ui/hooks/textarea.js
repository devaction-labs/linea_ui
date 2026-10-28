import {counterState, growHeight} from "../lib/textarea_logic.js"

const TONES = ["ok", "warn", "bad"]

/**
 * `LineaUI.Textarea`: a textarea that counts and/or grows with its text, with no round trip to the server.
 *
 * `data-counter` is the id of the element that shows the count ("68 / 200"; `data-min` and `data-max` are
 * the limits) and gets `data-tone` (`ok`, `warn`, `bad`) for its color. `data-autogrow` makes the height
 * follow the content, from `rows` up to `data-max-rows` lines (then it scrolls).
 */
export default {
  "LineaUI.Textarea": {
    mounted() {
      this.onInput = () => this.refresh()
      this.el.addEventListener("input", this.onInput)
      this.refresh()
    },

    updated() {
      this.refresh()
    },

    destroyed() {
      this.el.removeEventListener("input", this.onInput)
    },

    refresh() {
      this.count()
      this.grow()
    },

    count() {
      const id = this.el.dataset.counter
      const target = id && document.getElementById(id)
      if (!target) return

      const number = (value) => (value === undefined || value === "" ? null : Number(value))
      const next = counterState({length: this.el.value.length, min: number(this.el.dataset.min), max: number(this.el.dataset.max)})

      target.textContent === next.text || (target.textContent = next.text)
      TONES.includes(next.tone) && target.dataset.tone !== next.tone && (target.dataset.tone = next.tone)
    },

    grow() {
      if (this.el.dataset.autogrow === undefined) return

      const style = getComputedStyle(this.el)
      const number = (value) => parseFloat(value) || 0
      const lineHeight = number(style.lineHeight) || number(style.fontSize) * 1.5

      this.el.style.height = "auto"
      const next = growHeight({
        scrollHeight: this.el.scrollHeight,
        lineHeight,
        padding: number(style.paddingTop) + number(style.paddingBottom),
        border: number(style.borderTopWidth) + number(style.borderBottomWidth),
        rows: this.el.rows,
        maxRows: this.el.dataset.maxRows ? Number(this.el.dataset.maxRows) : null,
      })

      this.el.style.height = `${next.height}px`
      this.el.style.overflowY = next.scroll ? "auto" : "hidden"
    },
  },
}
