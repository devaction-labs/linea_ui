import {isTyping, runKey, wrap} from "../lib/keys.js"
import {closesOnSelect, extendBuffer, isTypeahead, matchIndex} from "../lib/menu_logic.js"
import {Floating} from "./popover.js"

const ITEM = '[role^="menuitem"]:not([aria-disabled="true"])'

/**
 * `Dropdown`: the trigger toggles the menu; opened with the keyboard (Enter, Space, ↓ or ↑ on the trigger) the
 * focus goes to the first (or last) item. In the menu ↑ ↓ move round the items, Home and End go to the ends,
 * a letter jumps to the next item that starts with it, Esc closes and gives the focus back, Tab closes, a
 * click outside closes, and choosing an item closes the menu unless `data-close-on-select="false"`. Typing in
 * a field inside the menu (a search) is left alone.
 */
export default {
  "LineaUI.Dropdown": {
    ...Floating,

    mounted() {
      this.setupFloating()
      const trigger = this.trigger()
      this.onClick = (event) => (this.toggle(), event.detail === 0 && this.isOpen() && this.focusItem(0))
      this.onTriggerKey = (event) =>
        runKey({ArrowDown: () => this.openAt(0), ArrowUp: () => this.openAt(-1)}, event)
      this.onMenuKey = (event) => this.menuKey(event)
      this.onPick = (event) => event.target.closest(ITEM) && closesOnSelect(this.el.dataset.closeOnSelect) && this.close(true)
      trigger.addEventListener("click", this.onClick)
      trigger.addEventListener("keydown", this.onTriggerKey)
      this.panel().addEventListener("keydown", this.onMenuKey)
      this.panel().addEventListener("click", this.onPick)
    },

    updated() {
      this.updatedFloating()
    },

    destroyed() {
      this.destroyedFloating()
    },

    items() {
      return [...this.panel().querySelectorAll(ITEM)]
    },

    focusItem(index) {
      const items = this.items()
      items.at(index)?.focus({preventScroll: false})
    },

    openAt(index) {
      this.open()
      this.focusItem(index)
    },

    menuKey(event) {
      const typing = isTyping(event.target)
      const items = this.items()
      const at = items.indexOf(document.activeElement)
      const go = (index) => () => (typing ? false : this.focusItem(index))
      const handled = runKey(
        {
          ArrowDown: go(wrap(at, 1, items.length)),
          ArrowUp: go(wrap(at, -1, items.length)),
          Home: go(0),
          End: go(-1),
          Tab: () => (this.close(false), false),
        },
        event,
      )
      handled || typing || (isTypeahead(event) && this.typeahead(event, items, at))
    },

    typeahead(event, items, at) {
      const now = Date.now()
      this.typed = extendBuffer(this.typed ?? "", event.key, now - (this.typedAt ?? 0))
      this.typedAt = now
      const index = matchIndex(items.map((item) => item.textContent), at, this.typed)
      index >= 0 && this.focusItem(index)
    },
  },
}
