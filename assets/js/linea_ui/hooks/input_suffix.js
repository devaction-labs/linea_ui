/**
 * `LineaUI.InputSuffix`: keeps the input's right padding equal to a text suffix's width. The hook
 * sits on the positioned wrapper around the input; it publishes the width of its
 * `[data-suffix-text]` box as `--linea-suffix-w` (the input's `pr` reads it, 2.25rem until then).
 */
const publish = (el) => {
  const box = el.querySelector("[data-suffix-text]")
  box && el.style.setProperty("--linea-suffix-w", `${box.offsetWidth}px`)
}

export default {
  "LineaUI.InputSuffix": {
    mounted() {
      publish(this.el)
      const box = this.el.querySelector("[data-suffix-text]")
      this.observer = box && typeof ResizeObserver !== "undefined" ? new ResizeObserver(() => publish(this.el)) : null
      this.observer?.observe(box)
    },
    updated() {
      publish(this.el)
    },
    destroyed() {
      this.observer?.disconnect()
    }
  }
}
