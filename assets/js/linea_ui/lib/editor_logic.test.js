import test from "node:test"
import assert from "node:assert/strict"
import {blocks, commands, currentStyle, filterItems, imageHtml, imageProblem, imageSize, mentionsIn, names, nextIndex, rowParts, safeHref, safeSrc, sends, slashActions, slashKind, styles, textboxAttributes, toggleAction, tokenize, triggerOf, uploadError, variableItems, wordCount, wordsLabel} from "./editor_logic.js"

const chain = () => {
  const calls = []
  const proxy = new Proxy({}, {get: (_t, name) => (...args) => { calls.push([name, ...args]); return proxy }})
  return {proxy, calls}
}

test("every command runs one command of the chain and says whether it is on", () => {
  for (const name of names) {
    const {proxy, calls} = chain()
    commands[name].run(proxy)
    assert.equal(calls.length, 1, name)
    assert.equal(typeof commands[name].active({isActive: () => true}), "boolean", name)
  }
})

test("the marks and blocks ask the editor whether they are active", () => {
  const editor = {isActive: (name) => name === "bold"}
  assert.equal(commands.bold.active(editor), true)
  assert.equal(commands.italic.active(editor), false)
  assert.equal(commands.undo.active(editor), false)
})

test("the style of the cursor is the heading it is in, or paragraph", () => {
  const inside = (level) => ({isActive: (name, attrs) => name === "heading" && attrs.level === level})
  assert.equal(currentStyle(inside(2)), "h2")
  assert.equal(currentStyle(inside(3)), "h3")
  assert.equal(currentStyle(inside(1)), "paragraph")
  const {proxy, calls} = chain()
  styles.h3(proxy)
  assert.deepEqual(calls, [["toggleHeading", {level: 3}]])
})

test("a link keeps http, https and mailto, adds https to a bare address and drops the rest", () => {
  assert.equal(safeHref("https://a.example/x"), "https://a.example/x")
  assert.equal(safeHref("  a.example  "), "https://a.example")
  assert.equal(safeHref("mailto:a@b.example"), "mailto:a@b.example")
  assert.equal(safeHref("javascript:alert(1)"), null)
  assert.equal(safeHref("data:text/html,x"), null)
  assert.equal(safeHref(""), null)
  assert.equal(safeHref(null), null)
})

test("the words are counted by their spaces", () => {
  assert.equal(wordCount("one  two\nthree"), 3)
  assert.equal(wordCount("   "), 0)
  assert.equal(wordCount(null), 0)
})


test("every block of the slash menu runs one command", () => {
  for (const [name, run] of Object.entries(blocks)) {
    const {proxy, calls} = chain()
    run(proxy)
    assert.equal(calls.length, 1, name)
  }
})

test("a menu is filtered by what was typed, ignoring case, and keeps its order", () => {
  const items = [{label: "Heading 2"}, {label: "Bulleted list"}, {label: "Heading 3"}]
  assert.deepEqual(filterItems(items, "head").map((i) => i.label), ["Heading 2", "Heading 3"])
  assert.equal(filterItems(items, "").length, 3)
  assert.equal(filterItems(items, null).length, 3)
  assert.equal(filterItems(items, "zzz").length, 0)
})

test("the highlight goes around the menu and the other keys are not its", () => {
  assert.equal(nextIndex(0, "ArrowDown", 3), 1)
  assert.equal(nextIndex(2, "ArrowDown", 3), 0)
  assert.equal(nextIndex(0, "ArrowUp", 3), 2)
  assert.equal(nextIndex(1, "Home", 3), 0)
  assert.equal(nextIndex(1, "End", 3), 2)
  assert.equal(nextIndex(1, "a", 3), null)
  assert.equal(nextIndex(0, "ArrowDown", 0), null)
})

test("an image is refused by its type before its size, and a good one passes", () => {
  const max = 1000
  assert.equal(imageProblem({type: "image/png", size: 10}, max), null)
  assert.equal(imageProblem({type: "image/webp", size: 1000}, max), null)
  assert.equal(imageProblem({type: "image/svg+xml", size: 10}, max), "unsupported")
  assert.equal(imageProblem({type: "application/pdf", size: 2000}, max), "unsupported")
  assert.equal(imageProblem({type: "image/jpeg", size: 1001}, max), "too_large")
})

test("the answer of an upload is a known key or failed", () => {
  assert.equal(uploadError({error: "too_large"}), "too_large")
  assert.equal(uploadError({error: "unsupported"}), "unsupported")
  assert.equal(uploadError({error: "boom"}), "failed")
  assert.equal(uploadError(null), "failed")
})

test("a comment is sent by command or control with enter, and by nothing else", () => {
  assert.equal(sends({key: "Enter", metaKey: true}), true)
  assert.equal(sends({key: "Enter", ctrlKey: true}), true)
  assert.equal(sends({key: "Enter"}), false)
  assert.equal(sends({key: "a", metaKey: true}), false)
})

test("the toolbar keys move round the tools, Home and End go to the ends, other keys are left alone", async () => {
  const {toolbarTarget} = await import("./editor_logic.js")
  assert.equal(toolbarTarget("ArrowRight", 2, 3), 0)
  assert.equal(toolbarTarget("ArrowLeft", 0, 3), 2)
  assert.equal(toolbarTarget("Home", 2, 3), 0)
  assert.equal(toolbarTarget("End", 0, 3), 2)
  assert.equal(toolbarTarget("a", 0, 3), null)
})

