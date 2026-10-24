import {execWithPayload} from "../lib/js_payload.js"
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
} from "../lib/timer_logic.js"

const now = () => performance.now()

const readServer = (el) => ({
  elapsed: Number(el.dataset.elapsed),
  total: Number(el.dataset.total),
  running: el.dataset.running === "true",
  direction: el.dataset.direction,
})

const selects = (el, selector) => {
  try {
    return typeof selector === "string" && el.matches(selector)
  } catch {
    return false
  }
}

/**
 * `LineaUI.Timer` ticks in the browser, without a round trip. The clock is a monotonic reference (`performance.now()`
 * at the moment of the last server value), so a throttled tab catches up exactly. Every tick redraws the time
 * (`[data-time]`), the ring (`[data-ring]`), the kicker (`[data-kicker-text]`) and `data-state` on the root.
 *
 * The server stays the source of truth: a new `data-elapsed`, `data-running`, `data-total` or `data-direction`
 * replaces the browser's clock, a patch that changes none of them leaves the count alone.
 *
 * Commands, from the DOM event `linea:timer` on the element (what `LineaUI.Timer.pause/resume/toggle/add(id)`
 * dispatch) or the server push of the same name whose `id` is a selector matching it: `detail.action` is `pause`,
 * `resume`, `toggle` or `add` (with `detail.seconds`).
 *
 * Events, as `%JS{}` in data attributes: `data-on-toggle` runs with `%{id, running, elapsed}` when a command
 * pauses or resumes, `data-on-tick` every second with `%{id, elapsed, remaining}`, `data-on-finish` once with
 * `%{id, elapsed}` when a countdown reaches zero (or a count up reaches `data-total` with `data-stop-at-total`);
 * the timer then stops.
 */
export default {
  "LineaUI.Timer": {
    mounted() {
      this.server = readServer(this.el)
      this.clock = clock({base: this.server.elapsed, at: now(), running: this.server.running})
      this.fired = false
      this.onCommand = (event) => (event.stopPropagation(), this.command(event.detail))
      this.onVisible = () => this.start()
      this.el.addEventListener("linea:timer", this.onCommand)
      document.addEventListener("visibilitychange", this.onVisible)
      this.handleEvent("linea:timer", ({id, ...detail}) => selects(this.el, id) && this.command(detail))
      this.start()
    },

    updated() {
      const server = readServer(this.el)
      const next = adopt({client: this.clock, lastServer: this.server, server, now: now()})
      this.fired = next === this.clock && this.fired
      this.clock = next
      this.server = server
      this.start()
    },

    destroyed() {
      clearTimeout(this.timer)
      this.el.removeEventListener("linea:timer", this.onCommand)
      document.removeEventListener("visibilitychange", this.onVisible)
    },

    command({action, seconds}) {
      const run = {
        pause: () => this.pause(),
        resume: () => this.resume(),
        toggle: () => (this.clock.running ? this.pause() : this.resume()),
        add: () => this.add(Number(seconds) || 0),
      }[action]
      run?.()
    },

    pause() {
      this.clock.running && this.change(pausedAt(this.clock, now()))
    },

    resume() {
      this.clock.running || this.change(resumedAt(this.clock, now()))
    },

    change(next) {
      this.clock = next
      this.start()
      this.emit("onToggle", {running: next.running, elapsed: Math.floor(next.base)})
    },

    add(seconds) {
      this.clock = added(this.clock, now(), seconds)
      this.fired = this.fired && this.reached(elapsedAt(this.clock, now()))
      this.start()
    },

    start() {
      clearTimeout(this.timer)
      this.paint()
      this.clock.running && (this.timer = setTimeout(() => this.tick(), nextDelay(elapsedAt(this.clock, now()))))
    },

    tick() {
      const elapsed = elapsedAt(this.clock, now())
      const reached = this.reached(elapsed)
      const finish = shouldFinish({reached, fired: this.fired})
      reached && (this.clock = clock({base: this.server.total, at: now(), running: false}))
      this.start()
      this.emit("onTick", {elapsed: Math.floor(elapsed), remaining: Math.max(0, Math.floor(this.server.total - elapsed))})
      finish && this.finish()
    },

    finish() {
      this.fired = true
      this.emit("onFinish", {elapsed: Math.floor(this.server.total)})
    },

    reached(elapsed) {
      const {total, direction} = this.server
      return reachedEnd({elapsed, total, direction, stopAtTotal: this.el.dataset.stopAtTotal === "true"})
    },

    emit(name, payload) {
      execWithPayload(this.liveSocket, this.el, this.el.dataset[name], {id: this.el.id, ...payload})
    },

    paint() {
      const elapsed = elapsedAt(this.clock, now())
      const {total, direction} = this.server
      const running = this.clock.running
      this.el.dataset.state = running ? "running" : "paused"
      this.write("[data-time]", formatTime(shownSeconds({elapsed, total, direction}), this.el.dataset.format))
      this.write("[data-kicker-text]", running ? this.el.dataset.kicker : (this.el.dataset.kickerPaused ?? this.el.dataset.kicker))
      this.drawRing(arcFraction({elapsed, total, direction}))
    },

    write(selector, text) {
      const target = this.el.querySelector(selector)
      target && target.textContent !== text && (target.textContent = text)
    },

    drawRing(fraction) {
      const ring = this.el.querySelector("[data-ring]")
      ring && ring.setAttribute("stroke-dashoffset", dashOffset(fraction, Number(ring.getAttribute("stroke-dasharray"))))
    },
  },
}
