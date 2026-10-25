import assert from "node:assert/strict"
import test from "node:test"
import {gradientOf, parseColor, shade} from "./chart_color.js"

test("colors are read from hex and rgb text", () => {
  assert.deepEqual(parseColor("#fff"), [255, 255, 255])
  assert.deepEqual(parseColor("#4467EF"), [68, 103, 239])
  assert.deepEqual(parseColor("rgba(10, 20, 30, .5)"), [10, 20, 30])
  assert.equal(parseColor("red"), null)
})

test("shade mixes toward white or black", () => {
  assert.equal(shade("#000000", 0.5), "#808080")
  assert.equal(shade("#ffffff", -0.5), "#808080")
  assert.equal(shade("#34d399", 0.5), "#9ae9cc")
  assert.equal(shade("tomato", 0.5), "tomato")
})

test("a gradient goes from the color to its light shade, or the other way round when inverted", () => {
  const options = {shade: "light", shadeIntensity: 0.5, inverseColors: false, opacityFrom: 0.65, opacityTo: 0.5, stops: [0, 100, 100], type: "vertical"}
  const spec = gradientOf(options, "#34d399", 0)
  assert.equal(spec.from, "#34d399")
  assert.equal(spec.to, "#9ae9cc")
  assert.deepEqual(spec.direction, {x1: 0, y1: 0, x2: 0, y2: 1})
  assert.equal(gradientOf({...options, inverseColors: true}, "#34d399", 0).from, "#9ae9cc")
})

test("gradientToColors name the end color per series, and dark shades go toward black", () => {
  const options = {shade: "dark", shadeIntensity: 1, inverseColors: false, gradientToColors: ["#86efac"], type: "horizontal"}
  assert.equal(gradientOf(options, "#a855f7", 0).to, "#86efac")
  assert.equal(gradientOf(options, "#a855f7", 1).to, "#a855f7")
  assert.equal(gradientOf({shade: "dark", shadeIntensity: 1}, "#a855f7", 0).to, "#000000")
})
