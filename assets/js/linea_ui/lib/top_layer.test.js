import test from "node:test"
import assert from "node:assert/strict"
import {canLift, clippingAncestors, drop, lift} from "./top_layer.js"

const fake = ({popover = true, api = true, open = false} = {}) => {
  const calls = []
  const el = {
    open,
    calls,
    hasAttribute: (name) => name === "popover" && popover,
    matches: (selector) => selector === ":popover-open" && el.open,
  }
  api &&
    Object.assign(el, {
      showPopover: () => (calls.push("show"), (el.open = true)),
      hidePopover: () => (calls.push("hide"), (el.open = false)),
    })
  return el
}

test("an element lifts only with the popover attribute and the API", () => {
  assert.equal(canLift(fake()), true)
  assert.equal(canLift(fake({popover: false})), false)
  assert.equal(canLift(fake({api: false})), false)
  assert.equal(canLift(null), false)
})

test("lift shows it once, drop hides it once", () => {
  const el = fake()
  lift(el)
  lift(el)
  assert.deepEqual(el.calls, ["show"])
  drop(el)
  drop(el)
  assert.deepEqual(el.calls, ["show", "hide"])
})

test("without the API lift and drop do nothing", () => {
  const el = fake({api: false})
  assert.doesNotThrow(() => (lift(el), drop(el)))
})

test("a browser that does not know :popover-open counts as not lifted", () => {
  const el = fake()
  el.matches = () => {
    throw new SyntaxError("unknown pseudo-class")
  }
  lift(el)
  assert.deepEqual(el.calls, ["show"])
})

test("the clipping ancestors are the ones whose overflow is not visible, nearest first, below the body", () => {
  const html = {name: "html", parentElement: null}
  const body = {name: "body", parentElement: html}
  const drawer = {name: "drawer-body", parentElement: body}
  const card = {name: "card", parentElement: drawer}
  const scroller = {name: "table-scroll", parentElement: card}
  const cell = {name: "td", parentElement: scroller}
  const trigger = {name: "dropdown", parentElement: cell}
  const styles = {
    html: ["hidden", "hidden"],
    body: ["hidden", "hidden"],
    "drawer-body": ["visible", "auto"],
    card: ["visible", "visible"],
    "table-scroll": ["auto", "hidden"],
    td: ["visible", "visible"],
  }
  const styleOf = (node) => ({overflowX: styles[node.name][0], overflowY: styles[node.name][1]})
  assert.deepEqual(
    clippingAncestors(trigger, styleOf).map((node) => node.name),
    ["table-scroll", "drawer-body"],
  )
  assert.deepEqual(clippingAncestors(null, styleOf), [])
})
