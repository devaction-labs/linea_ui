/**
 * The text editor: a `contenteditable` under Quill's snow toolbar, edited with the browser's own commands, with
 * the HTML cleaned on the way in and kept in a hidden input the form submits.
 *
 * Optional parts, each switched on by a `data-*` attribute: the "/" menu (`data-slash`, a JSON list of entries) and
 * the "@" menu (`data-mentions`, a JSON list of `{handle, label}`); variables (`data-variables`) and mentions drawn as
 * chips and kept in the submitted HTML as plain `{name}` and `@handle`; an AI button (`data-on-ai` is pushed with the
 * HTML and the selected text; the server answers with `linea:editor-insert`); Ctrl+Enter or the submit button
 * (`data-on-submit` is pushed with the HTML and the mentioned handles); an entry of the "/" menu that is not a built-in
 * block is pushed to `data-on-slash` with its key; and a word count in the footer.
 *
 * Toolbar buttons that are opt-in: `image` (a small popover for the address and description of a picture, or
 * `data-on-image` pushed instead so the app can upload it), `variable` (a menu of `data-variables` to insert at the
 * caret) and `mark` (toggles a `<mark>` around the selection). `<img>` survives the HTML cleaning only where
 * `data-images` is on.
 */
import {notify} from "../lib/dom.js"
import {filterItems, imageHtml, mentionsIn, nextIndex, safeHref, sends, slashActions, slashKind, toggleAction, tokenize, triggerOf, variableItems, wordsLabel} from "../lib/editor_logic.js"
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

const cleanNode = (node, images) => {
  const children = [...node.childNodes]
  children.forEach((child) => child.nodeType === Node.ELEMENT_NODE ? cleanElement(child, images) : child.nodeType !== Node.TEXT_NODE && child.remove())
}

const cleanElement = (element, images) => {
  const action = tagAction(element.tagName, images)
  ;[...element.attributes].forEach((attribute) => {
    const kept = cleanAttribute(element.tagName, attribute.name, attribute.value)
    kept === null ? element.removeAttribute(attribute.name) : element.setAttribute(attribute.name, kept)
  })
  action !== "drop" && cleanNode(element, images)
  action === "drop" && element.remove()
  action === "unwrap" && element.replaceWith(...element.childNodes)
}

export const sanitize = (html, images = false) => {
  const doc = new DOMParser().parseFromString(`<div>${html ?? ""}</div>`, "text/html")
  const root = doc.body.firstElementChild
  cleanNode(root, images)
  return root.innerHTML
}

