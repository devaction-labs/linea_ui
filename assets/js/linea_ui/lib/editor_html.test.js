import {test} from "node:test"
import assert from "node:assert/strict"
import {TOOLS, alignCommand, cleanAttribute, headerValue, isEmptyHtml, tagAction, toggleBlock} from "./editor_html.js"

test("tagAction keeps formatting, drops scripts, unwraps the rest", () => {
  assert.equal(tagAction("STRONG"), "keep")
  assert.equal(tagAction("BLOCKQUOTE"), "keep")
  assert.equal(tagAction("SCRIPT"), "drop")
  assert.equal(tagAction("IFRAME"), "drop")
  assert.equal(tagAction("TABLE"), "unwrap")
})

test("cleanAttribute keeps safe links, quill classes and a few styles", () => {
  assert.equal(cleanAttribute("A", "href", "https://example.com"), "https://example.com")
  assert.equal(cleanAttribute("A", "href", "javascript:alert(1)"), null)
  assert.equal(cleanAttribute("SPAN", "href", "https://example.com"), null)
  assert.equal(cleanAttribute("SPAN", "class", "ql-size-large evil"), "ql-size-large")
  assert.equal(cleanAttribute("SPAN", "class", "evil"), null)
  assert.equal(cleanAttribute("SPAN", "style", "color: red; position: fixed"), "color: red")
  assert.equal(cleanAttribute("SPAN", "style", "background-color: url(x)"), null)
  assert.equal(cleanAttribute("P", "onclick", "x()"), null)
  assert.equal(cleanAttribute("P", "dir", "rtl"), "rtl")
})

test("isEmptyHtml", () => {
  assert.equal(isEmptyHtml("<p><br></p>"), true)
  assert.equal(isEmptyHtml(""), true)
  assert.equal(isEmptyHtml("<p>Hi</p>"), false)
})

test("tool helpers", () => {
  assert.equal(TOOLS.bold.command, "bold")
  assert.equal(TOOLS["header-1"].block, "h1")
  assert.equal(toggleBlock("h1", "h1"), "p")
  assert.equal(toggleBlock("p", "h1"), "h1")
  assert.equal(alignCommand("center"), "justifyCenter")
  assert.equal(alignCommand(""), "justifyLeft")
  assert.equal(headerValue("h3"), "3")
  assert.equal(headerValue("p"), "")
})
