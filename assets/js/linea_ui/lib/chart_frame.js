/**
 * The frame of a cartesian chart: where the plot area goes inside the SVG, leaving room for the axis
 * labels, the legend and the grid padding, with the margins ApexCharts uses so options tuned for it
 * (negative paddings included) land in the same place.
 */

const TOP = 30
const BOTTOM = 15
const LABELS_HEIGHT = 24.3
const SIDE_GAP = 15
const TIP_EXTRA = 17.3
const HIDDEN_SIDE = 10
const HIDDEN_BARE = 0.5
const HIDDEN_TOP = 22
const BARE_ROWS = 15

export const shown = (axis) => axis.show !== false

export const labelled = (axis) => shown(axis) && axis.labels?.show !== false

const sideReserve = (config, {horizontal, sideWidth, bottomLabels, topLabels}) =>
  labelled(config.yaxis)
    ? sideWidth + SIDE_GAP
    : shown(config.yaxis)
      ? topLabels
        ? HIDDEN_TOP
        : bottomLabels
          ? HIDDEN_SIDE
          : sideWidth + HIDDEN_BARE
      : horizontal
        ? BARE_ROWS
        : 0

/**
 * `{plot, sideEdge}`: the plot rectangle `{x, y, w, h}` and the x where the right-aligned labels of the
 * left-hand axis end. `sideWidth` is the widest of those labels, `lastLabel` the width of the last
 * category label under a vertical chart, `bottomLabels` and `topLabels` tell where the other labels go.
 */
export const frame = (config, {width, height, legend, horizontal, sideWidth, lastLabel, bottomLabels, topLabels}) => {
  const pad = config.grid.padding
  const reserve = sideReserve(config, {horizontal, sideWidth, bottomLabels, topLabels})
  const tip = config.yaxis.tooltip?.enabled && !horizontal ? TIP_EXTRA : 0
  const x = reserve + tip + pad.left + (legend.position === "left" ? legend.width : 0)
  const y = TOP + pad.top + (legend.position === "top" ? legend.height : 0) + (topLabels ? LABELS_HEIGHT / 2 : 0)
  const right = pad.right + lastLabel + (legend.position === "right" ? legend.width : 0)
  const bottom = BOTTOM + pad.bottom + (bottomLabels ? LABELS_HEIGHT : 0) + (legend.position === "bottom" ? legend.height : 0)
  const spark = config.chart.sparkline.enabled
  const plot = spark ? {x: 0, y: 1, w: width, h: Math.max(height - 2, 1)} : {x, y, w: Math.max(width - x - right, 1), h: Math.max(height - y - bottom, 1)}
  const sideEdge = horizontal ? reserve - 3 : reserve + 2.1
  return {plot, sideEdge}
}
