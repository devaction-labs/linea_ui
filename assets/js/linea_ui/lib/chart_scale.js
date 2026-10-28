/**
 * Scales of the chart engine: "nice" value axes, evenly spaced category bands, time ticks and the number
 * and date text that goes on them. Pure functions, no DOM.
 */

const EPSILON = 1e-11

const MAGNITUDE_STEPS = [1, 1, 2, 5, 5, 5, 10, 10, 10, 10, 10]

const DEFAULT_TICKS = [1, 2, 4, 4, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 12, 12, 12, 12, 12, 12, 12, 12, 12, 24]

const isNumber = (value) => typeof value === "number" && Number.isFinite(value)

const strip = (value, digits = 7) => Number(value.toPrecision(digits))

const primeFactors = (number) => {
  const factors = []
  let rest = number
  for (let factor = 2; factor * factor <= rest; factor++) {
    while (rest % factor === 0) {
      factors.push(factor)
      rest /= factor
    }
  }
  return rest > 1 ? [...factors, rest] : factors
}

const gcd = (a, b, digits = 7) => {
  const scale = Math.pow(10, digits - Math.floor(Math.log10(Math.max(a, b))))
  let x = Math.round(Math.abs(a) * scale)
  let y = Math.round(Math.abs(b) * scale)
  while (y) [x, y] = [y, x % y]
  return x / scale
}

const reduceTicks = (ticks, maxTicks) => {
  const factors = primeFactors(ticks)
  const last = factors.length - 1
  for (let span = 0; span < last; span++) {
    for (let from = 0; from <= last - span; from++) {
      const divisor = factors.slice(from, Math.min(from + span, last) + 1).reduce((product, factor) => product * factor, 1)
      if (ticks / divisor < maxTicks) return ticks / divisor
    }
  }
  return ticks
}

const stepFor = (range, ticks) => {
  const raw = range / ticks
  const magnitude = Math.pow(10, Math.floor(Math.log10(raw)))
  return MAGNITUDE_STEPS[Math.ceil(raw / magnitude)] * magnitude
}

const snapped = (min, max, step, got) =>
  got.min && got.max
    ? [min, max]
    : got.max
      ? [step * Math.floor(min / step), max]
      : got.min
        ? [min, step * Math.ceil(max / step)]
        : [step * Math.floor(min / step), step * Math.ceil(max / step)]

const fitted = ({min, max, range, step, ticks, maxTicks}) => {
  const exact = range % step === 0
  const count = exact ? range / step : Math.ceil(range / step)
  const crude = range / count
  const common = gcd(range, step)
  const adjusted = exact ? step : range / common < maxTicks ? common : crude
  return {min, max, step: adjusted, ticks: Math.round(range / adjusted), tickAmount: ticks}
}

const inflate = (min, max, ticks) =>
  min === max ? [min === 0 ? 0 : min - 1, max === 0 ? 2 : max + 1] : min > max ? [max, min] : [min, max]

/**
 * The ticks of a value axis for data spanning `min..max`, in the manner ApexCharts lays them out so charts
 * keep their shape: a step of 1, 2 or 5 times a power of ten, the range snapped to it (and to zero when the
 * data starts close to it) and as many ticks as the chart's `size` (its height, or width for a horizontal
 * bar) leaves room for. `limits` may fix `min`, `max` and `tickAmount`.
 *
 * Returns `{ticks, min, max}`.
 */
