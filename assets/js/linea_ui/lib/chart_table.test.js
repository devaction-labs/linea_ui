import assert from "node:assert/strict"
import test from "node:test"
import {build} from "./chart_render.js"
import {stageHtml} from "./chart_stage.js"
import {tableHtml} from "./chart_table.js"

const env = {width: 400, viewport: 1200, uid: "t"}

test("series become columns and categories rows", () => {
  const {table} = build({chart: {type: "bar", height: 200}, xaxis: {categories: ["Jan", "Feb"]}, series: [{name: "A", data: [1, 2.5]}, {name: "B", data: [3, null]}]}, env)
  assert.equal(table.startsWith('<table class="linea-chart-sr"><caption>Bar chart</caption>'), true)
  assert.equal(table.includes("<th>A</th><th>B</th>"), true)
  assert.equal(table.includes("<th>Feb</th><td>2.5</td><td></td>"), true)
})

test("candles and ranges print their parts", () => {
  const candle = build({chart: {type: "candlestick", height: 200}, series: [{name: "c", data: [{x: "a", y: [1, 5, 0, 3]}]}]}, env).table
  assert.equal(candle.includes("<td>1 / 5 / 0 / 3</td>"), true)
  const range = build({chart: {type: "rangeBar", height: 200}, series: [{name: "r", data: [{x: "a", y: [10, 20]}]}]}, env).table
  assert.equal(range.includes("<td>10 - 20</td>"), true)
})

test("slices become a name and a value, escaped", () => {
  const html = tableHtml("Donut", {slices: [{name: "<x>", value: 4}], data: null})
  assert.equal(html.includes("<th>&lt;x&gt;</th><td>4</td>"), true)
})

test("the stage wraps the svg, the legend, the tooltip slots and the table", () => {
  const built = build({chart: {type: "bar", height: 200}, series: [{name: "A", data: [1]}, {name: "B", data: [2]}]}, env)
  const html = stageHtml(built, {entering: true})
  assert.equal(html.startsWith('<div class="linea-chart-stage linea-chart--enter" style="height:200px"><svg'), true)
  assert.equal(html.includes('class="linea-chart-legend" data-position="bottom"'), true)
  assert.equal(html.includes("linea-chart-tooltip"), true)
  assert.equal(html.includes("linea-chart-axistips"), true)
  assert.equal(html.includes("<table"), true)
  assert.equal(stageHtml(built, {entering: false}).includes("linea-chart--enter"), false)
})

test("a chart without a legend has none in the stage", () => {
  const built = build({chart: {type: "bar", height: 200}, series: [{name: "A", data: [1]}]}, env)
  assert.equal(stageHtml(built, {entering: false}).includes("linea-chart-legend"), false)
})
