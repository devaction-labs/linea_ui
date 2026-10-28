/**
 * Pointing at (or tabbing to) a legend entry puts its series forward: the others dim and a slice or ring grows.
 * The legend entry is found by `data-series`, the drawn marks by the same attribute.
 */

/** The marks that carry a series: a cartesian or radar series group, a donut or pie slice, a gauge ring. */
export const MARKS = ".linea-chart-series, .linea-chart-slice, .linea-chart-ring"

const GROWTH = 1.12

/** The class a mark of series `index` takes while `focus` is the series in front: `is-focus`, `is-dim`, or `null` when none is. */
export const focusClass = (index, focus) => (focus === null || focus === undefined ? null : Number(index) === Number(focus) ? "is-focus" : "is-dim")

/** The stroke width a focused slice or ring is drawn with: a little thicker than its own. */
export const grown = (width) => (Number.isFinite(Number(width)) && Number(width) > 0 ? Number(width) * GROWTH : null)

/** The series of the legend entry an event came from, or `null` when it came from elsewhere or the entry is hidden. */
export const legendFocus = (item) => (item && item.getAttribute("aria-pressed") !== "false" ? Number(item.dataset.series) : null)
