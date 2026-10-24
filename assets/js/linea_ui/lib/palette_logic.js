/**
 * What the command palette decides without a DOM: which items a scope and a query keep, whether the assistant row
 * or the empty message shows, where the active row goes and how an Enter is carried out.
 */
import {moveIndex} from "./select_box.js"
import {matches} from "./text.js"

/** The scope that keeps every item. */
export const ALL = "all"

/**
 * Whether an item is kept: its scope is the wanted one (or the wanted one is `ALL`), and, when the browser filters
 * (`local`), its text contains the query.
 *
 * @param {{scope: string, text: string}} item
 * @param {{scope: string, query: string, local: boolean}} filter
 */
export const keeps = ({scope, text}, filter) => (filter.scope === ALL || scope === filter.scope) && (!filter.local || matches(text, filter.query))

/** `keeps` for a list of items, as a list of booleans in the same order. */
export const visibility = (items, filter) => items.map((item) => keeps(item, filter))

/** Whether the assistant row shows: something was typed and either nothing matched or the assistant is always offered. */
export const assistantShown = ({mode, query, matched}) => query.trim() !== "" && (mode === "always" || matched === 0)

/** Whether the "nothing found" message shows: no item matched and there is no assistant row to offer instead. */
export const emptyShown = ({matched, assistant}) => matched === 0 && !assistant

/** The active row after a key among `count` rows; it stops at both ends. */
export const move = (active, key, count) => moveIndex(active, key, count)

/** The active row kept inside `count` rows: the first one when there are rows, none when there are not. */
export const settle = (active, count) => (count === 0 ? -1 : Math.min(Math.max(active, 0), count - 1))

/**
 * How an Enter opens the active row: Ctrl+Enter on a link opens its address in a new window, on any other item it
 * only reports `new_tab`, and a plain Enter presses the row.
 *
 * @param {{href?: string, newTab: boolean}} row
 * @returns {"window" | "report" | "press"}
 */
export const route = ({href, newTab}) => (newTab ? (href ? "window" : "report") : "press")

/** Whether a pressed key (`keyName`) is the palette's shortcut, ignoring case. */
export const isShortcut = (pressed, shortcut) => Boolean(shortcut) && pressed.toLowerCase() === shortcut.toLowerCase()
