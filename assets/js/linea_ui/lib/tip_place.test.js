import test from "node:test"
import assert from "node:assert/strict"
import {cursorRect, flip, parsePlacement, placeTooltip} from "./tip_place.js"

const viewport = {width: 1000, height: 800}
const ref = {left: 400, top: 400, right: 500, bottom: 440}
const box = {width: 60, height: 30}

test("a placement is a side and an alignment", () => {
  assert.deepEqual(parsePlacement("top"), {side: "top", align: "center"})
  assert.deepEqual(parsePlacement("left-end"), {side: "left", align: "end"})
  assert.deepEqual(parsePlacement("nowhere-middle"), {side: "top", align: "center"})
  assert.deepEqual(parsePlacement(undefined), {side: "top", align: "center"})
})

test("on top, centered over the trigger, ten pixels away", () => {
  const placed = placeTooltip({placement: "top", ref, box, viewport})
  assert.deepEqual(placed, {placement: "top", x: 420, y: 360, arrow: 22})
})

test("start and end align with the trigger's edges, the arrow still points at its middle", () => {
  assert.deepEqual(placeTooltip({placement: "bottom-start", ref, box, viewport}), {
    placement: "bottom-start",
    x: 400,
    y: 450,
    arrow: 39,
  })
  assert.deepEqual(placeTooltip({placement: "right-end", ref, box, viewport}), {
    placement: "right-end",
    x: 510,
    y: 410,
    arrow: 5,
  })
})

test("left goes before the trigger", () => {
  assert.deepEqual(placeTooltip({placement: "left", ref, box, viewport}), {placement: "left", x: 330, y: 405, arrow: 7})
})

test("it flips to the other side when there is no room", () => {
  const high = {left: 400, top: 10, right: 500, bottom: 50}
  assert.equal(flip("top", {ref: high, box, viewport, offset: 10}), "bottom")
  assert.equal(placeTooltip({placement: "top-start", ref: high, box, viewport}).placement, "bottom-start")
  assert.equal(flip("top", {ref, box, viewport, offset: 10}), "top")
})

test("it stays inside the screen and the arrow keeps pointing at the trigger", () => {
  const edge = {left: 0, top: 400, right: 20, bottom: 440}
  const placed = placeTooltip({placement: "top", ref: edge, box, viewport})
  assert.equal(placed.x, 5)
  assert.equal(placed.arrow, 5)
})

test("following the cursor takes the pointer for one or both axes", () => {
  const point = {x: 420, y: 410}
  assert.deepEqual(cursorRect("both", ref, point), {left: 420, right: 420, top: 410, bottom: 410})
  assert.deepEqual(cursorRect("horizontal", ref, point), {left: 420, right: 420, top: 400, bottom: 440})
  assert.deepEqual(cursorRect("vertical", ref, point), {left: 400, right: 500, top: 410, bottom: 410})
  assert.deepEqual(cursorRect("other", ref, point), cursorRect("both", ref, point))
})
