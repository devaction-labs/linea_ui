import {drawFlow} from "../lib/flow_draw.js"

/**
 * `Flow`: draws the connections of a `flow/1`. It measures the nodes, so it redraws when the view patches
 * the flow (a node added, moved or selected), when a node changes size and when the window does.
 * Enter and Space on a focused node card click it, so a `phx-click` on the node also works from the keyboard;
 * keys pressed in a link, button or field inside the card are left alone.
 */
export default {
  "LineaUI.Flow": {
    mounted() {
      this.draw = () => drawFlow(this.el)
      this.onKey = (event) => {
        if (event.key !== "Enter" && event.key !== " ") return
        if (!event.target.classList?.contains("linea-flow-card")) return
        event.preventDefault()
        event.target.click()
      }
      this.el.addEventListener("keydown", this.onKey)
      this.observer = new ResizeObserver(() => this.schedule())
      this.observe()
      window.addEventListener("resize", this.draw)
      document.fonts?.ready?.then(this.draw)
      this.draw()
    },

    updated() {
      this.observe()
      this.draw()
    },

    destroyed() {
      this.observer.disconnect()
      this.el.removeEventListener("keydown", this.onKey)
      window.removeEventListener("resize", this.draw)
      cancelAnimationFrame(this.frame)
    },

    observe() {
      this.observer.disconnect()
      this.el.querySelectorAll(".linea-flow-node").forEach((node) => this.observer.observe(node))
    },

    schedule() {
      cancelAnimationFrame(this.frame)
      this.frame = requestAnimationFrame(this.draw)
    }
  }
}
