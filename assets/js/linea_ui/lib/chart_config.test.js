import assert from "node:assert/strict"
import test from "node:test"
import {PALETTE, cartesian, colorAt, configure, heightOf, merge, pick} from "./chart_config.js"

test("merge is deep for objects and replaces arrays and scalars", () => {
  assert.deepEqual(merge({a: {b: 1, c: 2}, d: [1, 2]}, {a: {b: 9}, d: [3]}), {a: {b: 9, c: 2}, d: [3]})
  assert.deepEqual(merge({a: 1}, {a: undefined, b: undefined}), {a: 1})
  assert.deepEqual(merge({a: 1}, {a: {b: 2}}), {a: {b: 2}})
  assert.deepEqual(merge({a: {b: 1}}, {a: null}), {a: {b: 1}})
  assert.deepEqual(merge({a: 1}, {a: null}), {a: null})
})

test("pick reads a list by index and passes scalars through", () => {
  assert.equal(pick([1, 2], 1), 2)
  assert.equal(pick(5, 3), 5)
  assert.equal(pick(undefined, 0), undefined)
})

test("a chart type brings its defaults, which the options override", () => {
  const line = configure({chart: {type: "line"}})
  assert.equal(line.stroke.curve, "straight")
  assert.equal(line.stroke.width, 5)
  assert.equal(configure({chart: {type: "line"}, stroke: {width: 3}}).stroke.width, 3)
  assert.equal(configure({chart: {type: "area"}}).fill.type, "gradient")
  assert.equal(configure({chart: {type: "bar"}}).legend.markers.shape, "square")
  assert.equal(configure({chart: {type: "donut"}}).legend.position, "right")
  assert.equal(configure({chart: {type: "radar"}}).grid.show, false)
  assert.equal(configure({}).type, "line")
})

test("the grid pads like ApexCharts unless the chart says otherwise", () => {
  assert.deepEqual(configure({chart: {type: "bar"}}).grid.padding, {top: 0, right: 10, bottom: 0, left: 12})
  assert.equal(configure({chart: {type: "bar"}, grid: {padding: {left: 0}}}).grid.padding.left, 0)
})

test("a sparkline hides axes, legend and grid", () => {
  const config = configure({chart: {type: "area", sparkline: {enabled: true}}})
  assert.equal(config.yaxis.show, false)
  assert.equal(config.legend.show, false)
  assert.equal(config.grid.show, false)
  assert.equal(config.xaxis.labels.show, false)
  assert.equal(config.dataLabels.enabled, false)
})

test("null sections in the options leave the defaults alone", () => {
  const config = configure({chart: null, xaxis: null, series: null})
  assert.equal(config.type, "line")
  assert.equal(config.xaxis.show, true)
})

test("only the first y axis counts", () => {
  assert.equal(configure({yaxis: [{min: 1}, {min: 2}]}).yaxis.min, 1)
  assert.equal(configure({yaxis: {min: 4}}).yaxis.min, 4)
})

test("responsive rules apply below their breakpoint, the smaller one last", () => {
  const options = {
    chart: {type: "bar"},
    plotOptions: {bar: {columnWidth: "35%"}},
    responsive: [
      {breakpoint: 1024, options: {plotOptions: {bar: {columnWidth: "55%"}}}},
      {breakpoint: 640, options: {plotOptions: {bar: {columnWidth: "80%"}}}},
    ],
  }
  assert.equal(configure(options, {viewport: 1200}).plotOptions.bar.columnWidth, "35%")
  assert.equal(configure(options, {viewport: 900}).plotOptions.bar.columnWidth, "55%")
  assert.equal(configure(options, {viewport: 500}).plotOptions.bar.columnWidth, "80%")
  assert.equal(configure(options).plotOptions.bar.columnWidth, "35%")
})

test("height is a number, px text, a share of the width or width over the golden ratio", () => {
  assert.equal(heightOf({chart: {height: 250}}, 400), 250)
  assert.equal(heightOf({chart: {height: "200px"}}, 400), 200)
  assert.equal(heightOf({chart: {height: "50%"}}, 400), 200)
  assert.equal(Math.round(heightOf({chart: {height: "auto"}}, 404)), 250)
})

test("colors cycle through the palette when none are given", () => {
  assert.equal(colorAt({colors: ["#111", "#222"]}, 3), "#222")
  assert.equal(colorAt({}, 1), PALETTE[1])
  assert.equal(cartesian("bar"), true)
  assert.equal(cartesian("donut"), false)
})
