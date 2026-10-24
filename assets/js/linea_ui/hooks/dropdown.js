import {notify} from "../lib/dom.js"
import {isTyping, runKey, wrap} from "../lib/keys.js"
import {checkedTotal, choiceState, closesOnSelect, extendBuffer, isTypeahead, keepsSubmenus, matchIndex, serverChoice, submenuKey, submenuSide} from "../lib/menu_logic.js"
import {Floating} from "./popover.js"

const ITEM = '[role^="menuitem"]:not([aria-disabled="true"])'
const MENU = '[role="menu"]'
const CHOICE = '[role="menuitemcheckbox"], [role="menuitemradio"]'
const HOVER_MS = 120
const FOCUS_FRAMES = 12

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
 *
 * An item's `transition-all` keeps it `visibility: hidden` for the first frame of the menu's entrance, when
 * `focus()` is refused, so when the focus did not take it is given again on the next frames, until it does (at most `FOCUS_FRAMES`).
 * A filter menu: `menuitemcheckbox` and `menuitemradio` items flip their `aria-checked` when chosen and leave the menu open
 * (a radio unchecks the others of its `data-group`). One with a `name` has a real input beside it that follows the state
 * and fires a bubbling `input` event, so the surrounding form's `phx-change` hears it. A new `data-server-checked` from the
 * server wins; a patch that did not change it keeps what was chosen in the browser. A submenu's `[data-submenu-count]` shows
 * how many of its checkboxes are checked. The footer's buttons are `data-menu-action`: `clear` unchecks every checkbox,
 * `apply` closes the menu (the button's own `phx-click` or form submit runs as usual). `data-keep-submenus="true"` leaves
 * open submenus open when the pointer moves to another item.
 */
export default {
  "LineaUI.Dropdown": {
    ...Floating,

    mounted() {
      this.setupFloating()
      this.known = new WeakMap()
      this.choices().forEach((item) => this.known.set(item, item.dataset.serverChecked))
      this.syncCounts()
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
      this.applyServer()
      this.syncCounts()
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
      const item = this.items(menu).at(index)
      item?.focus({preventScroll: false})
      const retry = (frames) => {
        const pending = this.isOpen() && document.activeElement !== item
        pending && item.focus({preventScroll: true})
        pending && document.activeElement !== item && frames > 0 && requestAnimationFrame(() => retry(frames - 1))
      }
      item && document.activeElement !== item && requestAnimationFrame(() => retry(FOCUS_FRAMES))
    },

    openAt(index) {
      this.open()
      this.focusItem(index)
    },

    pick(event) {
      const action = event.target.closest("[data-menu-action]")
      const item = event.target.closest(ITEM)
      const submenu = item?.matches("[data-submenu-trigger]") && item.closest("[data-submenu]")
      const steps = [
        [action?.dataset.menuAction === "clear", () => this.clearChecks()],
        [action?.dataset.menuAction === "apply", () => action.dataset.closeOnApply !== "false" && this.close(true)],
        [Boolean(submenu), () => (this.toggleSubmenu(submenu), event.detail === 0 && this.isSubmenuOpen(submenu) && this.focusItem(0, this.submenuMenu(submenu)))],
        [item?.matches(CHOICE), () => this.choose(item)],
        [Boolean(item), () => closesOnSelect(this.el.dataset.closeOnSelect) && this.close(true)],
      ]
      steps.find(([hit]) => hit)?.[1]()
    },

    choices() {
      return [...this.panel().querySelectorAll(CHOICE)]
    },

    inputOf(item) {
      return item.parentElement.querySelector(":scope > [data-choice-input]")
    },

    isChecked(item) {
      return item.getAttribute("aria-checked") === "true"
    },

    setChecked(item, on) {
      item.setAttribute("aria-checked", String(on))
      const input = this.inputOf(item)
      input && (input.checked = on)
      return input
    },

    choose(item) {
      const role = item.getAttribute("role")
      const before = this.isChecked(item)
      const next = choiceState(role, before)
      role === "menuitemradio" && this.uncheckGroup(item)
      const input = this.setChecked(item, next)
      this.syncCounts()
      next !== before && input && notify(input)
    },

    uncheckGroup(item) {
      this.choices()
        .filter((other) => other !== item && other.getAttribute("role") === "menuitemradio" && other.dataset.group === item.dataset.group && this.menuOf(other) === this.menuOf(item))
        .forEach((other) => this.setChecked(other, false))
    },

    clearChecks() {
      const inputs = this.choices()
        .filter((item) => item.getAttribute("role") === "menuitemcheckbox" && this.isChecked(item))
        .map((item) => this.setChecked(item, false))
      this.syncCounts()
      const first = inputs.find(Boolean)
      first && notify(first)
    },

    applyServer() {
      this.choices().forEach((item) => {
        const next = serverChoice({server: item.dataset.serverChecked, previous: this.known.get(item)})
        this.known.set(item, item.dataset.serverChecked)
        next !== null && this.setChecked(item, next === "true")
      })
    },

    syncCounts() {
      this.panel().querySelectorAll("[data-submenu]").forEach((submenu) => {
        const badge = this.submenuTrigger(submenu)?.querySelector("[data-submenu-count]")
        const menu = this.submenuMenu(submenu)
        const states = [...menu.querySelectorAll('[role="menuitemcheckbox"]')].filter((item) => item.closest(MENU) === menu).map((item) => item.getAttribute("aria-checked"))
        const total = checkedTotal(states)
        badge && ((badge.textContent = String(total)), (badge.hidden = total === 0))
      })
    },

    hover(item) {
      clearTimeout(this.hoverTimer)
      item && (this.hoverTimer = setTimeout(() => this.hoverSettle(item), HOVER_MS))
    },

    hoverSettle(item) {
      const menu = this.menuOf(item)
      keepsSubmenus(this.el.dataset.keepSubmenus) ||
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
