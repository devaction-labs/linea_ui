import test from "node:test"
import assert from "node:assert/strict"
import {markRow, ROW, rowOf} from "./action_menu_logic.js"

const node = (closest) => ({closest, attrs: new Map(), setAttribute(k, v) { this.attrs.set(k, v) }, removeAttribute(k) { this.attrs.delete(k) }})

test("rowOf finds the nearest row and tolerates a lone menu", () => {
  const row = node(() => null)
  assert.equal(rowOf({closest: (selector) => (selector === ROW ? row : null)}), row)
  assert.equal(rowOf({closest: () => null}), null)
  assert.equal(rowOf(null), null)
})

test("markRow sets and clears data-am-open on the row", () => {
  const row = node(() => null)
  const el = {closest: () => row}
  markRow(el, true)
  assert.equal(row.attrs.has("data-am-open"), true)
  markRow(el, false)
  assert.equal(row.attrs.has("data-am-open"), false)
  assert.equal(markRow({closest: () => null}, true), null)
})
