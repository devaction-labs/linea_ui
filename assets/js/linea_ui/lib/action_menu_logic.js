/** What an open action menu marks as "the item these actions are for": the nearest `[data-am-row]`, table row or card-table row. */
export const ROW = "[data-am-row], tr, .linea-ctable-row"

export const rowOf = (el) => el?.closest?.(ROW) ?? null

/** Sets or clears `data-am-open` on the row of `el`; returns the row. */
export const markRow = (el, open) => {
  const row = rowOf(el)
  row && (open ? row.setAttribute("data-am-open", "") : row.removeAttribute("data-am-open"))
  return row
}
