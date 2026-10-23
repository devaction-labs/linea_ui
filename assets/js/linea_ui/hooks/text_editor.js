/**
 * The text editor: a `contenteditable` under Quill's snow toolbar, edited with the browser's own commands, with
 * the HTML cleaned on the way in and kept in a hidden input the form submits.
 */
import {notify} from "../lib/dom.js"
import {safeHref} from "../lib/editor_logic.js"
import {TOOLS, alignCommand, cleanAttribute, headerValue, isEmptyHtml, tagAction, toggleBlock} from "../lib/editor_html.js"

const STATES = {
  bold: "bold",
  italic: "italic",
  underline: "underline",
  strike: "strikeThrough",
  "script-sub": "subscript",
  "script-super": "superscript",
  "list-ordered": "insertOrderedList",
  "list-bullet": "insertUnorderedList",
}
const BLOCKS = {blockquote: "blockquote", "code-block": "pre", "header-1": "h1", "header-2": "h2"}
const MARKER = "linea-marker"

const cleanNode = (node) => {
  const children = [...node.childNodes]
  children.forEach((child) => child.nodeType === Node.ELEMENT_NODE ? cleanElement(child) : child.nodeType !== Node.TEXT_NODE && child.remove())
}

const cleanElement = (element) => {
  const action = tagAction(element.tagName)
  ;[...element.attributes].forEach((attribute) => {
    const kept = cleanAttribute(element.tagName, attribute.name, attribute.value)
    kept === null ? element.removeAttribute(attribute.name) : element.setAttribute(attribute.name, kept)
  })
  action !== "drop" && cleanNode(element)
  action === "drop" && element.remove()
  action === "unwrap" && element.replaceWith(...element.childNodes)
}

export const sanitize = (html) => {
  const doc = new DOMParser().parseFromString(`<div>${html ?? ""}</div>`, "text/html")
  const root = doc.body.firstElementChild
  cleanNode(root)
  return root.innerHTML
}

