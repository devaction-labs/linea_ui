import test from "node:test"
import assert from "node:assert/strict"
import {counterState, growHeight} from "./textarea_logic.js"

test("counterState with a maximum", () => {
  assert.deepEqual(counterState({length: 68, max: 200}), {text: "68 / 200", tone: "ok"})
  assert.deepEqual(counterState({length: 180, max: 200}), {text: "180 / 200", tone: "warn"})
  assert.deepEqual(counterState({length: 200, max: 200}), {text: "200 / 200", tone: "warn"})
  assert.deepEqual(counterState({length: 201, max: 200}), {text: "201 / 200", tone: "bad"})
})

test("counterState with a minimum", () => {
  assert.deepEqual(counterState({length: 2, min: 20}), {text: "2 / 20 mín.", tone: "bad"})
  assert.deepEqual(counterState({length: 0, min: 20}), {text: "0", tone: "ok"})
  assert.deepEqual(counterState({length: 20, min: 20}), {text: "20", tone: "ok"})
  assert.deepEqual(counterState({length: 5, min: 20, max: 200}), {text: "5 / 20 mín.", tone: "bad"})
  assert.deepEqual(counterState({length: 25, min: 20, max: 200}), {text: "25 / 200", tone: "ok"})
})

test("counterState without limits or with junk", () => {
  assert.deepEqual(counterState({length: 7}), {text: "7", tone: "ok"})
  assert.deepEqual(counterState({length: -1, max: NaN}), {text: "0", tone: "ok"})
})

test("growHeight follows the content between the rows and maxRows", () => {
  const base = {lineHeight: 20, padding: 20, border: 2, rows: 3}
  assert.deepEqual(growHeight({...base, scrollHeight: 40}), {height: 82, scroll: false})
  assert.deepEqual(growHeight({...base, scrollHeight: 120}), {height: 122, scroll: false})
  assert.deepEqual(growHeight({...base, scrollHeight: 400, maxRows: 6}), {height: 142, scroll: true})
  assert.deepEqual(growHeight({...base, scrollHeight: 100, maxRows: 6}), {height: 102, scroll: false})
})