export const niceScale = (min, max, {size = 300, limits = {}} = {}) => {
  const maxTicks = Math.max((size - 100) / 15, 2)
  const got = {min: isNumber(limits.min), max: isNumber(limits.max)}
  const wanted = isNumber(limits.tickAmount) ? Math.max(1, Math.round(limits.tickAmount)) : null
  const ticks = wanted ?? DEFAULT_TICKS[Math.min(Math.round(maxTicks / 2), DEFAULT_TICKS.length - 1)]
  const [low, high] = inflate(
    got.min ? limits.min : isNumber(min) ? min : 0,
    got.max ? limits.max : isNumber(max) ? max : (isNumber(min) ? min : 0) + ticks
  )
  const rawRange = Math.abs(high - low)
  const zeroLow = !got.min && low > 0 && low / rawRange < 0.15
  const zeroHigh = !got.max && high < 0 && -high / rawRange < 0.15
  const start = zeroLow ? 0 : low
  const end = zeroHigh ? 0 : high
  const gotMin = got.min || zeroLow
  const gotMax = got.max || zeroHigh
  const range = Math.abs(end - start)
  const base = stepFor(range, ticks)
  const bounded = gotMin && gotMax
  const [from, to] = snapped(start, end, base, {min: gotMin, max: gotMax})
  const span = Math.abs(to - from)
  const layout = bounded
    ? fitted({min: from, max: to, range: span, step: wanted ? range / ticks : base, ticks, maxTicks})
    : {min: from, max: to, step: gcd(span, base), ticks: Math.round(span / gcd(span, base))}
  const free = !wanted && !(gotMin || gotMax)
  const wrapped = free ? Math.ceil((span - EPSILON) / (layout.step + EPSILON)) : layout.ticks
  const counted = free && wrapped > 16 && primeFactors(wrapped).length < 2 ? wrapped + 1 : wrapped
  const reduce = counted > maxTicks && !wanted
  const reduced = reduce ? reduceTicks(counted, maxTicks) : counted
  const step = reduce ? (reduced === counted ? span : span / reduced) : layout.step
  const values = []
  let value = layout.min - step
  do {
    value += step
    values.push(strip(value))
  } while (layout.max - value > step * EPSILON)
  return {ticks: values, min: values[0], max: values[values.length - 1]}
}

/** The positions of `count` points spread over `0..size`, both ends included. */
export const spread = (count, size) => Array.from({length: count}, (_, index) => (count > 1 ? (index * size) / (count - 1) : size / 2))

/** The centers of `count` equal bands that fill `size`, with their common width. */
export const bands = (count, size) => {
  const width = count > 0 ? size / count : size
  return {width, centers: Array.from({length: count}, (_, index) => (index + 0.5) * width)}
}

/** Maps `value` from the domain `[d0, d1]` onto the range `[r0, r1]`; a flat domain maps to the middle. */
export const linear = (d0, d1, r0, r1) => (value) => (d1 === d0 ? (r0 + r1) / 2 : r0 + ((value - d0) / (d1 - d0)) * (r1 - r0))

const DAY = 86400000

const TIME_STEPS = [
  1000, 5000, 15000, 30000, 60000, 300000, 900000, 1800000, 3600000, 10800000, 21600000, 43200000, DAY, 2 * DAY, 3 * DAY, 7 * DAY, 14 * DAY,
]

const utcStart = (time, unit) => {
  const date = new Date(time)
  return unit === "year"
    ? Date.UTC(date.getUTCFullYear(), 0, 1)
    : Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1)
}

const calendarTicks = (min, max, unit, every) => {
  const ticks = []
  let time = utcStart(min, unit)
  while (time <= max) {
    time >= min && ticks.push(time)
    const date = new Date(time)
    time =
      unit === "year"
        ? Date.UTC(date.getUTCFullYear() + every, 0, 1)
        : Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + every, 1)
  }
  return ticks
}

/** Tick instants (ms, UTC) between `min` and `max`: at most `limit` of them, on whole seconds up to years. */
export const timeTicks = (min, max, limit) => {
  const span = Math.max(max - min, 1)
  const fixed = TIME_STEPS.find((step) => span / step <= limit)
  const months = [1, 2, 3, 6].find((every) => span / (every * 30.44 * DAY) <= limit)
  const years = [1, 2, 5, 10, 20, 50, 100].find((every) => span / (every * 365.25 * DAY) <= limit) ?? 100
  const unit = fixed ? null : months ? ["month", months] : ["year", years]
  return unit
    ? calendarTicks(min, max, ...unit)
    : Array.from({length: Math.floor(max / fixed) - Math.ceil(min / fixed) + 1}, (_, index) => (Math.ceil(min / fixed) + index) * fixed)
}

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

const DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

