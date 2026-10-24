import assert from "node:assert/strict"
import test from "node:test"
import {assignPath, FORMATTERS, parseSpec, resolveFormatters} from "./chart_formatters.js"

test("each formatter has its own meaning", () => {
  assert.equal(FORMATTERS.thousands(2500), "2.5k")
  assert.equal(FORMATTERS.thousands_round(2500), "3k")
  assert.equal(FORMATTERS.thousands_fixed(2500), "2.50k")
  assert.equal(FORMATTERS.thousands_fixed(800), 800)
  assert.equal(FORMATTERS.kilo(1499), "1k")
  assert.equal(FORMATTERS.kilo(10), 10)
  assert.equal(FORMATTERS.dollars(5), "$5")
  assert.equal(FORMATTERS.dollars_thousands(5000), "$5k")
  assert.equal(FORMATTERS.percent(12.5), "12.5%")
  assert.equal(FORMATTERS.percent_round(12.5), "13%")
  assert.equal(FORMATTERS.round(2.6), "3")
  assert.equal(FORMATTERS.hours(3), "3h")
  assert.equal(FORMATTERS.minutes(45), "45 min")
  assert.equal(FORMATTERS.none(7), "")
  assert.equal(FORMATTERS.total({config: {series: [10, 20, 30]}}), 60)
})

test("a path is assigned, creating the nodes in between", () => {
  assert.deepEqual(assignPath({}, "a.b.c", 1), {a: {b: {c: 1}}})
  assert.deepEqual(assignPath({a: {x: 1}}, "a.b", 2), {a: {x: 1, b: 2}})
})

test("formatters by path replace the name with the function", () => {
  const options = resolveFormatters({yaxis: {labels: {}}}, {"yaxis.labels.formatter": "thousands"})
  assert.equal(options.yaxis.labels.formatter(3000), "3k")
})

test("a bare formatter name inside the options is resolved at any depth", () => {
  const options = resolveFormatters({
    tooltip: {y: {formatter: "dollars"}},
    plotOptions: {radialBar: {dataLabels: {total: {formatter: "total"}}}},
    yaxis: [{labels: {formatter: "hours"}}],
  })
  assert.equal(options.tooltip.y.formatter(4), "$4")
  assert.equal(options.plotOptions.radialBar.dataLabels.total.formatter({config: {series: [1, 2]}}), 3)
  assert.equal(options.yaxis[0].labels.formatter(2), "2h")
})

test("unknown names and non formatter keys are left alone", () => {
  const options = resolveFormatters(
    {a: {formatter: "mystery"}, label: "dollars", name: {formatter: "constructor"}},
    {"x.y": "mystery", "z.w": "toString"},
  )
  assert.equal(options.a.formatter, "mystery")
  assert.equal(options.label, "dollars")
  assert.equal(options.name.formatter, "constructor")
  assert.equal(options.x, undefined)
  assert.equal(options.z, undefined)
})

test("the spec comes from JSON and bad input is empty", () => {
  assert.deepEqual(parseSpec('{"a.b": "round"}'), {"a.b": "round"})
  assert.deepEqual(parseSpec(undefined), {})
  assert.deepEqual(parseSpec("nope"), {})
  assert.deepEqual(parseSpec("[1]"), {})
})
