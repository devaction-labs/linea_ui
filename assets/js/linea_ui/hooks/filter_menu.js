import {notify} from "../lib/dom.js"
import {applySuffix, customText, customValue, onClose, payloadOf, pendingResults, stagedTotal} from "../lib/filter_menu.js"

const CHOICE = '[role="menuitemcheckbox"], [role="menuitemradio"]'

const isOn = (item) => item.getAttribute("aria-checked") === "true"
const inputOf = (item) => item.parentElement.querySelector(":scope > [data-choice-input]")

const setOn = (item, on) => {
  item.setAttribute("aria-checked", String(on))
  const input = inputOf(item)
  input && (input.checked = on)
  return input
}

/**
 * `FilterMenu`: the high-level filter on top of the dropdown's own hook. It reads the menu's state from the DOM (the
 * choice items of each `[data-filter-group]`) and keeps what the dropdown does not: the number after Apply
 * (`[data-apply-count]`, from the options' `data-count` unless the server gave `data-results`), the applied number
 * on the trigger of a live menu (`[data-filter-applied]`) and the counts of single-choice groups.
 *
 * `data-mode="apply"` stages: a tick never reaches the form, a menu closed without Apply goes back to what the
 * server rendered, and Apply pushes `data-on-apply` or submits the surrounding form. In `live` a tick reaches the
 * form's `phx-change` at once. `data-on-change` (every tick), `data-on-apply` and `data-on-clear` are pushed to
 * `phx-target` with `%{"id" => id, "values" => %{group => values}}`.
 *
 * A single group with `custom` has a `[data-filter-custom]` row that opens a panel with an inline range calendar
 * (a `LineaUI.DatePicker` with `<name>--from` and `<name>--to` inputs). Picking the second day stages the period: the
 * group's `[data-custom-input]` radio takes the value `custom:FROM..TO` and is checked (the presets uncheck), the row
 * shows the period, and the panel closes with the focus back on its row. A preset chosen afterwards, a close without
 * Apply (in `apply` mode) and a new value from the server put the row and the calendar back to what that value says.
 * The calendar's own two inputs are taken out of the form's data. Its keys stay in the panel (only `Esc` goes on to the
 * dropdown, which closes the panel); a key on the row (→, Enter, Space) opens the panel with the focus on a day.
 */
