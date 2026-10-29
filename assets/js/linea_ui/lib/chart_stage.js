/**
 * The markup the hook puts inside the chart element: the SVG, the legend, the places the tooltip and the
 * axis bubbles go, and the text alternative.
 */

/** The stage for a `build` result; `entering` plays the entry animation. */
export const stageHtml = (result, {entering}) => {
  const legend = result.legendHtml
    ? `<div class="linea-chart-legend" data-position="${result.legend.position}" data-layout="${result.legend.layout}" style="${result.legendStyle}">${result.legendHtml}</div>`
    : ""
  return `<div class="linea-chart-stage${entering ? " linea-chart--enter" : ""}" style="height:${result.height}px">${result.svg}${legend}<div class="linea-chart-axistips" aria-hidden="true"></div><div class="linea-chart-tooltip" aria-hidden="true" hidden></div>${result.table}</div>`
}
