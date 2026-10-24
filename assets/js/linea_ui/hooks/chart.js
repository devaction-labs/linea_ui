import {parseOptions, targets, updatesFor} from "../lib/chart_logic.js"
import {parseSpec, resolveFormatters} from "../lib/chart_formatters.js"

const prepared = (el, options) => {
  const detail = {options: resolveFormatters(options, parseSpec(el.dataset.formatters))}
  el.dispatchEvent(new CustomEvent("linea:chart:options", {bubbles: true, detail}))
  return detail.options
}

export default {
  "LineaUI.Chart": {
    mounted() {
      this.json = this.key()
      this.canvas = this.el.querySelector("[data-chart-canvas]")
      this.onLoad = () => this.draw()
      this.handleEvent("linea:chart", (payload) => this.apply(payload))
      this.draw()
    },

    updated() {
      const key = this.key()
      key !== this.json && ((this.json = key), this.redraw())
    },

    key() {
      return `${this.el.dataset.options}|${this.el.dataset.formatters ?? ""}`
    },

    destroyed() {
      window.removeEventListener("load", this.onLoad)
      this.chart?.destroy()
      this.chart = null
    },

    draw() {
      const options = parseOptions(this.el.dataset.options)
      const ApexCharts = window.ApexCharts
      this.el.dataset.state = ApexCharts ? "ready" : "waiting"
      ApexCharts || window.addEventListener("load", this.onLoad, {once: true})
      ApexCharts && options && this.render(ApexCharts, options)
    },

    render(ApexCharts, options) {
      this.chart?.destroy()
      this.chart = new ApexCharts(this.canvas, prepared(this.el, options))
      this.chart.render()
    },

    redraw() {
      const options = parseOptions(this.el.dataset.options)
      this.chart && options ? this.chart.updateOptions(prepared(this.el, options)) : this.draw()
    },

    apply(payload) {
      targets(payload, this.el.id) &&
        this.chart &&
        updatesFor(payload).forEach(([method, value]) => this.chart[method](value))
    },
  },
}
