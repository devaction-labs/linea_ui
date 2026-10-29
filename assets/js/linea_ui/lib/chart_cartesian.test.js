import assert from "node:assert/strict"
import test from "node:test"
import {draw, plan} from "./chart_cartesian.js"
import {configure} from "./chart_config.js"
import {hover} from "./chart_hover.js"
import {legendBox} from "./chart_legend.js"
import {estimateWidth} from "./chart_scale.js"
import {prepare} from "./chart_series.js"
import {h, render} from "./chart_svg.js"

const build = (options, {width = 600, height, hidden = []} = {}) => {
  const config = configure(options)
  const data = prepare(config, hidden)
  const size = {width, height: height ?? config.chart.height, measure: estimateWidth}
  const legend = legendBox(config, data, {...size, hidden})
  const layout = plan(config, data, {...size, legend})
  const drawn = draw(layout, "t")
  return {config, data, layout, drawn, svg: render(h("g", {}, drawn.layers.grid, drawn.layers.axes, drawn.layers.series, drawn.layers.labels))}
}

const count = (text, pattern) => (text.match(pattern) ?? []).length

const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]

const columns = {
  chart: {type: "bar", height: 270},
  xaxis: {categories: months, axisBorder: {show: false}, axisTicks: {show: false}},
  yaxis: {show: false},
  dataLabels: {enabled: false},
  legend: {show: false},
  grid: {padding: {left: 0, right: 0, top: 0, bottom: 0}},
  plotOptions: {bar: {columnWidth: "35%", borderRadius: 4}},
  series: [{name: "A", data: [28, 45, 35, 50, 20, 59]}, {name: "B", data: [14, 25, 20, 25, 10, 30]}],
}

test("the plot leaves ApexCharts' margins: 30 above, 15 below plus the labels, half the last label at the right", () => {
  const {layout} = build(columns, {width: 679})
  assert.equal(layout.plot.x, 0)
  assert.equal(layout.plot.y, 30)
  assert.equal(Math.round(layout.plot.h * 10) / 10, 200.7)
  assert.equal(layout.plot.w > 660 && layout.plot.w < 670, true)
  assert.deepEqual([layout.value.min, layout.value.max], [0, 60])
})

test("grouped columns sit side by side inside the band, rounded at both ends", () => {
  const {drawn, layout} = build(columns, {width: 600})
  assert.equal(drawn.boxes.length, 12)
  const first = drawn.boxes.find((box) => box.series === 0 && box.slot === 0)
  const second = drawn.boxes.find((box) => box.series === 1 && box.slot === 0)
  assert.equal(second.x, first.x + first.w)
  assert.equal(Math.round(first.w * 2), Math.round((layout.cat.width * 35) / 100))
  assert.equal(count(render(h("g", {}, drawn.layers.series)), /A 4 4/g) > 0, true)
})

test("a null value leaves no bar and a zero-height one is skipped", () => {
  const {drawn} = build({...columns, series: [{data: [1, null, 0]}]})
  assert.equal(drawn.boxes.length, 1)
})

test("horizontal bars read the categories down the left and the values along the bottom", () => {
  const {layout, svg} = build({...columns, chart: {type: "bar", height: 300}, plotOptions: {bar: {horizontal: true}}, yaxis: {}, xaxis: {categories: months}})
  assert.equal(layout.horizontal, true)
  assert.equal(layout.plot.x > 20, true)
  assert.equal(layout.across(0) < layout.across(1), true)
  assert.equal(count(svg, /text-anchor="end"/g), 6)
  assert.equal(count(svg, />Jan</g), 1)
})

test("stacked columns pile up on one slot, rounding only the ends of the pile", () => {
  const {drawn, layout, svg} = build({...columns, chart: {type: "bar", height: 270, stacked: true}, plotOptions: {bar: {columnWidth: "60%", borderRadius: 4}}})
  const low = drawn.boxes.find((box) => box.series === 0 && box.slot === 0)
  const high = drawn.boxes.find((box) => box.series === 1 && box.slot === 0)
  assert.equal(low.x, high.x)
  assert.equal(high.y + high.h, low.y)
  assert.equal(layout.value.max >= 74, true)
  assert.equal(count(svg, /A 4 4/g), 24)
})

