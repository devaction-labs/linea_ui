const WARN_AT = 0.9

const count = (value) => Number.isFinite(value) && value > 0 ? value : null

/**
 * What the counter of a textarea says and how loud it says it.
 *
 * With a `max` it reads "68 / 200"; warns from 90% of it and turns bad past it. With a `min` it reads
 * "2 / 20 mín." and is bad while the text is started but short of it (an empty field is not nagged). With
 * only a `min` and the minimum reached it is the bare count.
 *
 * @param {{length: number, min?: number | null, max?: number | null}} input
 * @returns {{text: string, tone: "ok" | "warn" | "bad"}}
 */
export const counterState = ({length, min, max}) => {
  const size = Math.max(0, Number(length) || 0)
  const low = count(min)
  const high = count(max)

  if (low !== null && size > 0 && size < low) return {text: `${size} / ${low} mín.`, tone: "bad"}
  if (high === null) return {text: String(size), tone: "ok"}
  if (size > high) return {text: `${size} / ${high}`, tone: "bad"}
  return {text: `${size} / ${high}`, tone: size >= high * WARN_AT ? "warn" : "ok"}
}

/**
 * The height an auto-growing textarea takes: its content, but no taller than `maxRows` lines.
 * `scrollHeight` already includes the padding; `border` is the vertical border to add back for border-box.
 *
 * @param {{scrollHeight: number, lineHeight: number, padding: number, border: number, rows?: number, maxRows?: number | null}} input
 * @returns {{height: number, scroll: boolean}}
 */
export const growHeight = ({scrollHeight, lineHeight, padding, border, rows, maxRows}) => {
  const content = scrollHeight + border
  const floor = count(rows) ? lineHeight * rows + padding + border : 0
  const ceiling = count(maxRows) ? lineHeight * maxRows + padding + border : Infinity
  const wanted = Math.max(content, floor)
  return {height: Math.min(wanted, ceiling), scroll: wanted > ceiling}
}
