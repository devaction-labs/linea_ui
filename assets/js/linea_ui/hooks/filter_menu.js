import {notify} from "../lib/dom.js"
import {applySuffix, onClose, payloadOf, pendingResults, stagedTotal} from "../lib/filter_menu.js"

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
 */
export default {
  "LineaUI.FilterMenu": {
    mounted() {
      this.applying = false
      this.onApply = (event) => event.target.closest("[data-menu-action='apply']") && this.apply()
      this.onClear = (event) => event.target.closest("[data-menu-action='clear']") && this.clear()
      this.onInput = (event) => this.ticked(event)
      this.onClosed = () => this.closed()
      this.el.addEventListener("click", this.onApply, true)
      this.el.addEventListener("click", this.onClear)
      this.el.addEventListener("input", this.onInput)
      this.el.addEventListener("linea:filter-close", this.onClosed)
      this.refresh()
    },

    updated() {
      this.refresh()
    },

    destroyed() {
      this.el.removeEventListener("click", this.onApply, true)
      this.el.removeEventListener("click", this.onClear)
      this.el.removeEventListener("input", this.onInput)
      this.el.removeEventListener("linea:filter-close", this.onClosed)
    },

    groups() {
      return [...this.el.querySelectorAll("[data-filter-group]")].map((el) => ({
        el,
        name: el.dataset.filterGroup,
        type: el.dataset.filterType,
        filter: el.hasAttribute("data-submenu"),
        items: [...el.querySelectorAll(CHOICE)],
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
        this.groups().map(({name, type, items}) => ({
          name,
          type,
          values: items.filter(isOn).map((item) => inputOf(item)?.value ?? ""),
        })),
      )
    },

    push(name) {
      const event = this.el.dataset[name]
      event && this.pushEventTo(this.el.getAttribute("phx-target") || this.el, event, {id: this.el.dataset.filterId, values: this.values()})
    },

    ticked(event) {
      const ours = event.target.closest("[data-choice-input]")
      this.el.dataset.mode === "apply" && ours && event.stopPropagation()
      this.applying = false
      ours && (this.refresh(), this.push("onChange"))
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
      this.groups()
        .flatMap(({items}) => items)
        .forEach((item) => setOn(item, item.dataset.serverChecked === "true"))
      this.refresh()
    },
  },
}