test("100% stacking runs the axis from 0 to 100", () => {
  const {layout} = build({...columns, chart: {type: "bar", height: 270, stacked: true, stackType: "100%"}, yaxis: {}})
  assert.deepEqual([layout.value.min, layout.value.max], [0, 100])
  assert.equal(layout.value.ticks.at(-1).label, "100%")
})

test("distributed bars take a color per point", () => {
  const {svg} = build({...columns, plotOptions: {bar: {distributed: true}}, series: [{data: [1, 2, 3]}], colors: ["#111111", "#222222", "#333333"]})
  assert.equal(svg.includes('fill="#222222"'), true)
})

test("lines draw one stroke per series, smooth by default and straight when asked", () => {
  const options = {chart: {type: "line", height: 200}, stroke: {width: 3, curve: "smooth"}, series: [{data: [1, 3, 2]}, {data: [2, 1, 3]}], xaxis: {categories: ["a", "b", "c"]}}
  const smooth = build(options)
  assert.equal(count(smooth.svg, /class="linea-chart-line"/g), 2)
  assert.equal(smooth.svg.includes(" C "), true)
  assert.equal(build({...options, stroke: {width: 3, curve: "straight"}}).svg.includes(" C "), false)
})

test("area fills use a gradient per series and markers appear when sized", () => {
  const {svg, drawn} = build({chart: {type: "area", height: 200}, markers: {size: 4}, series: [{data: [1, 3, 2]}], fill: {type: "gradient", gradient: {opacityFrom: 0.5, opacityTo: 0.1, stops: [20, 100, 100], inverseColors: false}}})
  assert.equal(count(svg, /class="linea-chart-area"/g), 1)
  assert.equal(count(svg, /class="linea-chart-marker"/g), 3)
  assert.equal(drawn.defs.filter((node) => node && node.tag === "linearGradient").length, 1)
})

test("stacked areas fill between the lines", () => {
  const {svg} = build({chart: {type: "area", height: 200, stacked: true}, series: [{data: [1, 3, 2]}, {data: [2, 1, 3]}]})
  assert.equal(count(svg, /class="linea-chart-area"/g), 2)
})

test("data labels use the formatter and the offsets", () => {
  const options = {...columns, dataLabels: {enabled: true, formatter: (value) => `${value}!`, offsetY: -5}, series: [{data: [5]}]}
  const {svg} = build(options)
  assert.equal(svg.includes(">5!<"), true)
})

test("candles are green when they close up and red when down", () => {
  const {svg, drawn} = build({chart: {type: "candlestick", height: 250}, series: [{data: [{x: "a", y: [1, 5, 0, 3]}, {x: "b", y: [3, 4, 1, 2]}]}]})
  assert.equal(svg.includes("#00B746"), true)
  assert.equal(svg.includes("#EF403C"), true)
  assert.equal(drawn.boxes.length, 2)
})

test("range bars run between their two values on a date axis", () => {
  const {layout, drawn} = build({
    chart: {type: "rangeBar", height: 200},
    plotOptions: {bar: {horizontal: true, distributed: true}},
    xaxis: {type: "datetime"},
    series: [{data: [{x: "a", y: [Date.UTC(2020, 0, 2), Date.UTC(2020, 0, 6)]}, {x: "b", y: [Date.UTC(2020, 0, 4), Date.UTC(2020, 0, 9)]}]}],
  })
  assert.equal(layout.value.time, true)
  assert.equal(drawn.boxes.length, 2)
  assert.equal(drawn.boxes[0].x < drawn.boxes[1].x, true)
})

test("hiding a series rescales the axis and drops its marks", () => {
  const options = {...columns, yaxis: {}, series: [{data: [10, 20]}, {data: [100, 200]}]}
  assert.equal(build(options).layout.value.max >= 200, true)
  const hidden = build(options, {hidden: [1]})
  assert.equal(hidden.layout.value.max <= 20, true)
  assert.equal(hidden.drawn.boxes.length, 2)
})