const pad = (value) => String(value).padStart(2, "0")

const capital = (text) => text.charAt(0).toUpperCase() + text.slice(1)

const names = new Map()

/** The month and day names of a locale (`pt-BR`), from `Intl`, capitalized and with no abbreviation dot; English when the locale is unknown. */
const namesOf = (locale) => {
  if (!locale) return {months: MONTHS, shortMonths: MONTHS.map((name) => name.slice(0, 3)), days: DAYS, shortDays: DAYS.map((name) => name.slice(0, 3))}
  if (!names.has(locale)) {
    try {
      const name = (options, date) => capital(new Intl.DateTimeFormat(locale, {...options, timeZone: "UTC"}).format(date).replace(/\.$/, ""))
      const months = (month) => Array.from({length: 12}, (_, index) => name({month}, new Date(Date.UTC(2000, index, 1))))
      const days = (weekday) => Array.from({length: 7}, (_, index) => name({weekday}, new Date(Date.UTC(2000, 0, 2 + index))))
      names.set(locale, {months: months("long"), shortMonths: months("short"), days: days("long"), shortDays: days("short")})
    } catch (_error) {
      names.set(locale, namesOf(null))
    }
  }
  return names.get(locale)
}

const TOKENS = {
  yyyy: (d) => String(d.getUTCFullYear()),
  yy: (d) => String(d.getUTCFullYear()).slice(-2),
  MMMM: (d, n) => n.months[d.getUTCMonth()],
  MMM: (d, n) => n.shortMonths[d.getUTCMonth()],
  MM: (d) => pad(d.getUTCMonth() + 1),
  dddd: (d, n) => n.days[d.getUTCDay()],
  ddd: (d, n) => n.shortDays[d.getUTCDay()],
  dd: (d) => pad(d.getUTCDate()),
  HH: (d) => pad(d.getUTCHours()),
  hh: (d) => pad(d.getUTCHours() % 12 || 12),
  mm: (d) => pad(d.getUTCMinutes()),
  ss: (d) => pad(d.getUTCSeconds()),
  TT: (d) => (d.getUTCHours() < 12 ? "AM" : "PM"),
}

const TOKEN_PATTERN = /yyyy|yy|MMMM|MMM|MM|dddd|ddd|dd|HH|hh|mm|ss|TT/g

/** Formats a UTC instant with tokens such as `dd MMM yyyy`, `MMM 'yy`, `HH:mm`; names of months and days in `locale` (English without). */
export const formatDate = (time, pattern, locale) => {
  const date = new Date(time)
  const set = namesOf(locale)
  return pattern.replace(TOKEN_PATTERN, (token) => TOKENS[token](date, set))
}

/** The pattern that fits the spacing between ticks when the chart does not give one. */
export const datePattern = (span) =>
  span >= 2 * 365 * DAY ? "yyyy" : span >= 60 * DAY ? "MMM yyyy" : span >= 2 * DAY ? "dd MMM" : span >= 60000 * 5 ? "HH:mm" : "HH:mm:ss"

/** A date from what a series carries: a timestamp, a Date or a date text. `NaN` when it is none of them. */
export const toTime = (value) => (typeof value === "number" ? value : Date.parse(value instanceof Date ? value.toISOString() : String(value)))

/** A number without floating point noise, as text: `0.1 + 0.2` is `0.3`. */
export const plain = (value) => (Number.isFinite(value) ? String(Number(value.toPrecision(12))) : "")

/** The number of decimals the ticks need to tell them apart. */
export const decimalsOf = (values) => Math.min(6, Math.max(0, ...values.map((value) => (plain(value).split(".")[1] ?? "").length)))

/** A width for `text` at `size` px without measuring: each glyph class has its own average advance. */
export const estimateWidth = (text, size) =>
  [...String(text)].reduce((sum, char) => sum + (/[il.,:;'|!1 ]/.test(char) ? 0.3 : /[mwMW]/.test(char) ? 0.88 : /[A-Z]/.test(char) ? 0.68 : /\d/.test(char) ? 0.6 : 0.56), 0) * size
