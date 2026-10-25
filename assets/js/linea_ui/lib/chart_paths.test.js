import assert from "node:assert/strict"
import test from "node:test"
import {areaPath, arcPath, bandPath, barPath, columnPath, linePath, polar, polygonPath, roundedRect, segments} from "./chart_paths.js"

const points = [{x: 0, y: 10}, {x: 10, y: 0}, {x: 20, y: 5}]

test("straight lines join points with L", () => {
  assert.equal(linePath(points), "M 0 10 L 10 0 L 20 5")
})

test("smooth lines use control points a third of the way along each segment", () => {
  assert.equal(linePath(points.slice(0, 2), "smooth"), "M 0 10 C 3.5 10 6.5 0 10 0")
})

test("stepline holds the previous value until the next x", () => {
  assert.equal(linePath(points.slice(0, 2), "stepline"), "M 0 10 L 10 10 L 10 0")
})

test("a gap splits the line into runs and a single point is a lone move", () => {
  assert.equal(linePath([{x: 0, y: 1}, null, {x: 2, y: 3}, {x: 3, y: 4}]), "M 0 1 M 2 3 L 3 4")
  assert.deepEqual(segments([null, null]), [])
  assert.equal(segments([{x: 0, y: 0}, {x: 1, y: NaN}, {x: 2, y: 2}]).length, 2)
})

test("an area closes down to the baseline for each run", () => {
  assert.equal(areaPath(points, 20), "M 0 10 L 10 0 L 20 5 L 20 20 L 0 20 Z")
  assert.equal(areaPath([{x: 0, y: 1}, null, {x: 2, y: 3}], 9).split("Z").length, 3)
})

test("a band runs along the upper line and back along the lower one", () => {
  const upper = [{x: 0, y: 0}, {x: 10, y: 0}]
  const lower = [{x: 0, y: 5}, {x: 10, y: 5}]
  assert.equal(bandPath(upper, lower), "M 0 0 L 10 0 L 10 5 L 10 5 L 0 5 Z")
})

test("rounded rectangles clamp the radius to half the smaller side", () => {
  assert.equal(roundedRect(0, 0, 10, 4, [9, 9, 9, 9]).includes("A 2 2"), true)
  assert.equal(roundedRect(0, 0, 10, 10), "M 0 0 H 10 V 10 H 0 V 0 Z")
  assert.equal(roundedRect(0, 0, 10, 10, [2, 0, 0, 0]).startsWith("M 2 0 H 10"), true)
})

test("columns round the far end, both ends or none; stacked pieces round what they are told", () => {
  const far = columnPath(0, 100, 20, 10, 4, "end")
  assert.equal(far.startsWith("M 4 20"), true)
  assert.equal(far.includes("V 100 H 0 V 24"), true)
  assert.equal(columnPath(0, 100, 20, 10, 4, "both").split("A").length, 5)
  assert.equal(columnPath(0, 100, 20, 10, 4, "none"), "M 0 20 H 10 V 100 H 0 V 20 Z")
  assert.equal(columnPath(0, 100, 20, 10, 4, {first: true, last: false}).split("A").length, 3)
  assert.equal(columnPath(0, 20, 100, 10, 4, "end").split("A").length, 3)
})

test("bars grow to the right or the left and round the far end", () => {
  assert.equal(barPath(0, 0, 50, 10, 4, "end").includes("A 4 4 0 0 1 50 4"), true)
  const left = barPath(0, 50, 0, 10, 4, "end")
  assert.equal(left.startsWith("M 4 0"), true)
  assert.equal(left.includes("A 4 4 0 0 1 0 6"), true)
})

test("polar angles start at the top and run clockwise", () => {
  const top = polar(10, 10, 5, 0)
  assert.deepEqual([Math.round(top.x), Math.round(top.y)], [10, 5])
  const right = polar(10, 10, 5, 90)
  assert.deepEqual([Math.round(right.x), Math.round(right.y)], [15, 10])
})

test("arcs pick the large flag past 180 degrees and split a full circle in two", () => {
  assert.equal(arcPath(0, 0, 10, 0, 90), "M 0 -10 A 10 10 0 0 1 10 0")
  assert.equal(arcPath(0, 0, 10, 0, 270).includes("0 1 1"), true)
  assert.equal(arcPath(0, 0, 10, 0, 360).split("A").length, 3)
  assert.equal(arcPath(0, 0, 10, 0, -90).includes("0 0 0"), true)
})

test("polygons close", () => {
  assert.equal(polygonPath(points), "M 0 10 L 10 0 L 20 5 Z")
})
