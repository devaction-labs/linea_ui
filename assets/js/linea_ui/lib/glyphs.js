/**
 * The glyphs the hooks draw in the browser, in both icon sets. The server puts `data-icons="lineone"` or
 * `data-icons="hugeicons"` on the element of the hook (`LineaUI.Components.Icon.icon_set/0`).
 *
 * This table is a subset of `@lineone` and `@hugeicons` of `lib/linea_ui/components/icon.ex`; a test
 * (`test/linea_ui/glyphs_js_test.exs`) fails when an entry differs. The Hugeicons class names are written in
 * full so Tailwind finds them when it scans this folder (`@source "../js"` in `linea_ui.css`).
 *
 * The table is plain JSON on purpose: the test reads it without running JavaScript.
 */
export const GLYPHS = {
  "close": {
    "lineone": {"view": "0 0 24 24", "paint": "stroke", "body": "<path stroke-linecap=\"round\" stroke-linejoin=\"round\" d=\"M6 18L18 6M6 6l12 12\" />"},
    "hugeicons": "huge-cancel-01"
  },
  "angle_left": {
    "lineone": {"view": "0 0 17 17", "paint": "bare", "body": "<path d=\"M5.207 8.471l7.146 7.147-0.707 0.707-7.853-7.854 7.854-7.853 0.707 0.707-7.147 7.146z\" />"},
    "hugeicons": "huge-arrow-left-01"
  },
  "angle_right": {
    "lineone": {"view": "0 0 17 17", "paint": "bare", "body": "<path d=\"M13.207 8.472l-7.854 7.854-0.707-0.707 7.146-7.146-7.146-7.148 0.707-0.707 7.854 7.854z\" />"},
    "hugeicons": "huge-arrow-right-01"
  }
}

const PAINT = {
  stroke: (width) => ` fill="none" stroke="currentColor" stroke-width="${width}"`,
  fill: () => ` fill="currentColor"`,
  bare: () => "",
}

/** The icon set a hook element asks for: its `data-icons`, `"lineone"` when absent or unknown. */
export const iconSet = (element) => (element?.dataset?.icons === "hugeicons" ? "hugeicons" : "lineone")

/** The Hugeicons class of a glyph, or `null` when the glyph does not exist. */
export const hugeClass = (name) => (Object.hasOwn(GLYPHS, name) ? GLYPHS[name].hugeicons : null)

/**
 * The markup of a glyph: LineOne's `<svg>` for `"lineone"`, a `<span>` with the Hugeicons class for
 * `"hugeicons"`. `className` goes on that element, `strokeWidth` on LineOne's stroked glyphs. A name that is
 * not in the table gives an empty string.
 */
export const glyphHtml = (name, set = "lineone", {className = "", strokeWidth = "2"} = {}) => {
  const glyph = Object.hasOwn(GLYPHS, name) ? GLYPHS[name] : null
  const classAttr = (extra) => ` class="${[extra, className].filter(Boolean).join(" ")}"`
  const draw = {
    hugeicons: () => `<span${classAttr(glyph.hugeicons)} aria-hidden="true"></span>`,
    lineone: () => {
      const {view, paint, body} = glyph.lineone
      return `<svg${className ? classAttr("") : ""} viewBox="${view}"${PAINT[paint](strokeWidth)} aria-hidden="true">${body}</svg>`
    },
  }
  return glyph ? (draw[set] ?? draw.lineone)() : ""
}

/** The glyph as a DOM element, for hooks that append nodes instead of writing HTML. */
export const glyphElement = (name, set, options, document = globalThis.document) => {
  const template = document.createElement("template")
  template.innerHTML = glyphHtml(name, set, options)
  return template.content.firstElementChild
}
