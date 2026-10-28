import assert from "node:assert/strict"
import test from "node:test"
import {configure} from "./chart_config.js"
import {legendBox, legendHtml, legendItems, legendStyle} from "./chart_legend.js"
import {estimateWidth} from "./chart_scale.js"
import {prepare} from "./chart_series.js"

const box = (options, hidden = []) => {
  const config = configure(options)
  return legendBox(config, prepare(config, hidden), {width: 400, measure: estimateWidth, hidden})
}

test("a single series shows no legend unless asked", () => {
  assert.deepEqual(box({chart: {type: "bar"}, series: [{name: "A", data: [1]}]}).items, [])
  assert.equal(box({chart: {type: "bar"}, legend: {showForSingleSeries: true}, series: [{name: "A", data: [1]}]}).items.length, 1)
})

test("several series list their names at the bottom, one row high", () => {
  const legend = box({chart: {type: "bar"}, series: [{name: "A", data: [1]}, {name: "B", data: [2]}]})
  assert.deepEqual(legend.items.map((item) => item.name), ["A", "B"])
  assert.equal(legend.position, "bottom")
  assert.equal(Math.round(legend.height), 22)
  assert.equal(legend.width, 0)
})

test("a legend beside the chart asks for width, not height", () => {
  const legend = box({chart: {type: "area"}, legend: {position: "right"}, series: [{name: "Alpha", data: [1]}, {name: "B", data: [2]}]})
  assert.equal(legend.width > 40, true)
  assert.equal(legend.height, 0)
})

test("legend.show false removes it", () => {
  assert.equal(box({chart: {type: "bar"}, legend: {show: false}, series: [{data: [1]}, {data: [2]}]}).height, 0)
})

test("a donut lists its slices by label with their colors", () => {
  const config = configure({chart: {type: "donut"}, labels: ["Direct", "Social"], colors: ["#111111", "#222222"], series: [44, 55]})
  assert.deepEqual(legendItems(config, prepare(config)).map((item) => [item.name, item.color]), [["Direct", "#111111"], ["Social", "#222222"]])
})

test("the markup is a toggle button per entry, escaped", () => {
  const html = legendHtml(box({chart: {type: "bar"}, series: [{name: "<A>", data: [1]}, {name: "B", data: [2]}]}, [1]))
  assert.equal(html.includes("&lt;A&gt;"), true)
  assert.equal(html.includes('data-series="1" aria-pressed="false"'), true)
  assert.equal(html.includes('data-shape="square"'), true)
  assert.equal(legendHtml({items: []}), "")
  assert.equal(legendStyle({align: "left", font: 12}), "justify-content:flex-start;font-size:12px")
})

const composition = (options, hidden = []) => {
  const config = configure(options)
  return legendItems(config, prepare(config, hidden), hidden)
}

test("a donut legend lists value and share when asked", () => {
  const donut = {chart: {type: "donut"}, labels: ["Web", "App", "Outros"], series: [524, 349, 375], legend: {showValue: true, showPercent: true}}
  assert.deepEqual(composition(donut).map((item) => item.figures), ["524 · 42%", "349 · 28%", "375 · 30%"])
  assert.deepEqual(composition({...donut, legend: {showPercent: true}}).map((item) => item.figures), ["42%", "28%", "30%"])
  assert.deepEqual(composition({...donut, legend: {showValue: true}}).map((item) => item.figures), ["524", "349", "375"])
  assert.deepEqual(composition({chart: {type: "donut"}, series: [1, 2]}).map((item) => item.figures), ["", ""])
})

test("the legend figures use the named formatters and leave hidden slices out of the share", () => {
  const donut = {chart: {type: "donut"}, labels: ["A", "B"], series: [1248, 1248], legend: {showValue: true, showPercent: true, value: {formatter: (value) => `n${value}`}, percent: {formatter: (share) => `${share.toFixed(1)}%`}}}
  assert.deepEqual(composition(donut).map((item) => item.figures), ["n1248 · 50.0%", "n1248 · 50.0%"])
  assert.deepEqual(composition(donut, [1]).map((item) => item.figures), ["n1248 · 100.0%", "n1248"])
})

test("a stacked chart lists each series total and share, a plain one lists nothing", () => {
  const series = [{name: "A", data: [1, 2, 3]}, {name: "B", data: [3, 4, 5]}]
  const stacked = composition({chart: {type: "bar", stacked: true}, series, legend: {showValue: true, showPercent: true}})
  assert.deepEqual(stacked.map((item) => item.figures), ["6 · 33%", "12 · 67%"])
  assert.deepEqual(composition({chart: {type: "bar"}, series, legend: {showValue: true, showPercent: true}}).map((item) => item.figures), ["", ""])
})

test("legend figures show in the markup and widen the entries", () => {
  const options = {chart: {type: "donut"}, labels: ["Web", "App"], series: [524, 349], legend: {position: "right"}}
  const plain = box(options)
  const rich = box({...options, legend: {position: "right", showValue: true, showPercent: true}})
  assert.equal(rich.width > plain.width, true)
  assert.equal(legendHtml(rich).includes('<span class="linea-chart-legend-figures">524 · 60%</span>'), true)
  assert.equal(legendHtml(plain).includes("legend-figures"), false)
})
