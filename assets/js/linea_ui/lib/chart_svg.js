/**
 * A tiny SVG tree: `h(tag, attrs, ...children)` builds nodes, `render` writes them as markup. Attribute
 * values and text are escaped; `null`, `undefined` and `false` attributes and children disappear.
 */

const ESCAPES = {"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;"}

export const escape = (value) => String(value).replace(/[&<>"]/g, (char) => ESCAPES[char])

const present = (value) => value !== null && value !== undefined && value !== false

const round = (value) => (typeof value === "number" ? Math.round(value * 100) / 100 : value)

export const h = (tag, attrs = {}, ...children) => ({tag, attrs: attrs ?? {}, children: children.flat(Infinity).filter(present)})

const attributes = (attrs) =>
  Object.entries(attrs)
    .filter(([, value]) => present(value))
    .map(([name, value]) => ` ${name}="${escape(value === true ? "" : round(value))}"`)
    .join("")

export const render = (node) =>
  typeof node === "object"
    ? `<${node.tag}${attributes(node.attrs)}>${node.children.map(render).join("")}</${node.tag}>`
    : escape(node)
