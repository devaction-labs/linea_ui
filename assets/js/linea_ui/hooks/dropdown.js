import {isTyping, runKey, wrap} from "../lib/keys.js"
import {closesOnSelect, extendBuffer, isTypeahead, matchIndex, submenuKey, submenuSide} from "../lib/menu_logic.js"
import {Floating} from "./popover.js"

const ITEM = '[role^="menuitem"]:not([aria-disabled="true"])'
const MENU = '[role="menu"]'
const HOVER_MS = 120

/**
 * `Dropdown`: the trigger toggles the menu; opened with the keyboard (Enter, Space, ↓ or ↑ on the trigger) the
 * focus goes to the first (or last) item. In the menu ↑ ↓ move round the items, Home and End go to the ends,
 * a letter jumps to the next item that starts with it, Esc closes and gives the focus back, Tab closes, a
 * click outside closes, and choosing an item closes the menu unless `data-close-on-select="false"`. Typing in
 * a field inside the menu (a search) is left alone.
 *
 * Submenus (`[data-submenu]`, with a `[data-submenu-trigger]` item and a nested `role="menu"`) open when the pointer
 * rests on their item, on click, and with → / Enter / Space (the focus moves in); ← and Esc close the submenu and
 * give the focus back to its item. Each menu's keys only move among its own items. A submenu opens on its
 * `data-placement` side, or the other when the screen has no room (`data-side`). Closing the dropdown closes them.
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
      this.onPick = (event) => this.pick(event)
      this.onHover = (event) => this.hover(event.target.closest(ITEM))
      trigger.addEventListener("click", this.onClick)
      trigger.addEventListener("keydown", this.onTriggerKey)
      this.panel().addEventListener("keydown", this.onMenuKey)
      this.panel().addEventListener("click", this.onPick)
      this.panel().addEventListener("mouseover", this.onHover)
    },

    updated() {
      this.updatedFloating()
    },

    destroyed() {
      clearTimeout(this.hoverTimer)
      this.destroyedFloating()
    },

    close(returnFocus) {
      clearTimeout(this.hoverTimer)
      this.panel()
        .querySelectorAll('[data-submenu][data-open="true"]')
        .forEach((submenu) => this.closeSubmenu(submenu))
      return Floating.close.call(this, returnFocus)
    },

    rootMenu() {
      return this.panel().querySelector(MENU)
    },

    menuOf(node) {
      return node?.closest(MENU) ?? this.rootMenu()
    },

    items(menu = this.rootMenu()) {
      return [...menu.querySelectorAll(ITEM)].filter((item) => item.closest(MENU) === menu)
    },

    focusItem(index, menu = this.rootMenu()) {
      const items = this.items(menu)
      items.at(index)?.focus({preventScroll: false})
    },

    openAt(index) {
      this.open()
      this.focusItem(index)
    },

    pick(event) {
      const item = event.target.closest(ITEM)
      const submenu = item?.matches("[data-submenu-trigger]") && item.closest("[data-submenu]")
      submenu
        ? (this.toggleSubmenu(submenu), event.detail === 0 && this.isSubmenuOpen(submenu) && this.focusItem(0, this.submenuMenu(submenu)))
        : item && closesOnSelect(this.el.dataset.closeOnSelect) && this.close(true)
    },

    hover(item) {
      clearTimeout(this.hoverTimer)
      item && (this.hoverTimer = setTimeout(() => this.hoverSettle(item), HOVER_MS))
    },

    hoverSettle(item) {
      const menu = this.menuOf(item)
      this.openSubmenusOf(menu)
        .filter((submenu) => !submenu.contains(item))
        .forEach((submenu) => this.closeSubmenu(submenu))
      const submenu = item.matches("[data-submenu-trigger]") && item.closest("[data-submenu]")
      submenu && this.openSubmenu(submenu)
    },

    openSubmenusOf(menu) {
      return [...menu.querySelectorAll('[data-submenu][data-open="true"]')].filter((submenu) => submenu.closest(MENU) === menu)
    },

    submenuTrigger(submenu) {
      return submenu.querySelector(":scope > [data-submenu-trigger]")
    },

    submenuMenu(submenu) {
      return submenu.querySelector(`:scope > [data-submenu-panel] > ${MENU}`)
    },

    isSubmenuOpen(submenu) {
      return submenu.dataset.open === "true"
    },

    toggleSubmenu(submenu) {
      this.isSubmenuOpen(submenu) ? this.closeSubmenu(submenu) : this.openSubmenu(submenu)
    },

    openSubmenu(submenu) {
      this.openSubmenusOf(this.menuOf(submenu)).filter((other) => other !== submenu).forEach((other) => this.closeSubmenu(other))
      submenu.dataset.open = "true"
      this.submenuTrigger(submenu)?.setAttribute("aria-expanded", "true")
      const anchor = submenu.getBoundingClientRect()
      const width = this.submenuMenu(submenu)?.offsetWidth ?? 0
      submenu.dataset.side = submenuSide(submenu.dataset.placement, anchor, width, window.innerWidth)
    },

    closeSubmenu(submenu) {
      submenu.querySelectorAll('[data-submenu][data-open="true"]').forEach((inner) => this.closeSubmenu(inner))
      submenu.dataset.open = "false"
      this.submenuTrigger(submenu)?.setAttribute("aria-expanded", "false")
    },

    menuKey(event) {
      const typing = isTyping(event.target)
      const menu = this.menuOf(event.target)
      const items = this.items(menu)
      const at = items.indexOf(document.activeElement)
      const go = (index) => () => (typing ? false : this.focusItem(index, menu))
      const nested = menu !== this.rootMenu()
      const onTrigger = !typing && event.target.matches?.("[data-submenu-trigger]")
      const action = submenuKey({key: event.key, onTrigger, nested})
      const submenu = {
        open: () => {
          const owner = event.target.closest("[data-submenu]")
          this.openSubmenu(owner)
          this.focusItem(0, this.submenuMenu(owner))
        },
        back: () => {
          const owner = menu.closest("[data-submenu]")
          this.closeSubmenu(owner)
          this.submenuTrigger(owner)?.focus({preventScroll: true})
        },
      }[action]
      const handled =
        (submenu && (event.preventDefault(), event.stopPropagation(), submenu(), true)) ||
        runKey(
          {
            ArrowDown: go(wrap(at, 1, items.length)),
            ArrowUp: go(wrap(at, -1, items.length)),
            Home: go(0),
            End: go(-1),
            Tab: () => (this.close(false), false),
          },
          event,
        )
      handled || typing || (isTypeahead(event) && this.typeahead(event, items, at, menu))
    },

    typeahead(event, items, at, menu) {
      const now = Date.now()
      this.typed = extendBuffer(this.typed ?? "", event.key, now - (this.typedAt ?? 0))
      this.typedAt = now
      const index = matchIndex(items.map((item) => item.textContent), at, this.typed)
      index >= 0 && this.focusItem(index, menu)
    },
  },
}
