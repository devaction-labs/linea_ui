import {fillQuery} from "../lib/autocomplete_logic.js"
import {keyName, runKey} from "../lib/keys.js"
import {ALL, assistantShown, emptyShown, isShortcut, move, route, settle, visibility} from "../lib/palette_logic.js"
import {runJS} from "./dialog.js"

/**
 * `CommandPalette`: the inside of the palette's modal. A text input (`[data-query]`), scope chips
 * (`[data-scope-chip]`) and a listbox of server-rendered items (`[data-item]`, grouped in `[data-group]`) that
 * the browser filters by scope and query. With `data-on-search` the query is pushed to the server (debounced) and
 * the items it renders are only filtered by scope. ↑ ↓ move the active row, Enter presses it, Ctrl+Enter opens it in
 * a new tab (a link in a new window, another item reports `new_tab`). The assistant row (`[data-assistant]`) shows
 * when the query has no match (or always, with `data-assistant-mode="always"`). Choosing a row closes the modal and
 * runs `data-on-select` with `%{id, value, new_tab}`; the assistant runs `data-on-assistant` with `%{id, query}`.
 * The modal's own hook handles Esc, the backdrop and focus; this one resets the palette each time the modal opens
 * and toggles it on the shortcut in `data-shortcut`.
 */
export default {
  "LineaUI.CommandPalette": {
    mounted() {
      this.query = ""
      this.scope = this.firstScope()
      this.active = 0
      this.modal = this.el.closest("[data-kind='modal']")

      this.onInput = (event) => event.target.matches("[data-query]") && this.typed(event.target.value)
      this.onKey = (event) => event.target.matches("[data-query]") && this.key(event)
      this.onClick = (event) => this.click(event)
      this.onMouseOver = (event) => {
        const row = event.target.closest("[data-item], [data-assistant]")
        row && this.setActive(this.rows().indexOf(row))
      }
      this.onShortcut = (event) => isShortcut(keyName(event), this.el.dataset.shortcut) && (event.preventDefault(), this.toggle())
      this.watcher = new MutationObserver(() => this.stateChanged())

      this.el.addEventListener("input", this.onInput)
      this.el.addEventListener("keydown", this.onKey)
      this.el.addEventListener("click", this.onClick)
      this.el.addEventListener("mouseover", this.onMouseOver)
      document.addEventListener("keydown", this.onShortcut)
      this.watcher.observe(this.modal, {attributes: true, attributeFilter: ["data-state"]})
      this.refresh()
    },

    updated() {
      this.refresh()
    },

    destroyed() {
      clearTimeout(this.searchTimer)
      this.watcher.disconnect()
      document.removeEventListener("keydown", this.onShortcut)
    },

    q(selector) {
      return this.el.querySelector(selector)
    },

    input() {
      return this.q("[data-query]")
    },

    local() {
      return !this.el.dataset.onSearch
    },

    chips() {
      return [...this.el.querySelectorAll("[data-scope-chip]")]
    },

    firstScope() {
      return this.chips()[0]?.dataset.scope ?? ALL
    },

    items() {
      return [...this.el.querySelectorAll("[data-item]")]
    },

    assistant() {
      return this.q("[data-assistant]")
    },

    rows() {
      const assistant = this.assistant()
      return [...this.items().filter((item) => !item.hidden), ...(assistant && !assistant.hidden ? [assistant] : [])]
    },

    toggle() {
      this.modal.dispatchEvent(new CustomEvent("linea:toggle"))
    },

    close() {
      this.modal.dispatchEvent(new CustomEvent("linea:close"))
    },

    stateChanged() {
      const open = this.modal.dataset.state === "open"
      open && this.reset()
      this.input().setAttribute("aria-expanded", String(open))
    },

    reset() {
      const searched = this.query !== ""
      this.query = ""
      this.scope = this.firstScope()
      this.active = 0
      this.input().value = ""
      this.refresh()
      searched && !this.local() && this.search()
    },

    typed(text) {
      this.query = text
      this.active = 0
      this.refresh()
      this.local() || this.search()
    },

    search() {
      clearTimeout(this.searchTimer)
      this.searchTimer = setTimeout(() => {
        const target = this.el.getAttribute("phx-target")
        this.pushEventTo(target || this.el, this.el.dataset.onSearch, {id: this.modal.id, query: this.query, scope: this.scope})
      }, Number(this.el.dataset.debounce || 0))
    },

    key(event) {
      const rows = this.rows()
      const go = (key) => () => this.setActive(move(this.active, key, rows.length))
      runKey(
        {
          ArrowDown: go("ArrowDown"),
          ArrowUp: go("ArrowUp"),
          Enter: () => this.choose(false),
          "Mod+Enter": () => this.choose(true),
        },
        event,
      )
    },

    click(event) {
      const chip = event.target.closest("[data-scope-chip]")
      const row = event.target.closest("[data-item], [data-assistant]")
      const action = (chip && (() => this.pickScope(chip))) || (row && (() => this.select(row, event.ctrlKey || event.metaKey)))
      action && action()
    },

    pickScope(chip) {
      this.scope = chip.dataset.scope
      this.active = 0
      this.refresh()
      this.local() || this.search()
      this.input().focus()
    },

    choose(newTab) {
      const row = this.rows()[this.active]
      const opens = {
        window: () => (window.open(row.getAttribute("href"), "_blank", "noopener"), this.select(row, true)),
        report: () => this.select(row, true),
        press: () => row.click(),
      }
      row && opens[route({href: row.getAttribute("href") ?? undefined, newTab})]()
      return Boolean(row)
    },

    select(row, newTab) {
      const assistant = row.matches("[data-assistant]")
      const handler = assistant ? this.el.dataset.onAssistant : this.el.dataset.onSelect
      const payload = assistant ? {id: this.modal.id, query: this.query.trim()} : {id: this.modal.id, value: row.dataset.value, new_tab: newTab}
      this.close()
      runJS(this, handler, payload)
    },

    setActive(index) {
      this.active = index
      this.paintActive()
    },

    paintActive() {
      const rows = this.rows()
      this.active = settle(this.active, rows.length)
      this.el.querySelectorAll("[role='option']").forEach((row) => row.setAttribute("aria-selected", "false"))
      const current = rows[this.active]
      const input = this.input()
      current ? (current.setAttribute("aria-selected", "true"), input.setAttribute("aria-activedescendant", current.id)) : input.removeAttribute("aria-activedescendant")
      current && current.scrollIntoView({block: "nearest"})
    },

    refresh() {
      const items = this.items()
      const flags = visibility(
        items.map((item) => ({scope: item.dataset.scope, text: item.dataset.text})),
        {scope: this.scope, query: this.query, local: this.local()},
      )
      items.forEach((item, index) => (item.hidden = !flags[index]))
      this.el.querySelectorAll("[data-group]").forEach((group) => {
        group.hidden = ![...group.querySelectorAll("[data-item]")].some((item) => !item.hidden)
      })
      this.chips().forEach((chip) => chip.setAttribute("aria-pressed", String(chip.dataset.scope === this.scope)))
      this.paintExtras(flags.filter(Boolean).length)
      this.paintActive()
    },

    paintExtras(matched) {
      const assistant = this.assistant()
      const offered = Boolean(assistant) && assistantShown({mode: this.el.dataset.assistantMode, query: this.query, matched})
      assistant && (assistant.hidden = !offered)
      assistant && (assistant.querySelector("[data-assistant-text]").textContent = fillQuery(assistant.dataset.template, this.query))
      this.q("[data-empty]").hidden = !emptyShown({matched, assistant: offered})
    },
  },
}
