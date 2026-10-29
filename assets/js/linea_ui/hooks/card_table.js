const INTERACTIVE = "a, button, input, select, textarea, label, [role=button], [data-dropdown]"
const COPIED_MS = 1500

/**
 * `CardTable`: the panel of a row. A click on the row (on any part that is not a control), or Enter or Space on
 * the focused row, opens it and it stays open, so it can be read and used (every line has a copy button). It
 * closes with Esc, a click outside, another row opening, or any control of the row being used (the action menu,
 * a checkbox), so it never competes with a dropdown.
 */
export default {
  "LineaUI.CardTable": {
    mounted() {
      const rowOf = (target) => target.closest?.(".linea-ctable-row")

      this.open = (row) => {
        this.closeAll(row)
        row.toggleAttribute("data-open", true)
        row.setAttribute("aria-expanded", "true")
      }

      this.close = (row) => {
        row.removeAttribute("data-open")
        row.setAttribute("aria-expanded", "false")
      }

      this.closeAll = (except) =>
        this.el.querySelectorAll(".linea-ctable-row[data-open]").forEach((row) => row !== except && this.close(row))

      this.toggle = (row) => (row.hasAttribute("data-open") ? this.close(row) : this.open(row))

      this.copyLine = async (button) => {
        const text = button.closest("div")?.querySelector(".linea-ctable-pv")?.innerText.trim() ?? ""
        const done = await navigator.clipboard?.writeText(text).then(() => true, () => false)
        if (!done) return
        const tip = button.dataset.tip
        button.toggleAttribute("data-copied", true)
        button.dataset.tip = button.dataset.copiedTip
        clearTimeout(button.timer)
        button.timer = setTimeout(() => {
          button.removeAttribute("data-copied")
          button.dataset.tip = tip
        }, COPIED_MS)
      }

      this.onClick = (event) => {
        const copy = event.target.closest("[data-copy-line]")
        if (copy) return this.copyLine(copy)
        if (event.target.closest(".linea-ctable-pop")) return

        const row = rowOf(event.target)
        if (!row) return
        if (event.target.closest(INTERACTIVE)) return this.closeAll()
        this.toggle(row)
      }

      this.onKey = (event) => {
        if (event.key === "Escape") {
          const open = this.el.querySelector(".linea-ctable-row[data-open]")
          if (open) {
            this.close(open)
            open.focus()
          }
        } else if ((event.key === "Enter" || event.key === " ") && this.el.contains(event.target) && event.target.matches?.(".linea-ctable-row")) {
          event.preventDefault()
          this.toggle(event.target)
        }
      }

      this.onOutside = (event) => this.el.contains(event.target) || this.closeAll()

      this.el.addEventListener("click", this.onClick)
      document.addEventListener("click", this.onOutside)
      document.addEventListener("keydown", this.onKey)
    },

    destroyed() {
      this.el.removeEventListener("click", this.onClick)
      document.removeEventListener("click", this.onOutside)
      document.removeEventListener("keydown", this.onKey)
    },
  },
}
