import test from "node:test"
import assert from "node:assert/strict"
import {breakpointName, clockText, initialCollapsed, initialOpen, isMobile, modeOn, modeValue, place, railValue, side, smAndUp, storedCollapsed, storedValue, tipSpot, xlAndUp} from "./shell_logic.js"

test("the framed menu starts as the person left it, and never collapsed on a phone", () => {
  assert.equal(isMobile(767), true)
  assert.equal(isMobile(768), false)
  assert.equal(storedCollapsed(railValue(true)), true)
  assert.equal(storedCollapsed(railValue(false)), false)
  assert.equal(storedCollapsed("junk"), null)
  assert.equal(initialCollapsed({width: 1200, stored: "collapsed", rendered: false}), true)
  assert.equal(initialCollapsed({width: 1200, stored: "expanded", rendered: true}), false)
  assert.equal(initialCollapsed({width: 1200, stored: null, rendered: true}), true)
  assert.equal(initialCollapsed({width: 500, stored: "collapsed", rendered: true}), false)
})

test("the clock reads the date and the time in the person's language", () => {
  const date = new Date(2026, 9, 24, 7, 40)
  assert.equal(clockText(date, "en-US"), "Sat, 24 Oct 2026 · 07:40")
  assert.equal(clockText(date, "pt-BR"), "Sáb, 24 out 2026 · 07:40")
})

test("the breakpoint names follow LineOne's service", () => {
  assert.equal(breakpointName(320), "xs")
  assert.equal(breakpointName(640), "sm")
  assert.equal(breakpointName(767), "sm")
  assert.equal(breakpointName(1023), "md")
  assert.equal(breakpointName(1279), "lg")
  assert.equal(breakpointName(1280), "xl")
  assert.equal(breakpointName(1600), "2xl")
})

test("xlAndUp and smAndUp", () => {
  assert.equal(xlAndUp(1279), false)
  assert.equal(xlAndUp(1280), true)
  assert.equal(smAndUp(639), false)
  assert.equal(smAndUp(640), true)
})

test("the sidebar is closed below xl whatever was stored", () => {
  assert.equal(initialOpen({width: 1000, stored: "open", rendered: true}), false)
})

test("at xl the stored choice wins over what was rendered", () => {
  assert.equal(initialOpen({width: 1440, stored: "closed", rendered: true}), false)
  assert.equal(initialOpen({width: 1440, stored: "open", rendered: false}), true)
})

test("with nothing stored the rendered state stays", () => {
  assert.equal(initialOpen({width: 1440, stored: null, rendered: true}), true)
  assert.equal(initialOpen({width: 1440, stored: "garbage", rendered: false}), false)
})

test("stored values", () => {
  assert.equal(storedValue(true), "open")
  assert.equal(storedValue(false), "closed")
  assert.equal(modeValue(true, "dark"), "dark")
  assert.equal(modeValue(false, "dark"), "")
  assert.equal(modeOn("dark", "dark"), true)
  assert.equal(modeOn("", "dark"), false)
  assert.equal(modeOn(null, "dark"), false)
})

const anchor = {top: 100, bottom: 132, left: 200, right: 232, width: 32, height: 32}
const screen = {width: 1440, height: 900}
const origin = {top: 0, left: 0}

test("bottom-end aligns the right edges, gap pixels below", () => {
  assert.deepEqual(place({placement: "bottom-end", gap: 12, anchor, box: {width: 320, height: 200}, origin, screen}), {top: 144, left: 0})
  const far = {...anchor, left: 1000, right: 1032}
  assert.deepEqual(place({placement: "bottom-end", gap: 12, anchor: far, box: {width: 320, height: 200}, origin, screen}), {top: 144, left: 712})
})

test("bottom-start aligns the left edges", () => {
  assert.deepEqual(place({placement: "bottom-start", gap: 4, anchor, box: {width: 100, height: 50}, origin, screen}), {top: 136, left: 200})
})

test("right-end aligns the bottoms, gap pixels to the right", () => {
  assert.deepEqual(place({placement: "right-end", gap: 12, anchor, box: {width: 256, height: 80}, origin, screen}), {top: 52, left: 244})
})

test("the box stays inside the screen", () => {
  const low = {...anchor, top: 880, bottom: 900}
  assert.deepEqual(place({placement: "bottom-start", gap: 4, anchor: low, box: {width: 100, height: 50}, origin, screen}), {top: 850, left: 200})
})

test("the answer is relative to the origin of a transformed ancestor", () => {
  const shifted = {top: 60, left: 240}
  assert.deepEqual(place({placement: "bottom-start", gap: 4, anchor, box: {width: 100, height: 50}, origin: shifted, screen}), {top: 76, left: -40})
})

test("an unknown placement falls back to bottom-start", () => {
  assert.deepEqual(place({placement: "nowhere", gap: 0, anchor, box: {width: 10, height: 10}, origin, screen}), {top: 132, left: 200})
})

test("the side of a placement", () => {
  assert.equal(side("bottom-end"), "bottom")
  assert.equal(side("right"), "right")
})

test("a collapsed item's tooltip is centred on it, to its right", () => {
  assert.deepEqual(tipSpot({top: 100, height: 40, right: 60}, 12), {top: 120, left: 72})
})
