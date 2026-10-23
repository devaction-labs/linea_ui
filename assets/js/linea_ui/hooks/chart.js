import {parseOptions, targets, updatesFor} from "../lib/chart_logic.js"

const prepared = (el, options) => {
  const detail = {options}
  el.dispatchEvent(new CustomEvent("linea:chart:options", {bubbles: true, detail}))
  return detail.options
}

export default {
  "LineaUI.Chart": {
    mounted() {
      this.json = this.el.dataset.options
      this.canvas = this.el.querySelector("[data-chart-canvas]")
      this.onLoad = () => this.draw()
      this.handleEvent("linea:chart", (payload) => this.apply(payload))
      this.draw()
    },

    updated() {
      const json = this.el.dataset.options
      json !== this.json && ((this.json = json), this.redraw())
    },

    destroyed() {
      window.removeEventListener("load", this.onLoad)
      this.chart?.destroy()
      this.chart = null
    },

    draw() {
      const options = parseOptions(this.json)
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
      const options = parseOptions(this.json)
      this.chart && options ? this.chart.updateOptions(prepared(this.el, options)) : this.draw()
    },

    apply(payload) {
      targets(payload, this.el.id) &&
        this.chart &&
        updatesFor(payload).forEach(([method, value]) => this.chart[method](value))
    },
  },
}