const TextEditor = {
  mounted() {
    this.server = this.el.dataset.value ?? ""
    this.editor().innerHTML = sanitize(this.server)
    this.input().value = this.html()
    this.paintBlank()

    this.onToolbarDown = (event) => event.target.closest("[data-toolbar]") && event.preventDefault()
    this.onClick = (event) => this.click(event)
    this.onInput = (event) =>
      event.target.closest("[data-editor]") ? this.sync() : event.target.matches("[data-link-input]") && event.stopPropagation()
    this.onPaste = (event) => this.paste(event)
    this.onSelection = () => document.activeElement === this.editor() && this.paintState()
    this.onOutside = (event) => !event.target.closest(`#${CSS.escape(this.el.id)} .ql-picker`) && this.closePickers()
    this.onKey = (event) => event.target.matches("[data-link-input]") && event.key === "Enter" && (event.preventDefault(), this.saveLink())

    this.el.addEventListener("mousedown", this.onToolbarDown)
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("paste", this.onPaste)
    this.el.addEventListener("keydown", this.onKey)
    document.addEventListener("selectionchange", this.onSelection)
    document.addEventListener("pointerdown", this.onOutside)
  },

  updated() {
    const incoming = this.el.dataset.value ?? ""
    const changed = incoming !== this.server && incoming !== this.html()
    this.server = incoming
    changed && ((this.editor().innerHTML = sanitize(incoming)), (this.input().value = this.html()), this.paintBlank())
  },

  destroyed() {
    clearTimeout(this.timer)
    document.removeEventListener("selectionchange", this.onSelection)
    document.removeEventListener("pointerdown", this.onOutside)
  },

  editor() {
    return this.el.querySelector("[data-editor]")
  },

  input() {
    return this.el.querySelector("[data-input]")
  },

  html() {
    const html = this.editor().innerHTML
    return isEmptyHtml(html) ? "" : html
  },

  click(event) {
    const button = event.target.closest("[data-tool]")
    const label = event.target.closest("[data-picker-label]")
    const item = event.target.closest("[data-item]")
    const save = event.target.closest("[data-link-save]")
    const action =
      (button && (() => this.run(button.dataset.tool))) ||
      (label && (() => this.togglePicker(label.closest("[data-picker]")))) ||
      (item && (() => this.pick(item.closest("[data-picker]"), item))) ||
      (save && (() => this.saveLink()))
    action && (event.preventDefault(), action())
  },

  exec(command, value = null) {
    this.editor().focus()
    document.execCommand(command, false, value)
  },

  run(name) {
    const tool = TOOLS[name]
    const block = String(document.queryCommandValue("formatBlock") || "p")
    const actions = [
      [tool.command, () => this.exec(tool.command)],
      [tool.block, () => this.exec("formatBlock", toggleBlock(block, tool.block))],
      [tool.wrap, () => this.wrapSelection(tool.wrap)],
      [tool.special === "direction", () => this.toggleDirection()],
      [tool.special === "link", () => this.openLink()],
      [tool.special === "clean", () => (this.exec("removeFormat"), this.exec("formatBlock", "p"), this.exec("unlink"))],
    ]
    actions.find(([applies]) => applies)[1]()
    this.sync()
  },

  wrapSelection(tag) {
    const selection = window.getSelection()
    const range = selection.rangeCount > 0 && selection.getRangeAt(0)
    const inside = range && this.editor().contains(range.commonAncestorContainer) && !range.collapsed
    inside && this.exec("insertHTML", `<${tag}>${range.toString().replace(/[&<>]/g, (c) => ({"&": "&amp;", "<": "&lt;", ">": "&gt;"})[c])}</${tag}>`)
  },

  currentBlock() {
    const selection = window.getSelection()
    const node = selection.rangeCount > 0 ? selection.getRangeAt(0).startContainer : null
    const element = node?.nodeType === Node.TEXT_NODE ? node.parentElement : node
    const block = element?.closest?.("p, h1, h2, h3, h4, h5, h6, blockquote, pre, li, div:not([data-editor])")
    return block && this.editor().contains(block) ? block : null
  },

  toggleDirection() {
    const block = this.currentBlock()
    block && (block.getAttribute("dir") === "rtl" ? block.removeAttribute("dir") : block.setAttribute("dir", "rtl"))
    block && block.classList.toggle("ql-direction-rtl", block.getAttribute("dir") === "rtl")
  },

  togglePicker(picker) {
    const open = !picker.classList.contains("ql-expanded")
    this.closePickers()
    picker.classList.toggle("ql-expanded", open)
    picker.querySelector("[data-picker-label]").setAttribute("aria-expanded", String(open))
    picker.querySelector(".ql-picker-options").setAttribute("aria-hidden", String(!open))
  },

  closePickers() {
    this.el.querySelectorAll(".ql-picker.ql-expanded").forEach((picker) => {
      picker.classList.remove("ql-expanded")
      picker.querySelector("[data-picker-label]").setAttribute("aria-expanded", "false")
      picker.querySelector(".ql-picker-options").setAttribute("aria-hidden", "true")
    })
  },

  pick(picker, item) {
    const kind = picker.dataset.picker
    const value = item.dataset.value ?? ""
    const actions = {
      header: () => this.exec("formatBlock", value ? `h${value}` : "p"),
      align: () => this.exec(alignCommand(value)),
      color: () => (document.execCommand("styleWithCSS", false, true), this.exec("foreColor", value || "#000000")),
      background: () => (document.execCommand("styleWithCSS", false, true), this.exec("hiliteColor", value || "transparent")),
      size: () => this.markSpan("ql-size-", value),
      font: () => this.markSpan("ql-font-", value),
    }
    actions[kind]()
    picker.querySelectorAll("[data-item]").forEach((other) => other.classList.toggle("ql-selected", other === item))
    this.setLabel(picker, value)
    this.closePickers()
    this.sync()
  },

  markSpan(prefix, value) {
    document.execCommand("styleWithCSS", false, false)
    this.exec("fontName", MARKER)
    this.editor().querySelectorAll(`font[face="${MARKER}"]`).forEach((font) => {
      const span = document.createElement("span")
      value && (span.className = prefix + value)
      span.append(...font.childNodes)
      font.replaceWith(span)
    })
    this.editor().querySelectorAll(`span[style*="${MARKER}"]`).forEach((span) => {
      span.style.removeProperty("font-family")
      value && (span.className = prefix + value)
    })
  },

  setLabel(picker, value) {
    const label = picker.querySelector("[data-picker-label]")
    value ? label.setAttribute("data-value", value) : label.removeAttribute("data-value")
  },

  openLink() {
    const selection = window.getSelection()
    this.savedRange = selection.rangeCount > 0 ? selection.getRangeAt(0).cloneRange() : null
    const box = this.el.querySelector("[data-link-box]")
    box.hidden = false
    box.classList.add("ql-editing")
    box.querySelector("[data-link-input]").value = ""
    box.querySelector("[data-link-input]").focus()
  },

  saveLink() {
    const box = this.el.querySelector("[data-link-box]")
    const href = safeHref(box.querySelector("[data-link-input]").value)
    const selection = window.getSelection()
    box.hidden = true
    this.editor().focus()
    this.savedRange && (selection.removeAllRanges(), selection.addRange(this.savedRange))
    href && this.exec("createLink", href)
    this.sync()
  },

  paste(event) {
    const inEditor = event.target.closest("[data-editor]")
    const html = event.clipboardData?.getData("text/html")
    const text = event.clipboardData?.getData("text/plain") ?? ""
    inEditor && (event.preventDefault(), html ? this.exec("insertHTML", sanitize(html)) : this.exec("insertText", text))
  },

  paintBlank() {
    this.editor().classList.toggle("ql-blank", isEmptyHtml(this.editor().innerHTML))
  },

  paintState() {
    const block = String(document.queryCommandValue("formatBlock") || "p").toLowerCase()
    this.el.querySelectorAll("[data-tool]").forEach((button) => {
      const name = button.dataset.tool
      const active = STATES[name] ? document.queryCommandState(STATES[name]) : BLOCKS[name] === block
      button.classList.toggle("ql-active", Boolean(active))
      button.setAttribute("aria-pressed", String(Boolean(active)))
    })
    const header = this.el.querySelector('[data-picker="header"]')
    header && this.setLabel(header, headerValue(block))
  },

  sync() {
    const html = this.html()
    const input = this.input()
    const changed = input.value !== html
    input.value = html
    this.paintBlank()
    this.paintState()
    changed && notify(input)
    changed && this.push(html)
  },

  push(html) {
    const event = this.el.dataset.onChange
    const target = this.el.getAttribute("phx-target")
    clearTimeout(this.timer)
    event &&
      (this.timer = setTimeout(
        () => this.pushEventTo(target || this.el, event, {id: this.el.id, value: html}),
        Number(this.el.dataset.debounce || 0),
      ))
  },
}

export default {"LineaUI.TextEditor": TextEditor}
