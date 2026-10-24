import assert from "node:assert/strict"
import test from "node:test"
import {areaKey, areaPoint, areaText, colorOfHex, hexOfColor, hsvToRgb, parseHex, rgbToHsv, sameHex, toHex} from "./color_logic.js"

test("hex text of three, four, six and eight digits is read, with or without the hash", () => {
  assert.deepEqual(parseHex("#6366f1"), {r: 99, g: 102, b: 241, a: 100})
  assert.deepEqual(parseHex("f00"), {r: 255, g: 0, b: 0, a: 100})
  assert.deepEqual(parseHex("#0f08"), {r: 0, g: 255, b: 0, a: 53})
  assert.deepEqual(parseHex("#FF000080"), {r: 255, g: 0, b: 0, a: 50})
})

test("text that is not a hex color is not read", () => {
  for (const text of ["", "#12", "#12345", "blue", "#GGGGGG", null, undefined]) assert.equal(parseHex(text), null)
})

test("a color is written in upper case, with the alpha digits only when asked for and not opaque", () => {
  assert.equal(toHex({r: 99, g: 102, b: 241}), "#6366F1")
  assert.equal(toHex({r: 255, g: 0, b: 0, a: 50}), "#FF0000")
  assert.equal(toHex({r: 255, g: 0, b: 0, a: 50}, true), "#FF000080")
  assert.equal(toHex({r: 255, g: 0, b: 0, a: 100}, true), "#FF0000")
})

test("hex texts are compared without caring about case", () => {
  assert.ok(sameHex("#6366f1", "#6366F1"))
  assert.ok(!sameHex("#6366f1", "#6366f2"))
  assert.ok(!sameHex(null, "#000000"))
})

test("HSV and RGB agree on the primaries, the grays and a known color", () => {
  assert.deepEqual(hsvToRgb(0, 100, 100), {r: 255, g: 0, b: 0})
  assert.deepEqual(hsvToRgb(120, 100, 100), {r: 0, g: 255, b: 0})
  assert.deepEqual(hsvToRgb(240, 100, 100), {r: 0, g: 0, b: 255})
  assert.deepEqual(hsvToRgb(200, 0, 50), {r: 128, g: 128, b: 128})
  assert.deepEqual(rgbToHsv({r: 255, g: 0, b: 0}), {h: 0, s: 100, v: 100})
  assert.deepEqual(rgbToHsv({r: 0, g: 0, b: 255}), {h: 240, s: 100, v: 100})
  assert.deepEqual(rgbToHsv({r: 0, g: 0, b: 0}), {h: 0, s: 0, v: 0})
  assert.deepEqual(rgbToHsv({r: 99, g: 102, b: 241}), {h: 239, s: 59, v: 95})
})

test("a hue that wraps below zero stays in 0-359", () => {
  assert.equal(rgbToHsv({r: 255, g: 0, b: 64}).h, 345)
  assert.equal(rgbToHsv({r: 255, g: 0, b: 1}).h, 0)
})

test("a hex color becomes a color and back to its own hex for the primaries", () => {
  assert.deepEqual(colorOfHex("#FF0000"), {h: 0, s: 100, v: 100, a: 100})
  assert.equal(hexOfColor(colorOfHex("#00FF00")), "#00FF00")
  assert.equal(colorOfHex("nope"), null)
  assert.equal(hexOfColor({h: 0, s: 100, v: 100, a: 50}, true), "#FF000080")
})

test("a pointer in the area gives saturation to the right and brightness upward, held in 0-100", () => {
  const rect = {left: 10, top: 20, width: 200, height: 100}
  assert.deepEqual(areaPoint(rect, 110, 70), {s: 50, v: 50})
  assert.deepEqual(areaPoint(rect, 10, 20), {s: 0, v: 100})
  assert.deepEqual(areaPoint(rect, 500, 500), {s: 100, v: 0})
  assert.deepEqual(areaPoint(rect, -50, -50), {s: 0, v: 100})
})

test("the arrow keys move the knob a point, ten with shift, and stop at the edges", () => {
  assert.deepEqual(areaKey("ArrowRight", {s: 50, v: 50}), {s: 51, v: 50})
  assert.deepEqual(areaKey("ArrowDown", {s: 50, v: 50}, true), {s: 50, v: 40})
  assert.deepEqual(areaKey("ArrowUp", {s: 50, v: 98}, true), {s: 50, v: 100})
  assert.deepEqual(areaKey("ArrowLeft", {s: 0, v: 50}), {s: 0, v: 50})
  assert.equal(areaKey("Enter", {s: 1, v: 1}), null)
})

test("the screen reader text fills the saturation and the brightness", () => {
  assert.equal(areaText("Saturação %{s}%, brilho %{v}%", {s: 72, v: 88}), "Saturação 72%, brilho 88%")
})
