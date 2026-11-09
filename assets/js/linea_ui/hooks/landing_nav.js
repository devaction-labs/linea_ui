import {isStuck, thresholdOf} from "../lib/landing_nav_logic.js"

/**
 * `LineaUI.LandingNav`: the client side of `<.landing_nav sticky>`. Sets `data-stuck` on the bar once the page
 * has scrolled past `data-stuck-after` px (default 8), and removes it back at the top; the CSS turns the bar solid
 * (with border and shadow) while it is set. The attribute is client-owned (the component ignores it on patches).
 */
export default {
  "LineaUI.LandingNav": {
    mounted() {
      this.update = () => {
        const stuck = isStuck(window.scrollY, thresholdOf(this.el.dataset.stuckAfter))
        this.el.toggleAttribute("data-stuck", stuck)
      }
      window.addEventListener("scroll", this.update, {passive: true})
      this.update()
    },

    destroyed() {
      window.removeEventListener("scroll", this.update)
    },
  },
}
