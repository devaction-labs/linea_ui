/**
 * `LineaUI.Autocomplete`: a text input (`[data-query]`) over a list of server-rendered options. The hidden
 * `[data-value-input]` (named like the field, `phx-update="ignore"`) holds the value; a bubbling `input` fires from it
 * only when the value changes, and the visible input's own `input` events are stopped so `phx-change` runs once.
 * Without `data-on-search` the list filters itself; with it the query is pushed to the server (debounced) and a
 * loading row shows until the reply. A new `data-value` from the server wins over the browser's.
 */
import {notify} from "../lib/dom.js"
import {escapeHtml} from "../lib/date_picker_view.js"
import {highlight, moveIndex} from "../lib/select_box.js"
import {matches} from "../lib/text.js"
import {fillQuery, left, opens, picked, searchable, statusHtml, typed} from "../lib/autocomplete_logic.js"

const COMMANDS = ["open", "close", "toggle"]

const Autocomplete = {
  mounted() {
    this.server = this.el.dataset.value
    this.value = this.server
    this.label = this.el.dataset.label
    this.term = ""
    this.active = -1
    this.isOpen = false
    this.loading = false
    this.serial = 0

    this.onInput = (event) => event.target.matches("[data-query]") && (event.stopPropagation(), this.typed(event.target.value))
    this.onFocusIn = (event) => event.target.matches("[data-query]") && this.focus()
    this.onFocusOut = (event) => event.target.matches("[data-query]") && this.leave()
    this.onKeyDown = (event) => event.target.matches("[data-query]") && this.key(event)
    this.onPointerDown = (event) => event.target.closest("[data-dropdown], [data-clear]") && event.preventDefault()
    this.onClick = (event) => this.click(event)
    this.onMouseOver = (event) => {
      const row = event.target.closest("[data-dropdown] .option[data-selectable]")
      row && this.setActive(this.rows().indexOf(row))
    }
    this.onCommand = (event) => this[event.type.replace("linea:", "")]()
    this.onPushed = (event) => event.detail?.id && this.el.matches(event.detail.id) && this[event.type.replace("phx:linea:", "")]()

    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("focusin", this.onFocusIn)
    this.el.addEventListener("focusout", this.onFocusOut)
    this.el.addEventListener("keydown", this.onKeyDown)
    this.el.addEventListener("pointerdown", this.onPointerDown)
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("mouseover", this.onMouseOver)
    COMMANDS.forEach((name) => {
      this.el.addEventListener(`linea:${name}`, this.onCommand)
      window.addEventListener(`phx:linea:${name}`, this.onPushed)
    })
    this.refresh()
  },

  updated() {
    const incoming = this.el.dataset.value
    const changed = incoming !== this.server && incoming !== this.value
    this.server = incoming
    changed && this.adopt(incoming, this.el.dataset.label)
    this.writeHidden()
    this.refresh()
  },

  destroyed() {
    clearTimeout(this.searchTimer)
    COMMANDS.forEach((name) => window.removeEventListener(`phx:linea:${name}`, this.onPushed))
  },

  q(selector) {
    return this.el.querySelector(selector)
  },

  input() {
    return this.q("[data-query]")
  },

  freeText() {
    return this.el.dataset.freeText === "true"
  },

  local() {
    return !this.el.dataset.onSearch
  },

  threshold() {
    return Number(this.el.dataset.threshold || 0)
  },

  options() {
    return [...this.el.querySelectorAll("[data-dropdown] .option[data-value]")]
  },

  rows() {
    return this.options().filter((row) => row.dataset.selectable === "true" && !row.hidden)
  },

  adopt(value, label) {
    this.value = value
    this.label = label
    this.term = ""
    this.input().value = label
    this.writeHidden()
  },

  open() {
    const disabled = this.el.classList.contains("disabled")
    !disabled && ((this.isOpen = true), this.input().focus(), this.refresh())
  },

  close() {
    this.isOpen = false
    this.active = -1
    this.refresh()
  },

  toggle() {
    this.isOpen ? this.close() : this.open()
  },

  focus() {
    this.el.classList.add("focus", "input-active")
    const wanted = opens({query: this.term, threshold: this.threshold(), onFocus: this.el.dataset.openOnFocus === "true", focusing: true})
    wanted && ((this.isOpen = true), this.refresh())
  },

  leave() {
    this.el.classList.remove("focus", "input-active")
    const next = left(this.input().value, {value: this.value, label: this.label, freeText: this.freeText()})
    this.term = ""
    this.input().value = next.text
    next.value === "" && (this.label = "")
    this.change(next.value)
    this.close()
  },

  click(event) {
    const clear = event.target.closest("[data-clear]")
    const row = event.target.closest("[data-dropdown] .option[data-selectable]")
    const control = event.target.closest(".ts-control")
    const action =
      (clear && (() => this.clear())) ||
      (row && (() => this.pick(row))) ||
      (control && (() => this.input().focus()))
    action && (event.stopPropagation(), action())
  },

  clear() {
    this.term = ""
    this.label = ""
    this.input().value = ""
    this.change("")
    this.input().focus()
  },

  key(event) {
    const rows = this.rows()
    const handlers = {
      ArrowDown: () => (this.isOpen ? this.setActive(moveIndex(this.active, "ArrowDown", rows.length)) : this.open()),
      ArrowUp: () => this.setActive(moveIndex(this.active, "ArrowUp", rows.length)),
      Enter: () => rows[this.active] && this.pick(rows[this.active]),
      Escape: () => this.escape(),
    }
    const picks = event.key === "Enter" && this.isOpen && rows[this.active]
    const prevents = ["ArrowDown", "ArrowUp", "Escape"].includes(event.key) || picks
    prevents && event.preventDefault()
    handlers[event.key]?.()
  },

  escape() {
    const restore = !this.freeText() && this.isOpen
    restore && ((this.term = ""), (this.input().value = this.label))
    this.close()
  },

  typed(text) {
    const next = typed(text, {value: this.value, freeText: this.freeText()})
    this.term = text
    this.active = -1
    this.isOpen = opens({query: text, threshold: this.threshold(), focusing: false})
    this.change(next.value)
    this.local() ? this.refresh() : this.search(text)
  },

  search(query) {
    clearTimeout(this.searchTimer)
    const wanted = searchable(query, this.threshold())
    this.loading = wanted
    this.refresh()
    wanted &&
      (this.searchTimer = setTimeout(() => {
        const target = this.el.getAttribute("phx-target")
        const serial = ++this.serial
        this.pushEventTo(target || this.el, this.el.dataset.onSearch, {id: this.el.id, query}, () => {
          serial === this.serial && ((this.loading = false), this.refresh())
        })
      }, Number(this.el.dataset.debounce || 0)))
  },

  pick(row) {
    const next = picked({value: row.dataset.value, label: row.dataset.label}, this.freeText())
    this.label = row.dataset.label
    this.term = ""
    this.input().value = next.text
    this.change(next.value)
    this.close()
  },

  change(value) {
    const changed = value !== this.value
    this.value = value
    this.writeHidden()
    this.el.classList.toggle("has-items", value !== "")
    changed && notify(this.q("[data-value-input]"))
  },

  writeHidden() {
    const hidden = this.q("[data-value-input]")
    hidden.value !== this.value && (hidden.value = this.value)
  },

  setActive(index) {
    this.active = index
    this.paintActive()
  },

  paintActive() {
    const rows = this.rows()
    rows.forEach((row, index) => row.classList.toggle("active", index === this.active))
    const current = rows[this.active]
    const input = this.input()
    current ? input.setAttribute("aria-activedescendant", current.id) : input.removeAttribute("aria-activedescendant")
    current && current.scrollIntoView({block: "nearest"})
  },

  refresh() {
    const term = this.local() ? this.term : ""
    this.options().forEach((row) => {
      const chosen = row.dataset.value === this.value && this.value !== ""
      const text = row.querySelector("[data-text]")
      row.hidden = this.loading || !matches(row.dataset.label, term)
      row.classList.toggle("selected", chosen)
      row.setAttribute("aria-selected", String(chosen))
      text && (text.innerHTML = this.marked(row.dataset.label))
    })
    this.el.querySelectorAll("[data-dropdown] [data-group]").forEach((group) => {
      group.hidden = ![...group.querySelectorAll(".option")].some((row) => !row.hidden)
    })
    const rows = this.rows()
    this.active = this.active >= 0 && this.active < rows.length ? this.active : -1
    this.paintStatus(rows)
    this.paintActive()
    this.paintOpen(rows)
  },

  marked(label) {
    return highlight(label, this.term)
      .map(({text, hit}) => (hit ? `<span class="highlight">${escapeHtml(text)}</span>` : escapeHtml(text)))
      .join("")
  },

  paintStatus(rows) {
    const status = this.q("[data-status]")
    const loading = this.loading && this.q("[data-loading]").textContent
    const empty = !this.loading && rows.length === 0 && this.term.trim() !== "" && fillQuery(this.q("[data-no-results]").textContent, this.term)
    const message = loading || empty
    const kind = loading ? "loading" : "no-results"
    const html = statusHtml(kind, message, escapeHtml)
    status.innerHTML !== html && (status.innerHTML = html)
    this.q("[data-listbox]").setAttribute("aria-busy", String(Boolean(loading)))
  },

  paintOpen(rows) {
    const dropdown = this.q("[data-dropdown]")
    const hasContent = rows.length > 0 || this.q("[data-status]").childElementCount > 0
    const shown = this.isOpen && hasContent
    dropdown.hidden = !shown
    this.el.classList.toggle("dropdown-active", shown)
    this.input().setAttribute("aria-expanded", String(shown))
  },
}

export default {"LineaUI.Autocomplete": Autocomplete}
