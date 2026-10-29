/**
 * The legend of a chart: which entries it lists, how much room it takes and its markup.
 */
import {colorAt} from "./chart_config.js"
import {plain} from "./chart_scale.js"
import {escape} from "./chart_svg.js"

const MARKER_GAP = 10
const ROW = 24
const BASE_MARGIN = {horizontal: 5, vertical: 2}

const circular = (type) => ["pie", "donut", "polarArea", "radialBar"].includes(type)

const call = (formatter, ...args) => (typeof formatter === "function" ? formatter(...args) : undefined)

const radialType = (type) => type === "radialBar"

/** Whether the legend can list values and shares: a pie, donut or gauge, or a stacked chart (the parts of a whole). */
const composed = (config) => circular(config.type) || (config.chart.stacked === true && ["bar", "area"].includes(config.type))

/**
 * The text each entry of a composition legend carries beside its name, `"524 · 42%"`, from `legend.showValue`
 * and `legend.showPercent`. `entries` are `{value, hidden}`; the share is of the entries still shown, and a
 * hidden entry keeps its value only. `legend.value.formatter` and `legend.percent.formatter` shape the two
 * (the second takes 0-100); a chart that is not a composition, and a gauge's percent, answer `""`.
 */
export const legendParts = (config, entries) => {
  const legend = config.legend
  const showValue = legend.showValue === true && composed(config)
  const showPercent = legend.showPercent === true && composed(config) && !radialType(config.type)
  const whole = entries.reduce((sum, entry) => sum + (entry.hidden ? 0 : Math.max(entry.value, 0)), 0)
  return entries.map((entry, index) => {
    const value = showValue ? String(call(legend.value?.formatter, entry.value, {seriesIndex: index, w: {config}}) ?? (radialType(config.type) ? `${entry.value}%` : plain(entry.value))) : ""
    const share = (Math.max(entry.value, 0) / whole) * 100
    const percent = showPercent && !entry.hidden && whole > 0 ? String(call(legend.percent?.formatter, share, {seriesIndex: index, w: {config}}) ?? `${Math.round(share)}%`) : ""
    return [value, percent]
  })
}

export const legendFigures = (config, entries) => legendParts(config, entries).map((parts) => parts.filter(Boolean).join(" · "))

const totalOf = (series) => series.points.reduce((sum, point) => sum + (Number.isFinite(point.value) ? point.value : 0), 0)

/** The entries of the legend: `{index, name, color, hidden, figures}`; the series, or the slices of a pie, donut or gauge. */
export const legendItems = (config, data, hidden = []) => {
  const items = circular(config.type)
    ? (Array.isArray(config.series) ? config.series : []).map((raw, index) => ({
        index,
        name: String(config.labels?.[index] ?? `Series ${index + 1}`),
        color: colorAt(config, index),
        hidden: hidden.includes(index),
        value: Number.isFinite(Number(raw)) ? Number(raw) : 0,
      }))
    : data.series.map((series) => ({index: series.index, name: String(series.name), color: series.color, hidden: series.hidden, value: totalOf(series)}))
  const parts = legendParts(config, items)
  return items.map(({value: _value, ...item}, position) => ({...item, figures: parts[position].filter(Boolean).join(" · "), parts: parts[position]}))
}

const wanted = (config, items) => config.legend.show !== false && (items.length > 1 || config.legend.showForSingleSeries === true)

const empty = (position) => ({position, items: [], rows: 0, width: 0, height: 0, shape: "circle", align: "center", layout: "inline", marker: 12, gap: BASE_MARGIN, font: 12})

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
  const sizes = items.map((item) => marker + MARKER_GAP + measure(item.figures ? `${item.name}  ${item.figures}` : item.name, font) + 2 * gap.horizontal + 4)
  const beside = position === "left" || position === "right"
  const table = config.legend.layout === "table"
  const rows = beside || table ? items.length : Math.max(1, Math.ceil(sizes.reduce((sum, size) => sum + size, 0) / Math.max(width - 20, 1)))
  const row = ROW + (gap.vertical - BASE_MARGIN.vertical) * 2
  return wanted(config, items)
    ? {position, items, rows, width: beside ? Math.max(0, ...sizes) + 10 : 0, height: beside ? 0 : rows * row - (rows === 1 ? 1.6 : 0), shape: config.legend.markers?.shape ?? "circle", align: config.legend.horizontalAlign, layout: table ? "table" : "inline", marker, gap, font}
    : empty(position)
}

const ALIGN = {left: "flex-start", center: "center", right: "flex-end"}

/** The markup of the legend: one button per entry that toggles its series. */
export const legendHtml = (box) =>
  box.items.length === 0
    ? ""
    : box.items
        .map((item) =>
          box.layout === "table"
            ? `<button type="button" class="linea-chart-legend-item" data-series="${item.index}" aria-pressed="${item.hidden ? "false" : "true"}"><span class="linea-chart-legend-marker" data-shape="${box.shape}" style="background:${escape(item.color)};width:${box.marker}px;height:${box.marker}px"></span><span class="linea-chart-legend-text">${escape(item.name)}</span><span class="linea-chart-legend-value">${escape(item.parts[0] ?? "")}</span><span class="linea-chart-legend-percent">${escape(item.parts[1] ?? "")}</span></button>`
            : `<button type="button" class="linea-chart-legend-item" data-series="${item.index}" aria-pressed="${item.hidden ? "false" : "true"}" style="padding:${box.gap.vertical}px ${box.gap.horizontal}px"><span class="linea-chart-legend-marker" data-shape="${box.shape}" style="background:${escape(item.color)};width:${box.marker}px;height:${box.marker}px"></span><span class="linea-chart-legend-text">${escape(item.name)}</span>${item.figures ? `<span class="linea-chart-legend-figures">${escape(item.figures)}</span>` : ""}</button>`
        )
        .join("")

export const legendStyle = (box) => `justify-content:${ALIGN[box.align] ?? "center"};font-size:${box.font}px`