test("the text area is named by its label, or by the visible label when there is one", () => {
  const plain = textboxAttributes({label: "Notes", invalid: false, disabled: false})
  assert.equal(plain["aria-label"], "Notes")
  assert.equal(plain["aria-labelledby"], null)
  assert.equal(plain["aria-invalid"], null)

  const labelled = textboxAttributes({label: "Notes", labelledby: "e-label", describedby: "e-error", invalid: true, disabled: true})
  assert.equal(labelled["aria-label"], null)
  assert.equal(labelled["aria-labelledby"], "e-label")
  assert.equal(labelled["aria-describedby"], "e-error")
  assert.equal(labelled["aria-invalid"], "true")
  assert.equal(labelled["aria-disabled"], "true")
})

test("a menu row has the label, and the icon and the hint when the item has them", () => {
  assert.deepEqual(rowParts({label: "Heading"}).map((part) => part.text), ["Heading"])
  assert.deepEqual(rowParts({label: "Heading", icon: "H", hint: "#"}).map((part) => part.text), ["H", "Heading", "#"])
})

test("the caret after a / or an @ asks for its menu", () => {
  assert.deepEqual(triggerOf("Hello /ti", ["slash", "mention"]), {kind: "slash", query: "ti", length: 3})
  assert.deepEqual(triggerOf("/", ["slash"]), {kind: "slash", query: "", length: 1})
  assert.deepEqual(triggerOf("ask @jul", ["slash", "mention"]), {kind: "mention", query: "jul", length: 4})
  assert.equal(triggerOf("a/b", ["slash"]), null)
  assert.equal(triggerOf("mail@x", ["mention"]), null)
  assert.equal(triggerOf("/x", ["mention"]), null)
})

test("known variables and mentions become tokens, the rest stays text", () => {
  const parts = tokenize("Hi {cliente}, ask @ana-s and @bob; {other}", {variables: ["cliente"], mentions: ["ana-s"]})
  assert.deepEqual(parts, [
    {text: "Hi "},
    {kind: "variable", name: "cliente", text: "{cliente}"},
    {text: ", ask "},
    {kind: "mention", name: "ana-s", text: "@ana-s"},
    {text: " and @bob; {other}"},
  ])
  assert.deepEqual(tokenize("plain", {}), [{text: "plain"}])
  assert.deepEqual(tokenize("", {variables: ["a"]}), [])
  assert.deepEqual(mentionsIn("@ana-s @ana-s @bob @ana-sx", ["ana-s", "bob"]), ["ana-s", "bob"])
})

test("the slash menu knows its commands and the footer its words", () => {
  assert.deepEqual(slashActions.h2, ["formatBlock", "h2"])
  assert.equal(wordsLabel("one two  three", "words"), "3 words")
})

test("a slash entry is a built-in block, a chip, or a custom command for the server", () => {
  assert.equal(slashKind("h2"), "command")
  assert.equal(slashKind("variable:cliente"), "variable")
  assert.equal(slashKind("mention:ana"), "mention")
  assert.equal(slashKind("insert-image"), "custom")
  assert.equal(slashKind("variable"), "custom")
})

test("safeSrc accepts http(s) and relative paths only", () => {
  assert.equal(safeSrc(" https://example.com/a.png "), "https://example.com/a.png")
  assert.equal(safeSrc("http://example.com/a.png"), "http://example.com/a.png")
  assert.equal(safeSrc("/a.png"), "/a.png")
  assert.equal(safeSrc("img/a.png"), "img/a.png")
  assert.equal(safeSrc("../a.png"), "../a.png")
  assert.equal(safeSrc("data:image/svg+xml,<svg/>"), null)
  assert.equal(safeSrc("JavaScript:alert(1)"), null)
  assert.equal(safeSrc("java\tscript:alert(1)"), null)
  assert.equal(safeSrc("ftp://example.com/a.png"), null)
  assert.equal(safeSrc("//example.com/a.png"), null)
  assert.equal(safeSrc("https://"), null)
  assert.equal(safeSrc(""), null)
  assert.equal(safeSrc(null), null)
})

test("imageSize keeps whole pixels from 1 to 4000", () => {
  assert.equal(imageSize("320"), "320")
  assert.equal(imageSize(" 0480 "), "480")
  assert.equal(imageSize("0"), null)
  assert.equal(imageSize("4001"), null)
  assert.equal(imageSize("12.5"), null)
  assert.equal(imageSize("auto"), null)
})

test("imageHtml escapes the address and the description, and refuses an unsafe address", () => {
  assert.equal(imageHtml("https://e.com/a.png?x=1&y=2", 'A "photo"'), '<img src="https://e.com/a.png?x=1&amp;y=2" alt="A &quot;photo&quot;">')
  assert.equal(imageHtml("/a.png"), '<img src="/a.png" alt="">')
  assert.equal(imageHtml("javascript:alert(1)", "x"), null)
})

test("toggleAction unwraps inside the element and wraps outside", () => {
  assert.equal(toggleAction(true), "unwrap")
  assert.equal(toggleAction(false), "wrap")
})

test("variableItems makes one chip entry per name", () => {
  assert.deepEqual(variableItems(["cliente", "preço"], "Variable"), [
    {key: "variable:cliente", label: "{cliente}", hint: "Variable"},
    {key: "variable:preço", label: "{preço}", hint: "Variable"},
  ])
  assert.deepEqual(variableItems([], "x"), [])
  assert.equal(slashKind("variable:cliente"), "variable")
})
