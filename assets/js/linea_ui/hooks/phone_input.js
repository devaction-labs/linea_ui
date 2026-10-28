/**
 * `LineaUI.PhoneInput`: the visible input (`[data-display]`, no name) shows the number in the national format of the
 * selected country; the hidden `[data-value-input]` (named like the field, `phx-update="ignore"`) holds the E.164
 * number and fires a bubbling `input` only when it changes, while the `input` events of the visible input and of the
 * picker's search are stopped so `phx-change` runs once. The picker button opens a searchable list of countries built
 * from `phone_countries.js`; an international number typed or pasted switches the country. A new `data-value` or
 * `data-country` from the server wins; a patch that did not change them keeps what is in the browser.
 */
import {notify} from "../lib/dom.js"
import {escapeHtml} from "../lib/date_picker_view.js"
import {fillQuery} from "../lib/autocomplete_logic.js"
import {runKey} from "../lib/keys.js"
import {caretFor, dropBefore, significantBefore} from "../lib/mask_logic.js"
import {moveIndex} from "../lib/select_box.js"
import {COUNTRIES, byIso, flag} from "../lib/phone_countries.js"
import {arrange, dialLabel, initialCountry, markHtml, nameOf, resolve, restrict, search} from "../lib/phone_logic.js"

const codes = (text) => (text ?? "").split(",").filter((code) => code !== "")

