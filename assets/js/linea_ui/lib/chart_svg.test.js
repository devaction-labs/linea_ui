import assert from "node:assert/strict"
import test from "node:test"
import {escape, h, render} from "./chart_svg.js"

test("nodes render with escaped attributes and text", () => {
  assert.equal(render(h("text", {x: 1.234, "data-x": 'a"b'}, "<&>")), '<text x="1.23" data-x="a&quot;b">&lt;&amp;&gt;</text>')
})

test("null, undefined and false attributes and children vanish, true is an empty attribute", () => {
  assert.equal(render(h("g", {a: null, b: undefined, c: false, hidden: true}, null, false, [h("i")])), '<g hidden=""><i></i></g>')
  assert.equal(escape(5), "5")
})
