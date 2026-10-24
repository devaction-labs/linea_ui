/**
 * The arithmetic of the color picker, with no DOM: hex text in and out, hue / saturation / brightness (HSV)
 * to red / green / blue, where a pointer or a key puts the knob in the saturation-brightness area, and the
 * text a screen reader hears. Colors are `{h, s, v, a}`: hue 0-359, saturation, brightness and alpha 0-100.
 */
import {clamp} from "./numbers.js"

const pair = (number) => Math.round(number).toString(16).toUpperCase().padStart(2, "0")

/** `{r, g, b, a}` (alpha 0-100) of `#RGB`, `#RGBA`, `#RRGGBB` or `#RRGGBBAA` (the `#` is optional), or `null`. */
export const parseHex = (text) => {
  const found = /^#?([0-9a-f]+)$/i.exec((text ?? "").trim())
  const digits = found?.[1]
  const full = [3, 4].includes(digits?.length) ? [...digits].map((char) => char + char).join("") : digits
  const ok = [6, 8].includes(full?.length)
  const byte = (at) => parseInt(full.slice(at, at + 2), 16)
  return ok ? {r: byte(0), g: byte(2), b: byte(4), a: full.length === 8 ? Math.round((byte(6) / 255) * 100) : 100} : null
}

/** The upper case hex text of a color; with `alpha` a color that is not fully opaque gets two more digits. */
export const toHex = ({r, g, b, a = 100}, alpha = false) =>
  `#${pair(r)}${pair(g)}${pair(b)}${alpha && a < 100 ? pair((a * 255) / 100) : ""}`

/** Whether two hex texts are the same color. */
export const sameHex = (a, b) => (a ?? "").toUpperCase() === (b ?? "").toUpperCase()

/** Red, green and blue (0-255) of a hue (0-360), saturation and brightness (0-100). */
export const hsvToRgb = (h, s, v) => {
  const saturation = s / 100
  const value = v / 100
  const channel = (n) => {
    const k = (n + h / 60) % 6
    return Math.round((value - value * saturation * Math.max(0, Math.min(k, 4 - k, 1))) * 255)
  }
  return {r: channel(5), g: channel(3), b: channel(1)}
}

const hueOf = ({r, g, b}, high, spread) =>
  spread === 0
    ? 0
    : 60 *
      [
        [high === r, ((g - b) / spread + 6) % 6],
        [high === g, (b - r) / spread + 2],
        [true, (r - g) / spread + 4],
      ].find(([hit]) => hit)[1]

/** The hue, saturation and brightness of a red / green / blue color. */
export const rgbToHsv = (rgb) => {
  const {r, g, b} = rgb
  const high = Math.max(r, g, b)
  const spread = high - Math.min(r, g, b)
  return {
    h: Math.round(hueOf(rgb, high, spread)) % 360,
    s: high === 0 ? 0 : Math.round((spread / high) * 100),
    v: Math.round((high / 255) * 100),
  }
}

/** The color of a hex text as `{h, s, v, a}`, or `null`. */
export const colorOfHex = (text) => {
  const rgb = parseHex(text)
  return rgb && {...rgbToHsv(rgb), a: rgb.a}
}

/** The hex text of `{h, s, v, a}`. */
export const hexOfColor = ({h, s, v, a}, alpha = false) => toHex({...hsvToRgb(h, s, v), a}, alpha)

/** The saturation and brightness a pointer at `(x, y)` means inside the area `rect`; both held between 0 and 100. */
export const areaPoint = ({left, top, width, height}, x, y) => ({
  s: Math.round(clamp(((x - left) / width) * 100, 0, 100)),
  v: Math.round(clamp(100 - ((y - top) / height) * 100, 0, 100)),
})

const KEY_MOVES = {
  ArrowLeft: [-1, 0],
  ArrowRight: [1, 0],
  ArrowUp: [0, 1],
  ArrowDown: [0, -1],
}

/** The saturation and brightness after a key: the arrows move one point, ten with Shift; `null` for other keys. */
export const areaKey = (key, {s, v}, shift = false) => {
  const move = KEY_MOVES[key]
  const step = shift ? 10 : 1
  return move ? {s: clamp(s + move[0] * step, 0, 100), v: clamp(v + move[1] * step, 0, 100)} : null
}

/** What a screen reader hears for the area: the template with `%{s}` and `%{v}` filled. */
export const areaText = (template, {s, v}) => template.replaceAll("%{s}", String(s)).replaceAll("%{v}", String(v))
