import {test} from "node:test"
import assert from "node:assert/strict"
import {format, raw, caretFor, significantBefore, dropBefore, cardBlocks} from "./mask_logic.js"

test("blocks with a prefix keep the prefix and join blocks with the delimiter", () => {
  const options = {prefix: "Prefix", delimiter: "-", blocks: [6, 4, 4, 7]}
  assert.equal(format("", "blocks", options), "Prefix-")
  assert.equal(format("Prefix", "blocks", options), "Prefix-")
  assert.equal(format("Prefix1234", "blocks", options), "Prefix-1234")
  assert.equal(format("Prefix-12345678abcdefghij", "blocks", options), "Prefix-1234-5678-abcdefg")
  assert.equal(format("Prefi12", "blocks", options), "Prefix-12")
  assert.equal(raw("Prefix-1234-5678", "blocks", options), "12345678")
})

test("blocks with several delimiters and uppercase", () => {
  const options = {delimiters: [".", "_", "-"], blocks: [3, 2, 3, 3], uppercase: true}
  assert.equal(format("abcdefghijklm", "blocks", options), "ABC.DE_FGH-IJK")
  assert.equal(format("ABC.DE_F", "blocks", options), "ABC.DE_F")
  assert.equal(format("ab", "blocks", options), "AB")
})

test("numeric blocks drop letters", () => {
  assert.equal(format("12a34", "blocks", {blocks: [2, 2], numeric: true}), "12 34")
})

test("credit cards follow the brand's blocks", () => {
  assert.deepEqual(cardBlocks("4111"), [4, 4, 4, 4])
  assert.deepEqual(cardBlocks("3782"), [4, 6, 5])
  assert.deepEqual(cardBlocks("3056"), [4, 6, 4])
  assert.equal(format("4111111111111111999", "credit_card"), "4111 1111 1111 1111")
  assert.equal(format("378282246310005", "credit_card"), "3782 822463 10005")
  assert.equal(format("4111 1", "credit_card"), "4111 1")
  assert.equal(raw("4111 1111", "credit_card"), "41111111")
})

test("dates pad and clamp day and month", () => {
  const options = {pattern: ["m", "d", "Y"], delimiter: "-"}
  assert.equal(format("12252024", "date", options), "12-25-2024")
  assert.equal(format("4", "date", options), "04")
  assert.equal(format("135", "date", options), "12-05")
  assert.equal(format("0000", "date", options), "01-01")
  assert.equal(format("1239", "date", options), "12-31")
  assert.equal(format("12-25-20245", "date", options), "12-25-2024")
  assert.equal(format("1225", "date", {pattern: ["m", "y"]}), "12/25")
})

test("times pad and clamp hours, minutes and seconds", () => {
  assert.equal(format("235959", "time"), "23:59:59")
  assert.equal(format("9", "time"), "09")
  assert.equal(format("2961", "time"), "23:06:1")
  assert.equal(format("12:3", "time", {pattern: ["h", "m"]}), "12:3")
})

test("phones group digits", () => {
  assert.equal(format("2015550123", "phone"), "201 555 0123")
  assert.equal(format("(201) 555", "phone"), "201 555")
  assert.equal(raw("201 555 0123", "phone"), "2015550123")
})

test("a numeral prefix shows before the figure and stays out of the raw value", () => {
  const options = {delimiter: ".", decimal_mark: ",", prefix: "R$ "}
  assert.equal(format("1234567,5", "numeral", options), "R$ 1.234.567,5")
  assert.equal(format("R$ 1.234.567,5", "numeral", options), "R$ 1.234.567,5")
  assert.equal(raw("R$ 1.234.567,5", "numeral", options), "1234567.5")
  assert.equal(format("", "numeral", options), "")
  assert.equal(format("-1234", "numeral", options), "-R$ 1.234")
})

test("a numeral prefix with the decimal mark or a digit in it is not read as part of the number", () => {
  const dotted = {delimiter: ",", decimal_mark: ".", prefix: "S/. "}
  assert.equal(format("S/. 12.5", "numeral", dotted), "S/. 12.5")
  assert.equal(format("-S/. 12.5", "numeral", dotted), "-S/. 12.5")
  assert.equal(raw("S/. 12.5", "numeral", dotted), "12.5")
  assert.equal(format("+1 25", "numeral", {prefix: "+1 "}), "+1 25")
})

test("numerals group thousands in three styles", () => {
  assert.equal(format("1234567.891", "numeral"), "1,234,567.89")
  assert.equal(format("1234567", "numeral", {thousands: "lakh"}), "12,34,567")
  assert.equal(format("123456789", "numeral", {thousands: "wan"}), "1,2345,6789")
  assert.equal(format("1234", "numeral", {thousands: "none"}), "1234")
  assert.equal(format("-0012", "numeral"), "-12")
  assert.equal(format("-12", "numeral", {positive: true}), "12")
  assert.equal(format(".5", "numeral"), "0.5")
  assert.equal(format("12.", "numeral"), "12.")
  assert.equal(format("12.5", "numeral", {decimals: 0}), "12")
  assert.equal(raw("1,234,567.89", "numeral"), "1234567.89")
  assert.equal(raw("", "numeral"), "")
})

test("formatting is idempotent", () => {
  for (const [value, kind, options] of [
    ["4111111111111111", "credit_card", {}],
    ["12252024", "date", {}],
    ["1234567.89", "numeral", {}],
    ["Prefix12345678", "blocks", {prefix: "Prefix", delimiter: "-", blocks: [6, 4, 4, 7]}],
  ]) {
    const once = format(value, kind, options)
    assert.equal(format(once, kind, options), once)
  }
})

test("the caret stays after the same typed character", () => {
  assert.equal(significantBefore("41111", 5), 5)
  assert.equal(caretFor("4111 1", 5), 6)
  assert.equal(caretFor("4111 1111", 2), 2)
  assert.equal(caretFor("abc", 0), 0)
  assert.equal(caretFor("ab", 9), 2)
})

test("a backspace over a delimiter drops the character before it", () => {
  assert.deepEqual(dropBefore("41111", 4), {text: "4111", position: 3})
  assert.deepEqual(dropBefore("--", 2), {text: "--", position: 2})
})
