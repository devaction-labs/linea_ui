import {clickAction, endsSelection, onControl, popLeft} from "../lib/card_table_logic.js"

const ROW = ".linea-ctable-row"
const POP = ".linea-ctable-pop"

const popOf = (row) => row.querySelector(`:scope > ${POP}`)
const shows = (pop) => !!pop && getComputedStyle(pop).display !== "none"

/**
 * `CardTable`: opens the details panel of a `card_table` row on a click (or a tap), at the click's x, and on Enter or
 * Space from the keyboard, at the fixed anchor of the CSS. One delegated listener on the table (`click`, `keydown`),
 * one on the document (a click outside, Esc). The open row carries `data-open` and `aria-expanded="true"`, and `--ct-pop-x`
 * (the panel's left edge, clamped inside the row) when a pointer opened it. The panel does not follow the pointer. A control
 * of the row (link, button, check box, copy, action menu) closes it, a second click on the row too.
 */
export default {
  "LineaUI.CardTable": {
    mounted() {
      this.row = null
      this.onClick = (e) => this.click(e)
      this.onKey = (e) => this.key(e)
      this.onDoc = (e) => {
        if (this.row && !this.el.contains(e.target)) this.close()
      }
      this.onEsc = (e) => {
        if (e.key !== "Escape" || !this.row) return
        const row = this.row
        this.close()
        row.focus({preventScroll: true})
      }
      this.el.addEventListener("click", this.onClick)
      this.el.addEventListener("keydown", this.onKey)
      document.addEventListener("click", this.onDoc)
      document.addEventListener("keydown", this.onEsc)
    },

    destroyed() {
      this.el.removeEventListener("click", this.onClick)
      this.el.removeEventListener("keydown", this.onKey)
      document.removeEventListener("click", this.onDoc)
      document.removeEventListener("keydown", this.onEsc)
    },

    current() {
      if (this.row && !this.row.isConnected) this.row = null
      return this.row
    },

    click(e) {
      const row = e.target.closest?.(ROW)
      if (!row || !this.el.contains(row)) return
      if (endsSelection(window.getSelection?.(), row)) return
      if (e.target.closest?.(".linea-ctable-expand, .linea-ctable-edit")) return
      const pop = popOf(row)
      const action = clickAction({
        inPop: !!pop && pop.contains(e.target),
        hasPop: shows(pop),
        control: onControl(e.target, row),
        isOpen: this.current() === row,
      })
      if (action === "close") this.close()
      else if (action === "open") {
        const box = row.getBoundingClientRect()
        this.open(row, popLeft({clientX: e.clientX, rowLeft: box.left, rowWidth: box.width, popWidth: pop.offsetWidth}))
      }
    },

    key(e) {
      if (e.key !== "Enter" && e.key !== " ") return
      const row = e.target
      if (!row.matches?.(ROW) || !shows(popOf(row))) return
      e.preventDefault()
      this.current() === row ? this.close() : this.open(row, null)
    },

    open(row, x) {
      this.close()
      x == null ? row.style.removeProperty("--ct-pop-x") : row.style.setProperty("--ct-pop-x", `${x}px`)
      row.setAttribute("data-open", "")
      row.setAttribute("aria-expanded", "true")
      this.row = row
    },

    close() {
      const row = this.row
      this.row = null
      if (!row) return
      row.removeAttribute("data-open")
      row.setAttribute("aria-expanded", "false")
      row.style.removeProperty("--ct-pop-x")
    },
  },
}
