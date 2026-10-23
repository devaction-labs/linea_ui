/**
 * LineOne's notifications (Toastify) without a DOM: where a toast goes, how the toasts of a corner pile up,
 * which colors exist and how long each one stays.
 */

/** The colors LineOne's notification page shows. */
export const COLORS = ["neutral", "primary", "secondary", "info", "success", "warning", "error", "light", "dark"]

/** The corners and edges a toast can go to, as `<horizontal>-<vertical>`. */
export const POSITIONS = ["left-top", "left-bottom", "center-top", "center-bottom", "right-top", "right-bottom"]

/** The distance of the first toast from the edge, and between two toasts, as Toastify draws them. */
export const EDGE_PX = 15

/** How long the fade of a leaving toast lasts, and how long a toast stays by default. */
export const LEAVE_MS = 400
export const DURATION_MS = 5000

/** The color, `neutral` for one LineOne does not have. */
export const colorOf = (color) => (COLORS.includes(color) ? color : "neutral")

/**
 * The horizontal and vertical part of a position; anything unknown falls back to `fallback`, and then to
 * `right-bottom`, LineOne's default.
 *
 * @returns {{x: "left" | "center" | "right", y: "top" | "bottom", key: string}}
 */
export const positionOf = (position, fallback = "right-bottom") => {
  const key = [position, fallback].find((candidate) => POSITIONS.includes(candidate)) ?? "right-bottom"
  const [x, y] = key.split("-")
  return {x, y, key}
}

/** How long a toast stays: its own duration, or the toaster's; zero or less keeps it until it is closed. */
export const durationOf = (duration, fallback = DURATION_MS) => {
  const wanted = Number.isFinite(Number(duration)) && duration !== null && duration !== "" ? Number(duration) : fallback
  return wanted > 0 ? wanted : Infinity
}

/**
 * The distance of each toast from the edge, from their heights in the order they are stacked (the newest,
 * closest to the edge, first).
 *
 * @param {number[]} heights
 * @param {number} [gap]
 */
export const offsets = (heights, gap = EDGE_PX) =>
  heights.reduce(({at, list}, height) => ({at: at + height + gap, list: [...list, at]}), {at: gap, list: []}).list

/** Whether a toast has been seen already: the flash is read again on every patch of the toaster. */
export const unseen = (toasts, seen) => toasts.filter((toast) => !seen.has(String(toast.id)))
