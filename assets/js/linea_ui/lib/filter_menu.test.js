import assert from "node:assert/strict"
import test from "node:test"
import {applySuffix, customText, customValue, onClose, parseCustom, payloadOf, pendingResults, rangeLabel, stagedTotal} from "./filter_menu.js"

test("a custom period is `custom:` and two ISO days in order", () => {
  assert.equal(customValue("2026-11-01", "2026-11-13"), "custom:2026-11-01..2026-11-13")
  assert.equal(customValue("2026-11-13", "2026-11-13"), "custom:2026-11-13..2026-11-13")
  assert.equal(customValue("2026-11-13", "2026-11-01"), "")
  assert.equal(customValue("2026-11-01", ""), "")
  assert.equal(customValue("", ""), "")
})

test("a value is read back into its two days, and a preset is not a period", () => {
  assert.deepEqual(parseCustom("custom:2026-11-01..2026-11-13"), {from: "2026-11-01", to: "2026-11-13"})
  assert.equal(parseCustom("today"), null)
  assert.equal(parseCustom(""), null)
  assert.equal(parseCustom(null), null)
  assert.equal(parseCustom("custom:2026-11-13..2026-11-01"), null)
  assert.equal(parseCustom("custom:2026-11-01"), null)
})

test("the row shows the period in the locale of the menu, or its own text", () => {
  const row = {label: "Personalizado…", locale: "pt_BR"}
  assert.equal(rangeLabel({from: "2026-11-01", to: "2026-11-13"}, "pt_BR"), "01/11/2026 – 13/11/2026")
  assert.equal(rangeLabel({from: "2026-11-01", to: "2026-11-13"}, "en"), "2026-11-01 – 2026-11-13")
  assert.equal(customText("custom:2026-11-01..2026-11-13", row), "01/11/2026 – 13/11/2026")
  assert.equal(customText("today", row), "Personalizado…")
  assert.equal(customText("", row), "Personalizado…")
})

const options = (...pairs) => pairs.map(([on, count]) => ({on, count}))

test("one group staged: Apply counts the records of the ticked options, as the canvas does", () => {
  const status = options([true, 3], [true, 2], [false, 2], [false, 1])
  assert.equal(pendingResults([status]), 5)
})

test("nothing staged is every record", () => {
  const status = options([false, 3], [false, 2], [false, 2], [false, 1])
  const channel = options([false, 4], [false, 4])
  assert.equal(pendingResults([status, channel]), 8)
})

test("several groups staged give the smallest of them", () => {
  const status = options([true, 3], [false, 5])
  const channel = options([true, 2], [false, 6])
  const seller = options([false, 4], [false, 4])
  assert.equal(pendingResults([status, channel, seller]), 2)
})

test("options without a count fall back to the ticked values, or no number", () => {
  assert.equal(pendingResults([options([true, null], [true, null], [false, null])]), 2)
  assert.equal(pendingResults([options([false, null], [false, null])]), null)
  assert.equal(pendingResults([]), null)
})

test("the trigger counts every staged value", () => {
  assert.equal(stagedTotal([options([true, 1], [false, 1]), options([true, 1], [true, 1])]), 3)
  assert.equal(stagedTotal([]), 0)
})

test("Apply is followed by the number when there is one", () => {
  assert.equal(applySuffix(5), " (5)")
  assert.equal(applySuffix(0), " (0)")
  assert.equal(applySuffix(null), "")
})

test("the payload lists multiple groups and picks the value of single ones", () => {
  const groups = [
    {name: "status", type: "multiple", values: ["paid", "open"]},
    {name: "channel", type: "multiple", values: []},
    {name: "sort", type: "single", values: ["recent"]},
    {name: "period", type: "single", values: []},
  ]
  assert.deepEqual(payloadOf(groups), {status: ["paid", "open"], channel: [], sort: "recent", period: ""})
})

test("closing without Apply takes the staged values back, only in apply mode", () => {
  assert.equal(onClose({mode: "apply", applying: false}), "revert")
  assert.equal(onClose({mode: "apply", applying: true}), "keep")
  assert.equal(onClose({mode: "live", applying: false}), "keep")
})
