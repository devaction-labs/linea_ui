import assert from "node:assert/strict"
import test from "node:test"
import {bands, datePattern, decimalsOf, estimateWidth, formatDate, linear, niceScale, plain, spread, timeTicks, toTime} from "./chart_scale.js"

const scale = (min, max, size, limits) => {
  const {ticks} = niceScale(min, max, {size, limits})
  return [ticks[0], ticks.at(-1), ticks[1] - ticks[0], ticks.length]
}

test("value axes pick the same ticks ApexCharts picks for the same data and height", () => {
  assert.deepEqual(scale(20, 55, 150), [20, 60, 20, 3])
  assert.deepEqual(scale(35, 65, 150), [30, 70, 20, 3])
  assert.deepEqual(scale(12, 60, 290), [10, 60, 10, 6])
  assert.deepEqual(scale(23, 60, 249), [20, 60, 10, 5])
  assert.deepEqual(scale(0, 60, 270), [0, 60, 10, 7])
  assert.deepEqual(scale(0, 88, 280), [0, 100, 20, 6])
  assert.deepEqual(scale(8107.85, 9340.85, 220), [8000, 9500, 500, 4])
  assert.deepEqual(scale(20, 614, 100), [0, 1000, 500, 3])
  assert.deepEqual(scale(12, 77, 100), [0, 100, 50, 3])
  assert.deepEqual(scale(0, 50, 100), [0, 50, 50, 2])
  assert.deepEqual(scale(100, 500, 268), [100, 500, 100, 5])
  assert.deepEqual(scale(6584.22, 6651, 364), [6580, 6660, 20, 5])
  assert.deepEqual(scale(20, 75, 150), [20, 80, 20, 4])
  assert.deepEqual(scale(20, 82, 150), [20, 100, 40, 3])
  assert.deepEqual(scale(20, 82, 180), [20, 100, 20, 5])
  assert.deepEqual(scale(0, 4221, 85), [0, 5000, 5000, 2])
  assert.deepEqual(scale(0, 7020, 85), [0, 10000, 5000, 3])
  assert.deepEqual(scale(0, 2857, 85), [0, 4000, 2000, 3])
  assert.deepEqual(scale(12, 36, 240), [10, 40, 5, 7])
  assert.deepEqual(scale(11, 109, 300), [0, 120, 20, 7])
  assert.deepEqual(scale(0, 64, 300), [0, 80, 20, 5])
  assert.deepEqual(scale(0, 95, 300), [0, 100, 20, 6])
  assert.deepEqual(scale(0, 1000, 60), [0, 1000, 500, 3])
})

test("a flat or empty range still gets an axis", () => {
  assert.deepEqual(niceScale(5, 5, {size: 200}).ticks.length > 1, true)
  assert.deepEqual(niceScale(0, 0, {size: 200}).ticks[0], 0)
  assert.equal(niceScale(NaN, NaN, {size: 200}).ticks.length > 1, true)
})

test("limits fix the ends and the tick count", () => {
  assert.deepEqual(niceScale(3, 97, {size: 300, limits: {min: 0, max: 100}}).ticks, [0, 20, 40, 60, 80, 100])
  assert.deepEqual(niceScale(3, 97, {size: 300, limits: {min: 0, max: 100, tickAmount: 4}}).ticks, [0, 25, 50, 75, 100])
  assert.equal(niceScale(3, 97, {size: 300, limits: {min: 0}}).ticks[0], 0)
})

test("spread, bands and linear place values", () => {
  assert.deepEqual(spread(3, 100), [0, 50, 100])
  assert.deepEqual(spread(1, 100), [50])
  assert.deepEqual(bands(4, 100), {width: 25, centers: [12.5, 37.5, 62.5, 87.5]})
  assert.equal(linear(0, 10, 100, 0)(5), 50)
  assert.equal(linear(3, 3, 0, 10)(3), 5)
})

test("time ticks fall on whole days, months or years", () => {
  const day = 86400000
  const start = Date.UTC(2000, 4, 5)
  assert.deepEqual(timeTicks(start, start + 6 * day, 10), [0, 1, 2, 3, 4, 5, 6].map((n) => start + n * day))
  assert.equal(timeTicks(start, start + 21 * day, 8).length <= 8, true)
  const months = timeTicks(Date.UTC(2020, 0, 1), Date.UTC(2020, 11, 31), 12)
  assert.equal(formatDate(months[0], "MMM yyyy"), "Jan 2020")
  assert.equal(months.length, 12)
  const years = timeTicks(Date.UTC(1990, 0, 1), Date.UTC(2024, 0, 1), 8)
  assert.equal(formatDate(years[0], "yyyy"), "1990")
  assert.equal(years.length <= 8, true)
})

test("dates format with tokens in UTC", () => {
  const time = Date.UTC(2000, 4, 5, 14, 7, 9)
  assert.equal(formatDate(time, "dd MMM"), "05 May")
  assert.equal(formatDate(time, "dddd, MMMM dd yyyy"), "Friday, May 05 2000")
  assert.equal(formatDate(time, "dd MMM yyyy", "pt-BR"), "05 Mai 2000")
  assert.equal(formatDate(time, "dddd, MMMM", "pt-BR"), "Sexta-feira, Maio")
  assert.equal(formatDate(time, "dd MMM", "not a locale!"), "05 May")
  assert.equal(formatDate(time, "HH:mm:ss"), "14:07:09")
  assert.equal(formatDate(time, "hh:mm TT"), "02:07 PM")
  assert.equal(toTime("2000-05-05"), Date.UTC(2000, 4, 5))
  assert.equal(toTime(1000), 1000)
  assert.equal(datePattern(10 * 86400000), "dd MMM")
  assert.equal(datePattern(3600000), "HH:mm")
})

test("numbers lose their floating point noise", () => {
  assert.equal(plain(0.1 + 0.2), "0.3")
  assert.equal(plain(8107.85), "8107.85")
  assert.equal(plain(NaN), "")
  assert.equal(decimalsOf([1, 2, 3]), 0)
  assert.equal(decimalsOf([1, 1.5, 2.25]), 2)
  assert.equal(estimateWidth("111", 10) < estimateWidth("000", 10), true)
})
