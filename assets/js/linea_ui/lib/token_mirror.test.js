import test from "node:test"
import assert from "node:assert/strict"
import {splitTokens, tokenSpacing} from "./token_mirror.js"

test("splitTokens separates the {{tokens}} from the text, keeping every character", () => {
  const pieces = splitTokens("A {{fatura.numero}} de {{fornecedor.nome}}.")
  assert.deepEqual(pieces, [
    {kind: "text", text: "A "},
    {kind: "token", text: "{{fatura.numero}}"},
    {kind: "text", text: " de "},
    {kind: "token", text: "{{fornecedor.nome}}"},
    {kind: "text", text: "."},
  ])
  assert.equal(pieces.map((piece) => piece.text).join(""), "A {{fatura.numero}} de {{fornecedor.nome}}.")
})

test("splitTokens: adjacent tokens, empty text and unclosed braces", () => {
  assert.deepEqual(splitTokens("{{a}}{{b}}"), [{kind: "token", text: "{{a}}"}, {kind: "token", text: "{{b}}"}])
  assert.deepEqual(splitTokens(""), [])
  assert.deepEqual(splitTokens(null), [])
  assert.deepEqual(splitTokens("{{abc"), [{kind: "text", text: "{{abc"}])
  assert.deepEqual(splitTokens("{{a {{b}}"), [{kind: "text", text: "{{a "}, {kind: "token", text: "{{b}}"}])
})

test("splitTokens does not cross a line break and does not interpret HTML", () => {
  assert.deepEqual(splitTokens("{{a\nb}}"), [{kind: "text", text: "{{a\nb}}"}])
  assert.deepEqual(splitTokens("<b>{{x}}</b>"), [
    {kind: "text", text: "<b>"},
    {kind: "token", text: "{{x}}"},
    {kind: "text", text: "</b>"},
  ])
})

test("tokenSpacing spreads the width difference over the characters", () => {
  assert.equal(tokenSpacing(100, 110, 10), 1)
  assert.equal(tokenSpacing(100, 90, 10), -1)
  assert.equal(tokenSpacing(100, 100, 10), 0)
  assert.equal(tokenSpacing(100, 110, 0), 0)
  assert.equal(tokenSpacing(NaN, 110, 5), 0)
})
