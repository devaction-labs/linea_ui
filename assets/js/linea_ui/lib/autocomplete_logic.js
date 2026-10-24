/**
 * What `<.autocomplete>` decides without a DOM: what a choice, a keystroke or leaving the input does to the value and
 * the text, when to ask the server, and the "no results" message with the query in it.
 */

/** A message with its `%{query}` filled in by what was typed (trimmed). */
export const fillQuery = (template, query) => (template ?? "").replaceAll("%{query}", (query ?? "").trim())

/** Whether a query is long enough to search for. */
export const searchable = (query, threshold) => query.trim().length >= (threshold || 0)

/**
 * The field after choosing an option: the value is the option's, the text its label; in free-text mode the text is
 * the value, because the text is what is submitted.
 */
export const picked = ({value, label}, freeText) => ({value, text: freeText ? value : label})

/** The field after a keystroke: in free-text mode the text is the value, otherwise the value waits for a choice. */
export const typed = (text, {value, freeText}) => ({value: freeText ? text : value, text})

/**
 * The field after the input is left: free text stays as typed; otherwise an emptied input clears the value, and any
 * other text gives way to the chosen option's label.
 */
export const left = (text, {value, label, freeText}) =>
  freeText ? {value: text, text} : text.trim() === "" ? {value: "", text: ""} : {value, text: value === "" ? "" : label}

/** Whether the list should open: on focus only when asked to, and never for a query under the threshold. */
export const opens = ({query, threshold, onFocus, focusing}) =>
  focusing ? onFocus && searchable(query, threshold) : searchable(query, threshold)
