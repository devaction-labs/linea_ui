/**
 * The listbox of `<.select>` and `<.tags_input>`, in tom-select's shape: chips and a search input in the
 * control, a dropdown of options under it, a hidden `<select>` that the form submits. The server renders the
 * options and the chips it knows; the hook keeps the choice, filters, creates and tells the form.
 */
import {canCreate} from "../lib/listbox_logic.js"
import {fillQuery} from "../lib/autocomplete_logic.js"
import {notify} from "../lib/dom.js"
import {choose, highlight, isFull, moveIndex, removeLast, removeValue, sameValues, shows, splitTags} from "../lib/select_box.js"
import {escapeHtml} from "../lib/date_picker_view.js"

const COMMANDS = ["open", "close", "toggle"]

/** The width kept for typing in a pillbox that has chips. */
const MIN_INPUT_PX = 48

const readValues = (el) => JSON.parse(el.dataset.value || "[]")

export const Listbox = {
  mounted() {
    this.values = readValues(this.el)
    this.server = this.el.dataset.value
    this.term = ""
    this.active = -1
    this.isOpen = false
    this.serial = 0
    this.remembered = new Map()
    this.el.querySelectorAll(".ts-control [data-ts-item]").forEach((chip) =>
      this.remembered.set(chip.dataset.value, {label: chip.firstChild?.textContent?.trim() || chip.dataset.value, chip: chip.cloneNode(true)}),
    )

    this.onClick = (event) => this.click(event)
    this.onPointerDown = (event) =>
      event.target.closest("[data-dropdown], [data-clear], [data-remove]") && !event.target.closest("[data-panel-search]") && event.preventDefault()
    this.onFocusIn = (event) => event.target.matches("[data-search]") && this.focus(event.target)
    this.onFocusOut = (event) => event.target.matches("[data-search]") && !this.el.contains(event.relatedTarget) && this.blur()
    this.onInput = (event) => event.target.matches("[data-search]") && this.typed(event.target.value)
    this.onKeyDown = (event) => event.target.matches("[data-search]") && this.key(event)
    this.onMouseOver = (event) => {
      const row = event.target.closest("[data-selectable], .create")
      row && this.setActive(this.rows().indexOf(row))
    }
    this.onCommand = (event) => this[event.type.replace("linea:", "")]()
    this.onPushed = (event) => event.detail?.id && this.el.matches(event.detail.id) && this[event.type.replace("phx:linea:", "")]()

    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("pointerdown", this.onPointerDown)
    this.el.addEventListener("focusin", this.onFocusIn)
    this.el.addEventListener("focusout", this.onFocusOut)
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("keydown", this.onKeyDown)
    this.el.addEventListener("mouseover", this.onMouseOver)
    COMMANDS.forEach((name) => {
      this.el.addEventListener(`linea:${name}`, this.onCommand)
      window.addEventListener(`phx:linea:${name}`, this.onPushed)
    })
    this.refresh()
    this.watchFit()
  },

  updated() {
    const incoming = this.el.dataset.value
    const next = readValues(this.el)
    const changed = incoming !== this.server && !sameValues(next, this.values)
    this.server = incoming
    changed && ((this.values = next), this.renderChips(), this.writeInput())
    this.refresh()
  },

  destroyed() {
    clearTimeout(this.searchTimer)
    this.fitObserver?.disconnect()
    COMMANDS.forEach((name) => window.removeEventListener(`phx:linea:${name}`, this.onPushed))
  },

  q(selector) {
    return this.el.querySelector(selector)
  },

  control() {
    return this.q(".ts-control [data-search]")
  },

  input() {
    return this.q("[data-panel-search]") ?? this.control()
  },

  searchMode() {
    return this.el.dataset.searchMode ?? "control"
  },

  typesInControl() {
    return this.searchMode() === "control"
  },

  multiple() {
    return this.el.dataset.multiple === "true"
  },

  max() {
    return this.el.dataset.max ? Number(this.el.dataset.max) : null
  },

  local() {
    return !this.el.dataset.onSearch
  },

  options() {
    return [...this.el.querySelectorAll("[data-dropdown] .option[data-value]")]
  },

  rows() {
    return [...this.el.querySelectorAll("[data-dropdown] .create, [data-dropdown] .option[data-selectable]")].filter(
      (row) => !row.hidden,
    )
  },

  labelOf(value) {
    const option = this.options().find((row) => row.dataset.value === value)
    return option?.dataset.label ?? this.remembered.get(value)?.label ?? value
  },

  template(value) {
    return [...this.el.querySelectorAll("[data-templates] template")].find((t) => t.dataset.value === value)
  },

  remember(value) {
    const template = this.template(value)
    const chip = template && template.content.firstElementChild.cloneNode(true)
    this.remembered.set(value, {label: this.labelOf(value), chip})
  },

  open() {
    const disabled = this.el.classList.contains("disabled") || isFull(this.values.length, this.multiple(), this.max()) && this.multiple()
    !disabled && ((this.isOpen = true), this.refresh(), this.input().focus())
  },

  close() {
    const inPanel = this.q("[data-dropdown]").contains(document.activeElement)
    this.isOpen = false
    this.active = -1
    this.refresh()
    inPanel && this.control().focus()
  },

  toggle() {
    this.isOpen ? this.close() : this.open()
  },

  focus(target) {
    this.el.classList.add("focus", "input-active")
    ;(this.typesInControl() || target !== this.control()) && this.open()
  },

  blur() {
    this.el.classList.remove("focus", "input-active")
    this.setTerm("")
    this.close()
  },

  click(event) {
    const remove = event.target.closest("[data-remove]")
    const clear = event.target.closest("[data-clear]")
    const row = event.target.closest("[data-dropdown] [data-selectable], [data-dropdown] .create")
    const control = event.target.closest(".ts-control")
    const action =
      (remove && (() => this.remove(remove.closest("[data-ts-item]").dataset.value))) ||
      (clear && (() => this.change([]))) ||
      (row && (() => this.pickRow(row))) ||
      (control && (() => (this.isOpen && !this.typesInControl() ? this.close() : this.open())))
    action && (event.preventDefault(), event.stopPropagation(), action())
  },

  key(event) {
    const rows = this.rows()
    const handlers = {
      ArrowDown: () => (this.isOpen ? this.setActive(moveIndex(this.active, "ArrowDown", rows.length)) : this.open()),
      ArrowUp: () => this.setActive(moveIndex(this.active, "ArrowUp", rows.length)),
      Enter: () => (!this.isOpen ? this.open() : rows[this.active] ? this.pickRow(rows[this.active]) : this.createTyped()),
      " ": () => !this.typesInControl() && !this.isOpen && this.open(),
      Escape: () => this.close(),
      Tab: () => this.el.dataset.mode === "tags" && this.term.trim() && this.createTyped(),
      Backspace: () => this.erases() && this.backspace(),
    }
    const handler = handlers[event.key]
    const prevents =
      ["ArrowDown", "ArrowUp", "Enter", "Escape"].includes(event.key) ||
      (event.key === "Backspace" && this.erases()) ||
      (event.key === " " && !this.typesInControl())
    prevents && event.preventDefault()
    handler && handler()
  },

  erases() {
    return this.typesInControl() && this.input().value === "" && this.values.length > 0
  },

  typed(text) {
    const tags = this.el.dataset.mode === "tags" && this.el.dataset.create === "true"
    const {done, rest} = tags ? splitTags(text) : {done: [], rest: text}
    done.forEach((tag) => this.create(tag))
    done.length > 0 && (this.input().value = rest)
    this.term = rest
    this.isOpen = true
    this.active = -1
    this.el.classList.toggle("input-hidden", this.hidesControl(rest))
    this.local() ? this.refresh() : this.search(rest)
  },

  search(query) {
    clearTimeout(this.searchTimer)
    this.searchTimer = setTimeout(() => {
      const target = this.el.getAttribute("phx-target")
      this.pushEventTo(target || this.el, this.el.dataset.onSearch, {id: this.el.id, query})
    }, Number(this.el.dataset.debounce || 0))
    this.refresh()
  },

  hidesControl(text) {
    return !this.multiple() && this.values.length > 0 && (text === "" || !this.typesInControl())
  },

  setTerm(text) {
    this.term = text
    this.input() && (this.input().value = text)
  },

  backspace() {
    const {values, removed} = removeLast(this.values)
    const restore = this.el.dataset.restore === "true"
    const label = this.labelOf(removed)
    this.dropCreated(removed)
    this.change(values)
    restore && (this.setTerm(label), this.typed(label))
  },

  pickRow(row) {
    row.classList.contains("create") ? this.createTyped() : this.pick(row.dataset.value)
  },

  pick(value) {
    this.remember(value)
    this.setTerm("")
    this.change(choose(this.values, value, {multiple: this.multiple(), max: this.max()}))
    !this.multiple() && this.close()
    isFull(this.values.length, this.multiple(), this.max()) && this.multiple() && this.close()
  },

  createTyped() {
    const term = this.term.trim()
    const labels = this.options().map((row) => row.dataset.label)
    const known = this.options().find((row) => row.dataset.label.toLowerCase() === term.toLowerCase())
    this.el.dataset.create === "true" && term && canCreate(term, labels) ? this.create(term) : known && this.pick(known.dataset.value)
  },

  create(term) {
    const full = isFull(this.values.length, this.multiple(), this.max()) && this.multiple()
    const exists = this.options().some((row) => row.dataset.value === term)
    !full && !exists && this.q("[data-extra]").insertAdjacentHTML("beforeend", this.createdOption(term))
    !full && this.pick(term)
  },

  createdOption(term) {
    this.serial += 1
    const text = escapeHtml(term)
    return `<div class="option" role="option" id="${this.el.id}-new-${this.serial}" data-value="${text}" data-label="${text}" data-selectable="true" data-created aria-selected="false"><span data-text>${text}</span></div>`
  },

  dropCreated(value) {
    const created = this.options().find((row) => row.dataset.value === value && row.hasAttribute("data-created"))
    this.el.dataset.persist === "false" && created && created.remove()
  },

  remove(value) {
    this.dropCreated(value)
    this.change(removeValue(this.values, value))
  },

  change(values) {
    const changed = !sameValues(values, this.values)
    this.values = values
    this.renderChips()
    this.writeInput()
    this.refresh()
    changed && notify(this.q("[data-input]"))
  },

  renderChips() {
    const control = this.q(".ts-control")
    control.querySelectorAll("[data-ts-item]").forEach((chip) => chip.remove())
    const input = this.control()
    this.values.forEach((value) => input.insertAdjacentElement("beforebegin", this.chip(value)))
    this.fit()
  },

  counts() {
    return this.multiple() && this.el.dataset.overflow === "count"
  },

  watchFit() {
    if (!this.counts() || typeof ResizeObserver === "undefined") return
    this.fitObserver = new ResizeObserver(() => this.fit())
    this.fitObserver.observe(this.q(".ts-control"))
    this.fit()
  },

  /** Pillbox: keep the chips that fit on the one line and sum the rest up in a `+N` chip. */
  fit() {
    if (!this.counts()) return
    const control = this.q(".ts-control")
    const input = this.control()
    const chips = [...control.querySelectorAll("[data-ts-item]")]
    const badge = this.badge(control, input)
    chips.forEach((chip) => (chip.hidden = false))
    badge.hidden = true
    const style = getComputedStyle(control)
    const clear = control.querySelector(".clear-button")
    const room =
      control.clientWidth - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight) -
      (parseFloat(style.getPropertyValue("--ts-pr-caret")) || 0) - (clear?.offsetWidth ?? 0) - MIN_INPUT_PX
    const widths = chips.map((chip) => chip.offsetWidth + (parseFloat(getComputedStyle(chip).marginRight) || 0))
    const total = widths.reduce((sum, width) => sum + width, 0)
    if (total <= room) return
    let keep = chips.length
    let used = total
    while (keep > 0) {
      badge.textContent = `+${chips.length - keep}`
      badge.hidden = false
      const width = badge.offsetWidth + (parseFloat(getComputedStyle(badge).marginRight) || 0)
      if (used + width <= room) break
      keep -= 1
      used -= widths[keep]
    }
    chips.forEach((chip, index) => (chip.hidden = index >= keep))
    badge.textContent = `+${chips.length - keep}`
    badge.hidden = keep === chips.length
    const names = chips.slice(keep).map((chip) => this.labelOf(chip.dataset.value)).join(", ")
    badge.title = names
    badge.setAttribute("aria-label", `${chips.length - keep} ${this.el.dataset.moreLabel || "more"}: ${names}`)
  },

  badge(control, input) {
    const badge = control.querySelector(".ts-more") ?? Object.assign(document.createElement("div"), {className: "item ts-more"})
    badge.hidden = true
    input.insertAdjacentElement("beforebegin", badge)
    return badge
  },

  chip(value) {
    const template = this.template(value)
    const chip = this.remembered.get(value)?.chip
    return template ? template.content.firstElementChild.cloneNode(true) : chip ? chip.cloneNode(true) : this.defaultChip(value)
  },

  defaultChip(value) {
    const chip = document.createElement("div")
    const removeLabel = this.el.dataset.removeLabel
    chip.className = "item"
    chip.dataset.value = value
    chip.setAttribute("data-ts-item", "")
    chip.insertAdjacentHTML("afterbegin", `<span class="item-text">${escapeHtml(this.labelOf(value))}</span>`)
    removeLabel &&
      chip.insertAdjacentHTML(
        "beforeend",
        `<button type="button" class="remove" tabindex="-1" title="${escapeHtml(removeLabel)}" aria-label="${escapeHtml(removeLabel)}" data-remove>×</button>`,
      )
    return chip
  },

  writeInput() {
    const select = this.q("[data-input]")
    const empty = this.values.length === 0 && !this.multiple() ? `<option value="" selected></option>` : ""
    select.innerHTML =
      empty + this.values.map((value) => `<option value="${escapeHtml(value)}" selected>${escapeHtml(value)}</option>`).join("")
    ;[...select.options].forEach((option) => (option.selected = true))
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
    current ? input.setAttribute("aria-activedescendant", current.id || "") : input.removeAttribute("aria-activedescendant")
    current && current.scrollIntoView({block: "nearest"})
  },

  refresh() {
    const state = {values: this.values, multiple: this.multiple(), term: this.term, local: this.local()}
    const options = this.options()
    options.forEach((row) => {
      const visible = shows({value: row.dataset.value, label: row.dataset.label, keywords: row.dataset.keywords}, state)
      const text = row.querySelector("[data-text]")
      row.hidden = !visible
      row.classList.toggle("selected", this.values.includes(row.dataset.value))
      row.setAttribute("aria-selected", String(this.values.includes(row.dataset.value)))
      text && (text.innerHTML = this.marked(row.dataset.label))
    })
    this.el.querySelectorAll("[data-dropdown] [data-group]").forEach((group) => {
      group.hidden = ![...group.querySelectorAll(".option")].some((row) => !row.hidden)
    })
    this.paintCreate(options)
    this.paintNoResults()
    this.paintWrapper()
    const rows = this.rows()
    const selected = rows.findIndex((row) => row.classList.contains("selected"))
    this.active = this.active >= 0 && this.active < rows.length ? this.active : this.isOpen && rows.length > 0 ? Math.max(selected, 0) : -1
    this.paintActive()
    this.paintOpen(rows)
    this.paintFooter()
  },

  paintFooter() {
    const footer = this.q("[data-footer]")
    const text = footer?.querySelector("[data-footer-count]")
    text &&
      (text.textContent = footer.dataset.countLabel
        .replace("%{count}", String(this.values.length))
        .replace("%{total}", String(this.options().length)))
  },

  marked(label) {
    return highlight(label, this.local() ? this.term : "")
      .map(({text, hit}) => (hit ? `<span class="highlight">${escapeHtml(text)}</span>` : escapeHtml(text)))
      .join("")
  },

  paintCreate(options) {
    const holder = this.q("[data-create-row]")
    const term = this.term.trim()
    const wanted =
      this.el.dataset.create === "true" && term !== "" && canCreate(term, options.map((row) => row.dataset.label)) &&
      !(this.multiple() && isFull(this.values.length, true, this.max()))
    const label = escapeHtml(this.el.dataset.createLabel || "Add")
    holder.innerHTML = wanted ? `<div class="create" id="${this.el.id}-create-row">${label} <strong>${escapeHtml(term)}</strong>&hellip;</div>` : ""
  },

  paintNoResults() {
    const extra = this.q("[data-extra]")
    const shown = this.rows().length > 0
    const message = fillQuery(this.q("[data-no-results]").textContent, this.term)
    const row = extra.querySelector(".no-results")
    const wanted = !shown && this.term.trim() !== "" && this.el.dataset.create !== "true"
    row && (!wanted || row.textContent !== message) && row.remove()
    ;(!row || row.textContent !== message) && wanted && extra.insertAdjacentHTML("beforeend", `<div class="no-results">${escapeHtml(message)}</div>`)
  },

  paintWrapper() {
    const full = isFull(this.values.length, this.multiple(), this.max())
    this.el.classList.toggle("has-items", this.values.length > 0)
    this.el.classList.toggle("full", full)
    this.el.classList.toggle("input-hidden", !this.multiple() && full && this.hidesControl(this.term))
  },

  paintOpen(rows) {
    const dropdown = this.q("[data-dropdown]")
    const hasContent = rows.length > 0 || Boolean(this.q("[data-extra] .no-results"))
    const shown = this.isOpen && hasContent
    dropdown.hidden = !shown
    this.el.classList.toggle("dropdown-active", shown)
    this.control().setAttribute("aria-expanded", String(shown))
  },
}

export default {"LineaUI.Select": Listbox}
