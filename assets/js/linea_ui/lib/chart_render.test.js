import assert from "node:assert/strict"
import test from "node:test"
import {build} from "./chart_render.js"

const env = {width: 400, viewport: 1200, uid: "x"}

const radar = {chart: {type: "radar", height: 280}, series: [{name: "Score", data: [80, 50, 30, 40, 100, 20]}], xaxis: {categories: ["Speed", "Power", "Range", "Agility", "Focus", "Luck"]}}

test("every supported type builds an SVG with a title and a description", () => {
  const options = {
    line: {chart: {type: "line", height: 200}, series: [{name: "A", data: [1, 2, 3]}]},
    area: {chart: {type: "area", height: 200}, series: [{name: "A", data: [1, 2, 3]}]},
    bar: {chart: {type: "bar", height: 200}, series: [{name: "A", data: [1, 2, 3]}]},
    rangeBar: {chart: {type: "rangeBar", height: 200}, series: [{data: [{x: "a", y: [1, 2]}]}]},
    candlestick: {chart: {type: "candlestick", height: 200}, series: [{data: [{x: "a", y: [1, 5, 0, 3]}]}]},
    donut: {chart: {type: "donut", height: 200}, series: [1, 2], labels: ["a", "b"]},
    pie: {chart: {type: "pie", height: 200}, series: [1, 2]},
    radialBar: {chart: {type: "radialBar", height: 200}, series: [40]},
    radar,
  }
  Object.entries(options).forEach(([type, given]) => {
    const built = build(given, env)
    assert.equal(built.svg.startsWith("<svg"), true, type)
    assert.equal(built.svg.includes('role="img"'), true, type)
    assert.equal(built.svg.includes('<title id="x-title">'), true, type)
    assert.equal(built.svg.includes('<desc id="x-desc">'), true, type)
    assert.equal(typeof built.probe, "function", type)
  })
})

test("an unknown type is drawn as a line and an empty chart as an empty frame", () => {
  assert.equal(build({chart: {type: "scatter", height: 150}, series: [{data: [1, 2]}]}, env).config.type, "line")
  assert.equal(build({chart: {type: "polarArea", height: 150}, series: [1, 2]}, env).config.type, "pie")
  assert.equal(build({}, env).svg.startsWith("<svg"), true)
  assert.equal(build({chart: {type: "bar", height: 100}, series: []}, env).svg.startsWith("<svg"), true)
})

test("the svg takes the width and the configured height", () => {
  const built = build({chart: {type: "bar", height: 250}, series: [{data: [1]}]}, env)
  assert.equal(built.height, 250)
  assert.equal(built.svg.includes('width="400" height="250"'), true)
})

test("the legend comes back as markup beside the svg", () => {
  const built = build({chart: {type: "bar", height: 250}, series: [{name: "A", data: [1]}, {name: "B", data: [2]}]}, env)
  assert.equal(built.legendHtml.includes('data-series="1"'), true)
  assert.equal(build({chart: {type: "bar", height: 250}, series: [{name: "A", data: [1]}]}, env).legendHtml, "")
})

test("responsive options apply for the viewport given", () => {
  const options = {chart: {type: "bar", height: 250}, series: [{data: [1]}], responsive: [{breakpoint: 600, options: {chart: {height: 100}}}]}
  assert.equal(build(options, env).height, 250)
  assert.equal(build(options, {...env, viewport: 500}).height, 100)
})

test("a radar answers the pointer near a vertex with the category and the value", () => {
  const built = build(radar, env)
  const hit = built.probe(built.layout.cx, built.layout.cy - 0.8 * built.layout.size)
  assert.equal(hit.title, "Speed")
  assert.equal(hit.rows[0].value, "80")
  assert.equal(built.probe(0, 0), null)
})

test("a donut answers with the slice and dark tooltip colors", () => {
  const built = build({chart: {type: "donut", height: 280}, series: [1, 1], labels: ["a", "b"], legend: {show: false}}, env)
  const hit = built.probe(built.g.cx + 5, built.g.cy - (built.g.size * 0.8))
  assert.equal(hit.rows[0].name, "a")
  assert.equal(hit.theme, "dark")
  assert.equal(typeof hit.fill, "string")
})

test("a tooltip can be turned off", () => {
  const built = build({chart: {type: "donut", height: 280}, series: [1, 1], tooltip: {enabled: false}, legend: {show: false}}, env)
  assert.equal(built.probe(built.g.cx + 5, built.g.cy - built.g.size * 0.8), null)
})

test("a cartesian chart lists the slots a keyboard visits and answers at each one", () => {
  const result = build({chart: {type: "line", height: 200}, series: [{name: "A", data: [1, 3, 2]}], xaxis: {categories: ["a", "b", "c"]}}, {width: 400})
  assert.deepEqual(result.keys.slots, [0, 1, 2])
  const hit = result.probe(result.keys.at(1).x, result.keys.at(1).y)
  assert.equal(hit.slot, 1)
  assert.equal(hit.title, "b")
  assert.deepEqual(build({chart: {type: "donut"}, series: [1, 2], labels: ["x", "y"]}, {width: 300}).keys.slots, [0, 1])
})

test("a pie or donut is visited slice by slice from the keyboard, with the tooltip of the slice", () => {
  const donut = build({chart: {type: "donut", height: 240}, labels: ["Web", "App", "Zero"], series: [60, 40, 0]}, env)
  assert.deepEqual(donut.keys.slots, [0, 1])
  const hit = donut.keys.hit(1)
  assert.equal(hit.rows[0].name, "App")
  assert.equal(hit.active.slice, 1)
  assert.equal(hit.center.name, "App")
  const at = donut.keys.at(1)
  assert.equal(donut.probe(at.x, at.y).slot, 1)
  assert.equal(donut.keys.hit(2), null)
  assert.deepEqual(build({chart: {type: "radialBar", height: 200}, series: [40]}, env).keys.slots, [])
  assert.equal(build({chart: {type: "donut", height: 240}, tooltip: {enabled: false}, series: [1, 2]}, env).keys.hit(0), null)
})

test("a radar is visited spoke by spoke, the tooltip listing every series on it", () => {
  const two = {...radar, series: [{name: "A", data: [80, 50, 30, 40, 100, 20]}, {name: "B", data: [10, 20, 30, 40, 50, 60]}]}
  const built = build(two, env)
  assert.deepEqual(built.keys.slots, [0, 1, 2, 3, 4, 5])
  const hit = built.keys.hit(1)
  assert.equal(hit.title, "Power")
  assert.deepEqual(hit.rows.map((row) => row.name), ["A", "B"])
  assert.equal(hit.markers.length, 2)
  assert.equal(build(two, {...env, hidden: [0, 1]}).keys.slots.length, 0)
  assert.equal(build({...two, tooltip: {enabled: false}}, env).keys.hit(1), null)
})