export default {
  "LineaUI.FilterMenu": {
    mounted() {
      this.applying = false
      this.onApply = (event) => event.target.closest("[data-menu-action='apply']") && this.apply()
      this.onClear = (event) => event.target.closest("[data-menu-action='clear']") && this.clear()
      this.onInput = (event) => this.ticked(event)
      this.onClosed = () => this.closed()
      this.onFormData = (event) => this.customNames().forEach((name) => event.formData.delete(name))
      this.onCustomKey = (event) => event.key !== "Escape" && event.stopPropagation()
      this.onCustomClick = (event) => event.stopPropagation()
      this.bound = new WeakSet()
      this.onIntent = (event) => (this.intent = ["ArrowRight", "Enter", " "].includes(event.key) && Boolean(event.target.matches?.("[data-filter-custom] > [data-submenu-trigger]")))
      this.opened = new MutationObserver((records) => records.forEach(({target}) => this.customOpened(target)))
      this.el.addEventListener("click", this.onApply, true)
      this.el.addEventListener("click", this.onClear)
      this.el.addEventListener("input", this.onInput)
      this.el.addEventListener("linea:filter-close", this.onClosed)
      this.el.addEventListener("keydown", this.onIntent, true)
      this.form = this.el.closest("form")
      this.form?.addEventListener("formdata", this.onFormData)
      this.opened.observe(this.el, {attributes: true, attributeFilter: ["data-open"], subtree: true})
      this.known = new WeakMap()
      this.customs().forEach((custom) => this.known.set(custom, custom.dataset.serverValue))
      this.bindCustoms()
      this.refresh()
    },

    updated() {
      this.bindCustoms()
      this.applyServerCustoms()
      this.refresh()
    },

    destroyed() {
      this.el.removeEventListener("click", this.onApply, true)
      this.el.removeEventListener("click", this.onClear)
      this.el.removeEventListener("input", this.onInput)
      this.el.removeEventListener("linea:filter-close", this.onClosed)
      this.customs().forEach((custom) => this.unbindCustom(custom))
      this.el.removeEventListener("keydown", this.onIntent, true)
      this.form?.removeEventListener("formdata", this.onFormData)
      this.opened.disconnect()
    },

    customs() {
      return [...this.el.querySelectorAll("[data-filter-custom]")]
    },

    // The panel's keys and clicks stop here, below the dropdown's own listeners: its arrows would move among the items, Tab
    // would close the menu, and a click on a day (that the calendar redraws) would look like a click outside.
    bindCustoms() {
      this.customs()
        .filter((custom) => !this.bound.has(custom))
        .forEach((custom) => {
          const panel = custom.querySelector(":scope > [data-submenu-panel]")
          this.bound.add(custom)
          panel.addEventListener("keydown", this.onCustomKey)
          panel.addEventListener("click", this.onCustomClick)
        })
    },

    unbindCustom(custom) {
      const panel = custom.querySelector(":scope > [data-submenu-panel]")
      panel.removeEventListener("keydown", this.onCustomKey)
      panel.removeEventListener("click", this.onCustomClick)
    },

    customNames() {
      return this.customs().flatMap((custom) => {
        const picker = custom.querySelector("[data-start-name]")
        return picker ? [picker.dataset.startName, picker.dataset.endName] : []
      })
    },

    customInput(custom) {
      return custom.parentElement.querySelector(":scope > [data-custom-input]")
    },

    customPicker(custom) {
      return custom.querySelector("[data-kind]")
    },

    // The row, the radio and the calendar all say `value` (`custom:FROM..TO`, or "" for a preset or nothing).
    syncCustom(custom, value) {
      const input = this.customInput(custom)
      const on = value !== ""
      input.value = value
      input.checked = on
      custom.toggleAttribute("data-selected", on)
      custom.querySelector(":scope > [data-submenu-trigger] > span.flex-1").textContent = customText(value, {label: custom.dataset.label, locale: custom.dataset.locale})
      const picker = this.customPicker(custom)
      const days = value.replace("custom:", "").split("..").filter(Boolean)
      picker.dataset.value = JSON.stringify(days)
      picker.dispatchEvent(new CustomEvent("linea:reset"))
    },

    applyServerCustoms() {
      this.customs().forEach((custom) => {
        const next = custom.dataset.serverValue
        next !== this.known.get(custom) && (this.known.set(custom, next), this.syncCustom(custom, next))
      })
    },

    picked(custom) {
      const [from, to] = [...custom.querySelectorAll("[data-hidden] input")].map((input) => input.value)
      const value = customValue(from, to)
      value && this.choosePeriod(custom, value)
    },

    choosePeriod(custom, value) {
      const group = custom.closest("[data-filter-group]")
      group.querySelectorAll(CHOICE).forEach((item) => setOn(item, false))
      this.syncCustom(custom, value)
      this.closeCustom(custom)
      notify(this.customInput(custom))
    },

    closeCustom(custom) {
      const trigger = custom.querySelector(":scope > [data-submenu-trigger]")
      const lost = !document.activeElement || document.activeElement === document.body || custom.contains(document.activeElement)
      custom.dataset.open = "false"
      trigger.setAttribute("aria-expanded", "false")
      lost && trigger.focus({preventScroll: true})
    },

    customOpened(custom) {
      const keyboard = this.intent && custom.matches("[data-filter-custom]") && custom.dataset.open === "true"
      this.intent = false
      keyboard && requestAnimationFrame(() => (custom.querySelector("[data-calendar] [data-date][tabindex='0']") ?? custom.querySelector("[data-calendar] [data-date]"))?.focus({preventScroll: true}))
    },

    groups() {
      return [...this.el.querySelectorAll("[data-filter-group]")].map((el) => ({
        el,
        name: el.dataset.filterGroup,
        type: el.dataset.filterType,
        filter: el.hasAttribute("data-submenu"),
        items: [...el.querySelectorAll(CHOICE)],
        custom: el.querySelector("[data-custom-input]"),
      }))
    },

    filters() {
      return this.groups().filter((group) => group.filter)
    },

    refresh() {
      const options = this.filters().map((group) =>
        group.items.map((item) => ({on: isOn(item), count: Number.parseInt(item.dataset.count, 10)})),
      )
      this.badges()
      this.el.dataset.mode === "live" && this.pill(stagedTotal(options))
      const label = this.el.querySelector("[data-apply-count]")
      label && !("results" in this.el.dataset) && (label.textContent = applySuffix(pendingResults(options)))
    },

    badges() {
      this.filters().forEach(({el, items}) => {
        const badge = el.querySelector(":scope > [data-submenu-trigger] [data-submenu-count]")
        const total = items.filter(isOn).length
        badge && ((badge.textContent = String(total)), (badge.hidden = total === 0))
      })
    },

    pill(total) {
      const pill = this.el.querySelector("[data-filter-applied]")
      pill && ((pill.textContent = String(total)), (pill.hidden = total === 0))
    },

    values() {
      return payloadOf(
        this.groups().map(({name, type, items, custom}) => ({
          name,
          type,
          values: custom?.checked ? [custom.value] : items.filter(isOn).map((item) => inputOf(item)?.value ?? ""),
        })),
      )
    },

    push(name) {
      const event = this.el.dataset[name]
      event && this.pushEventTo(this.el.getAttribute("phx-target") || this.el, event, {id: this.el.dataset.filterId, values: this.values()})
    },

    ticked(event) {
      const custom = event.target.closest("[data-filter-custom]")
      const picking = Boolean(custom) && !event.target.matches("[data-custom-input]")
      picking && (event.stopPropagation(), this.picked(custom))
      const ours = !picking && event.target.closest("[data-choice-input]")
      ours && !event.target.matches("[data-custom-input]") && this.releaseCustoms(event.target)
      this.el.dataset.mode === "apply" && ours && event.stopPropagation()
      this.applying = false
      ours && (this.refresh(), this.push("onChange"))
    },

    // A preset chosen (its radio is now checked) takes the period back.
    releaseCustoms(input) {
      this.customs()
        .filter((custom) => custom.closest("[data-filter-group]").contains(input) && this.customInput(custom).value !== "")
        .forEach((custom) => this.syncCustom(custom, ""))
    },

    apply() {
      this.applying = true
      this.el.dataset.onApply ? this.push("onApply") : this.el.closest("form")?.requestSubmit()
    },

    clear() {
      const radios = this.filters()
        .flatMap(({items}) => items)
        .filter((item) => item.getAttribute("role") === "menuitemradio" && isOn(item))
        .map((item) => setOn(item, false))
      this.refresh()
      radios.find(Boolean) && notify(radios.find(Boolean))
      this.push("onClear")
    },

    closed() {
      onClose({mode: this.el.dataset.mode, applying: this.applying}) === "revert" && this.revert()
      this.applying = false
    },

    revert() {
      this.customs().forEach((custom) => this.syncCustom(custom, custom.dataset.serverValue))
      this.groups()
        .flatMap(({items}) => items)
        .forEach((item) => setOn(item, item.dataset.serverChecked === "true"))
      this.refresh()
    },
  },
}
