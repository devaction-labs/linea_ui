/**
 * Colors and gradients for the chart engine: reading `#rgb`, `#rrggbb` and `rgb()/rgba()`, mixing toward
 * white or black, and the stops of the gradient a `fill` asks for.
 */

const HEX3 = /^#([0-9a-f])([0-9a-f])([0-9a-f])$/i
const HEX6 = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i
const RGB = /^rgba?\(\s*(\d+)[,\s]+(\d+)[,\s]+(\d+)/i

/** `[r, g, b]` of a color text, or `null` when it is not one the engine can read. */
export const parseColor = (color) => {
  const text = String(color ?? "").trim()
  const short = HEX3.exec(text)
  const long = HEX6.exec(text)
  const rgb = RGB.exec(text)
  return short ? short.slice(1).map((part) => parseInt(part + part, 16)) : long ? long.slice(1).map((part) => parseInt(part, 16)) : rgb ? rgb.slice(1).map(Number) : null
}

const hex = (channels) => `#${channels.map((value) => Math.round(value).toString(16).padStart(2, "0")).join("")}`

/** Mixes `color` toward white (`amount` > 0) or black (`amount` < 0) by that fraction. Unreadable colors stay. */
export const shade = (color, amount) => {
  const channels = parseColor(color)
  const target = amount < 0 ? 0 : 255
  return channels ? hex(channels.map((value) => value + (target - value) * Math.abs(amount))) : color
}

const DIRECTIONS = {
  vertical: {x1: 0, y1: 0, x2: 0, y2: 1},
  horizontal: {x1: 0, y1: 0, x2: 1, y2: 0},
  diagonal1: {x1: 0, y1: 0, x2: 1, y2: 1},
  diagonal2: {x1: 1, y1: 0, x2: 0, y2: 1},
}

const listed = (value, index) => (Array.isArray(value) ? value[index] : value)

/**
 * The gradient `fill.gradient` describes for `color`, for series `index`:
 * `{from, to, opacityFrom, opacityTo, stops, direction}`, `direction` being the `x1 y1 x2 y2` of the vector
 * in a unit box. `to` is the shade of `color` unless `gradientToColors` names one; `inverseColors` swaps them.
 */
export const gradientOf = (gradient, color, index, opacity = 1) => {
  const target = listed(gradient.gradientToColors, index)
  const toward = target || (gradient.gradientToColors?.length ? color : shade(color, (gradient.shade === "dark" ? -1 : 1) * Number(gradient.shadeIntensity ?? 0.5)))
  const [from, to] = gradient.inverseColors ? [toward, color] : [color, toward]
  const stops = Array.isArray(gradient.stops) && gradient.stops.length > 0 ? gradient.stops : [0, 50, 100]
  return {
    from,
    to,
    opacityFrom: listed(gradient.opacityFrom, index) ?? opacity,
    opacityTo: listed(gradient.opacityTo, index) ?? opacity,
    stops,
    direction: DIRECTIONS[gradient.type] ?? DIRECTIONS.horizontal,
  }
}
