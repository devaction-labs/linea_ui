export const DEFAULT_THRESHOLD = 8

/** The scroll distance (px) after which the bar is "stuck": `data-stuck-after` of the bar, else 8. */
export const thresholdOf = (value) => {
  const px = Number(value)
  return value !== "" && value != null && Number.isFinite(px) && px >= 0 ? px : DEFAULT_THRESHOLD
}

/** Whether the page has scrolled far enough for the bar to turn solid. */
export const isStuck = (scrollY, threshold = DEFAULT_THRESHOLD) => Number(scrollY) > threshold

/** How long (ms) the pointer may be away from the trigger and the open panel before the panel closes. */
export const CLOSE_DELAY = 220

/** How long (ms) the pointer rests on a trigger before its panel opens, when no panel is open yet. */
export const OPEN_DELAY = 80

/** Whether the bar opens its panels on hover: `data-open-on="hover"` and a mouse or pen (never a touch). */
export const opensOnHover = (openOn, pointerType) => openOn === "hover" && pointerType !== "touch"

/**
 * The index the focus moves to inside an open panel for `key`, or `null` when the key does not move it: the arrows
 * walk the items (and wrap), Home and End jump to the ends.
 */
export const stepIndex = (key, index, length) => {
  if (length <= 0) return null
  const at = index < 0 ? -1 : index

  switch (key) {
    case "ArrowDown":
    case "ArrowRight":
      return (at + 1) % length
    case "ArrowUp":
    case "ArrowLeft":
      return at <= 0 ? length - 1 : at - 1
    case "Home":
      return 0
    case "End":
      return length - 1
    default:
      return null
  }
}