const PhoneInput = {
  mounted() {
    this.read()
    this.country = initialCountry(this.el.dataset.country, this.pool, this.first)
    this.server = {country: this.el.dataset.country, value: this.el.dataset.value ?? ""}
    this.value = this.server.value
    this.national = this.value.startsWith(`+${this.country.code}`) ? this.value.slice(this.country.code.length + 1) : ""
    this.shown = this.input().value
    this.term = ""
    this.active = -1
    this.isOpen = false

    this.onInput = (event) => this.route(event, {"[data-display]": () => this.typed(event), "[data-search]": () => this.searched(event)})
    this.onPaste = (event) => event.target.matches("[data-display]") && this.pasted(event)
    this.onClick = (event) => this.click(event)
    this.onKeyDown = (event) => this.route(event, {"[data-search]": () => this.searchKey(event), "[data-picker]": () => this.pickerKey(event)})
    this.onPointerDown = (event) => event.target.closest("[data-dropdown], [data-picker], [data-clear]") && !event.target.closest("[data-search]") && event.preventDefault()
    this.onMouseOver = (event) => {
      const row = event.target.closest(".option[data-iso]")
      row && this.setActive(this.rows().indexOf(row))
    }
    this.onFocusIn = (event) => this.isOpen && event.target.matches("[data-display]") && this.close()
    this.onFocusOut = (event) => this.isOpen && !this.el.contains(event.relatedTarget) && this.close()

    this.listeners().forEach(([type, handler]) => this.el.addEventListener(type, handler))
    this.paint()
  },

  updated() {
    this.read()
    const country = this.el.dataset.country
    const value = this.el.dataset.value ?? ""
    const valueChanged = value !== this.server.value && value !== this.value
    const countryChanged = country !== this.server.country && country !== this.country.iso
    this.server = {country, value}
    ;(valueChanged || countryChanged) && this.adopt(country, value)
    this.input().value !== this.shown && (this.input().value = this.shown)
    this.paint()
  },

  destroyed() {
    this.listeners().forEach(([type, handler]) => this.el.removeEventListener(type, handler))
  },

  listeners() {
    return [
      ["input", this.onInput],
      ["paste", this.onPaste],
      ["click", this.onClick],
      ["keydown", this.onKeyDown],
      ["pointerdown", this.onPointerDown],
      ["mouseover", this.onMouseOver],
      ["focusin", this.onFocusIn],
      ["focusout", this.onFocusOut],
    ]
  },

  route(event, table) {
    const selector = Object.keys(table).find((candidate) => event.target.matches(candidate))
    selector && table[selector]()
  },

  q(selector) {
    return this.el.querySelector(selector)
  },

  input() {
    return this.q("[data-display]")
  },

  hidden() {
    return this.q("[data-value-input]")
  },

  searchInput() {
    return this.q("[data-search]")
  },

  rows() {
    return [...this.el.querySelectorAll("[data-list] .option[data-iso]")]
  },

  read() {
    const data = this.el.dataset
    const pool = restrict(COUNTRIES, {only: codes(data.only), except: codes(data.except)})
    this.locale = data.locale || "en"
    this.flags = data.flags === "true"
    this.pool = pool.length > 0 ? pool : COUNTRIES
    this.first = codes(data.order)
    this.listed = arrange(this.pool, {locale: this.locale, first: this.first})
  },

  resolve(text, refine = true) {
    return resolve(text, this.country, {pool: this.pool, refine})
  },

  adopt(iso, value) {
    this.country = initialCountry(iso, this.pool, this.first)
    const result = this.resolve(value, false)
    this.show(result)
    this.national = result.national
    this.value = result.value
  },

  typed(event) {
    event.stopPropagation()
    const input = this.input()
    const text = input.value
    const caret = input.selectionStart ?? text.length
    const deleted = event.inputType === "deleteContentBackward" && this.resolve(text).display === this.shown
    const edit = deleted ? dropBefore(text, caret) : {text, position: caret}
    const result = this.resolve(edit.text)
    this.show(result, edit)
    this.commit(result)
  },

  pasted(event) {
    const text = event.clipboardData?.getData("text") ?? ""
    const international = text.trim().startsWith("+")
    const result = international ? this.resolve(text) : null
    result && (event.preventDefault(), this.show(result), this.commit(result))
  },

  show(result, edit = null) {
    const input = this.input()
    const assigned = input.value !== result.display
    assigned && (input.value = result.display)
    this.shown = result.display
    const placed = edit !== null && assigned && document.activeElement === input
    placed && this.place(edit.position >= edit.text.length ? result.display.length : caretFor(result.display, significantBefore(edit.text, edit.position)))
  },

  place(position) {
    try {
      this.input().setSelectionRange(position, position)
    } catch (_error) {
      return
    }
  },

  commit(result) {
    const switched = result.country.iso !== this.country.iso
    const changed = result.value !== this.value
    this.country = result.country
    this.national = result.national
    this.value = result.value
    this.writeHidden()
    this.paint()
    switched && this.announce()
    changed && notify(this.hidden())
  },

  announce() {
    const event = this.el.dataset.onCountryChange
    const target = this.el.getAttribute("phx-target")
    event && this.pushEventTo(target || this.el, event, {id: this.input().id, country: this.country.iso, code: this.country.code})
  },

  writeHidden() {
    const hidden = this.hidden()
    hidden.value !== this.value && (hidden.value = this.value)
  },

  paint() {
    const button = this.q("[data-picker]")
    const clear = this.q("[data-clear]")
    const disabled = this.input().disabled
    this.writeHidden()
    this.flags ? (this.q("[data-flag]").textContent = flag(this.country.iso)) : (this.q("[data-iso-code]").textContent = this.country.iso)
    this.q("[data-code]").textContent = `+${this.country.code}`
    button.setAttribute("aria-label", `${this.el.dataset.pickerLabel}: ${nameOf(this.country, this.locale)} +${this.country.code}`)
    button.disabled = disabled
    clear && (clear.hidden = this.shown === "")
    clear && (clear.disabled = disabled)
  },

  click(event) {
    const target = event.target
    const row = target.closest(".option[data-iso]")
    const inside = target.closest("[data-dropdown]") && !target.closest("[data-search]")
    inside && event.preventDefault()
    const action =
      (row && (() => this.choose(byIso(row.dataset.iso)))) ||
      (target.closest("[data-picker]") && (() => (this.isOpen ? this.close() : this.open()))) ||
      (target.closest("[data-clear]") && (() => this.clear()))
    action && action()
  },

  choose(country) {
    const result = resolve(this.national, country, {pool: this.pool, refine: false})
    this.show(result)
    this.commit(result)
    this.close()
    this.input().focus()
  },

  clear() {
    const result = this.resolve("")
    this.show(result)
    this.commit(result)
    this.input().focus()
  },

  open() {
    const blocked = this.q("[data-picker]").disabled || this.isOpen
    blocked || ((this.isOpen = true), (this.term = ""), (this.searchInput().value = ""), this.paintOpen(), this.renderList(), this.searchInput().focus())
  },

  close(refocus = false) {
    this.isOpen = false
    this.paintOpen()
    refocus && this.q("[data-picker]").focus()
  },

  paintOpen() {
    this.q("[data-dropdown]").hidden = !this.isOpen
    this.q("[data-picker]").setAttribute("aria-expanded", String(this.isOpen))
  },

  searched(event) {
    event.stopPropagation()
    this.term = this.searchInput().value
    this.renderList()
  },

  renderList() {
    const matches = search(this.listed, this.term, this.locale)
    const empty = `<div class="no-results">${escapeHtml(fillQuery(this.q("[data-no-results]").textContent, this.term))}</div>`
    this.q("[data-list]").innerHTML = matches.length > 0 ? matches.map((country) => this.rowHtml(country)).join("") : empty
    this.active = this.term.trim() === "" ? matches.findIndex((country) => country.iso === this.country.iso) : matches.length > 0 ? 0 : -1
    this.paintActive()
  },

  rowHtml(country) {
    const chosen = country.iso === this.country.iso
    return (
      `<div class="option${chosen ? " selected" : ""}" role="option" id="${this.el.id}-opt-${country.iso}" data-iso="${country.iso}" data-selectable="true" aria-selected="${chosen}">` +
      markHtml(country, this.flags) +
      `<span class="min-w-0 flex-1 truncate">${escapeHtml(nameOf(country, this.locale))}</span>` +
      `<span class="shrink-0 font-inter text-xs-plus text-slate-400 dark:text-navy-300">${escapeHtml(dialLabel(country))}</span>` +
      `</div>`
    )
  },

  searchKey(event) {
    const count = this.rows().length
    runKey(
      {
        ArrowDown: () => this.setActive(moveIndex(this.active, "ArrowDown", count)),
        ArrowUp: () => this.setActive(moveIndex(this.active, "ArrowUp", count)),
        Enter: () => this.rows()[this.active] && this.choose(byIso(this.rows()[this.active].dataset.iso)),
        Escape: () => (event.stopPropagation(), this.close(true)),
        Tab: () => (this.close(), false),
      },
      event,
    )
  },

  pickerKey(event) {
    runKey({ArrowDown: () => this.open(), ArrowUp: () => this.open()}, event)
  },

  setActive(index) {
    this.active = index
    this.paintActive()
  },

  paintActive() {
    const rows = this.rows()
    const current = rows[this.active]
    rows.forEach((row, index) => row.classList.toggle("active", index === this.active))
    current ? this.searchInput().setAttribute("aria-activedescendant", current.id) : this.searchInput().removeAttribute("aria-activedescendant")
    current && current.scrollIntoView({block: "nearest"})
  },
}

export default {"LineaUI.PhoneInput": PhoneInput}
