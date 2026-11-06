/**
 * The grid lines and the axes of a cartesian chart: border lines, ticks and labels.
 */
import {labelled, shown} from "./chart_frame.js"
import {fontOf} from "./chart_plan.js"
import {h} from "./chart_svg.js"

const TICK = 6
const LABEL_DROP = 20

const axisLine = (x1, y1, x2, y2) => h("line", {class: "linea-chart-axisline", x1, y1, x2, y2})

const label = (text, x, y, anchor, size, extra = {}) =>
  h("text", {class: "linea-chart-label", x, y, "text-anchor": anchor, "dominant-baseline": "central", "font-size": size, ...extra}, String(text))

const listed = (value, index) => (Array.isArray(value) ? value[index] : value)

/**
 * The color and weight of category label `slot`: `labels.style.colors` and `labels.style.fontWeight`, one
 * value or one per category, and the axis's `labels.style.fontFamily`. Written as an inline style, so they win over the theme's label color.
 */
const slotStyle = (axis, slot) => {
  const style = axis.labels?.style ?? {}
  const fill = listed(style.colors, slot)
  const weight = listed(style.fontWeight, slot)
  const family = style.fontFamily
  const css = [fill ? `fill:${fill}` : null, weight ? `font-weight:${weight}` : null, family ? `font-family:${family}` : null].filter(Boolean).join(";")
  return css ? {style: css} : {}
}

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
        labelled(config.yaxis) ? cat.labels.map((one) => label(one.text, p.sideEdge + (y.offsetX ?? 0), plot.y + one.pos + (y.offsetY ?? 0) - 2, "end", fontOf(config.yaxis), slotStyle(config.yaxis, one.slot))) : null,
        labelled(config.xaxis) ? value.ticks.map((tick) => label(tick.label, p.along(tick.value) + (x.offsetX ?? 0), bottom + LABEL_DROP + (x.offsetY ?? 0), "middle", fontOf(config.xaxis), slotStyle({labels: {style: {fontFamily: x.style?.fontFamily}}}, 0))) : null,
      ]
    : [
        labelled(config.xaxis) ? cat.labels.map((one) => label(one.text, plot.x + one.pos + (x.offsetX ?? 0), below + (x.offsetY ?? 0), "middle", fontOf(config.xaxis), slotStyle(config.xaxis, one.slot))) : null,
        labelled(config.yaxis) ? value.ticks.map((tick) => label(tick.label, p.sideEdge + (y.offsetX ?? 0), p.along(tick.value) + (y.offsetY ?? 0), "end", fontOf(config.yaxis), slotStyle({labels: {style: {fontFamily: y.style?.fontFamily}}}, 0))) : null,
      ]
}

const BADGE = {height: 20, padding: 8, radius: 7, fontSize: 11}

/**
 * `annotations.yaxis`: a line across the plot at a value (`y`), with `borderColor`, `borderWidth`,
 * `strokeDashArray` and `opacity`, and an optional `label` badge on it (`text`, `position` `left` or
 * `right` (default), `offsetX`, `offsetY`, `borderRadius`, `style` with `background`, `color`, `fontSize`
 * and `fontWeight`). On a row chart the value runs across, so the line runs up and down.
 */
export const annotationNodes = (p) => {
  const {config, plot, horizontal} = p
  const list = Array.isArray(config.annotations?.yaxis) ? config.annotations.yaxis : []
  return list
    .filter((one) => Number.isFinite(Number(one.y)))
    .map((one, index) => {
      const at = p.along(Number(one.y))
      const line = horizontal ? {x1: at, x2: at, y1: plot.y, y2: plot.y + plot.h} : {x1: plot.x, x2: plot.x + plot.w, y1: at, y2: at}
      const style = one.label?.style ?? {}
      const size = parseFloat(style.fontSize ?? BADGE.fontSize)
      const text = one.label?.text ? String(one.label.text) : null
      const width = text ? p.measure(text, size) + BADGE.padding * 2 : 0
      const left = one.label?.position === "left"
      const bx = (horizontal ? at - width / 2 : left ? plot.x : plot.x + plot.w - width) + Number(one.label?.offsetX ?? 0)
      const by = (horizontal ? plot.y : at - BADGE.height / 2) + Number(one.label?.offsetY ?? 0)
      return h(
        "g",
        {class: "linea-chart-annotation", "data-annotation": index},
        h("line", {...line, stroke: one.borderColor ?? "currentColor", "stroke-width": one.borderWidth ?? 1.5, "stroke-dasharray": one.strokeDashArray ? String(one.strokeDashArray) : null, opacity: one.opacity ?? null}),
        text
          ? [
              h("rect", {x: bx, y: by, width, height: BADGE.height, rx: one.label.borderRadius ?? BADGE.radius, fill: style.background ?? "#17171a"}),
              h("text", {x: bx + width / 2, y: by + BADGE.height / 2, "text-anchor": "middle", "dominant-baseline": "central", "font-size": size, "font-weight": style.fontWeight ?? 500, fill: style.color ?? "#fff"}, text),
            ]
          : null
      )
    })
}

/** The axis lines, ticks and labels. */
export const axisNodes = (p) => [borders(p), ticks(p), labels(p)]
