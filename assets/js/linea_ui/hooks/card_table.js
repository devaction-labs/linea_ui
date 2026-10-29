const INTERACTIVE = "a, button, input, select, textarea, label, [role=button], [data-dropdown]"
const COPIED_MS = 1500
const LEAVE_MS = 350

/**
 * `CardTable`: the panel of a row. A click on the row (on any part that is not a control), or Enter or Space on
 * the focused row, opens it, so it can be read and used (every line has a copy button). It closes with Esc, a
 * click outside, another row opening, or any control of the row being used (the action menu, a checkbox), so it
 * never competes with a dropdown. Opened with the mouse, it also goes away `LEAVE_MS` after the pointer leaves
 * the row and the panel; coming back, or being on the panel, keeps it (the delay also crosses the gap between
 * the row and its panel). Text selected in it, or the focus inside it, keeps it too. Opened with the keyboard
 * or a finger, it stays until it is closed.
 */
export default {
  "LineaUI.CardTable": {
    mounted() {
      const rowOf = (target) => target.closest?.(".linea-ctable-row")

      this.open = (row, byMouse = false) => {
        this.closeAll(row)
        this.byMouse = byMouse
        row.toggleAttribute("data-open", true)
        row.setAttribute("aria-expanded", "true")
      }

      this.close = (row) => {
        clearTimeout(this.timer)
        row.removeAttribute("data-open")
        row.setAttribute("aria-expanded", "false")
      }

      this.closeAll = (except) =>
        this.el.querySelectorAll(".linea-ctable-row[data-open]").forEach((row) => row !== except && this.close(row))

      this.toggle = (row, byMouse) => (row.hasAttribute("data-open") ? this.close(row) : this.open(row, byMouse))

      this.busy = (row) => {
        const pop = row.querySelector(".linea-ctable-pop")
        const selection = window.getSelection()
        const selecting = selection && !selection.isCollapsed && pop?.contains(selection.anchorNode)
        return row.matches(":hover") || pop?.contains(document.activeElement) || selecting
      }

      this.leave = (event) => {
        const row = this.el.querySelector(".linea-ctable-row[data-open]")
        if (!row || !this.byMouse || row.contains(event.relatedTarget)) return
        clearTimeout(this.timer)
        this.timer = setTimeout(() => !this.busy(row) && this.close(row), LEAVE_MS)
      }

      this.enter = (event) => rowOf(event.target)?.hasAttribute("data-open") && clearTimeout(this.timer)

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
        this.toggle(row, event.detail > 0)
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
      this.el.addEventListener("mouseout", this.leave)
      this.el.addEventListener("mouseover", this.enter)
      document.addEventListener("click", this.onOutside)
      document.addEventListener("keydown", this.onKey)
    },

    destroyed() {
      this.el.removeEventListener("click", this.onClick)
      this.el.removeEventListener("mouseout", this.leave)
      this.el.removeEventListener("mouseover", this.enter)
      clearTimeout(this.timer)
      document.removeEventListener("click", this.onOutside)
      document.removeEventListener("keydown", this.onKey)
    },
  },
}
