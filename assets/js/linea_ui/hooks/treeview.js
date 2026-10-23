import {resolveBranch, target} from "../lib/carousel_logic.js"

const emit = (hook, spec, payload, source = hook.el) => {
  const run = {
    js: () => hook.liveSocket.execJS(source, spec),
    push: () => hook.pushEventTo(hook.el.getAttribute("phx-target") || hook.el, spec, payload),
  }
  spec && run[spec.trim().startsWith("[") ? "js" : "push"]()
}

const listen = (hook, element, type, handler, options) => {
  element.addEventListener(type, handler, options)
  hook.cleanups.push(() => element.removeEventListener(type, handler, options))
}

/**
 * The treeview's branches are native `<details>`; this hook keeps the person's choice across patches
 * (LiveView leaves `open` alone), applies the server's when it changes, and reports toggles and leaf picks.
 */
const Treeview = {
  mounted() {
    this.cleanups = []
    this.chosen = {}
    this.last = {}
    this.expected = {}
    listen(this, this.el, "toggle", (event) => this.toggled(event), true)
    listen(this, this.el, "click", (event) => this.clicked(event))
    listen(this, this.el, "keydown", (event) => this.keyed(event))
    this.sync()
  },

  updated() {
    this.sync()
  },

  destroyed() {
    this.cleanups.forEach((cleanup) => cleanup())
  },

  listed() {
    return JSON.parse(this.el.dataset.expanded || "[]")
  },

  branches() {
    return [...this.el.querySelectorAll("details[data-tree-item]")].filter((item) => item.closest("[phx-hook='LineaUI.Treeview']") === this.el)
  },

  sync() {
    const listed = this.listed()
    this.branches().forEach((item) => {
      const id = item.dataset.treeItem
      const server = item.dataset.serverOpen === "true" || listed.includes(id)
      const next = resolveBranch({chosen: this.chosen[id], lastServer: this.last[id], server})
      this.chosen[id] = next.chosen
      this.last[id] = next.lastServer
      this.expected[id] = next.open
      item.open === next.open || (item.open = next.open)
    })
  },

  toggled(event) {
    const item = event.target
    const id = item.dataset?.treeItem
    const byPerson = id !== undefined && item.open !== this.expected[id]
    byPerson && this.chose(item, id)
  },

  chose(item, id) {
    this.chosen[id] = item.open
    this.expected[id] = item.open
    emit(this, this.el.dataset.onToggle, {id, expanded: item.open}, item)
  },

  clicked(event) {
    const leaf = event.target.closest("[data-tree-leaf]")
    leaf && emit(this, this.el.dataset.onSelect, {id: leaf.dataset.treeLeaf}, leaf)
  },

  keyed(event) {
    const leaf = event.key === "Enter" && event.target.closest("[data-tree-leaf]")
    leaf && emit(this, this.el.dataset.onSelect, {id: leaf.dataset.treeLeaf}, leaf)
  },
}

export default {"LineaUI.Treeview": Treeview}
