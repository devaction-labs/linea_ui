/**
 * The plan of a cartesian chart: the axes, the plot rectangle and the functions that turn values and
 * categories into pixels. Drawing and the pointer both read it.
 */
import {categoryAxis, horizontalOf, stacksOf, valueAxis} from "./chart_axes.js"
import {frame, labelled} from "./chart_frame.js"
import {linear, timeTicks} from "./chart_scale.js"

const call = (formatter, ...args) => (typeof formatter === "function" ? formatter(...args) : undefined)

export const fontOf = (axis) => parseFloat(axis.labels?.style?.fontSize ?? 12)

const categoryTexts = (config, data) =>
  Array.from({length: data.count}, (_, slot) => String(call(config.xaxis.labels?.formatter, data.labels[slot] ?? "", undefined, {}) ?? data.labels[slot] ?? ""))

const retimed = (axis, length) =>
  timeTicks(axis.min, axis.max, Math.max(2, Math.floor(length / 55))).map((instant) => ({value: instant, label: axis.text(instant)}))

/**
 * `{config, data, width, height, plot, sideEdge, horizontal, visible, stacks, value, cat, along, across, at, ...}`.
 * `along(v)` maps a value to its pixel along the value axis, `across(slot)` a slot to the pixel of its
 * center, `at(point)` a point to it (dates and numbers are placed by their x, not their slot).
 */
export const plan = (config, data, {width, height, measure, legend}) => {
  const horizontal = horizontalOf(config)
  const visible = data.series.filter((series) => !series.hidden)
  const stacks = stacksOf(config, visible, data.count)
  const first = valueAxis(config, visible, stacks, {horizontal, size: horizontal ? width : height})
  const texts = categoryTexts(config, data)
  const sideTexts = horizontal ? texts : first.ticks.map((tick) => tick.label)
  const sideWidth = Math.max(0, ...sideTexts.map((text) => measure(text, fontOf(config.yaxis))))
  const topLabels = !horizontal && labelled(config.xaxis) && config.xaxis.position === "top"
  const bottomLabels = horizontal ? labelled(config.xaxis) : labelled(config.xaxis) && !topLabels
  const reach = !horizontal && data.kind === "category" && labelled(config.xaxis) ? measure(texts.at(-1) ?? "", fontOf(config.xaxis)) / 2 + 1 : 0
  const {plot, sideEdge} = frame(config, {width, height, legend, horizontal, sideWidth, lastLabel: reach, bottomLabels, topLabels})
  const value = first.time ? {...first, ticks: retimed(first, plot.w)} : first
  const cat = categoryAxis(config, data, horizontal ? plot.h : plot.w, {measure, horizontal, room: {left: plot.x, right: width - plot.x - plot.w}})
  const along = horizontal ? linear(value.min, value.max, plot.x, plot.x + plot.w) : linear(value.min, value.max, plot.y + plot.h, plot.y)
  const origin = horizontal ? plot.y : plot.x
  return {
    config,
    data,
    width,
    height,
    plot,
    sideEdge,
    horizontal,
    visible,
    stacks,
    value,
    cat,
    along,
    across: (slot) => origin + cat.center(slot),
    at: (point) => origin + cat.center(cat.timed ? point.x : point.slot),
    measure,
    legend,
    topLabels,
    bottomLabels,
  }
}
