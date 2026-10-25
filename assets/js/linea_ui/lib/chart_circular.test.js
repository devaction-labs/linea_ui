import assert from "node:assert/strict"
import test from "node:test"
import {configure} from "./chart_config.js"
import {centerText, drawCircular, geometry, hoverText, sliceAt, slicesOf} from "./chart_circular.js"
import {legendBox} from "./chart_legend.js"
import {estimateWidth} from "./chart_scale.js"
import {h, render} from "./chart_svg.js"

const setup = (options, {width = 323, height, hidden = []} = {}) => {
  const config = configure(options)
  const slices = slicesOf(config, hidden)
  const legend = legendBox(config, {series: []}, {width, measure: estimateWidth, hidden})
  const g = geometry(config, {width, height: height ?? config.chart.height, legend})
  const drawn = drawCircular(config, g, slices)
  return {config, slices, legend, g, drawn, svg: render(h("g", {}, drawn.layers.tracks, drawn.layers.series, drawn.layers.labels, drawn.layers.center))}
}

const donut = {chart: {type: "donut", height: 280}, labels: ["Direct", "Social", "Email", "Referral"], series: [44, 55, 13, 33], legend: {position: "bottom"}, dataLabels: {enabled: false}}

test("a donut sits in the room the bottom legend leaves, with ApexCharts' radius", () => {
  const {g} = setup(donut)
  assert.equal(Math.round(g.size), 114)
  assert.equal(g.cx, 161.5)
  assert.equal(g.height, 280)
})

test("a gauge without legend fills the height and shrinks the SVG to what it draws", () => {
  const {g} = setup({chart: {type: "radialBar", height: 280}, series: [76]}, {width: 323})
  assert.equal(g.height, 283)
  assert.equal(Math.round(g.size * 10) / 10, 130.6)
})

test("grid padding moves the circle and changes the SVG height like ApexCharts", () => {
  const {g} = setup({chart: {type: "radialBar", height: 250}, series: [44, 55, 67], grid: {padding: {left: 0, right: 0, bottom: -20, top: -20}}}, {width: 244.3})
  assert.equal(g.height, 207)
  assert.equal(Math.round(g.cx), 122)
})

test("slices share the circle by value, in order, as arcs that start at the top", () => {
  const {drawn, slices} = setup(donut)
  const total = slices.reduce((sum, slice) => sum + slice.value, 0)
  assert.equal(drawn.hits.length, 4)
  assert.equal(drawn.hits[0].a0, 0)
  assert.equal(Math.round(drawn.hits[0].a1), Math.round((44 / total) * 360))
  assert.equal(Math.round(drawn.hits.at(-1).a1), 360)
})

test("a pie has no hole and a donut leaves 35% of the radius", () => {
  assert.equal(setup({...donut, chart: {type: "pie", height: 280}}).drawn.hits[0].inner, 0)
  const {drawn, g} = setup(donut)
  assert.equal(Math.round((drawn.hits[0].inner / g.size) * 100), 65)
})

test("the pointer finds the slice by angle and ring", () => {
  const {drawn, g} = setup(donut)
  const radius = (g.size + drawn.hits[0].inner) / 2
  assert.equal(sliceAt(drawn.hits, g, g.cx + 5, g.cy - radius).index, 0)
  assert.equal(sliceAt(drawn.hits, g, g.cx - 5, g.cy - radius).index, 3)
  assert.equal(sliceAt(drawn.hits, g, g.cx, g.cy), null)
  assert.equal(sliceAt(drawn.hits, g, g.cx, g.cy - g.size - 20), null)
})

test("hiding a slice gives its share to the others", () => {
  const {drawn} = setup(donut, {hidden: [1]})
  assert.deepEqual(drawn.hits.map((arc) => arc.index), [0, 2, 3])
})

test("data labels show percentages on slices wide enough", () => {
  const {svg} = setup({...donut, series: [100, 55, 1], labels: ["a", "b", "c"], dataLabels: {enabled: true}})
  assert.equal(svg.includes(">64.1%<"), true)
  assert.equal(svg.includes(">0.6%<"), false)
})

test("rings of a radial bar have a track each and stop at their percentage", () => {
  const {svg, drawn} = setup({chart: {type: "radialBar", height: 280}, series: [50, 100], labels: ["A", "B"]})
  assert.equal((svg.match(/linea-chart-track/g) ?? []).length, 2)
  assert.equal((svg.match(/linea-chart-ring/g) ?? []).length, 2)
  assert.equal(drawn.hits.length, 0)
})

test("a gauge sweeps over its own angles", () => {
  const {svg} = setup({chart: {type: "radialBar", height: 200, sparkline: {enabled: true}}, series: [50], plotOptions: {radialBar: {startAngle: -90, endAngle: 90}}})
  assert.equal(svg.includes("A "), true)
})

test("the middle reads the total, the single value, or nothing", () => {
  const total = centerText(configure({chart: {type: "radialBar"}, series: [10, 20], plotOptions: {radialBar: {dataLabels: {total: {show: true, label: "Sum", formatter: (w) => w.globals.seriesTotals.reduce((a, b) => a + b, 0)}}}}}), slicesOf(configure({series: [10, 20]})))
  assert.deepEqual([total.name, total.value, total.opacity], ["Sum", "30", 1])
  const single = centerText(configure({chart: {type: "radialBar"}, series: [65]}), slicesOf(configure({series: [65]})))
  assert.deepEqual([single.value, single.opacity], ["65%", 1])
  const many = centerText(configure({chart: {type: "radialBar"}, series: [1, 2]}), slicesOf(configure({series: [1, 2]})))
  assert.equal(many.opacity, 0)
})

test("a donut shows its middle only when labels are on, and on hover names the slice", () => {
  const options = {chart: {type: "donut"}, labels: ["A", "B"], series: [1, 3], plotOptions: {pie: {donut: {labels: {show: true, total: {show: true, label: "Total"}}}}}}
  const config = configure(options)
  const slices = slicesOf(config)
  assert.equal(centerText(config, slices).value, "4")
  assert.deepEqual(hoverText(config, slices[1], slices), {name: "B", value: "3"})
  assert.equal(centerText(configure({...options, plotOptions: {}}), slices).opacity, 0)
})
