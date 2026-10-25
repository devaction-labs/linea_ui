import {parseSpec, resolveFormatters} from "../lib/chart_formatters.js"
import {applyUpdate, parseOptions, targets, widthOf} from "../lib/chart_logic.js"
import {build} from "../lib/chart_render.js"
import {estimateWidth} from "../lib/chart_scale.js"
import {stageHtml} from "../lib/chart_stage.js"
import {axisTipsHtml, overlaySvg, tooltipHtml} from "../lib/chart_tooltip.js"

/**
 * A chart drawn in SVG from ApexCharts-shaped options, with no library behind it: the lines, bars, rings
 * and axes come from `lib/chart_*.js`, and this hook sizes the chart to its element, draws it, follows
 * the pointer for the tooltip and crosshair, toggles series from the legend and takes the `linea:chart`
 * pushes. The first draw plays a short entry animation (not under `prefers-reduced-motion`).
 */

const prepared = (el, options) => {
  const detail = {options: resolveFormatters(structuredClone(options), parseSpec(el.dataset.formatters))}
  el.dispatchEvent(new CustomEvent("linea:chart:options", {bubbles: true, detail}))
  return detail.options
}

const measurer = (el) => {
  const context = document.createElement("canvas").getContext("2d")
  const family = getComputedStyle(el).fontFamily
  return context ? (text, size) => ((context.font = `${size}px ${family}`), context.measureText(String(text)).width) : estimateWidth
}

const Chart = {
  mounted() {
    this.hidden = new Set()
    this.entering = true
    this.options = parseOptions(this.el.dataset.options)
    this.el.style.width = widthOf(this.options?.chart?.width)
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
    this.observer = new ResizeObserver(() => this.schedule())
    this.observer.observe(this.canvas)
    this.handleEvent("linea:chart", (payload) => this.apply(payload))
    this.resized()
  },

  updated() {
    const key = this.keyOf()
    key !== this.key && ((this.key = key), (this.options = parseOptions(this.el.dataset.options)), (this.el.style.width = widthOf(this.options?.chart?.width)), this.draw())
  },

  destroyed() {
    cancelAnimationFrame(this.frame)
    this.observer?.disconnect()
    this.canvas?.removeEventListener("pointermove", this.onMove)
    this.canvas?.removeEventListener("pointerdown", this.onMove)
    this.canvas?.removeEventListener("pointerleave", this.onLeave)
    this.canvas?.removeEventListener("click", this.onClick)
  },

  keyOf() {
    return `${this.el.dataset.options}|${this.el.dataset.formatters ?? ""}`
  },

  schedule() {
    cancelAnimationFrame(this.frame)
    this.frame = requestAnimationFrame(() => this.resized())
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
    const env = {width: this.width, viewport: window.innerWidth, measure: this.measure, uid: this.el.id, hidden: [...this.hidden]}
    const result = this.attempt(() => build(prepared(this.el, options), env))
    result && this.reveal(result)
  },

  attempt(work) {
    try {
      return work()
    } catch (error) {
      console.error(`LineaUI.Chart #${this.el.id}`, error)
      return null
    }
  },

  reveal(result) {
    this.result = result
    this.canvas.innerHTML = stageHtml(result, {entering: this.entering && result.config.chart.animations?.enabled !== false})
    this.entering = false
    this.stage = this.canvas.firstElementChild
    this.el.style.minHeight = `${result.height + (result.config.chart.parentHeightOffset ?? 0)}px`
  },

  point(event) {
    const svg = this.stage?.querySelector("svg")
    const outside = event.target.closest?.(".linea-chart-legend")
    svg && !outside && this.show(svg.getBoundingClientRect(), event)
  },

  show(box, event) {
    const hit = this.result.probe(event.clientX - box.left, event.clientY - box.top)
    hit ? this.hit(hit) : this.clear()
  },

  hit(hit) {
    const tip = this.stage.querySelector(".linea-chart-tooltip")
    this.stage.querySelector(".linea-chart-hover").innerHTML = overlaySvg(hit)
    this.stage.querySelector(".linea-chart-axistips").innerHTML = axisTipsHtml(hit)
    this.activate(hit.active)
    this.center(hit.center)
    this.result.config.tooltip.enabled === false ? (tip.hidden = true) : this.place(tip, hit)
  },

  place(tip, hit) {
    tip.innerHTML = tooltipHtml(hit)
    tip.style.background = hit.fill ?? ""
    tip.dataset.theme = hit.theme ?? "light"
    tip.hidden = false
    const room = this.stage.getBoundingClientRect()
    const flip = hit.anchor.x + 14 + tip.offsetWidth > room.width
    const left = flip ? hit.anchor.x - 14 - tip.offsetWidth : hit.anchor.x + 14
    const top = Math.min(Math.max(hit.anchor.y - tip.offsetHeight / 2, 0), Math.max(room.height - tip.offsetHeight, 0))
    tip.style.transform = `translate(${Math.max(left, 0)}px, ${top}px)`
  },

  activate(active) {
    this.stage.querySelectorAll(".is-active").forEach((node) => node.classList.remove("is-active"))
    const selector =
      active?.slice !== undefined
        ? `.linea-chart-slice[data-series="${active.slice}"]`
        : active
          ? `.linea-chart-bar[data-series="${active.series}"][data-i="${active.slot}"]`
          : null
    selector && this.stage.querySelector(selector)?.classList.add("is-active")
  },

  center(text) {
    const shown = text ?? this.result.text
    const group = this.stage.querySelector(".linea-chart-center")
    const name = this.stage.querySelector("[data-center=name]")
    const value = this.stage.querySelector("[data-center=value]")
    name && (name.textContent = shown?.name ?? "")
    value && (value.textContent = shown?.value ?? "")
    group?.setAttribute("opacity", text ? 1 : (this.result.text?.opacity ?? 1))
  },

  clear() {
    const tip = this.stage?.querySelector(".linea-chart-tooltip")
    tip && (tip.hidden = true)
    this.stage && (this.stage.querySelector(".linea-chart-hover").innerHTML = "")
    this.stage && (this.stage.querySelector(".linea-chart-axistips").innerHTML = "")
    this.stage && this.activate(null)
    this.stage && this.center(null)
  },

  legendClick(event) {
    const item = event.target.closest?.(".linea-chart-legend-item")
    item && this.result.config.legend.onItemClick?.toggleDataSeries !== false && this.toggle(Number(item.dataset.series))
  },

  toggle(index) {
    this.hidden.has(index) ? this.hidden.delete(index) : this.hidden.add(index)
    this.draw()
  },
}

export default {"LineaUI.Chart": Chart}
