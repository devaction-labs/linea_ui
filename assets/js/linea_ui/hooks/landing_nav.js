import {CLOSE_DELAY, OPEN_DELAY, isStuck, opensOnHover, stepIndex, thresholdOf} from "../lib/landing_nav_logic.js"

const ITEMS = "a[href], button:not([disabled])"

/**
 * `LineaUI.LandingNav`: the client side of `<.landing_nav>`.
 *
 * - Sticky (`data-sticky`): sets `data-stuck` on the bar once the page has scrolled past `data-stuck-after` px
 *   (default 8) and removes it back at the top; the CSS turns the bar solid while it is set. The attribute is
 *   client-owned (the component ignores it on patches).
 * - Hover (`data-open-on="hover"`): a mouse resting on a trigger opens its mega menu, which stays open while the
 *   pointer goes down into it (a short grace period covers the gap), and closes once the pointer has left both.
 *   Moving to another trigger switches panels at once. A touch still opens and closes it by tap.
 * - Keyboard, in both modes: ArrowDown on a trigger opens its panel and focuses the first card or link; inside, the
 *   arrows (and Home, End) walk the items; Escape closes and gives the focus back to the trigger; tabbing out of the
 *   bar closes it.
 *
 * Opening and closing run the component's own `Phoenix.LiveView.JS` (the trigger's `phx-click`, the bar's
 * `phx-click-away`), so the state survives patches like a click would.
 */
export default {
  "LineaUI.LandingNav": {
    mounted() {
      const el = this.el

      if (el.hasAttribute("data-sticky")) {
        this.update = () => el.toggleAttribute("data-stuck", isStuck(window.scrollY, thresholdOf(el.dataset.stuckAfter)))
        window.addEventListener("scroll", this.update, {passive: true})
        this.update()
      }

      this.timer = null
      const clear = () => (clearTimeout(this.timer), (this.timer = null))
      const later = (ms, fn) => (clear(), (this.timer = setTimeout(fn, ms)))

      const triggers = () => [...el.querySelectorAll(".lo-lp-links button[aria-controls]")]
      const panelOf = (trigger) => document.getElementById(trigger.getAttribute("aria-controls"))
      const isOpen = (trigger) => trigger.getAttribute("aria-expanded") === "true"
      const openTrigger = () => triggers().find(isOpen)
      const open = (trigger) => isOpen(trigger) || this.liveSocket.execJS(trigger, trigger.getAttribute("phx-click"))
      const close = () => openTrigger() && this.liveSocket.execJS(el, el.getAttribute("phx-click-away"))
      const items = (panel) => [...panel.querySelectorAll(ITEMS)].filter((item) => item.offsetParent !== null)
      const hover = (e) => opensOnHover(el.dataset.openOn, e.pointerType)

      this.onOver = (e) => {
        if (!hover(e)) return
        const trigger = e.target.closest?.(".lo-lp-links button[aria-controls]")
        const panel = e.target.closest?.(".lo-lp-mega")

        if (trigger && el.contains(trigger)) {
          if (isOpen(trigger)) return clear()
          openTrigger() ? (clear(), open(trigger)) : later(OPEN_DELAY, () => open(trigger))
        } else if (panel && el.contains(panel)) {
          clear()
        } else if (openTrigger()) {
          later(CLOSE_DELAY, close)
        } else {
          clear()
        }
      }

      this.onLeave = (e) => hover(e) && (openTrigger() ? later(CLOSE_DELAY, close) : clear())

      this.onKey = (e) => {
        const trigger = e.target.closest?.(".lo-lp-links button[aria-controls]")
        const panel = e.target.closest?.(".lo-lp-mega")

        if (trigger && e.key === "ArrowDown") {
          e.preventDefault()
          open(trigger)
          requestAnimationFrame(() => items(panelOf(trigger))[0]?.focus())
        } else if (panel && e.key !== "Escape") {
          const list = items(panel)
          const next = stepIndex(e.key, list.indexOf(document.activeElement), list.length)
          if (next !== null) (e.preventDefault(), list[next].focus())
        } else if (e.key === "Escape" && (trigger || panel)) {
          const owner = trigger || triggers().find((t) => panelOf(t) === panel)
          requestAnimationFrame(() => owner?.focus())
        }
      }

      this.onFocusOut = (e) => {
        if (e.relatedTarget && !el.contains(e.relatedTarget)) close()
      }

      el.addEventListener("pointerover", this.onOver)
      el.addEventListener("pointerleave", this.onLeave)
      el.addEventListener("keydown", this.onKey)
      el.addEventListener("focusout", this.onFocusOut)
    },

    destroyed() {
      clearTimeout(this.timer)
      this.update && window.removeEventListener("scroll", this.update)
    },
  },
}
