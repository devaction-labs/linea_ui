import assert from "node:assert/strict"
import test from "node:test"
import {fillQuery, left, opens, picked, searchable, typed} from "./autocomplete_logic.js"

test("the no-results message takes the query", () => {
  assert.equal(fillQuery('Nothing for "%{query}"', " tea "), 'Nothing for "tea"')
  assert.equal(fillQuery("No results", "tea"), "No results")
  assert.equal(fillQuery(undefined, undefined), "")
})

test("a query is searched once it reaches the threshold", () => {
  assert.equal(searchable("ab", 3), false)
  assert.equal(searchable("abc", 3), true)
  assert.equal(searchable("", 0), true)
  assert.equal(searchable("", undefined), true)
})

test("choosing, typing and leaving", () => {
  assert.deepEqual(picked({value: "2", label: "Bruno"}, false), {value: "2", text: "Bruno"})
  assert.deepEqual(picked({value: "Santos", label: "Santos (SP)"}, true), {value: "Santos", text: "Santos"})
  assert.deepEqual(typed("Br", {value: "2", freeText: false}), {value: "2", text: "Br"})
  assert.deepEqual(typed("Br", {value: "2", freeText: true}), {value: "Br", text: "Br"})
  assert.deepEqual(left("Br", {value: "2", label: "Bruno", freeText: false}), {value: "2", text: "Bruno"})
  assert.deepEqual(left("Br", {value: "", label: "", freeText: false}), {value: "", text: ""})
  assert.deepEqual(left("  ", {value: "2", label: "Bruno", freeText: false}), {value: "", text: ""})
  assert.deepEqual(left("Rua A", {value: "x", label: "x", freeText: true}), {value: "Rua A", text: "Rua A"})
})

test("the list opens on focus only when asked to", () => {
  assert.equal(opens({query: "", threshold: 0, onFocus: true, focusing: true}), true)
  assert.equal(opens({query: "", threshold: 0, onFocus: false, focusing: true}), false)
  assert.equal(opens({query: "a", threshold: 2, focusing: false}), false)
  assert.equal(opens({query: "ab", threshold: 2, focusing: false}), true)
})
