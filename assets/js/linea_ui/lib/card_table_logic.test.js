import test from "node:test"
import assert from "node:assert/strict"
import {clickAction, endsSelection, onControl, popLeft} from "./card_table_logic.js"

const at = (clientX, extra = {}) => popLeft({clientX, rowLeft: 100, rowWidth: 800, popWidth: 300, ...extra})

test("popLeft puts the panel 16px left of the pointer, inside the row", () => {
  assert.equal(at(400), 284)
})

test("popLeft keeps the panel 8px inside the left edge", () => {
  assert.equal(at(100), 8)
  assert.equal(at(110), 8)
})

test("popLeft keeps the panel 8px inside the right edge", () => {
  assert.equal(at(890), 800 - 300 - 8)
  assert.equal(at(5000), 492)
})

test("popLeft with a panel wider than the row falls back to the left pad", () => {
  assert.equal(at(400, {popWidth: 900}), 8)
})

test("onControl matches a control inside the row, never the row itself", () => {
  const row = {contains: (n) => n !== outside}
  const outside = {}
  const inside = {closest: () => ({})}
  assert.equal(onControl({closest: () => row}, row), false)
  assert.equal(onControl(inside, row), true)
  assert.equal(onControl({closest: () => outside}, row), false)
  assert.equal(onControl({closest: () => null}, row), false)
  assert.equal(onControl(null, row), false)
})

test("clickAction opens, moves/closes, and closes on a control", () => {
  const base = {inPop: false, hasPop: true, control: false, isOpen: false}
  assert.equal(clickAction(base), "open")
  assert.equal(clickAction({...base, isOpen: true}), "close")
  assert.equal(clickAction({...base, control: true, isOpen: true}), "close")
  assert.equal(clickAction({...base, control: true}), "close")
  assert.equal(clickAction({...base, inPop: true, isOpen: true}), "ignore")
  assert.equal(clickAction({...base, hasPop: false}), "ignore")
})

test("endsSelection is true only for a non-collapsed selection anchored in the row", () => {
  const inside = {}
  const row = {contains: (n) => n === inside}
  assert.equal(endsSelection({isCollapsed: false, anchorNode: inside}, row), true)
  assert.equal(endsSelection({isCollapsed: true, anchorNode: inside}, row), false)
  assert.equal(endsSelection({isCollapsed: false, anchorNode: {}}, row), false)
  assert.equal(endsSelection({isCollapsed: false, anchorNode: null}, row), false)
  assert.equal(endsSelection(null, row), false)
})
