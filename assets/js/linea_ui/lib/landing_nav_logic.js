export const DEFAULT_THRESHOLD = 8

/** The scroll distance (px) after which the bar is "stuck": `data-stuck-after` of the bar, else 8. */
export const thresholdOf = (value) => {
  const px = Number(value)
  return value !== "" && value != null && Number.isFinite(px) && px >= 0 ? px : DEFAULT_THRESHOLD
}

/** Whether the page has scrolled far enough for the bar to turn solid. */
export const isStuck = (scrollY, threshold = DEFAULT_THRESHOLD) => Number(scrollY) > threshold
