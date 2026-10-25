/**
 * The text alternative of a chart: a table of its data that screen readers can walk, hidden from sight.
 */
import {plain} from "./chart_scale.js"
import {escape} from "./chart_svg.js"

const cell = (tag, text) => `<${tag}>${escape(text)}</${tag}>`

const row = (cells) => `<tr>${cells.join("")}</tr>`

const value = (point) =>
  point === undefined
    ? ""
    : point.high !== undefined
      ? `${plain(point.open)} / ${plain(point.high)} / ${plain(point.low)} / ${plain(point.close)}`
      : point.start !== undefined
        ? `${plain(point.start)} - ${plain(point.end)}`
        : point.value === null
          ? ""
          : plain(point.value)

const byPoints = (title, data) =>
  [
    `<caption>${escape(title)}</caption>`,
    row([cell("th", ""), ...data.series.map((series) => cell("th", series.name))]),
    ...Array.from({length: data.count}, (_, slot) =>
      row([cell("th", data.labels[slot] ?? String(slot + 1)), ...data.series.map((series) => cell("td", value(series.points.find((point) => point.slot === slot))))])
    ),
  ].join("")

const bySlices = (title, slices) =>
  [`<caption>${escape(title)}</caption>`, ...slices.map((slice) => row([cell("th", slice.name), cell("td", plain(slice.value))]))].join("")

/** The `<table>` for the series (`data`) or slices (`slices`) of a chart. */
export const tableHtml = (title, {data, slices}) =>
  `<table class="linea-chart-sr">${slices ? bySlices(title, slices) : byPoints(title, data)}</table>`
