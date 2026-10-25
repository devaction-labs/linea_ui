import assert from "node:assert/strict"
import test from "node:test"
import {axisTipsHtml, overlaySvg, tooltipHtml} from "./chart_tooltip.js"

const hit = {
  title: "Mon <1>",
  rows: [{name: "Sales", value: "$5", color: "#4467ef"}, {name: "Open", value: "1", color: null}],
  crosshair: {x1: 10, x2: 10, y1: 0, y2: 50},
  markers: [{x: 10, y: 20, r: 5, color: "#4467ef"}],
  band: {x: 0, y: 0, w: 20, h: 50},
  axisTip: {x: 10, y: 50, text: "Mon"},
  yTip: {x: 0, y: 20, text: "20"},
}

test("the tooltip card has a title and a row per entry, escaped", () => {
  const html = tooltipHtml(hit)
  assert.equal(html.includes("Mon &lt;1&gt;"), true)
  assert.equal(html.includes('style="background:#4467ef"'), true)
  assert.equal(html.includes("<b>$5</b>"), true)
  assert.equal(tooltipHtml({...hit, title: ""}).includes("tooltip-title"), false)
})

test("a row without a color has no marker and one without a name has no name", () => {
  const html = tooltipHtml({title: "", rows: [{name: "", value: "7", color: null}]})
  assert.equal(html.includes("tooltip-marker"), false)
  assert.equal(html.includes("tooltip-name"), false)
})

test("the overlay draws the band, the crosshair and a marker per series", () => {
  const svg = overlaySvg(hit)
  assert.equal(svg.includes("linea-chart-band"), true)
  assert.equal(svg.includes('class="linea-chart-crosshair"'), true)
  assert.equal(svg.includes('r="5"'), true)
  assert.equal(overlaySvg({markers: [], band: null, crosshair: null}), "")
})

test("axis bubbles sit at their coordinates", () => {
  const html = axisTipsHtml(hit)
  assert.equal(html.includes("axistip--x"), true)
  assert.equal(html.includes("axistip--y"), true)
  assert.equal(axisTipsHtml({}), "")
})
