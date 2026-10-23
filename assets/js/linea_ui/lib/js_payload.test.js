import {test} from "node:test"
import assert from "node:assert/strict"
import {withPayload} from "./js_payload.js"

test("the payload is merged into push ops and the caller's values win", () => {
  const encoded = JSON.stringify([["push", {event: "closed", value: {kind: "x", id: "mine"}}], ["hide", {to: "#a"}]])
  assert.deepEqual(JSON.parse(withPayload(encoded, {id: "modal", open: false})), [
    ["push", {event: "closed", value: {id: "mine", open: false, kind: "x"}}],
    ["hide", {to: "#a"}],
  ])
})

test("a push without value gets the payload as its value", () => {
  assert.deepEqual(JSON.parse(withPayload(JSON.stringify([["push", {event: "e"}]]), {index: 2})), [
    ["push", {event: "e", value: {index: 2}}],
  ])
})
