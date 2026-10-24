import assert from "node:assert/strict"
import test from "node:test"
import {GLYPHS, glyphElement, glyphHtml, hugeClass, iconSet} from "./glyphs.js"

test("LineOne's glyph is its stroked SVG with the class and stroke width asked for", () => {
  const html = glyphHtml("close", "lineone", {className: "size-4", strokeWidth: "2.5"})
  assert.match(html, /^<svg class="size-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">/)
  assert.match(html, /d="M6 18L18 6M6 6l12 12"/)
  assert.match(html, /<\/svg>$/)
})

test("LineOne is the default set and an unknown set", () => {
  assert.equal(glyphHtml("close"), glyphHtml("close", "lineone"))
  assert.equal(glyphHtml("close", "other"), glyphHtml("close", "lineone"))
})

test("a bare glyph carries no paint, as the flatpickr arrows have none", () => {
  const html = glyphHtml("angle_left", "lineone")
  assert.equal(html.startsWith('<svg viewBox="0 0 17 17" aria-hidden="true"><path d="M5.207'), true)
  assert.doesNotMatch(html, /fill=|stroke=/)
})

test("Hugeicons draw a span with the class of the icon, then the class asked for", () => {
  assert.equal(glyphHtml("close", "hugeicons", {className: "size-4"}), '<span class="huge-cancel-01 size-4" aria-hidden="true"></span>')
  assert.equal(glyphHtml("angle_right", "hugeicons"), '<span class="huge-arrow-right-01" aria-hidden="true"></span>')
})

test("a glyph that is not in the table draws nothing", () => {
  assert.equal(glyphHtml("nope", "lineone"), "")
  assert.equal(glyphHtml("nope", "hugeicons"), "")
  assert.equal(glyphHtml("toString", "lineone"), "")
  assert.equal(hugeClass("nope"), null)
})

test("the set comes from data-icons and falls back to LineOne", () => {
  assert.equal(iconSet({dataset: {icons: "hugeicons"}}), "hugeicons")
  assert.equal(iconSet({dataset: {icons: "lineone"}}), "lineone")
  assert.equal(iconSet({dataset: {icons: "weird"}}), "lineone")
  assert.equal(iconSet({dataset: {}}), "lineone")
  assert.equal(iconSet(null), "lineone")
})

test("every Hugeicons class is written as huge-name and every LineOne glyph has a viewBox and a body", () => {
  Object.entries(GLYPHS).forEach(([name, glyph]) => {
    assert.match(glyph.hugeicons, /^huge-[a-z0-9]+(-[a-z0-9]+)*$/, name)
    assert.ok(["stroke", "fill", "bare"].includes(glyph.lineone.paint), name)
    assert.match(glyph.lineone.view, /^\d+ \d+ \d+ \d+$/, name)
    assert.ok(glyph.lineone.body.startsWith("<path"), name)
  })
})

test("glyphElement parses the markup with the document it is given", () => {
  const made = []
  const document = {
    createElement: (tag) => {
      const template = {tag, content: {firstElementChild: null}, set innerHTML(html) { made.push(html); this.content.firstElementChild = {html} }}
      return template
    },
  }
  const element = glyphElement("close", "hugeicons", {className: "size-4"}, document)
  assert.equal(element.html, '<span class="huge-cancel-01 size-4" aria-hidden="true"></span>')
  assert.equal(made.length, 1)
})
