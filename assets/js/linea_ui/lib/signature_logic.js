/**
 * What the signature pad decides without a DOM: where a pointer draws, the SVG a signature exports (drawn strokes
 * as one path, or a typed name as text), and whether there is ink to export. Strokes are lists of `[x, y]` points
 * in the pad's own pixels.
 */

const round = (number) => Math.round(number * 10) / 10

const FONT = "'Brush Script MT','Segoe Script','Snell Roundhand',cursive"

/** The point of a pointer inside the pad whose box is `rect`. */
export const pointIn = ({left, top}, x, y) => [round(x - left), round(y - top)]

const strokePath = (stroke) =>
  stroke.length === 1
    ? `M${stroke[0][0]} ${stroke[0][1]}L${stroke[0][0]} ${stroke[0][1]}`
    : stroke.map(([x, y], index) => `${index === 0 ? "M" : "L"}${x} ${y}`).join("")

/** The `d` of the path that draws every stroke; a single point is drawn as a dot. */
export const pathOf = (strokes) => strokes.filter((stroke) => stroke.length > 0).map(strokePath).join(" ")

/** `text` made safe to write inside an XML element. */
export const escapeXml = (text) =>
  text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;")

/** Whether the signature has anything: strokes in draw mode, a name in type mode. */
export const hasInk = ({mode, strokes, text}) => (mode === "type" ? text.trim().length > 0 : pathOf(strokes) !== "")

const svgBody = {
  draw: ({strokes, ink}) =>
    `<path d="${pathOf(strokes)}" fill="none" stroke="${ink}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>`,
  type: ({text, size, ink}) =>
    `<text x="44" y="${size.height - 52}" font-family="${FONT}" font-style="italic" font-size="34" fill="${ink}">${escapeXml(text.trim())}</text>`,
}

/** The SVG of the signature, or `""` when there is nothing to export. */
export const svgOf = (signature) =>
  hasInk(signature)
    ? `<svg xmlns="http://www.w3.org/2000/svg" width="${signature.size.width}" height="${signature.size.height}" viewBox="0 0 ${signature.size.width} ${signature.size.height}">${svgBody[signature.mode](signature)}</svg>`
    : ""

/** A data URI an `<img>` can show for the SVG text. */
export const svgUri = (svg) => `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`

/**
 * What the server sent against what the pad holds: the server's SVG when it changed and is not the one the pad
 * made itself, `null` when the pad keeps what it has.
 */
export const incomingValue = ({server, previous, current}) => (server !== previous && server !== current ? server : null)

/** The modes the pad offers, from `"draw,type"`; an unknown name is dropped and an empty list means both. */
export const modesOf = (text) => {
  const known = (text ?? "").split(",").filter((mode) => ["draw", "type"].includes(mode))
  return known.length === 0 ? ["draw", "type"] : known
}
