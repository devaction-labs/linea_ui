import assert from "node:assert/strict"
import test from "node:test"
import {
  adopt,
  added,
  arcFraction,
  clock,
  dashOffset,
  elapsedAt,
  formatTime,
  nextDelay,
  pausedAt,
  reachedEnd,
  resumedAt,
  shouldFinish,
  shownSeconds,
} from "./timer_logic.js"

test("formats hours, minutes and seconds padded, or the short hours and minutes", () => {
  assert.equal(formatTime(3 * 3600 + 12 * 60 + 45), "03:12:45")
  assert.equal(formatTime(3 * 3600 + 12 * 60 + 45, "hm"), "3h12")
  assert.equal(formatTime(59, "hm"), "0h00")
  assert.equal(formatTime(3 * 3600 + 12 * 60 + 45, "hh:mm"), "03:12")
  assert.equal(formatTime(0), "00:00:00")
  assert.equal(formatTime(-5), "00:00:00")
  assert.equal(formatTime(100 * 3600), "100:00:00")
})

test("shows the elapsed seconds counting up and the seconds left counting down", () => {
  assert.equal(shownSeconds({elapsed: 61.9, total: 100, direction: "up"}), 61)
  assert.equal(shownSeconds({elapsed: 61.9, total: 100, direction: "down"}), 38)
  assert.equal(shownSeconds({elapsed: 130, total: 100, direction: "down"}), 0)
  assert.equal(shownSeconds({elapsed: 130, total: 100, direction: "up"}), 130)
})

test("the arc is the elapsed fraction counting up and what is left counting down, kept between 0 and 1", () => {
  assert.equal(arcFraction({elapsed: 7200, total: 28800, direction: "up"}), 0.25)
  assert.equal(arcFraction({elapsed: 7200, total: 28800, direction: "down"}), 0.75)
  assert.equal(arcFraction({elapsed: 40000, total: 28800, direction: "up"}), 1)
  assert.equal(arcFraction({elapsed: -5, total: 28800, direction: "up"}), 0)
  assert.equal(arcFraction({elapsed: 10, total: 0, direction: "up"}), 0)
})

test("the dash offset hides what is not drawn, to one decimal", () => {
  assert.equal(dashOffset(0, 326.7), 326.7)
  assert.equal(dashOffset(1, 326.7), 0)
  assert.equal(dashOffset(0.25, 326.7), 245)
})

test("a running clock counts from its monotonic reference, a paused one does not", () => {
  const running = clock({base: 100, at: 5000, running: true})
  assert.equal(elapsedAt(running, 5000), 100)
  assert.equal(elapsedAt(running, 8500), 103.5)
  assert.equal(elapsedAt(clock({base: 100, at: 5000, running: false}), 99999), 100)
})

test("a late timeout does not lose time: the reading depends on the clock, not on the number of ticks", () => {
  const running = clock({base: 0, at: 0, running: true})
  assert.equal(Math.floor(elapsedAt(running, 1000)), 1)
  assert.equal(Math.floor(elapsedAt(running, 61_250)), 61)
  assert.equal(Math.floor(elapsedAt(running, 3_600_000)), 3600)
})

test("a clock never reads backwards", () => {
  assert.equal(elapsedAt(clock({base: 10, at: 5000, running: true}), 4000), 10)
})

test("pausing keeps the elapsed time and resuming counts from there", () => {
  const paused = pausedAt(clock({base: 10, at: 0, running: true}), 2500)
  assert.deepEqual(paused, {base: 12.5, at: 2500, running: false})
  const resumed = resumedAt(paused, 9000)
  assert.equal(elapsedAt(resumed, 10000), 13.5)
})

test("adding time moves the reading and keeps the state; taking time away stops at zero", () => {
  const running = clock({base: 10, at: 0, running: true})
  const more = added(running, 2000, 900)
  assert.equal(more.running, true)
  assert.equal(elapsedAt(more, 3000), 913)
  assert.equal(elapsedAt(added(clock({base: 10, at: 0, running: false}), 0, -900), 0), 0)
})

test("the browser's count survives a patch that did not change what the server sent", () => {
  const server = {elapsed: 100, running: true, total: 28800, direction: "up"}
  const client = clock({base: 160, at: 1000, running: true})
  assert.equal(adopt({client, lastServer: server, server: {...server}, now: 2000}), client)
})

test("the server wins when elapsed, running, total or direction changed", () => {
  const last = {elapsed: 100, running: true, total: 28800, direction: "up"}
  const client = clock({base: 160, at: 1000, running: true})
  const changes = [{elapsed: 500}, {running: false}, {total: 600}, {direction: "down"}]
  for (const change of changes) {
    const next = adopt({client, lastServer: last, server: {...last, ...change}, now: 2000})
    assert.deepEqual(next, clock({base: change.elapsed ?? 100, at: 2000, running: change.running ?? true}))
  }
})

test("the next tick lands on the next whole second", () => {
  assert.equal(nextDelay(5), 1000)
  assert.equal(nextDelay(5.25), 750)
  assert.equal(nextDelay(5.999), 1)
})

test("the end is reached counting down at zero, or counting up at the total when it stops there", () => {
  assert.equal(reachedEnd({elapsed: 60, total: 60, direction: "down", stopAtTotal: false}), true)
  assert.equal(reachedEnd({elapsed: 59.9, total: 60, direction: "down", stopAtTotal: false}), false)
  assert.equal(reachedEnd({elapsed: 90, total: 60, direction: "up", stopAtTotal: false}), false)
  assert.equal(reachedEnd({elapsed: 60, total: 60, direction: "up", stopAtTotal: true}), true)
  assert.equal(reachedEnd({elapsed: 0, total: 0, direction: "down", stopAtTotal: false}), false)
})

test("finishing fires once per stretch", () => {
  assert.equal(shouldFinish({reached: true, fired: false}), true)
  assert.equal(shouldFinish({reached: true, fired: true}), false)
  assert.equal(shouldFinish({reached: false, fired: false}), false)
})
