const NS = "http://www.w3.org/2000/svg"
const R = 10
const PORT = 8

const svgEl = (name, attrs) => {
  const el = document.createElementNS(NS, name)
  Object.entries(attrs).forEach(([k, v]) => v != null && v !== false && el.setAttribute(k, v === true ? "" : v))
  return el
}

/* Down from (x1, y1), across at `ym` and down to (x2, y2), with rounded corners. */
export const edgePath = (x1, y1, x2, y2, ym) => {
  if (Math.abs(x1 - x2) < 1) return `M${x1} ${y1}V${y2}`
  const r = Math.min(R, Math.abs(x2 - x1) / 2, (ym - y1), (y2 - ym))
  const s = x2 > x1 ? 1 : -1
  return (
    `M${x1} ${y1}V${ym - r}Q${x1} ${ym} ${x1 + s * r} ${ym}` +
    `H${x2 - s * r}Q${x2} ${ym} ${x2} ${ym + r}V${y2}`
  )
}

/**
 * Draws the edges of a flow: for every `.linea-flow-edge[data-from][data-to]` a path from the bottom of the
 * `from` card to the top of the `to` card, a port at each end, and the label (the edge element itself) on
 * the last vertical stretch. Sizes the stage to hold every node. Pure DOM, so it also runs outside a hook.
 */
export const drawFlow = (root) => {
  const stage = root.querySelector(".linea-flow-stage")
  const svg = root.querySelector(".linea-flow-edges")
  if (!stage || !svg) return
  const o = stage.getBoundingClientRect()
  const scale = o.width / stage.offsetWidth || 1
  const box = (el) => {
    const r = el.getBoundingClientRect()
    return {x: (r.left - o.left) / scale, y: (r.top - o.top) / scale, w: r.width / scale, h: r.height / scale}
  }
  const byId = (id) => id && stage.querySelector(`#${CSS.escape(id)}`)
  const card = (node) => node && (node.querySelector(".linea-flow-card") || node)

  let maxX = 0
  let maxY = 0
  stage.querySelectorAll(".linea-flow-node").forEach((n) => {
    const b = box(n)
    maxX = Math.max(maxX, b.x + b.w)
    maxY = Math.max(maxY, b.y + b.h)
  })
  const pad = Number(root.dataset.padding || 96)
  stage.style.width = `${Math.ceil(maxX + pad)}px`
  stage.style.height = `${Math.ceil(maxY + pad)}px`

  const parts = []
  const ports = []
  root.querySelectorAll(".linea-flow-edge[data-from][data-to]").forEach((edge) => {
    const a = card(byId(edge.dataset.from))
    const b = card(byId(edge.dataset.to))
    if (!a || !b) return (edge.hidden = true)
    edge.hidden = false
    const A = box(a)
    const B = box(b)
    const [x1, y1, x2, y2] = [A.x + A.w / 2, A.y + A.h, B.x + B.w / 2, B.y]
    const ym = y1 + Math.min(28, Math.max(12, (y2 - y1) / 3))
    const state = {"data-active": edge.hasAttribute("data-active"), "data-status": edge.dataset.status}
    parts.push(svgEl("path", {d: edgePath(x1, y1, x2, y2, ym), ...state}))
    ;[[x1, y1], [x2, y2]].forEach(([x, y]) =>
      ports.push(svgEl("rect", {x: x - PORT / 2, y: y - PORT / 2, width: PORT, height: PORT, rx: 2, ...state}))
    )
    const straight = Math.abs(x1 - x2) < 1
    edge.style.left = `${x2}px`
    edge.style.top = `${straight ? (y1 + y2) / 2 : ym + (y2 - ym) / 2}px`
  })
  svg.replaceChildren(...parts, ...ports)
}
