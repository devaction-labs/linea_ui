import assert from "node:assert/strict"
import test from "node:test"
import {configure} from "./chart_config.js"
import {legendBox} from "./chart_legend.js"
import {drawRadar, radarPlan, vertexAt} from "./chart_radar.js"
import {estimateWidth} from "./chart_scale.js"
import {prepare} from "./chart_series.js"
import {h, render} from "./chart_svg.js"

const options = {
  chart: {type: "radar", height: 280},
  series: [{name: "A", data: [80, 50, 30, 40, 100, 20]}, {name: "B", data: [20, 30, 40, 80, 20, 80]}],
  xaxis: {categories: ["Speed", "Power", "Range", "Agility", "Focus", "Luck"]},
}

const setup = (given = options, width = 400) => {
  const config = configure(given)
  const data = prepare(config)
  const legend = legendBox(config, data, {width, measure: estimateWidth})
  const plan = radarPlan(config, data, {width, height: config.chart.height, legend, measure: estimateWidth})
  const drawn = drawRadar(config, plan, data)
  return {config, data, plan, drawn, svg: render(h("g", {}, drawn.layers.grid, drawn.layers.axes, drawn.layers.series, drawn.layers.labels))}
}

test("the rings follow the value ticks, from zero to the next round number above the data", () => {
  const {plan} = setup()
  assert.deepEqual(plan.ticks, [0, 20, 40, 60, 80, 100])
  assert.equal(plan.count, 6)
})

test("the plan keeps the chart centered under the top margin", () => {
  const {plan} = setup({...options, series: [options.series[0]]})
  assert.equal(plan.cx, 200)
  assert.equal(plan.cy, 30 + (280 - 35) / 2)
  assert.equal(plan.size > 60 && plan.size < 120, true)
})

test("every ring, spoke and category gets its own node", () => {
  const {svg} = setup()
  assert.equal((svg.match(/linea-chart-polygon/g) ?? []).length, 6)
  assert.equal((svg.match(/linea-chart-spoke/g) ?? []).length, 6)
  assert.equal(svg.includes(">Agility<"), true)
  assert.equal((svg.match(/class="linea-chart-series linea-chart-pop"/g) ?? []).length, 2)
})

test("the vertices land on the spoke at the value's share of the radius", () => {
  const {drawn, plan} = setup()
  const first = drawn.hits.find((point) => point.series === 0 && point.slot === 0)
  assert.equal(Math.round(first.x), Math.round(plan.cx))
  assert.equal(Math.round(plan.cy - first.y), Math.round(plan.size * 0.8))
})

test("the pointer finds the nearest vertex within reach only", () => {
  const {drawn} = setup()
  const target = drawn.hits[0]
  assert.equal(vertexAt(drawn.hits, target.x + 3, target.y - 2).slot, 0)
  assert.equal(vertexAt(drawn.hits, target.x + 200, target.y), null)
})

test("data labels and markers are optional", () => {
  assert.equal(setup().svg.includes("linea-chart-datalabel"), false)
  assert.equal(setup({...options, dataLabels: {enabled: true}}).svg.includes("linea-chart-datalabel"), true)
  assert.equal(setup({...options, markers: {size: 0}}).svg.includes("linea-chart-marker"), false)
})
