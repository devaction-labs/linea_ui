import {clearsOnEscape} from "../lib/bulk_bar_logic.js"

/**
 * `BulkBar`: Esc presses the bar's close button, which clears the selection. An Escape that closes an open list
 * (the field's listbox) is left to that list.
 */
export default {
  "LineaUI.BulkBar": {
    mounted() {
      this.onKey = (event) => {
        const listOpen = this.el.querySelector(".dropdown-active, [data-dropdown]:not([hidden])") !== null
        clearsOnEscape(event, {listOpen}) && this.el.querySelector("[data-bulk-clear]")?.click()
      }
      document.addEventListener("keydown", this.onKey)
    },

    destroyed() {
      document.removeEventListener("keydown", this.onKey)
    },
  },
}
