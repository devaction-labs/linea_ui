const TOKEN = /\{\{[^{}\n]*\}\}/g

/**
 * Splits a text into plain and `{{token}}` pieces, in order, so the two can be drawn differently.
 * The same rule as the server's `LineaUI.Components.Textarea` mirror: `{{`, anything but braces and
 * line breaks, `}}`.
 *
 * @param {string} text
 * @returns {Array<{kind: "text" | "token", text: string}>}
 */
export const splitTokens = (text) => {
  const value = String(text ?? "")
  const pieces = []
  let last = 0

  for (const match of value.matchAll(TOKEN)) {
    match.index > last && pieces.push({kind: "text", text: value.slice(last, match.index)})
    pieces.push({kind: "token", text: match[0]})
    last = match.index + match[0].length
  }

  last < value.length && pieces.push({kind: "text", text: value.slice(last)})
  return pieces
}

/**
 * The letter spacing, in px, that makes a token drawn in another face as wide as the textarea's own
 * text for the same characters (so the caret stays under what is drawn).
 *
 * @param {number} ownWidth width of the token as drawn, with no spacing
 * @param {number} refWidth width the textarea gives the same characters
 * @param {number} chars number of characters in the token
 * @returns {number}
 */
export const tokenSpacing = (ownWidth, refWidth, chars) =>
  chars > 0 && Number.isFinite(ownWidth) && Number.isFinite(refWidth) ? (refWidth - ownWidth) / chars : 0
