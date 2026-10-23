/**
 * What the text editor keeps of the HTML it is given or pasted, and what its toolbar buttons do, without a DOM:
 * the tags kept, unwrapped or dropped, the attributes kept, and the browser editing command behind each tool.
 */
import {safeHref} from "./editor_logic.js"

const KEEP = new Set(["P", "BR", "B", "STRONG", "I", "EM", "U", "S", "STRIKE", "SUB", "SUP", "H1", "H2", "H3", "H4", "H5", "H6", "OL", "UL", "LI", "BLOCKQUOTE", "PRE", "CODE", "A", "SPAN", "DIV", "FONT"])
const DROP = new Set(["SCRIPT", "STYLE", "IFRAME", "OBJECT", "EMBED", "LINK", "META", "TEMPLATE", "NOSCRIPT", "SVG", "MATH", "FORM", "INPUT", "BUTTON", "TEXTAREA", "SELECT"])

/** What happens to an element: `keep` it, `unwrap` it (keep its children) or `drop` it with its children. */
export const tagAction = (tag) => (KEEP.has(tag) ? "keep" : DROP.has(tag) ? "drop" : "unwrap")

const STYLES = ["color", "background-color", "text-align"]

const cleanStyle = (style) =>
  style
    .split(";")
    .map((rule) => rule.split(":").map((part) => part.trim()))
    .filter(([property, value]) => STYLES.includes(property?.toLowerCase()) && value && !/url\(|expression/i.test(value))
    .map(([property, value]) => `${property.toLowerCase()}: ${value}`)
    .join("; ")

const ATTRIBUTES = {
  href: (value, tag) => (tag === "A" ? safeHref(value) : null),
  class: (value) => value.split(/\s+/).filter((name) => /^ql-[a-z0-9-]+$/.test(name)).join(" ") || null,
  style: (value) => cleanStyle(value) || null,
  dir: (value) => (["rtl", "ltr"].includes(value) ? value : null),
  face: (value, tag) => (tag === "FONT" ? value : null),
}

/** The value an attribute keeps, or `null` to remove it. */
export const cleanAttribute = (tag, name, value) => ATTRIBUTES[name.toLowerCase()]?.(value ?? "", tag) ?? null

/** The HTML of an empty editor as the browser leaves it, which the form gets as an empty text. */
export const isEmptyHtml = (html) => html.replace(/<(p|div|br)[^>]*>|<\/(p|div)>|&nbsp;|\s/gi, "") === ""

/** The browser command of each toolbar button: `[command, value]`, a block to toggle, or a special action. */
export const TOOLS = {
  bold: {command: "bold"},
  italic: {command: "italic"},
  underline: {command: "underline"},
  strike: {command: "strikeThrough"},
  "script-sub": {command: "subscript"},
  "script-super": {command: "superscript"},
  "list-ordered": {command: "insertOrderedList"},
  "list-bullet": {command: "insertUnorderedList"},
  "indent-minus1": {command: "outdent"},
  "indent-plus1": {command: "indent"},
  blockquote: {block: "blockquote"},
  "code-block": {block: "pre"},
  "header-1": {block: "h1"},
  "header-2": {block: "h2"},
  code: {wrap: "code"},
  "direction-rtl": {special: "direction"},
  link: {special: "link"},
  clean: {special: "clean"},
}

/** The block a toggle asks for: the block itself, or a paragraph when the text is already in it. */
export const toggleBlock = (current, block) => (current.toLowerCase() === block ? "p" : block)

/** The alignment command for a value of the align picker. */
export const alignCommand = (value) => ({center: "justifyCenter", right: "justifyRight", justify: "justifyFull"})[value] ?? "justifyLeft"

/** The value of the header picker for the block the cursor is in (`"1"`–`"6"`, or `""` for a paragraph). */
export const headerValue = (block) => (/^h[1-6]$/i.test(block) ? block.slice(1) : "")