const TextEditor = {
  mounted() {
    this.server = this.el.dataset.value ?? ""
    this.readOptions()
    this.load(this.server)
    this.input().value = this.html()
    this.paintBlank()
    this.paintCount()
    this.menu = null

    this.onToolbarDown = (event) => event.target.closest("[data-toolbar], [data-menu], [data-comment-bar]") && event.preventDefault()
    this.onClick = (event) => this.click(event)
    this.onInput = (event) =>
      event.target.closest("[data-editor]") ? this.sync() : event.target.matches("[data-link-input], [data-image-input], [data-image-alt]") && event.stopPropagation()
    this.onPaste = (event) => this.paste(event)
    this.onSelection = () => document.activeElement === this.editor() && (this.paintState(), this.refreshMenu())
    this.onOutside = (event) => {
      !event.target.closest(`#${CSS.escape(this.el.id)} .ql-picker`) && this.closePickers()
      !event.target.closest("[data-menu]") && this.closeMenu()
    }
    this.onKey = (event) => this.key(event)
    this.onFocusOut = (event) => !this.el.contains(event.relatedTarget) && this.closeMenu()
    this.handleEvent("linea:editor-insert", ({id, html}) => id === this.el.id && this.insert(html))

    this.el.addEventListener("mousedown", this.onToolbarDown)
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("paste", this.onPaste)
    this.el.addEventListener("keydown", this.onKey)
    this.el.addEventListener("focusout", this.onFocusOut)
    document.addEventListener("selectionchange", this.onSelection)
    document.addEventListener("pointerdown", this.onOutside)
  },

  updated() {
    const incoming = this.el.dataset.value ?? ""
    const changed = incoming !== this.server && incoming !== this.html()
    this.server = incoming
    this.readOptions()
    changed && (this.load(incoming), (this.input().value = this.html()), this.paintBlank())
    this.paintCount()
  },

  destroyed() {
    clearTimeout(this.timer)
    document.removeEventListener("selectionchange", this.onSelection)
    document.removeEventListener("pointerdown", this.onOutside)
  },

  readOptions() {
    const read = (name) => JSON.parse(this.el.dataset[name] || "[]")
    this.slash = this.el.dataset.slash ? read("slash") : null
    this.variables = read("variables")
    this.mentions = read("mentions")
    this.images = this.el.dataset.images === "true"
  },

  names() {
    return {variables: this.variables, mentions: this.mentions.map((mention) => mention.handle)}
  },

  load(html) {
    this.editor().innerHTML = sanitize(html, this.images)
    this.chipify()
  },

  chipify() {
    const names = this.names()
    const walker = document.createTreeWalker(this.editor(), NodeFilter.SHOW_TEXT)
    const nodes = []
    while (walker.nextNode()) nodes.push(walker.currentNode)
    nodes
      .filter((node) => !node.parentElement.closest("[data-token]"))
      .forEach((node) => {
        const parts = tokenize(node.textContent, names)
        parts.some((part) => part.kind) && node.replaceWith(...parts.map((part) => (part.kind ? this.chip(part.kind, part.text) : part.text)))
      })
  },

  chip(kind, text) {
    const chip = document.createElement("span")
    chip.className = `ql-token ql-token-${kind}`
    chip.contentEditable = "false"
    chip.dataset.token = kind
    chip.textContent = text
    return chip
  },

  editor() {
    return this.el.querySelector("[data-editor]")
  },

  input() {
    return this.el.querySelector("[data-input]")
  },

  html() {
    const copy = this.editor().cloneNode(true)
    copy.querySelectorAll("[data-token]").forEach((chip) => chip.replaceWith(chip.textContent))
    const html = copy.innerHTML
    return isEmptyHtml(html) ? "" : html
  },

  click(event) {
    const button = event.target.closest("[data-tool]")
    const label = event.target.closest("[data-picker-label]")
    const item = event.target.closest("[data-item]")
    const save = event.target.closest("[data-link-save]")
    const saveImage = event.target.closest("[data-image-save]")
    const row = event.target.closest("[data-menu-index]")
    const ai = event.target.closest("[data-ai]")
    const submit = event.target.closest("[data-submit]")
    const mention = event.target.closest("[data-mention-button]")
    const action =
      (row && (() => this.choose(Number(row.dataset.menuIndex)))) ||
      (ai && (() => this.askAi())) ||
      (submit && (() => this.submit())) ||
      (mention && (() => (this.exec("insertText", "@"), this.sync()))) ||
      (button && (() => this.run(button.dataset.tool))) ||
      (label && (() => this.togglePicker(label.closest("[data-picker]")))) ||
      (item && (() => this.pick(item.closest("[data-picker]"), item))) ||
      (save && (() => this.saveLink())) ||
      (saveImage && (() => this.saveImage()))
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
      [tool.special === "image", () => this.openImage()],
      [tool.special === "variable", () => this.openVariables()],
      [tool.special === "mark", () => this.toggleMark()],
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

  markAround() {
    const range = this.selectionRange()
    const node = range?.commonAncestorContainer
    const element = node?.nodeType === Node.TEXT_NODE ? node.parentElement : node
    const mark = element?.closest?.("mark")
    return mark && this.editor().contains(mark) ? mark : null
  },

  selectionRange() {
    const selection = window.getSelection()
    const range = selection.rangeCount > 0 ? selection.getRangeAt(0) : null
    return range && this.editor().contains(range.commonAncestorContainer) ? range : null
  },

  toggleMark() {
    const mark = this.markAround()
    const range = this.selectionRange()
    const actions = {
      unwrap: () => this.unwrapNode(mark),
      wrap: () => range && !range.collapsed && this.wrapRange(range),
    }
    actions[toggleAction(Boolean(mark))]()
  },

  wrapRange(range) {
    const mark = document.createElement("mark")
    mark.append(range.extractContents())
    range.insertNode(mark)
    const selection = window.getSelection()
    range.selectNodeContents(mark)
    selection.removeAllRanges()
    selection.addRange(range)
  },

  unwrapNode(node) {
    const children = [...node.childNodes]
    node.replaceWith(...children)
    const range = document.createRange()
    const selection = window.getSelection()
    children.length > 0 && (range.setStartBefore(children[0]), range.setEndAfter(children[children.length - 1]))
    selection.removeAllRanges()
    selection.addRange(range)
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

  openImage() {
    const event = this.el.dataset.onImage
    const target = this.el.getAttribute("phx-target")
    event ? this.pushEventTo(target || this.el, event, {id: this.el.id}) : this.showImageBox()
  },

  showImageBox() {
    this.savedRange = this.selectionRange()?.cloneRange() ?? null
    const box = this.el.querySelector("[data-image-box]")
    box.hidden = false
    box.querySelectorAll("input").forEach((input) => (input.value = ""))
    box.querySelector("[data-image-input]").focus()
  },

  saveImage() {
    const box = this.el.querySelector("[data-image-box]")
    const html = imageHtml(box.querySelector("[data-image-input]").value, box.querySelector("[data-image-alt]").value)
    html ? this.insertImage(box, html) : box.querySelector("[data-image-input]").setAttribute("aria-invalid", "true")
  },

  insertImage(box, html) {
    const selection = window.getSelection()
    box.hidden = true
    box.querySelector("[data-image-input]").removeAttribute("aria-invalid")
    this.editor().focus()
    this.savedRange && (selection.removeAllRanges(), selection.addRange(this.savedRange))
    this.insertWith(html)
    this.sync()
  },

  closeImageBox() {
    const box = this.el.querySelector("[data-image-box]")
    const open = box && !box.hidden
    box && (box.hidden = true)
    open && this.editor().focus()
  },

  insertWith(html) {
    this.exec("insertHTML", sanitize(html, true))
  },

  paste(event) {
    const inEditor = event.target.closest("[data-editor]")
    const html = event.clipboardData?.getData("text/html")
    const text = event.clipboardData?.getData("text/plain") ?? ""
    inEditor && (event.preventDefault(), html ? this.exec("insertHTML", sanitize(html, this.images)) : this.exec("insertText", text))
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
      button.hasAttribute("aria-pressed") && button.setAttribute("aria-pressed", String(Boolean(active)))
    })
    const mark = this.el.querySelector('[data-tool="mark"]')
    mark && (mark.classList.toggle("ql-active", Boolean(this.markAround())), mark.setAttribute("aria-pressed", String(Boolean(this.markAround()))))
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
    this.paintCount()
    this.refreshMenu()
    changed && notify(input)
    changed && this.push(html)
  },

  paintCount() {
    const count = this.el.querySelector("[data-count]")
    count && (count.textContent = wordsLabel(this.editor().textContent, this.el.dataset.wordsLabel ?? "words"))
  },

  key(event) {
    const link = event.target.matches("[data-link-input]")
    const inEditor = event.target.closest("[data-editor]")
    const actions = [
      [link && event.key === "Enter", () => this.saveLink()],
      [event.target.closest("[data-image-box]") && event.key === "Enter", () => this.saveImage()],
      [event.target.closest("[data-image-box]") && event.key === "Escape", () => this.closeImageBox()],
      [inEditor && this.menu && this.menuKey(event.key), () => this.menuPress(event.key)],
      [inEditor && this.el.dataset.onSubmit && sends(event), () => this.submit()],
    ]
    const action = actions.find(([applies]) => applies)
    action && (event.preventDefault(), action[1]())
  },

  submit() {
    const value = this.html()
    const event = this.el.dataset.onSubmit
    const target = this.el.getAttribute("phx-target")
    const payload = {id: this.el.id, value, mentions: mentionsIn(this.editor().textContent, this.names().mentions)}
    value !== "" &&
      event &&
      (target ? this.pushEventTo(target, event, payload) : this.pushEventTo(this.el, event, payload),
      this.el.dataset.clearOnSubmit !== "false" && ((this.editor().innerHTML = ""), this.sync()))
  },

  askAi() {
    const event = this.el.dataset.onAi
    const target = this.el.getAttribute("phx-target")
    const payload = {id: this.el.id, value: this.html(), selection: window.getSelection().toString()}
    event && this.pushEventTo(target || this.el, event, payload)
  },

  insert(html) {
    this.exec("insertHTML", sanitize(html, this.images))
    this.sync()
  },

  items(kind) {
    const slash = [...(this.slash ?? []), ...this.variableItems()]
    const mentions = this.mentions.map((mention) => ({key: `mention:${mention.handle}`, label: mention.label, hint: `@${mention.handle}`}))
    return {slash, mention: mentions}[kind]
  },

  variableItems() {
    return variableItems(this.variables, this.el.dataset.variableLabel ?? "")
  },

  openVariables() {
    const items = this.variableItems()
    const button = this.el.querySelector('[data-tool="variable"]')
    const range = this.selectionRange()
    this.savedRange = range ? range.cloneRange() : null
    this.editor().focus()
    this.savedRange && (window.getSelection().removeAllRanges(), window.getSelection().addRange(this.savedRange))
    this.menu = {kind: "variable", tool: true, length: 0, items, index: 0}
    items.length > 0 ? this.paintMenu(button) : this.closeMenu()
  },

  kinds() {
    return [this.slash !== null && "slash", this.mentions.length > 0 && "mention"].filter(Boolean)
  },

  caret() {
    const selection = window.getSelection()
    const range = selection.rangeCount > 0 ? selection.getRangeAt(0) : null
    return range && range.collapsed && this.editor().contains(range.startContainer) && range.startContainer.nodeType === Node.TEXT_NODE ? range : null
  },

  refreshMenu() {
    if (this.menu?.tool) return
    const range = document.activeElement === this.editor() ? this.caret() : null
    const trigger = range && triggerOf(range.startContainer.textContent.slice(0, range.startOffset), this.kinds())
    const items = trigger ? filterItems(this.items(trigger.kind), trigger.query) : []
    items.length > 0 ? this.openMenu(trigger, items, range) : this.closeMenu()
  },

  openMenu(trigger, items, range) {
    const previous = this.menu
    const keep = previous && previous.kind === trigger.kind && previous.items.length === items.length
    this.menu = {kind: trigger.kind, length: trigger.length, node: range.startContainer, end: range.startOffset, items, index: keep ? previous.index : 0}
    this.paintMenu(range)
  },

  closeMenu() {
    this.menu = null
    const box = this.el.querySelector("[data-menu]")
    box && (box.hidden = true)
  },

  paintMenu(range) {
    const box = this.el.querySelector("[data-menu]")
    const title = this.el.dataset[{slash: "slashTitle", mention: "mentionTitle", variable: "variableTitle"}[this.menu.kind]] ?? ""
    const caption = document.createElement("div")
    caption.className = "ql-menu-title"
    caption.textContent = title
    const rows = this.menu.items.map((item, index) => this.row(item, index))
    box.replaceChildren(caption, ...rows)
    const at = range.getBoundingClientRect()
    const host = this.el.getBoundingClientRect()
    box.style.left = `${Math.max(at.left - host.left, 0)}px`
    box.style.top = `${at.bottom - host.top + 6}px`
    box.hidden = false
  },

  row(item, index) {
    const row = document.createElement("div")
    row.className = "ql-menu-item"
    row.setAttribute("role", "option")
    row.setAttribute("aria-selected", String(index === this.menu.index))
    row.dataset.menuIndex = String(index)
    item.icon && row.append(this.cell("ql-menu-icon", item.icon))
    row.append(this.cell("ql-menu-label", item.label))
    item.hint && row.append(this.cell("ql-menu-hint", item.hint))
    return row
  },

  cell(className, text) {
    const cell = document.createElement("span")
    cell.className = className
    cell.textContent = text
    return cell
  },

  menuKey(key) {
    return ["ArrowDown", "ArrowUp", "Enter", "Tab", "Escape", "Home", "End"].includes(key)
  },

  menuPress(key) {
    const moved = nextIndex(this.menu.index, key, this.menu.items.length)
    const actions = {
      Enter: () => this.choose(this.menu.index),
      Tab: () => this.choose(this.menu.index),
      Escape: () => this.closeMenu(),
    }
    moved === null
      ? actions[key]()
      : ((this.menu.index = moved),
        this.el.querySelectorAll("[data-menu-index]").forEach((row, index) => row.setAttribute("aria-selected", String(index === moved))))
  },

  choose(index) {
    const {length, node, end, items, tool} = this.menu
    const item = items[index]
    const range = tool ? this.savedRange : document.createRange()
    tool || (range.setStart(node, end - length), range.setEnd(node, end))
    const selection = window.getSelection()
    selection.removeAllRanges()
    range && selection.addRange(range)
    tool || range.deleteContents()
    this.closeMenu()
    this.apply(item)
    this.sync()
  },

  apply(item) {
    const [type, name] = item.key.split(":")
    const chips = {variable: `{${name}}`, mention: `@${name}`}
    const applies = {
      command: () => this.exec(...slashActions[item.key]),
      custom: () => this.pushSlash(item.key),
    }
    ;(applies[slashKind(item.key)] ?? (() => this.exec("insertHTML", `${this.chip(type, chips[type]).outerHTML}&nbsp;`)))()
  },

  pushSlash(key) {
    const event = this.el.dataset.onSlash
    const target = this.el.getAttribute("phx-target")
    event && this.pushEventTo(target || this.el, event, {id: this.el.id, key})
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
