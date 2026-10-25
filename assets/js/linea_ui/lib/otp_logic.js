const PATTERNS = {numeric: /\d/, alphanumeric: /[A-Za-z0-9]/}

const pattern = (mode) => PATTERNS[mode] ?? PATTERNS.numeric

/**
 * Keeps the characters a code of this mode allows.
 *
 * @param {string} text
 * @param {"numeric" | "alphanumeric"} mode
 * @returns {string}
 */
export const sanitize = (text, mode) => [...String(text ?? "")].filter((char) => pattern(mode).test(char)).join("")

/**
 * The boxes of a value: one character each, cut to `length` and padded with empty boxes.
 *
 * @param {string} value
 * @param {number} length
 * @param {"numeric" | "alphanumeric"} mode
 * @returns {string[]}
 */
export const cellsOf = (value, length, mode) => {
  const chars = [...sanitize(value, mode)]
  return Array.from({length}, (_unused, index) => chars[index] ?? "")
}

/** The code the boxes hold, empty boxes left out. */
export const joined = (cells) => cells.join("")

/** Whether every box holds a character. */
export const complete = (cells) => cells.length > 0 && cells.every((cell) => cell !== "")

/**
 * Writes `text` from box `start` on: what is typed, pasted or autofilled. Boxes after the text are kept; when
 * nothing usable was written the box at `start` is emptied. `focus` is the box to move to.
 *
 * @param {string[]} cells
 * @param {number} start
 * @param {string} text
 * @param {"numeric" | "alphanumeric"} mode
 * @returns {{cells: string[], focus: number}}
 */
export const spread = (cells, start, text, mode) => {
  const chars = [...sanitize(text, mode)]
  const next = cells.map((cell, index) => {
    const offset = index - start
    return offset < 0 ? cell : (chars[offset] ?? (offset === 0 ? "" : cell))
  })
  const focus = chars.length === 0 ? start : Math.min(start + chars.length, cells.length - 1)
  return {cells: next, focus}
}

/**
 * Backspace on an empty box empties the one before it and moves there; on a box with a character the
 * browser's own deletion runs.
 *
 * @param {string[]} cells
 * @param {number} at
 * @returns {{cells: string[], focus: number} | null}
 */
export const erase = (cells, at) =>
  at > 0 && cells[at] === "" ? {cells: cells.map((cell, index) => (index === at - 1 ? "" : cell)), focus: at - 1} : null

/**
 * The box a navigation key moves to, or `null` for a key that does not move.
 *
 * @param {string} key
 * @param {number} at
 * @param {number} length
 * @returns {number | null}
 */
export const target = (key, at, length) => {
  const moves = {ArrowLeft: at - 1, ArrowRight: at + 1, Home: 0, End: length - 1}
  const to = moves[key]
  return to === undefined || to < 0 || to >= length ? null : to
}

/** The first empty box, or the last when all are filled: where the focus goes when the field is autofocused. */
export const firstOpen = (cells) => {
  const open = cells.findIndex((cell) => cell === "")
  return open < 0 ? cells.length - 1 : open
}

/**
 * Where a text written into box `at` starts: a text as long as the whole code (a paste or an autofill) always
 * starts at the first box, whichever one received it.
 *
 * @param {number} at
 * @param {string} text
 * @param {number} length
 * @param {"numeric" | "alphanumeric"} mode
 * @returns {number}
 */
export const startOf = (at, text, length, mode) => (sanitize(text, mode).length >= length ? 0 : Math.max(at, 0))

/**
 * Decides what to do with the value a server render carries. The browser sent values the server may still be
 * echoing back, one render per keystroke; an echo of a value already sent is ignored so it cannot undo what was
 * typed since. A value that is neither the current one nor an echo is the server's own, and wins.
 *
 * @param {{incoming: string, current: string, sent: string[]}} state
 * @returns {{adopt: boolean, sent: string[]}}
 */
export const reconcile = ({incoming, current, sent}) => {
  const echoed = sent.lastIndexOf(incoming)
  return incoming === current
    ? {adopt: false, sent: []}
    : echoed >= 0
      ? {adopt: false, sent: sent.slice(echoed + 1)}
      : {adopt: true, sent: []}
}
