/**
 * The grid lines and the axes of a cartesian chart: border lines, ticks and labels.
 */
import {labelled, shown} from "./chart_frame.js"
import {fontOf} from "./chart_plan.js"
import {h} from "./chart_svg.js"

const TICK = 6
const LABEL_DROP = 20

const axisLine = (x1, y1, x2, y2) => h("line", {class: "linea-chart-axisline", x1, y1, x2, y2})

const label = (text, x, y, anchor, size) =>
  h("text", {class: "linea-chart-label", x, y, "text-anchor": anchor, "dominant-baseline": "central", "font-size": size}, String(text))

/** The grid lines: `grid.yaxis.lines` run across the plot, `grid.xaxis.lines` up and down it. */
export const gridNodes = (p) => {
  const {config, plot, horizontal, value, cat} = p
  const dash = config.grid.strokeDashArray ? String(config.grid.strokeDashArray) : null
  const line = (x1, y1, x2, y2) => h("line", {class: "linea-chart-gridline", x1, y1, x2, y2, "stroke-dasharray": dash})
  const atValues = value.ticks.map((tick) => p.along(tick.value))
  const atEdges = cat.edges.map((edge) => (horizontal ? plot.y : plot.x) + edge)
  const [rows, columns] = horizontal ? [atEdges, atValues] : [atValues, atEdges]
  return config.grid.show === false
    ? []
    : [
        config.grid.yaxis?.lines?.show !== false ? rows.map((y) => line(plot.x, y, plot.x + plot.w, y)) : null,
        config.grid.xaxis?.lines?.show === true ? columns.map((x) => line(x, plot.y, x, plot.y + plot.h)) : null,
      ]
}

const borders = (p) => {
  const {config, plot, horizontal} = p
  const bottom = plot.y + plot.h
  const edge = p.topLabels ? plot.y : bottom
  return [
    horizontal && config.grid.show !== false ? h("line", {class: "linea-chart-gridline", x1: plot.x, y1: plot.y, x2: plot.x, y2: bottom}) : null,
    shown(config.xaxis) && config.xaxis.axisBorder?.show !== false ? axisLine(plot.x, edge, plot.x + plot.w, edge) : null,
    shown(config.yaxis) && config.yaxis.axisBorder?.show === true ? axisLine(plot.x, plot.y, plot.x, bottom) : null,
  ]
}

const ticks = (p) => {
  const {config, plot, horizontal, value, cat} = p
  const bottom = plot.y + plot.h
  const edge = p.topLabels ? plot.y : bottom
  const reach = p.topLabels ? -TICK : TICK
  const xTicks = shown(config.xaxis) && config.xaxis.axisTicks?.show !== false
  const yTicks = shown(config.yaxis) && config.yaxis.axisTicks?.show === true
  const catAt = (cat.kind === "bands" ? cat.edges : cat.labels.map((one) => one.pos)).map((pos) => (horizontal ? plot.y : plot.x) + pos)
  return horizontal
    ? [
        yTicks ? catAt.map((y) => axisLine(plot.x, y, plot.x - TICK, y)) : null,
        xTicks ? value.ticks.map((tick) => axisLine(p.along(tick.value), bottom, p.along(tick.value), bottom + TICK)) : null,
      ]
    : [
        xTicks ? catAt.map((x) => axisLine(x, edge, x, edge + reach)) : null,
        yTicks ? value.ticks.map((tick) => axisLine(plot.x, p.along(tick.value), plot.x - TICK, p.along(tick.value))) : null,
      ]
}

const labels = (p) => {
  const {config, plot, horizontal, value, cat} = p
  const bottom = plot.y + plot.h
  const x = config.xaxis.labels ?? {}
  const y = config.yaxis.labels ?? {}
  const below = p.topLabels ? plot.y - 12 : bottom + LABEL_DROP
  return horizontal
    ? [
        labelled(config.yaxis) ? cat.labels.map((one) => label(one.text, p.sideEdge + (y.offsetX ?? 0), plot.y + one.pos + (y.offsetY ?? 0) - 2, "end", fontOf(config.yaxis))) : null,
        labelled(config.xaxis) ? value.ticks.map((tick) => label(tick.label, p.along(tick.value) + (x.offsetX ?? 0), bottom + LABEL_DROP + (x.offsetY ?? 0), "middle", fontOf(config.xaxis))) : null,
      ]
    : [
        labelled(config.xaxis) ? cat.labels.map((one) => label(one.text, plot.x + one.pos + (x.offsetX ?? 0), below + (x.offsetY ?? 0), "middle", fontOf(config.xaxis))) : null,
        labelled(config.yaxis) ? value.ticks.map((tick) => label(tick.label, p.sideEdge + (y.offsetX ?? 0), p.along(tick.value) + (y.offsetY ?? 0), "end", fontOf(config.yaxis))) : null,
      ]
}

/** The axis lines, ticks and labels. */
export const axisNodes = (p) => [borders(p), ticks(p), labels(p)]
