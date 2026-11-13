import test from "node:test"
import assert from "node:assert/strict"
import {pathName} from "./treeview.js"

const node = (parent) => {
  const el = {parentElement: parent, children: []}
  parent && parent.children.push(el)
  return el
}

test("an item without an id is named by its position, and two same-named items differ", () => {
  const root = node(null)
  const docsA = node(root)
  const docsB = node(root)
  const innerA = node(node(docsA))
  const innerB = node(node(docsB))
  assert.equal(pathName(docsA, root), "tree-item-0")
  assert.equal(pathName(innerA, root), "tree-item-0.0.0")
  assert.equal(pathName(innerB, root), "tree-item-1.0.0")
  assert.equal(pathName(innerA, root), pathName(innerA, root))
})
