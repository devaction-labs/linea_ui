import {test} from "node:test"
import assert from "node:assert/strict"
import {groupsKey, parseGroups, serializeGroups} from "./sidebar_groups.js"

test("the key is per menu", () => {
  assert.equal(groupsKey("menu"), "linea-sidebar-groups:menu")
})

test("parseGroups reads the booleans and ignores the rest", () => {
  assert.deepEqual(parseGroups('{"a":true,"b":false,"c":"x"}'), {a: true, b: false})
})

test("parseGroups survives a missing or broken value", () => {
  assert.deepEqual(parseGroups(null), {})
  assert.deepEqual(parseGroups("{oops"), {})
  assert.deepEqual(parseGroups("[1]"), {})
})

test("serializeGroups round-trips", () => {
  const raw = serializeGroups([
    {id: "g0", open: true},
    {id: "g1", open: false},
  ])
  assert.deepEqual(parseGroups(raw), {g0: true, g1: false})
})
