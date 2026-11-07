import {markRow} from "../lib/action_menu_logic.js"
import Dropdown from "./dropdown.js"

const Base = Dropdown["LineaUI.Dropdown"]

/**
 * `ActionMenu`: the Dropdown's hook (trigger, placement and flip, keys, focus return, ARIA) plus the marking of the item
 * the actions belong to: while the menu is open its row (`[data-am-row]`, a `tr` or a card-table row) carries
 * `data-am-open`, which the CSS tints, and its button is pressed (`aria-expanded="true"`). It is cleared on close and when the menu is removed.
 */
export default {
  "LineaUI.ActionMenu": {
    ...Base,

    announce() {
      Base.announce.call(this)
      markRow(this.el, this.isOpen())
    },

    destroyed() {
      markRow(this.el, false)
      Base.destroyed.call(this)
    },
  },
}
