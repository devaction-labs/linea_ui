/**
 * The reusable parts a chart declares in `<defs>`: gradients and the drop shadow, and the paint (fill and
 * opacity) a mark takes from the `fill` options.
 */
import {gradientOf} from "./chart_color.js"
import {pick} from "./chart_config.js"
import {h} from "./chart_svg.js"

/** A `linearGradient` node for a `gradientOf` spec; the declared opacities act twice, as they did in ApexCharts. */
export const gradientNode = (id, spec) =>
  h(
    "linearGradient",
    {id, x1: spec.direction.x1, y1: spec.direction.y1, x2: spec.direction.x2, y2: spec.direction.y2},
    h("stop", {offset: `${spec.stops[0]}%`, "stop-color": spec.from, "stop-opacity": spec.opacityFrom ** 2}),
    h("stop", {offset: `${spec.stops[1] ?? 100}%`, "stop-color": spec.to, "stop-opacity": spec.opacityTo ** 2}),
    spec.stops.length > 2 ? h("stop", {offset: `${spec.stops[2]}%`, "stop-color": spec.to, "stop-opacity": spec.opacityTo ** 2}) : null
  )

/** The `<filter>` of `chart.dropShadow`, or `null` when it is off. */
export const shadowNode = (config, uid) => {
  const shadow = config.chart.dropShadow
  return shadow?.enabled
    ? h(
        "filter",
        {id: `${uid}-shadow`, x: "-20%", y: "-20%", width: "140%", height: "140%"},
        h("feDropShadow", {dx: shadow.left ?? 0, dy: shadow.top ?? 0, stdDeviation: (shadow.blur ?? 3) / 2, "flood-color": shadow.color ?? "#000", "flood-opacity": shadow.opacity ?? 0.35})
      )
    : null
}

/**
 * The paint of mark `key` of series `index` in `color`: `{fill, opacity}` where `fill` is the color or a
 * `url(#gradient)` (declared into `defs`) and `opacity` the fill opacity when it is a plain color.
 * `direction` overrides the gradient's vector.
 */
export const paintFor = (config, {index, color, key, uid, defs, direction}) => {
  const type = pick(config.fill.type, index)
  const gradient = type === "gradient" ? {...gradientOf(config.fill.gradient, color, index, 1)} : null
  const id = `${uid}-${key}`
  gradient && defs.push(gradientNode(id, direction ? {...gradient, direction} : gradient))
  return gradient ? {fill: `url(#${id})`, opacity: undefined} : {fill: color, opacity: pick(config.fill.opacity, index)}
}
