import test from "node:test"
import assert from "node:assert/strict"
import {anchorBox, commandOf, parsePlacement, pickSide, sidesToTry, toLocal} from "./anchor_logic.js"

const rect = (left, top, width, height) => ({left, top, width, height, right: left + width, bottom: top + height})
const screen = {width: 1000, height: 800}

test("a command is the last part of the event type", () => {
  assert.equal(commandOf("linea:open"), "open")
  assert.equal(commandOf("phx:linea:toggle"), "toggle")
})

test("a placement is a side and an alignment", () => {
  assert.deepEqual(parsePlacement("bottom-start"), {side: "bottom", align: "start"})
  assert.deepEqual(parsePlacement("top"), {side: "top", align: "center"})
  assert.deepEqual(parsePlacement("nowhere-else"), {side: "bottom", align: "center"})
})

test("the fallbacks come after the side asked for, the opposite one by default", () => {
  assert.deepEqual(sidesToTry("bottom"), ["bottom", "top"])
  assert.deepEqual(sidesToTry("right", ["bottom", "top"]), ["right", "bottom", "top"])
})

test("the first side with room wins", () => {
  const room = {top: 300, bottom: 50, left: 0, right: 40}
  assert.equal(pickSide("right", {panel: {width: 200, height: 100}, room, offset: 12, fallbacks: ["bottom", "top"]}), "top")
  assert.equal(pickSide("bottom", {panel: {width: 200, height: 400}, room, offset: 4}), "bottom")
})

test("bottom-start sits under the trigger, aligned to its start, offset away", () => {
  const box = anchorBox({placement: "bottom-start", anchor: rect(100, 100, 80, 36), panel: {width: 160, height: 140}, screen, offset: 4})
  assert.deepEqual([box.side, box.top, box.left], ["bottom", 140, 100])
})

test("a menu with no room below opens above", () => {
  const box = anchorBox({placement: "bottom-start", anchor: rect(100, 700, 80, 36), panel: {width: 160, height: 140}, screen, offset: 4})
  assert.deepEqual([box.side, box.top], ["top", 556])
})

test("right-start sits to the right, its top on the trigger's top, and the arrow points at the trigger", () => {
  const box = anchorBox({placement: "right-start", anchor: rect(100, 100, 120, 36), panel: {width: 300, height: 200}, screen, offset: 12})
  assert.deepEqual([box.side, box.left, box.top, box.arrow], ["right", 232, 100, 10])
})

test("top centers the panel over the trigger", () => {
  const box = anchorBox({placement: "top", anchor: rect(400, 400, 32, 32), panel: {width: 192, height: 200}, screen, offset: 12})
  assert.deepEqual([box.side, box.left, box.top, box.arrow], ["top", 320, 188, 88])
})

test("a panel past the edge is shifted back inside, keeping the padding", () => {
  const box = anchorBox({placement: "top", anchor: rect(0, 400, 32, 32), panel: {width: 192, height: 100}, screen, offset: 12, padding: 10})
  assert.equal(box.left, 10)
  assert.equal(box.arrow, 0)
})

test("screen coordinates become coordinates inside the holder", () => {
  assert.deepEqual(toLocal({top: 140, left: 100}, {top: 100, left: 90}), {top: 40, left: 10})
})
