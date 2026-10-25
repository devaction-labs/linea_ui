import {parseSpec, resolveFormatters} from "../lib/chart_formatters.js"
import {hover} from "../lib/chart_hover.js"
import {applyUpdate, parseOptions, targets} from "../lib/chart_logic.js"
import {build} from "../lib/chart_render.js"
import {estimateWidth} from "../lib/chart_scale.js"
import {axisTipsHtml, overlaySvg, tooltipHtml} from "../lib/chart_tooltip.js"

/**
 * A chart drawn in SVG from ApexCharts-shaped options, with no library behind it: the lines, bars,
 * rings and axes come from `lib/chart_*.js` and this hook only sizes the chart to its element, draws it,
 * follows the pointer for the tooltip and crosshair, toggles series from the legend and takes the
 * `linea:chart` pushes. The first draw plays a short entry animation (not under `prefers-reduced-motion`).
 */

const prepared = (el, options) => {
  const detail = {options: resolveFormatters(structuredClone(options), parseSpec(el.dataset.formatters))}
  el.dispatchEvent(new CustomEvent("linea:chart:options", {bubbles: true, detail}))
  return detail.options
}

const measurer = (el) => {
  const context = document.createElement("canvas").getContext("2d")
  const family = getComputedStyle(el).fontFamily
  return context
    ? (text, size) => ((context.font = `${size}px ${family}`), context.measureText(String(text)).width)
    : estimateWidth
}

const Chart = {
  mounted() {
    this.hidden = new Set()
    this.entering = true
    this.options = parseOptions(this.el.dataset.options)
    this.key = this.keyOf()
    this.canvas = this.el.querySelector("[data-chart-canvas]")
    this.measure = measurer(this.el)
    this.width = 0
    this.onMove = (event) => this.point(event)
    this.onLeave = () => this.clear()
    this.onClick = (event) => this.legendClick(event)
    this.canvas.addEventListener("pointermove", this.onMove)
    this.canvas.addEventListener("pointerdown", this.onMove)
    this.canvas.addEventListener("pointerleave", this.onLeave)
    this.canvas.addEventListener("click", this.onClick)
    this.observer = new ResizeObserver(() => this.resized())
    this.observer.observe(this.canvas)
    this.handleEvent("linea:chart", (payload) => this.apply(payload))
    this.resized()
  },

  updated() {
    const key = this.keyOf()
    key !== this.key && ((this.key = key), (this.options = parseOptions(this.el.dataset.options)), this.draw())
  },

  destroyed() {
    this.observer?.disconnect()
    this.canvas?.removeEventListener("pointermove", this.onMove)
    this.canvas?.removeEventListener("pointerdown", this.onMove)
    this.canvas?.removeEventListener("pointerleave", this.onLeave)
    this.canvas?.removeEventListener("click", this.onClick)
  },

  keyOf() {
    return `${this.el.dataset.options}|${this.el.dataset.formatters ?? ""}`
  },

  resized() {
    const width = Math.floor(this.canvas.clientWidth)
    width > 0 && width !== this.width && ((this.width = width), this.draw())
  },

  apply(payload) {
    targets(payload, this.el.id) && this.options && ((this.options = applyUpdate(this.options, payload)), this.draw())
  },

  draw() {
    this.options && this.width > 0 && this.paint(this.options)
  },

  paint(options) {
    const result = build(prepared(this.el, options), {
      width: this.width,
      viewport: window.innerWidth,
      measure: this.measure,
      uid: this.el.id,
      hidden: [...this.hidden],
    })
    this.result = result
    const position = result.legend?.position ?? "bottom"
    this.canvas.innerHTML = `<div class="linea-chart-stage${this.entering ? " linea-chart--enter" : ""}" style="height:${result.height}px">${result.svg}${
      result.legendHtml ? `<div class="linea-chart-legend" data-position="${position}" style="${result.legendStyle}">${result.legendHtml}</div>` : ""
    }<div class="linea-chart-axistips" aria-hidden="true"></div><div class="linea-chart-tooltip" aria-hidden="true" hidden></div></div>`
    this.entering = false
    this.stage = this.canvas.firstElementChild
    this.el.style.minHeight = `${result.height + (result.config.chart.parentHeightOffset ?? 0)}px`
  },

  point(event) {
    const result = this.result
    const svg = this.stage?.querySelector("svg")
    result?.layout && svg && event.target.closest?.(".linea-chart-legend") === null && this.show(result, svg.getBoundingClientRect(), event)
  },

  show(result, box, event) {
    const hit = hover(result.layout, result.drawn.boxes, event.clientX - box.left, event.clientY - box.top)
    hit ? this.hit(hit) : this.clear()
  },

  hit(hit) {
    const tip = this.stage.querySelector(".linea-chart-tooltip")
    this.stage.querySelector(".linea-chart-hover").innerHTML = overlaySvg(hit)
    this.stage.querySelector(".linea-chart-axistips").innerHTML = axisTipsHtml(hit)
    this.activate(hit.active)
    result_enabled(this.result.config) ? this.place(tip, hit) : (tip.hidden = true)
  },

  place(tip, hit) {
    tip.innerHTML = tooltipHtml(hit)
    tip.hidden = false
    const room = this.stage.getBoundingClientRect()
    const width = tip.offsetWidth
    const height = tip.offsetHeight
    const left = hit.anchor.x + 14 + width > room.width ? hit.anchor.x - 14 - width : hit.anchor.x + 14
    const top = Math.min(Math.max(hit.anchor.y - height / 2, 0), Math.max(room.height - height, 0))
    tip.style.transform = `translate(${Math.max(left, 0)}px, ${top}px)`
  },

  activate(active) {
    this.stage.querySelectorAll(".linea-chart-bar.is-active").forEach((bar) => bar.classList.remove("is-active"))
    active && this.stage.querySelector(`.linea-chart-bar[data-series="${active.series}"][data-i="${active.slot}"]`)?.classList.add("is-active")
  },

  clear() {
    const tip = this.stage?.querySelector(".linea-chart-tooltip")
    tip && (tip.hidden = true)
    this.stage && (this.stage.querySelector(".linea-chart-hover").innerHTML = "")
    this.stage && (this.stage.querySelector(".linea-chart-axistips").innerHTML = "")
    this.stage && this.activate(null)
  },

  legendClick(event) {
    const item = event.target.closest?.(".linea-chart-legend-item")
    const index = item ? Number(item.dataset.series) : null
    index !== null && this.result.config.legend.onItemClick?.toggleDataSeries !== false && this.toggle(index)
  },

  toggle(index) {
    this.hidden.has(index) ? this.hidden.delete(index) : this.hidden.add(index)
    this.draw()
  },
}

const result_enabled = (config) => config.tooltip.enabled !== false

export default {"LineaUI.Chart": Chart}
