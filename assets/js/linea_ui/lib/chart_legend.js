/**
 * The legend of a chart: which entries it lists, how much room it takes and its markup.
 */
import {colorAt} from "./chart_config.js"
import {escape} from "./chart_svg.js"

const MARKER_GAP = 10
const ROW = 24
const BASE_MARGIN = {horizontal: 5, vertical: 2}

const circular = (type) => ["pie", "donut", "polarArea", "radialBar"].includes(type)

/** The entries of the legend: `{index, name, color, hidden}`; the series, or the slices of a pie, donut or gauge. */
export const legendItems = (config, data, hidden = []) =>
  circular(config.type)
    ? (Array.isArray(config.series) ? config.series : []).map((_, index) => ({
        index,
        name: String(config.labels?.[index] ?? `Series ${index + 1}`),
        color: colorAt(config, index),
        hidden: hidden.includes(index),
      }))
    : data.series.map((series) => ({index: series.index, name: String(series.name), color: series.color, hidden: series.hidden}))

const wanted = (config, items) => config.legend.show !== false && (items.length > 1 || config.legend.showForSingleSeries === true)

const empty = (position) => ({position, items: [], rows: 0, width: 0, height: 0, shape: "circle", align: "center", marker: 12, gap: BASE_MARGIN, font: 12})

/**
 * The room the legend asks for in a chart `width` px wide: `{position, items, rows, width, height, ...}`;
 * `height` is the legend's own when it sits above or below, `width` when it sits beside the chart, and both
 * are 0 when it is not shown.
 */
export const legendBox = (config, data, {width, measure, hidden = []}) => {
  const items = legendItems(config, data, hidden)
  const position = config.legend.position
  const font = parseFloat(config.legend.fontSize ?? 12)
  const marker = Number(config.legend.markers?.size ?? 12)
  const gap = {...BASE_MARGIN, ...config.legend.itemMargin}
  const sizes = items.map((item) => marker + MARKER_GAP + measure(item.name, font) + 2 * gap.horizontal + 4)
  const beside = position === "left" || position === "right"
  const rows = beside ? items.length : Math.max(1, Math.ceil(sizes.reduce((sum, size) => sum + size, 0) / Math.max(width - 20, 1)))
  const row = ROW + (gap.vertical - BASE_MARGIN.vertical) * 2
  return wanted(config, items)
    ? {position, items, rows, width: beside ? Math.max(0, ...sizes) + 10 : 0, height: beside ? 0 : rows * row - (rows === 1 ? 1.6 : 0), shape: config.legend.markers?.shape ?? "circle", align: config.legend.horizontalAlign, marker, gap, font}
    : empty(position)
}

const ALIGN = {left: "flex-start", center: "center", right: "flex-end"}

/** The markup of the legend: one button per entry that toggles its series. */
export const legendHtml = (box) =>
  box.items.length === 0
    ? ""
    : box.items
        .map(
          (item) =>
            `<button type="button" class="linea-chart-legend-item" data-series="${item.index}" aria-pressed="${item.hidden ? "false" : "true"}" style="padding:${box.gap.vertical}px ${box.gap.horizontal}px"><span class="linea-chart-legend-marker" data-shape="${box.shape}" style="background:${escape(item.color)};width:${box.marker}px;height:${box.marker}px"></span><span class="linea-chart-legend-text">${escape(item.name)}</span></button>`
        )
        .join("")

export const legendStyle = (box) => `justify-content:${ALIGN[box.align] ?? "center"};font-size:${box.font}px`
