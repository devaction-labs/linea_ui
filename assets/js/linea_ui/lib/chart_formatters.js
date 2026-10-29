const PT_NUMBER = new Intl.NumberFormat("pt-BR", {maximumFractionDigits: 2})

export const FORMATTERS = {
  thousands: (value) => `${value / 1000}k`,
  thousands_round: (value) => `${Math.round(value / 1000)}k`,
  thousands_fixed: (value) => (value >= 1000 ? (value / 1000).toFixed(2) + "k" : value),
  kilo: (value) => (value >= 1000 ? Math.round(value / 1000) + "k" : value),
  dollars: (value) => `$${value}`,
  dollars_thousands: (value) => `$${value / 1000}k`,
  brl: (value) => `R$ ${PT_NUMBER.format(value)}`,
  brl_thousands: (value) => (Math.abs(value) >= 1000 ? `R$ ${PT_NUMBER.format(Math.round(value / 100) / 10)} mil` : `R$ ${PT_NUMBER.format(value)}`),
  number_br: (value) => PT_NUMBER.format(value),
  percent: (value) => `${value}%`,
  percent_round: (value) => `${Math.round(value)}%`,
  round: (value) => `${Math.round(value)}`,
  hours: (value) => `${value}h`,
  minutes: (value) => `${value} min`,
  none: () => "",
  total: (w) => w.config.series.reduce((sum, value) => sum + value, 0),
  total_br: (w) => PT_NUMBER.format(w.config.series.reduce((sum, value) => sum + value, 0)),
}

const lookup = (name, table) => (typeof name === "string" && Object.hasOwn(table, name) ? table[name] : undefined)

export const parseSpec = (json) => {
  try {
    const spec = JSON.parse(json || "{}")
    return spec && typeof spec === "object" && !Array.isArray(spec) ? spec : {}
  } catch (_error) {
    return {}
  }
}

export const assignPath = (target, path, value) => {
  const keys = path.split(".")
  const last = keys.pop()
  const parent = keys.reduce((node, key) => (node[key] = node[key] ?? {}), target)
  parent[last] = value
  return target
}

const isObject = (value) => value !== null && typeof value === "object"

const resolveNamed = (node, table) => {
  Object.entries(node).forEach(([key, value]) => {
    const fn = key === "formatter" ? lookup(value, table) : undefined
    fn ? (node[key] = fn) : isObject(value) && resolveNamed(value, table)
  })
  return node
}

export const resolveFormatters = (options, spec = {}, table = FORMATTERS) => {
  Object.entries(spec).forEach(([path, name]) => {
    const fn = lookup(name, table)
    fn && assignPath(options, path, fn)
  })
  return resolveNamed(options, table)
}
