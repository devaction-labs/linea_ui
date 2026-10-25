import {afterScroll, endOf} from "../lib/scroll_bottom_logic.js"

/**
 * `LineaUI.ScrollBottom` (`scroll_area` with `stick_bottom`): keeps a list that grows at its end scrolled to it.
 * It jumps to the end when mounted and scrolls there, smoothly, each time the server patches the box, unless
 * the reader scrolled up: the box counts as pinned while it is within a few pixels of its end, and scrolling back
 * down to it pins it again.
 */
export default {
  "LineaUI.ScrollBottom": {
    mounted() {
      this.pinned = true
      this.top = 0
      this.onScroll = () => {
        this.pinned = afterScroll({was: this.pinned, box: this.el, previousTop: this.top})
        this.top = this.el.scrollTop
      }
      this.el.addEventListener("scroll", this.onScroll, {passive: true})
      this.el.scrollTop = endOf(this.el)
    },

    updated() {
      this.pinned && this.el.scrollTo({top: endOf(this.el), behavior: "smooth"})
    },

    destroyed() {
      this.el.removeEventListener("scroll", this.onScroll)
    },
  },
}
