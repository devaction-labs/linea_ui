/**
 * SVG path data for the chart engine: polylines with straight, smooth and stepped joins, filled areas,
 * rounded bars, arcs and rings. Angles are in degrees, 0 at the top, growing clockwise.
 */

const SMOOTHING = 0.35

const num = (value) => Math.round(value * 100) / 100

const at = (x, y) => `${num(x)} ${num(y)}`

const solid = (point) => point !== null && point !== undefined && Number.isFinite(point.y)

/** The runs of consecutive points; a missing point (`null`) ends a run. */
export const segments = (points) =>
  points.reduce(
    (runs, point) => (solid(point) ? [...runs.slice(0, -1), [...(runs.at(-1) ?? []), point]] : runs.at(-1)?.length === 0 ? runs : [...runs, []]),
    [[]]
  ).filter((run) => run.length > 0)

const join = {
  straight: (from, to) => `L ${at(to.x, to.y)}`,
  smooth: (from, to) => {
    const reach = (to.x - from.x) * SMOOTHING
    return `C ${at(from.x + reach, from.y)} ${at(to.x - reach, to.y)} ${at(to.x, to.y)}`
  },
  stepline: (from, to) => `L ${at(to.x, from.y)} L ${at(to.x, to.y)}`,
}

const joiner = (curve) => join[curve] ?? join.straight

/** The outline of one run of points as a `M ... L/C ...` path. */
export const runPath = (run, curve = "straight") =>
  run.length === 1
    ? `M ${at(run[0].x, run[0].y)}`
    : run.reduce((path, point, index) => (index === 0 ? `M ${at(point.x, point.y)}` : `${path} ${joiner(curve)(run[index - 1], point)}`), "")

/** The line through `points` (`null` entries leave a gap), one `M` per run. */
export const linePath = (points, curve = "straight") =>
  segments(points)
    .map((run) => runPath(run, curve))
    .join(" ")

/** The area between the line through `points` and the horizontal `baseY`, one closed shape per run. */
export const areaPath = (points, baseY, curve = "straight") =>
  segments(points)
    .map((run) => `${runPath(run, curve)} L ${at(run.at(-1).x, baseY)} L ${at(run[0].x, baseY)} Z`)
    .join(" ")

/** The area between the line through `upper` and the line through `lower`: one forward, the other back. */
export const bandPath = (upper, lower, curve = "straight") =>
  `${runPath(upper, curve)} L ${at(lower.at(-1).x, lower.at(-1).y)} ${runPath([...lower].reverse(), curve).replace(/^M/, "L")} Z`

/** A rectangle with a radius per corner, `[topLeft, topRight, bottomRight, bottomLeft]`, kept within the size. */
export const roundedRect = (x, y, width, height, radii = [0, 0, 0, 0]) => {
  const limit = Math.max(0, Math.min(width, height) / 2)
  const [tl, tr, br, bl] = radii.map((radius) => Math.min(Math.max(radius, 0), limit))
  return [
    `M ${at(x + tl, y)}`,
    `H ${num(x + width - tr)}`,
    tr ? `A ${num(tr)} ${num(tr)} 0 0 1 ${at(x + width, y + tr)}` : "",
    `V ${num(y + height - br)}`,
    br ? `A ${num(br)} ${num(br)} 0 0 1 ${at(x + width - br, y + height)}` : "",
    `H ${num(x + bl)}`,
    bl ? `A ${num(bl)} ${num(bl)} 0 0 1 ${at(x, y + height - bl)}` : "",
    `V ${num(y + tl)}`,
    tl ? `A ${num(tl)} ${num(tl)} 0 0 1 ${at(x + tl, y)}` : "",
    "Z",
  ]
    .filter(Boolean)
    .join(" ")
}

const corners = (towardEnd, awayEnd, rounded) => (rounded === "none" ? [0, 0] : rounded === "end" ? [towardEnd, 0] : rounded.first || rounded.last ? [rounded.last ? towardEnd : 0, rounded.first ? awayEnd : 0] : [0, 0])

/**
 * A column from `from` to `to` (y coordinates) of `width`. `ends` says which ends are rounded by `radius`:
 * `"both"`, `"end"` (the far end), `"none"`, or `{first, last}` for a piece of a stack.
 */
export const columnPath = (x, from, to, width, radius, ends = "both") => {
  const [far, near] = corners(radius, radius, ends === "both" ? {first: true, last: true} : ends)
  const up = to <= from
  const top = Math.min(from, to)
  const height = Math.abs(to - from)
  const [head, foot] = up ? [far, near] : [near, far]
  return roundedRect(x, top, width, height, [head, head, foot, foot])
}

/** A bar from `from` to `to` (x coordinates) of `height` at `y`, rounded like `columnPath`. */
export const barPath = (y, from, to, height, radius, ends = "both") => {
  const [far, near] = corners(radius, radius, ends === "both" ? {first: true, last: true} : ends)
  const right = to >= from
  const left = Math.min(from, to)
  const width = Math.abs(to - from)
  const [back, front] = right ? [near, far] : [far, near]
  return roundedRect(left, y, width, height, [back, front, front, back])
}

/** The point at `angle` degrees on the circle of `radius` around `(cx, cy)`. */
export const polar = (cx, cy, radius, angle) => {
  const radians = ((angle - 90) * Math.PI) / 180
  return {x: cx + radius * Math.cos(radians), y: cy + radius * Math.sin(radians)}
}

/** An arc of the circle, as a stroke path; a full circle is drawn as two halves. */
export const arcPath = (cx, cy, radius, from, to) => {
  const sweep = to - from
  const full = Math.abs(sweep) >= 359.99
  const start = polar(cx, cy, radius, from)
  const mid = polar(cx, cy, radius, from + sweep / 2)
  const end = polar(cx, cy, radius, to)
  const large = Math.abs(sweep) > 180 ? 1 : 0
  const direction = sweep >= 0 ? 1 : 0
  return full
    ? `M ${at(start.x, start.y)} A ${num(radius)} ${num(radius)} 0 0 ${direction} ${at(mid.x, mid.y)} A ${num(radius)} ${num(radius)} 0 0 ${direction} ${at(end.x, end.y)}`
    : `M ${at(start.x, start.y)} A ${num(radius)} ${num(radius)} 0 ${large} ${direction} ${at(end.x, end.y)}`
}

/** A closed polygon through `points`. */
export const polygonPath = (points) => `${points.map((point, index) => `${index === 0 ? "M" : "L"} ${at(point.x, point.y)}`).join(" ")} Z`
