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

/** How long a finished progress toast stays before it leaves. */
export const PROGRESS_DONE_MS = 1600

/** The fill of a progress toast, 0 to 100, or `null` for a toast without `value` (an error never shows progress). */
export const progressOf = ({kind, value}) =>
  kind === "error" || value === null || value === undefined || value === "" || !Number.isFinite(Number(value))
    ? null
    : Math.min(Math.max(Number(value), 0), 100)

/** Whether a progress toast failed: it has a `value` and became an `error`. */
export const failedOf = ({kind, value}) =>
  kind === "error" && value !== null && value !== undefined && value !== "" && Number.isFinite(Number(value))

/** The kind a toast is drawn with: a progress toast spins while it runs and turns into a success at 100. */
export const progressKind = (input) => {
  const progress = progressOf(input)
  return progress === null ? input.kind : progress >= 100 ? "success" : (input.kind ?? "loading")
}

/** The color a toast is drawn in: its own `color`, else its kind's, else `neutral`; a progress toast is a neutral card, or a dark one. */
export const colorFor = (input) =>
  progressOf(input) === null ? colorOf(input.color ?? KIND_COLORS[input.kind] ?? "neutral") : input.color === "dark" ? "dark" : "neutral"

/** Whether a toast takes the layout with icon, title, description and actions instead of LineOne's one line. */
export const isRich = (input) =>
  Boolean(kindOf(input.kind) || input.description || input.actions?.length || input.aura || progressOf(input) !== null)

/** Whether a toast waits for the person: it has buttons, a template of its own, or an aura that asks for attention. */
export const needsAction = ({actions, template, aura}) => Boolean(actions?.length || template || aura === "glow")

const unset = (value) => value === null || value === undefined

/**
 * How long a toast stays: a `loading` one until it changes, a progress one until it reaches 100 and then
 * `PROGRESS_DONE_MS`, one that waits for the person (actions, a template, a `glow` aura) until it is closed, an error
 * without a duration until it is closed when the toaster persists errors, the others their own duration or the
 * toaster's. A `duration` given always wins over what the toast would do by itself.
 */
export const durationFor = (input, fallback = DURATION_MS, persistErrors = false) => {
  const {kind, duration} = input
  const progress = progressOf(input)
  const stays = kind === "loading" || (unset(duration) && (needsAction(input) || (kind === "error" && persistErrors)))
  return progress !== null ? (progress >= 100 ? durationOf(duration, PROGRESS_DONE_MS) : Infinity) : stays ? Infinity : durationOf(duration, fallback)
}

/** Whether a toast gets a close button: asked for, or one that stays (except while loading or progressing). */
export const closeFor = (input, duration) =>
  progressOf(input) !== null ? Boolean(input.close) : input.kind !== "loading" && Boolean(input.close || !Number.isFinite(duration))

/** Whether a toast draws its countdown line: it leaves by itself, is not a progress toast, and did not turn it off. */
export const timerFor = (input, duration, fallback = true) =>
  Number.isFinite(duration) && progressOf(input) === null && (unset(input.timer) ? fallback : Boolean(input.timer))

export const AURA_VARIANTS = ["default", "dual", "glow"]
export const AURA_SIZES = ["xs", "sm", "lg"]
export const AURA_COLORS = ["assistant", "primary", "secondary", "info", "success", "warning", "error"]

/**
 * The light that runs around a toast, or `null` for a toast without `aura`. Unknown values fall back to the
 * rotating `default`, the `sm` thickness and the assistant's color.
 *
 * @returns {{variant: string, size: string, color: string} | null}
 */
export const auraOf = ({aura, aura_size: size, aura_color: color}) =>
  aura
    ? {
        variant: AURA_VARIANTS.includes(aura) ? aura : "default",
        size: AURA_SIZES.includes(size) ? size : "sm",
        color: AURA_COLORS.includes(color) ? color : "assistant",
      }
    : null

/** The toast with `changes` applied; what the changes do not say (null or undefined) stays as it was. */
export const mergeToast = (toast, changes) =>
  Object.entries(changes ?? {}).reduce(
    (merged, [key, value]) => (value === null || value === undefined ? merged : {...merged, [key]: value}),
    toast,
  )

/** An update that changes the `kind` without a `color` takes the new kind's color. */
export const withKindColor = (changes) =>
  changes.kind && !changes.color ? {...changes, color: KIND_COLORS[changes.kind] ?? "neutral"} : changes

/** What an action's event pushes: its `value` with the id of the toast. */
export const actionPayload = (action, id) => ({...(action.value ?? {}), toast_id: id})

/** An action's `%JS{}` as the string `liveSocket.execJS` takes, or `null` without one. */
export const encodedJS = (js) => (js === null || js === undefined ? null : typeof js === "string" ? js : JSON.stringify(js))
