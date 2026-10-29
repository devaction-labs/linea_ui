const INTERACTIVE = "a, button, input, select, textarea, label, [role=button]"

/**
 * `CardTable`: the panel of a row opens while the row has focus (a click on it, or Tab). This closes it the way a
 * pointer expects: it goes when the mouse leaves the row, and a click on the open row (outside its controls)
 * closes it again.
 */
export default {
  "LineaUI.CardTable": {
    mounted() {
      const rowOf = (target) => target.closest?.(".linea-ctable-row")

      this.onDown = (event) => {
        const row = rowOf(event.target)
        this.wasOpen = !!row && row.contains(document.activeElement)
      }

      this.onClick = (event) => {
        const row = rowOf(event.target)
        if (row && this.wasOpen && !event.target.closest(INTERACTIVE)) document.activeElement?.blur()
        this.wasOpen = false
      }

      this.onOut = (event) => {
        const row = rowOf(event.target)
        if (row && !row.contains(event.relatedTarget) && row.contains(document.activeElement)) document.activeElement.blur()
      }

      this.el.addEventListener("mousedown", this.onDown)
      this.el.addEventListener("click", this.onClick)
      this.el.addEventListener("mouseout", this.onOut)
    },

    destroyed() {
      this.el.removeEventListener("mousedown", this.onDown)
      this.el.removeEventListener("click", this.onClick)
      this.el.removeEventListener("mouseout", this.onOut)
    },
  },
}
