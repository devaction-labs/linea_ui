import assert from "node:assert/strict"
import test from "node:test"
import {configure} from "./chart_config.js"
import {extent, prepare, stack} from "./chart_series.js"

const read = (options, hidden) => prepare(configure(options), hidden)

test("plain numbers become points on the category slots", () => {
  const data = read({chart: {type: "bar"}, xaxis: {categories: ["Jan", "Feb"]}, series: [{name: "A", data: [1, null]}, {data: [3, 4]}]})
  assert.deepEqual(data.labels, ["Jan", "Feb"])
  assert.equal(data.kind, "category")
  assert.equal(data.count, 2)
  assert.deepEqual(data.series[0].points.map((point) => point.value), [1, null])
  assert.equal(data.series[1].name, "series-2")
  assert.notEqual(data.series[0].color, data.series[1].color)
})

test("{x, y} points name their own categories", () => {
  const data = read({chart: {type: "bar"}, series: [{data: [{x: "a", y: 1}, {x: "b", y: 2}]}]})
  assert.deepEqual(data.labels, ["a", "b"])
})

test("a date axis reads timestamps from categories or from x", () => {
  const byCategory = read({xaxis: {type: "datetime", categories: ["2000-05-05", "2000-05-06"]}, series: [{data: [1, 2]}]})
  assert.equal(byCategory.kind, "datetime")
  assert.deepEqual(byCategory.series[0].points.map((point) => point.x), [Date.UTC(2000, 4, 5), Date.UTC(2000, 4, 6)])
  const byX = read({xaxis: {type: "datetime"}, series: [{data: [{x: 5000, y: 1}, [6000, 2]]}]})
  assert.deepEqual(byX.series[0].points.map((point) => point.x), [5000, 6000])
})

test("numeric axes count from one when the data has no x", () => {
  const data = read({xaxis: {type: "numeric"}, series: [{data: [5, 6]}]})
  assert.deepEqual(data.series[0].points.map((point) => point.x), [1, 2])
})

test("candles and ranges carry their parts", () => {
  const candles = read({chart: {type: "candlestick"}, series: [{data: [{x: "a", y: [1, 5, 0, 3]}, {x: "b", y: [1, 2]}]}]})
  assert.deepEqual([candles.series[0].points[0].open, candles.series[0].points[0].high, candles.series[0].points[0].low, candles.series[0].points[0].close], [1, 5, 0, 3])
  assert.equal(candles.series[0].points[1].value, null)
  const ranges = read({chart: {type: "rangeBar"}, series: [{data: [{x: "task", y: [10, 20], fillColor: "#f00"}, {x: "other", y: [5, 6]}]}]})
  assert.deepEqual(ranges.labels, ["task", "other"])
  assert.equal(ranges.series[0].points[0].start, 10)
  assert.equal(ranges.series[0].points[0].end, 20)
  assert.equal(ranges.series[0].points[0].fill, "#f00")
})

test("hidden series keep their index and color", () => {
  const data = read({series: [{data: [1]}, {data: [2]}]}, [0])
  assert.deepEqual(data.series.map((series) => series.hidden), [true, false])
  assert.equal(data.series[1].index, 1)
})

test("stacking piles positives up and negatives down", () => {
  const stacked = stack([[1, 2, null], [3, -4, 5]])
  assert.deepEqual(stacked[0], [{from: 0, to: 1}, {from: 0, to: 2}, null])
  assert.deepEqual(stacked[1], [{from: 1, to: 4}, {from: 0, to: -4}, {from: 0, to: 5}])
})

test("stacking to 100% scales each slot to its total", () => {
  const stacked = stack([[1, 0], [3, 0]], true)
  assert.deepEqual(stacked[0][0], {from: 0, to: 25})
  assert.deepEqual(stacked[1][0], {from: 25, to: 100})
  assert.deepEqual(stacked[0][1], {from: 0, to: 0})
})

test("extent skips what is not a number", () => {
  assert.deepEqual(extent([3, null, 1, NaN, 2]), [1, 3])
  assert.equal(extent([null]), null)
})
