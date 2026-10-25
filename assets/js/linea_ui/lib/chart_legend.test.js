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
