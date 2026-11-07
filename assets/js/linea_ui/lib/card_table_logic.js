/** What a click on a card-table row does with its details panel: where the panel goes and whether the click counts. */

/** Parts of a row that are controls: a click on them does their own thing, so it closes the panel instead of opening it. */
export const CONTROLS = "a, button, input, select, textarea, label, summary, [role=button], [data-dropdown], [phx-click], .linea-ctable-cpw, .linea-ctable-sel, .linea-ctable-act"

/** The pointer sits this far inside the panel's left edge, so the panel starts just left of the cursor. */
export const OFFSET = 16

/** The least room between the panel and either side of the row. */
export const PAD = 8

/**
 * Left edge (px, from the row's left) of a panel `popWidth` wide opened by a click at `clientX` on a row at
 * `rowLeft` that is `rowWidth` wide: the pointer minus OFFSET, kept PAD inside both sides of the row. A panel wider than
 * the row (less PAD on each side) sits at PAD.
 */
export const popLeft = ({clientX, rowLeft, rowWidth, popWidth}) => {
  const max = Math.max(PAD, rowWidth - popWidth - PAD)
  return Math.round(Math.min(Math.max(clientX - rowLeft - OFFSET, PAD), max))
}

/** Is `target` a control of `row` (or of something between the two)? The row itself is not one. */
export const onControl = (target, row) => {
  const hit = target?.closest?.(CONTROLS)
  return !!hit && hit !== row && row.contains(hit)
}

/** What a click does: "ignore" (inside the panel, or the row has none), "close" (a control, or the open row again), "open". */
export const clickAction = ({inPop, hasPop, control, isOpen}) => {
  if (inPop || !hasPop) return control && isOpen ? "close" : "ignore"
  if (control) return "close"
  return isOpen ? "close" : "open"
}

/** Does a click end a text selection made inside `row`? Then it was a drag to select text, not a click to toggle the panel. */
export const endsSelection = (selection, row) =>
  !!selection && !selection.isCollapsed && !!selection.anchorNode && row.contains(selection.anchorNode)
