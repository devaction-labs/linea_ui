import assert from "node:assert/strict"
import test from "node:test"
import {configure} from "./chart_config.js"
import {frame, labelled, shown} from "./chart_frame.js"

const none = {position: "bottom", height: 0, width: 0}

const lay = (options, extra = {}) =>
  frame(configure(options), {width: 600, height: 300, legend: none, horizontal: false, sideWidth: 20, lastLabel: 11, bottomLabels: true, topLabels: false, ...extra})

test("a bare chart keeps 30 above and 15 below, plus the label row", () => {
  const {plot} = lay({chart: {type: "bar"}, grid: {padding: {left: 0, right: 0, top: 0, bottom: 0}}, yaxis: {show: false}})
  assert.equal(plot.x, 0)
  assert.equal(plot.y, 30)
  assert.equal(Math.round((300 - plot.y - plot.h) * 100) / 100, 39.3)
  assert.equal(plot.w, 589)
})

test("the default padding adds 12 on the left and 10 on the right", () => {
  const {plot} = lay({chart: {type: "bar"}, yaxis: {show: false}})
  assert.equal(plot.x, 12)
  assert.equal(plot.w, 600 - 12 - 10 - 11)
})

test("visible y labels reserve their width plus 15, and the labels end 2 past it", () => {
  const {plot, sideEdge} = lay({chart: {type: "bar"}, grid: {padding: {left: 0}}})
  assert.equal(plot.x, 35)
  assert.equal(sideEdge, 37.1)
})

test("negative paddings reach into the margins", () => {
  const {plot} = lay({chart: {type: "bar"}, yaxis: {show: false}, grid: {padding: {top: -20, left: -8, right: -8, bottom: -10}}})
  assert.equal(plot.y, 10)
  assert.equal(plot.x, -8)
  assert.equal(plot.w, 600 + 8 + 8 - 11)
})

test("a legend below or above takes its height, one at the side its width", () => {
  const below = lay({chart: {type: "bar"}}, {legend: {position: "bottom", height: 24, width: 0}})
  const above = lay({chart: {type: "bar"}}, {legend: {position: "top", height: 24, width: 0}})
  const right = lay({chart: {type: "bar"}}, {legend: {position: "right", height: 0, width: 80}})
  const plain = lay({chart: {type: "bar"}})
  assert.equal(plain.plot.h - below.plot.h, 24)
  assert.equal(above.plot.y - plain.plot.y, 24)
  assert.equal(plain.plot.w - right.plot.w, 80)
})

test("a sparkline uses the whole chart but a pixel", () => {
  const {plot} = lay({chart: {type: "area", sparkline: {enabled: true}}})
  assert.deepEqual(plot, {x: 0, y: 1, w: 600, h: 298})
})

test("y axis tooltips make room for their bubble", () => {
  const plain = lay({chart: {type: "bar"}})
  const tip = lay({chart: {type: "bar"}, yaxis: {tooltip: {enabled: true}}})
  assert.equal(Math.round((tip.plot.x - plain.plot.x) * 10) / 10, 17.3)
})

test("axes are shown and labelled unless turned off", () => {
  assert.equal(shown({}), true)
  assert.equal(shown({show: false}), false)
  assert.equal(labelled({labels: {show: false}}), false)
  assert.equal(labelled({show: false}), false)
  assert.equal(labelled({}), true)
})
