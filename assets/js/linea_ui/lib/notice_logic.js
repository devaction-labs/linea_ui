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

/** The part of the front toast that stays visible of each toast behind it, in pixels. */
export const PEEK_PX = 12

/** How much smaller each toast behind the front one is drawn, and how many toasts a closed stack shows. */
export const SCALE_STEP = 0.05
export const VISIBLE = 3

/** The least a paused timer waits after the pointer leaves, so a toast does not vanish the moment it is released. */
export const RESUME_MIN_MS = 1000

/**
 * How the toasts of one corner are drawn, newest first. A closed stack shows the newest at full size
 * and the others behind it, each 12px further from the edge, a little smaller and as wide and tall as the
 * newest, so only a sliver shows; past `VISIBLE` they are hidden. An open stack (the pointer is over it)
 * lays them out one above the other with their own sizes.
 *
 * @param {{width: number, height: number}[]} sizes the natural size of each toast
 * @param {boolean} expanded
 * @returns {{offset: number, scale: number, width: number, height: number, hidden: boolean}[]}
 */
export const stack = (sizes, expanded) => {
  const opened = offsets(sizes.map((size) => size.height))
  return sizes.map((size, index) =>
    expanded
      ? {offset: opened[index], scale: 1, width: size.width, height: size.height, hidden: false}
      : {
          offset: EDGE_PX + index * PEEK_PX,
          scale: Math.max(1 - index * SCALE_STEP, 0.8),
          width: sizes[0].width,
          height: sizes[0].height,
          hidden: index >= VISIBLE,
        },
  )
}

/** How long a toast has left after it was shown for `shown` ms of its `left` ms. */
export const timeLeft = (left, shown) => Math.max(left - shown, 0)

/** How long a released toast waits before it leaves. */
export const resumeAfter = (left) => Math.max(left, RESUME_MIN_MS)

/** The kinds of toast: each draws an icon and a title, `loading` a spinner that stays until the toast changes. */
export const KINDS = ["neutral", "info", "success", "warning", "error", "loading"]

const KIND_COLORS = {info: "info", success: "success", warning: "warning", error: "error"}

/** The kind, or `null` for a plain toast (no kind, or one LineaUI does not know). */
export const kindOf = (kind) => (KINDS.includes(kind) ? kind : null)

/** The color a toast is drawn in: its own `color`, else its kind's, else `neutral`. */
export const colorFor = ({color, kind}) => colorOf(color ?? KIND_COLORS[kind] ?? "neutral")

/** Whether a toast takes the layout with icon, title, description and actions instead of LineOne's one line. */
export const isRich = ({kind, description, actions}) => Boolean(kindOf(kind) || description || actions?.length)

/**
 * How long a toast stays: a `loading` one until it changes, an error without a duration until it is closed when
 * the toaster persists errors, the others their own duration or the toaster's.
 */
export const durationFor = ({kind, duration}, fallback = DURATION_MS, persistErrors = false) =>
  kind === "loading" || (kind === "error" && persistErrors && (duration === null || duration === undefined))
    ? Infinity
    : durationOf(duration, fallback)

/** Whether a toast gets a close button: asked for, or a rich toast that stays (except while loading). */
export const closeFor = (input, duration) =>
  input.kind !== "loading" && Boolean(input.close || (isRich(input) && !Number.isFinite(duration)))

/** The toast with `changes` applied; what the changes do not say (null or undefined) stays as it was. */
export const mergeToast = (toast, changes) =>
  Object.entries(changes ?? {}).reduce(
    (merged, [key, value]) => (value === null || value === undefined ? merged : {...merged, [key]: value}),
    toast,
  )

/** What an action's event pushes: its `value` with the id of the toast. */
export const actionPayload = (action, id) => ({...(action.value ?? {}), toast_id: id})

/** An action's `%JS{}` as the string `liveSocket.execJS` takes, or `null` without one. */
export const encodedJS = (js) => (js === null || js === undefined ? null : typeof js === "string" ? js : JSON.stringify(js))
