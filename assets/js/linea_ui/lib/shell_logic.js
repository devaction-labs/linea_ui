/**
 * The pure part of the application shell: LineOne's breakpoint names, whether the sidebar starts open, and where
 * a shell popper (profile, notifications, search, horizontal menus) or a main sidebar tooltip goes.
 */

/** LineOne's breakpoints (`services/breakpoint.js`), the same as Tailwind's. */
export const BREAKPOINTS = {sm: 640, md: 768, lg: 1024, xl: 1280, "2xl": 1536}

/** The name of the breakpoint a window `width` falls in: `xs sm md lg xl 2xl`. */
export const breakpointName = (width) =>
  Object.entries(BREAKPOINTS).reduce((name, [key, min]) => (width >= min ? key : name), "xs")

/** Whether the window is at LineOne's `xlAndUp`, the only size where the sidebar may stay open. */
export const xlAndUp = (width) => width >= BREAKPOINTS.xl

/** Whether the window is at `smAndUp`, where the header shows its own search bar. */
export const smAndUp = (width) => width >= BREAKPOINTS.sm

const STORED = {open: true, closed: false}

/**
 * Whether the sidebar starts open: always closed below `xl` (LineOne closes it there), otherwise what the person
 * chose last time, otherwise what the page rendered.
 *
 * @param {{width: number, stored: string | null, rendered: boolean}} state
 */
export const initialOpen = ({width, stored, rendered}) => xlAndUp(width) && (STORED[stored] ?? rendered)

/** The value kept in `localStorage` for an open or a closed sidebar. */
export const storedValue = (open) => (open ? "open" : "closed")

/** The keys LineOne's dark mode service keeps, and the one monochrome mode keeps the same way. */
export const DARK_KEY = "dark-mode"
export const DARK_VALUE = "dark"
export const MONOCHROME_KEY = "monochrome-mode"
export const MONOCHROME_VALUE = "monochrome"

/** The stored value for a mode that is on or off: LineOne stores `"dark"` or an empty string. */
export const modeValue = (on, value) => (on ? value : "")

/** Whether a stored mode is on. */
export const modeOn = (stored, value) => stored === value

const clampTo = (value, min, max) => Math.max(min, Math.min(value, Math.max(min, max)))

const CORNERS = {
  "bottom-start": (a, box, gap) => ({top: a.bottom + gap, left: a.left}),
  "bottom-end": (a, box, gap) => ({top: a.bottom + gap, left: a.right - box.width}),
  "bottom": (a, box, gap) => ({top: a.bottom + gap, left: a.left + (a.width - box.width) / 2}),
  "top-start": (a, box, gap) => ({top: a.top - gap - box.height, left: a.left}),
  "top-end": (a, box, gap) => ({top: a.top - gap - box.height, left: a.right - box.width}),
  "right-end": (a, box, gap) => ({top: a.bottom - box.height, left: a.right + gap}),
  "right-start": (a, box, gap) => ({top: a.top, left: a.right + gap}),
  "right": (a, box, gap) => ({top: a.top + (a.height - box.height) / 2, left: a.right + gap}),
}

/**
 * Where a box with `position: fixed` goes next to its anchor, the way Popper places LineOne's boxes: on the side and
 * alignment of `placement`, `gap` pixels away, kept inside the screen. `origin` is where the box lands at
 * `top: 0; left: 0`, which is not the corner of the screen when an ancestor has a transform; the answer is relative
 * to it.
 *
 * @param {{placement: string, gap: number, anchor: DOMRect, box: {width: number, height: number}, origin: {top: number, left: number}, screen: {width: number, height: number}}} spec
 * @returns {{top: number, left: number}}
 */
export const place = ({placement, gap, anchor, box, origin, screen}) => {
  const corner = (CORNERS[placement] ?? CORNERS["bottom-start"])(anchor, box, gap)
  return {
    top: clampTo(corner.top, 0, screen.height - box.height) - origin.top,
    left: clampTo(corner.left, 0, screen.width - box.width) - origin.left,
  }
}

/** The side of a placement, the value of `data-popper-placement` LineOne's CSS reads for its shift. */
export const side = (placement) => placement.split("-")[0]
