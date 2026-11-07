const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

/**
 * Tailwind plugin for Hugeicons Stroke Rounded (free set): every `huge-<name>` class draws the icon with a
 * CSS mask in the current text color. In the app's css, after the LineaUI import:
 *
 *   @plugin "../../deps/linea_ui/assets/css/hugeicons.cjs" { dir: "assets/vendor/hugeicons"; }
 *
 * `dir` is the folder of the SVGs, relative to where Tailwind runs (the app's root); default
 * `assets/vendor/hugeicons`. Only the `.svg` files count (the folder also holds a manifest and the LICENSE).
 * The app fills it with `mix linea_ui.icons sync` (or `get NAME...`); a folder from the whole-repo git dep
 * (`dir: "deps/hugeicons/icons"`) works too.
 */
module.exports = plugin.withOptions(
  (options = {}) =>
    ({matchComponents, theme}) => {
      const dir = path.resolve(process.cwd(), String(options.dir || "assets/vendor/hugeicons").replace(/^["']|["']$/g, ""))
      const values = Object.fromEntries(
        fs.readdirSync(dir).filter((file) => file.endsWith(".svg")).map((file) => {
          const name = path.basename(file, ".svg")
          return [name, {name, fullPath: path.join(dir, file)}]
        }),
      )
      matchComponents(
        {
          huge: ({name, fullPath}) => {
            const svg = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "")
              .replace(/(?:stroke|fill)="#[0-9A-Fa-f]{3,8}"/g, (match) =>
                match.startsWith("fill") ? 'fill="currentColor"' : 'stroke="currentColor"',
              )
              .replace(/<svg\s+width="[^"]*"\s+height="[^"]*"/, "<svg")
            const mask = `url('data:image/svg+xml;utf8,${encodeURIComponent(svg)}')`
            return {
              [`--huge-${name}`]: mask,
              "-webkit-mask": `var(--huge-${name})`,
              mask: `var(--huge-${name})`,
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
