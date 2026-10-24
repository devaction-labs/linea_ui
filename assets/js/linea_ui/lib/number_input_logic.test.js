import assert from "node:assert/strict"
import test from "node:test"
import {canStep, display, displayOf, machine, numberOptions, parse, sameNumber, sanitize, settle, STEP_KEYS, stepFrom, valueOf} from "./number_input_logic.js"
import {scaled} from "./numbers.js"

const br = numberOptions({decimal: ",", group: ".", step: "1"})
const money = numberOptions({decimal: ",", group: ".", decimals: "2", min: "0", max: "1000", step: "0.01", negative: "false"})
const en = numberOptions({decimal: ".", group: ",", maxDecimals: "3", step: "0.5"})

test("options are read from the data attributes", () => {
  assert.deepEqual(numberOptions({}), {decimal: ".", group: "", decimals: null, maxDecimals: null, min: null, max: null, step: {int: 1, scale: 0}, negative: true})
  assert.equal(money.decimals, 2)
  assert.deepEqual(money.min, {int: 0, scale: 0})
  assert.equal(money.negative, false)
  assert.equal(en.maxDecimals, 3)
})

test("typing keeps digits, separators and a leading sign only", () => {
  assert.equal(sanitize("1.234,5a", br), "1.234,5")
  assert.equal(sanitize("-12", br), "-12")
  assert.equal(sanitize("1-2", br), "12")
  assert.equal(sanitize("-12", money), "12")
  assert.equal(sanitize("1,2,3", br), "1,23")
  assert.equal(sanitize("1,239", money), "1,23")
  assert.equal(sanitize("1.5", numberOptions({decimal: ".", group: ",", maxDecimals: "0"})), "1")
  assert.equal(sanitize("12,", br), "12,")
})

test("localized text is parsed into a scaled number", () => {
  assert.deepEqual(parse("1.234,56", br), {kind: "number", number: {int: 123456, scale: 2}})
  assert.deepEqual(parse("1,234.5", en), {kind: "number", number: {int: 12345, scale: 1}})
  assert.deepEqual(parse("1 234,5", numberOptions({decimal: ",", group: " "})), {kind: "number", number: {int: 12345, scale: 1}})
  assert.deepEqual(parse("", br), {kind: "empty"})
  assert.deepEqual(parse("1,2,3", br), {kind: "invalid"})
  assert.deepEqual(parse("-", br), {kind: "invalid"})
})

test("machine and display text", () => {
  assert.equal(machine(scaled("1234.5"), br), "1234.5")
  assert.equal(machine(scaled("1234.5"), money), "1234.50")
  assert.equal(machine(scaled("1.23456"), en), "1.235")
  assert.equal(machine(scaled("1.2"), en), "1.2")
  assert.equal(display(scaled("1234567.5"), br), "1.234.567,5")
  assert.equal(display(scaled("-1234.5"), money), "-1.234,50")
  assert.equal(display(scaled("1234.5"), numberOptions({decimal: ",", group: ""})), "1234,5")
  assert.equal(displayOf("1234.5", money), "1.234,50")
  assert.equal(displayOf("", money), "")
  assert.equal(displayOf(undefined, money), "")
  assert.equal(displayOf("abc", money), "abc")
})

test("the hidden value of typed text", () => {
  assert.equal(valueOf("1.234,5", money), "1234.50")
  assert.equal(valueOf("", money), "")
  assert.equal(valueOf("1,2,3", br), "1,2,3")
})

test("leaving the field clamps, rounds and groups", () => {
  assert.deepEqual(settle("5000", money), {display: "1.000,00", value: "1000.00"})
  assert.deepEqual(settle("12,3", money), {display: "12,30", value: "12.30"})
  assert.deepEqual(settle("", money), {display: "", value: ""})
  assert.deepEqual(settle("1,2,3", br), {display: "1,2,3", value: "1,2,3"})
})

test("steps move by the step and stop at the limits", () => {
  assert.deepEqual(STEP_KEYS, ["ArrowUp", "ArrowDown", "PageUp", "PageDown"])
  assert.deepEqual(stepFrom("1.5", "up", en), {display: "2", value: "2"})
  assert.deepEqual(stepFrom("1.5", "PageDown", en), {display: "-3.5", value: "-3.5"})
  assert.deepEqual(stepFrom("999.99", "up", money), {display: "1.000,00", value: "1000.00"})
  assert.equal(stepFrom("1000", "up", money), null)
  assert.equal(stepFrom("1", "Enter", br), null)
  assert.deepEqual(stepFrom("", "up", money), {display: "0,00", value: "0.00"})
  assert.equal(canStep("1000", "up", money), false)
  assert.equal(canStep("10", "up", money), true)
  assert.equal(canStep("0", "down", money), false)
  assert.equal(canStep("", "down", money), true)
  assert.equal(canStep("5", "down", br), true)
})

test("two values are the same number", () => {
  assert.equal(sameNumber("1.50", "1.5"), true)
  assert.equal(sameNumber("1.5", "2"), false)
  assert.equal(sameNumber("", undefined), true)
  assert.equal(sameNumber("x", "x"), true)
  assert.equal(sameNumber("x", "1"), false)
})
