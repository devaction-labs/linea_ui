import assert from "node:assert/strict"
import test from "node:test"
import {ALL, assistantShown, emptyShown, isShortcut, keeps, move, route, settle, visibility} from "./palette_logic.js"

const items = [
  {scope: "go", text: "Pedidos Vendas"},
  {scope: "go", text: "Clientes Relacionamento"},
  {scope: "act", text: "Novo pedido"},
]

test("the all scope keeps every scope and a scope keeps only its own items", () => {
  assert.deepEqual(visibility(items, {scope: ALL, query: "", local: true}), [true, true, true])
  assert.deepEqual(visibility(items, {scope: "go", query: "", local: true}), [true, true, false])
  assert.deepEqual(visibility(items, {scope: "act", query: "", local: true}), [false, false, true])
})

test("a query keeps the items whose text contains it, ignoring case and accents", () => {
  assert.deepEqual(visibility(items, {scope: ALL, query: "PEDIDO", local: true}), [true, false, true])
  assert.deepEqual(visibility([{scope: "go", text: "Relação"}], {scope: ALL, query: "relacao", local: true}), [true])
})

test("a server search leaves the query to the server and keeps filtering by scope", () => {
  assert.equal(keeps(items[0], {scope: ALL, query: "zzz", local: false}), true)
  assert.equal(keeps(items[0], {scope: "act", query: "zzz", local: false}), false)
})

test("the assistant shows for a typed query with no match, or always when asked", () => {
  assert.equal(assistantShown({mode: "no_match", query: "xyz", matched: 0}), true)
  assert.equal(assistantShown({mode: "no_match", query: "xyz", matched: 2}), false)
  assert.equal(assistantShown({mode: "always", query: "xyz", matched: 2}), true)
  assert.equal(assistantShown({mode: "always", query: "  ", matched: 0}), false)
})

test("the empty message shows only when nothing matched and there is no assistant row", () => {
  assert.equal(emptyShown({matched: 0, assistant: false}), true)
  assert.equal(emptyShown({matched: 0, assistant: true}), false)
  assert.equal(emptyShown({matched: 3, assistant: false}), false)
})

test("the active row moves with the arrows and stops at both ends", () => {
  assert.equal(move(0, "ArrowDown", 3), 1)
  assert.equal(move(2, "ArrowDown", 3), 2)
  assert.equal(move(0, "ArrowUp", 3), 0)
  assert.equal(move(0, "ArrowDown", 0), -1)
})

test("the active row settles on the first row, and on none when there are none", () => {
  assert.equal(settle(-1, 3), 0)
  assert.equal(settle(7, 3), 2)
  assert.equal(settle(1, 3), 1)
  assert.equal(settle(0, 0), -1)
})

test("Enter presses the row; Ctrl+Enter opens a link in a window and only reports the rest", () => {
  assert.equal(route({href: "/orders", newTab: false}), "press")
  assert.equal(route({href: "/orders", newTab: true}), "window")
  assert.equal(route({newTab: true}), "report")
})

test("the shortcut matches regardless of case and never when there is none", () => {
  assert.equal(isShortcut("Mod+k", "Mod+k"), true)
  assert.equal(isShortcut("Mod+K", "Mod+k"), true)
  assert.equal(isShortcut("Mod+j", "Mod+k"), false)
  assert.equal(isShortcut("Mod+k", null), false)
})
