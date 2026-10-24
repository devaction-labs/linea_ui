import {execWithPayload} from "../lib/js_payload.js"
import {keyName, nextTab} from "../lib/keys.js"
import {openTabs, resolveSelection} from "../lib/tabs_logic.js"

export default {
  "LineaUI.Tabs": {
    mounted() {
      this.lastServer = this.el.dataset.selected
      this.chosen = ""
      this.onClick = (event) => {
        const tab = event.target.closest("[role='tab']")
        this.owns(tab) && !tab.disabled && this.choose(tab)
      }
      this.onKey = (event) => {
        const tab = event.target.closest("[role='tab']")
        this.owns(tab) && this.move(tab, event)
      }
      this.el.addEventListener("click", this.onClick)
      this.el.addEventListener("keydown", this.onKey)
    },

    updated() {
      const next = resolveSelection({
        chosen: this.chosen,
        lastServer: this.lastServer,
        server: this.el.dataset.selected,
        ids: this.tabs().map((tab) => tab.dataset.value),
      })
      this.lastServer = next.lastServer
      this.chosen = next.chosen
      this.apply(next.selected)
    },

    destroyed() {
      this.el.removeEventListener("click", this.onClick)
      this.el.removeEventListener("keydown", this.onKey)
    },

    owns(node) {
      return Boolean(node) && node.closest("[phx-hook='LineaUI.Tabs']") === this.el
    },

    tabs() {
      return [...this.el.querySelectorAll("[role='tab']")].filter((tab) => this.owns(tab))
    },

    panels() {
      return [...this.el.querySelectorAll("[role='tabpanel']")].filter((panel) => this.owns(panel))
    },

    move(tab, event) {
      const open = openTabs(this.tabs())
      const at = nextTab(keyName(event), open.indexOf(tab), open.length, {
        orientation: this.el.dataset.orientation,
        rtl: getComputedStyle(this.el).direction === "rtl",
      })
      const target = at === null ? undefined : open[at]
      target && (event.preventDefault(), target.focus(), "link" in target.dataset || this.choose(target))
    },

    choose(tab) {
      const value = tab.dataset.value
      const current = this.tabs().find((item) => item.getAttribute("aria-selected") === "true")?.dataset.value
      value === current || (this.chosen = value, this.apply(value), this.notify(value))
    },

    notify(value) {
      const {event, onChange} = this.el.dataset
      const target = this.el.getAttribute("phx-target") || this.el
      this.el.dispatchEvent(new CustomEvent("linea:change", {bubbles: true, detail: {id: this.el.id, value, tab: value}}))
      event && this.pushEventTo(target, event, {id: this.el.id, value, tab: value})
      execWithPayload(this.liveSocket, this.el, onChange, {id: this.el.id, value, tab: value})
    },

    apply(value) {
      this.tabs().forEach((tab) => {
        const on = tab.dataset.value === value
        tab.setAttribute("aria-selected", String(on))
        tab.setAttribute("tabindex", on ? "0" : "-1")
        "link" in tab.dataset && (on ? tab.setAttribute("aria-current", "page") : tab.removeAttribute("aria-current"))
      })
      this.panels().forEach((panel) => panel.toggleAttribute("hidden", panel.dataset.value !== value))
    },
  },
}