test("the pointer finds the slot and builds the tooltip rows", () => {
  const options = {chart: {type: "line", height: 200}, series: [{name: "A", data: [1, 3, 2]}, {name: "B", data: [2, 1, 3]}], xaxis: {categories: ["a", "b", "c"]}}
  const {layout, drawn} = build(options, {width: 300})
  const hit = hover(layout, drawn.boxes, layout.across(1), layout.plot.y + 20)
  assert.equal(hit.title, "b")
  assert.deepEqual(hit.rows.map((row) => [row.name, row.value]), [["A", "3"], ["B", "1"]])
  assert.equal(hit.crosshair.x1, layout.across(1))
  assert.equal(hit.markers.length, 2)
  assert.equal(hover(layout, drawn.boxes, -50, 20), null)
})

test("bars only answer when the pointer is on one, unless the tooltip is shared", () => {
  const {layout, drawn} = build(columns, {width: 600})
  const box = drawn.boxes[0]
  const on = hover(layout, drawn.boxes, box.x + 1, box.y + 2)
  assert.deepEqual(on.rows.map((row) => row.name), ["A"])
  assert.deepEqual(on.active, {series: 0, slot: 0})
  assert.equal(hover(layout, drawn.boxes, box.x + 1, layout.plot.y + 1), null)
  const shared = build({...columns, tooltip: {shared: true}}, {width: 600})
  const both = hover(shared.layout, shared.drawn.boxes, box.x + 1, layout.plot.y + 1)
  assert.deepEqual(both.rows.map((row) => row.name), ["A", "B"])
  assert.equal(both.band !== null, true)
})

test("tooltip formatters and titles apply", () => {
  const options = {chart: {type: "line", height: 200}, tooltip: {y: {formatter: (value) => `$${value}`}, x: {formatter: (value) => `at ${value}`}}, series: [{name: "A", data: [1, 3]}], xaxis: {categories: ["a", "b"]}}
  const {layout, drawn} = build(options, {width: 300})
  const hit = hover(layout, drawn.boxes, layout.across(0), 50)
  assert.equal(hit.rows[0].value, "$1")
  assert.equal(hit.title, "at a")
})

test("candles show open, high, low and close", () => {
  const options = {chart: {type: "candlestick", height: 250}, series: [{data: [{x: "a", y: [1, 5, 0, 3]}]}]}
  const {layout, drawn} = build(options, {width: 300})
  const hit = hover(layout, drawn.boxes, layout.across(0), layout.plot.y + 10)
  assert.deepEqual(hit.rows.map((row) => [row.name, row.value]), [["Open", "1"], ["High", "5"], ["Low", "0"], ["Close", "3"]])
})

const rows = {...columns, chart: {type: "bar", height: 190}, xaxis: {categories: ["Web", "App", "Parceiros", "Balcão", "Outros"]}, yaxis: {}, series: [{name: "Pedidos", data: [524, 349, 225, 150, 100]}], plotOptions: {bar: {horizontal: true, barHeight: "55%"}}}

test("the categories of a row chart are thinned by their height, not their width", () => {
  const {layout} = build(rows, {width: 300})
  assert.equal(layout.cat.labels.length, 5)
})

test("row labels at the end sit past each bar, in room kept at the right of the plot", () => {
  const on = {...rows, dataLabels: {enabled: true}, plotOptions: {bar: {horizontal: true, barHeight: "55%", dataLabels: {position: "end"}}}}
  const plain = build({...on, plotOptions: {bar: {horizontal: true, barHeight: "55%"}}}, {width: 300})
  const {layout, drawn, svg} = build(on, {width: 300})
  assert.equal(layout.plot.w < plain.layout.plot.w, true)
  const first = drawn.boxes.find((box) => box.slot === 0)
  const label = drawn.layers.labels[0]
  assert.equal(label.attrs.x, first.x + first.w + 6)
  assert.equal(label.attrs["text-anchor"], "start")
  assert.equal(count(svg, /linea-chart-datalabel--end/g), 5)
  assert.equal(count(svg, />524</g), 1)
})
