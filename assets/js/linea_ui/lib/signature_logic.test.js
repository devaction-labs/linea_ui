import assert from "node:assert/strict"
import test from "node:test"
import {escapeXml, hasInk, incomingValue, modesOf, pathOf, pointIn, svgOf, svgUri} from "./signature_logic.js"

const size = {width: 300, height: 170}

test("a pointer is placed inside the pad and rounded to a tenth", () => {
  assert.deepEqual(pointIn({left: 10, top: 20}, 52.26, 70), [42.3, 50])
})

test("strokes become one path, a lone point becomes a dot, and empty strokes are skipped", () => {
  assert.equal(pathOf([[[1, 2], [3, 4], [5, 6]], [[7, 8]]]), "M1 2L3 4L5 6 M7 8L7 8")
  assert.equal(pathOf([[], []]), "")
  assert.equal(pathOf([]), "")
})

test("text is made safe for XML", () => {
  assert.equal(escapeXml(`<a href="x">Tom & Jerry</a>`), "&lt;a href=&quot;x&quot;&gt;Tom &amp; Jerry&lt;/a&gt;")
})

test("there is ink when strokes are drawn or a name is typed, by the mode", () => {
  assert.ok(hasInk({mode: "draw", strokes: [[[1, 1]]], text: ""}))
  assert.ok(!hasInk({mode: "draw", strokes: [], text: "Ana"}))
  assert.ok(hasInk({mode: "type", strokes: [], text: " Ana "}))
  assert.ok(!hasInk({mode: "type", strokes: [[[1, 1]]], text: "   "}))
})

test("a drawn signature exports one path in the pad's box", () => {
  const svg = svgOf({mode: "draw", strokes: [[[1, 2], [3, 4]]], text: "", size, ink: "#0F172A"})
  assert.match(svg, /^<svg xmlns="http:\/\/www\.w3\.org\/2000\/svg" width="300" height="170" viewBox="0 0 300 170">/)
  assert.match(svg, /<path d="M1 2L3 4" fill="none" stroke="#0F172A"/)
  assert.match(svg, /<\/svg>$/)
})

test("a typed signature exports the escaped name as text", () => {
  const svg = svgOf({mode: "type", strokes: [], text: " A<b>& ", size, ink: "#000"})
  assert.match(svg, /<text x="44" y="118" /)
  assert.match(svg, />A&lt;b&gt;&amp;<\/text>/)
})

test("nothing to sign exports nothing", () => {
  assert.equal(svgOf({mode: "draw", strokes: [], text: "", size, ink: "#000"}), "")
  assert.equal(svgOf({mode: "type", strokes: [], text: "", size, ink: "#000"}), "")
})

test("the SVG can be shown as an image", () => {
  assert.equal(svgUri("<svg/>"), "data:image/svg+xml;charset=utf-8,%3Csvg%2F%3E")
})

test("the server's signature wins only when it changed and is not what the pad made", () => {
  assert.equal(incomingValue({server: "<svg>b</svg>", previous: "<svg>a</svg>", current: "<svg>a</svg>"}), "<svg>b</svg>")
  assert.equal(incomingValue({server: "", previous: "<svg>a</svg>", current: "<svg>a</svg>"}), "")
  assert.equal(incomingValue({server: "<svg>a</svg>", previous: "<svg>a</svg>", current: "<svg>c</svg>"}), null)
  assert.equal(incomingValue({server: "<svg>c</svg>", previous: "<svg>a</svg>", current: "<svg>c</svg>"}), null)
})

test("the modes come from a list and fall back to both", () => {
  assert.deepEqual(modesOf("draw,type"), ["draw", "type"])
  assert.deepEqual(modesOf("type"), ["type"])
  assert.deepEqual(modesOf("scribble"), ["draw", "type"])
  assert.deepEqual(modesOf(undefined), ["draw", "type"])
})
