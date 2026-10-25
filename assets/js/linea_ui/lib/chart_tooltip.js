/**
 * The markup a hover produces: the tooltip card, and the crosshair, band and markers drawn over the plot.
 */
import {escape, h, render} from "./chart_svg.js"

const row = (item) =>
  `<div class="linea-chart-tooltip-row">${item.color ? `<span class="linea-chart-tooltip-marker" style="background:${escape(item.color)}"></span>` : ""}<span class="linea-chart-tooltip-text">${item.name ? `<span class="linea-chart-tooltip-name">${escape(item.name)}:</span> ` : ""}<b>${escape(item.value)}</b></span></div>`

/** The inside of the tooltip card for a hover result. */
export const tooltipHtml = (hit) => `${hit.title ? `<div class="linea-chart-tooltip-title">${escape(hit.title)}</div>` : ""}<div class="linea-chart-tooltip-body">${hit.rows.map(row).join("")}</div>`

/** The SVG for what is drawn over the plot while the pointer is on it. */
export const overlaySvg = (hit) =>
  render(
    h(
      "g",
      {},
      hit.band ? h("rect", {class: "linea-chart-band", x: hit.band.x, y: hit.band.y, width: hit.band.w, height: hit.band.h}) : null,
      hit.crosshair ? h("line", {class: "linea-chart-crosshair", ...hit.crosshair}) : null,
      hit.markers.map((marker) => h("circle", {class: "linea-chart-marker linea-chart-marker--hover", cx: marker.x, cy: marker.y, r: marker.r, fill: marker.color}))
    )
  ).replace(/^<g>|<\/g>$/g, "")

/** The bubbles on the axes where the crosshair meets them, as HTML placed by `left`/`top` in pixels. */
export const axisTipsHtml = (hit) =>
  [hit.axisTip ? {...hit.axisTip, cls: "x"} : null, hit.yTip ? {...hit.yTip, cls: "y"} : null]
    .filter(Boolean)
    .map((tip) => `<div class="linea-chart-axistip linea-chart-axistip--${tip.cls}" style="left:${Math.round(tip.x * 10) / 10}px;top:${Math.round(tip.y * 10) / 10}px">${escape(tip.text)}</div>`)
    .join("")
