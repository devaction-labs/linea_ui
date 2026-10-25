/**
 * Draws the charts that sit on axes: line, area, bar (columns and rows, grouped, stacked, distributed),
 * range bar and candlestick. `plan` (see `chart_plan.js`) measures and positions everything; `draw` turns a
 * plan into SVG nodes and the boxes the pointer can hit.
 */
import {shadowNode} from "./chart_defs.js"
import {axisNodes, gridNodes} from "./chart_grid.js"
import {barMark, candleMark, dataLabels, lineMark, rangeMark} from "./chart_marks.js"

export {plan} from "./chart_plan.js"

const mark = (p, series, position, uid, defs, boxes) =>
  p.config.type === "candlestick"
    ? candleMark(p, series, boxes)
    : p.config.type === "rangeBar"
      ? rangeMark(p, series, position, uid, defs, boxes)
      : p.config.type === "bar"
        ? barMark(p, series, position, uid, defs, boxes)
        : lineMark(p, series, p.stacks?.[position], uid, defs)

/** `{defs, boxes, layers: {grid, axes, series, labels}}` for a plan; `uid` prefixes the ids inside the SVG. */
export const draw = (p, uid) => {
  const defs = [shadowNode(p.config, uid)]
  const boxes = []
  const series = p.visible.map((one, position) => mark(p, one, position, uid, defs, boxes))
  return {defs, boxes, layers: {grid: gridNodes(p), axes: axisNodes(p), series, labels: dataLabels(p, boxes)}}
}
