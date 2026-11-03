const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

/**
 * Tailwind plugin for Keenicons (the icon set of Metronic): every `ki-<style>-<name>` class draws the icon with a
 * CSS mask in the current text color, with `<style>` one of `filled`, `outline` or `solid` (`ki-filled-eye`,
 * `ki-outline-home-2`). In the app's css, after the LineaUI import:
 *
 *   @plugin "../../deps/linea_ui/assets/css/keenicons.cjs" { dir: "assets/keenicons"; }
 *
 * `dir` holds one folder per style with one SVG per icon (`filled/eye.svg`), relative to where Tailwind runs. The
 * SVGs are the glyphs of the Keenicons fonts that come with Metronic and are covered by its license, so LineaUI
 * does not ship them: the app brings its own copy.
 */
module.exports = plugin.withOptions(
  (options = {}) =>
    ({matchComponents, theme}) => {
      const dir = path.resolve(process.cwd(), String(options.dir || "assets/keenicons").replace(/^["']|["']$/g, ""))
      const values = {}
      for (const style of fs.readdirSync(dir)) {
        const folder = path.join(dir, style)
        if (!fs.statSync(folder).isDirectory()) continue
        for (const file of fs.readdirSync(folder)) {
          if (!file.endsWith(".svg")) continue
          const name = `${style}-${path.basename(file, ".svg")}`
          values[name] = {name, fullPath: path.join(folder, file)}
        }
      }
      matchComponents(
        {
          ki: ({name, fullPath}) => {
            const svg = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
            const mask = `url('data:image/svg+xml;utf8,${encodeURIComponent(svg)}')`
            return {
              [`--ki-${name}`]: mask,
              "-webkit-mask": `var(--ki-${name})`,
              mask: `var(--ki-${name})`,
              "mask-repeat": "no-repeat",
              "mask-size": "100% 100%",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            }
          },
        },
        {values},
      )
    },
)
