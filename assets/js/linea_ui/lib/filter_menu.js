/**
 * What `filter_menu` decides without a DOM: the number Apply shows, how many values are staged and the payload
 * of its events.
 */

const total = (options) => options.reduce((all, option) => all + option.count, 0)

/**
 * The number after Apply: how many records the staged filters leave. Each group is a list of options (`on`, and the
 * `count` of records it matches). A group with nothing ticked does not filter; the others narrow the result, and
 * with several of them the smallest group is the best the options alone can say (give `results` for the exact
 * number). With nothing ticked it is every record. When an option has no count it is the number of ticked values,
 * and `null` (no number) when there are none.
 *
 * @param {{on: boolean, count: number | null}[][]} groups
 * @returns {number | null}
 */
export function pendingResults(groups) {
  const countable = groups.length > 0 && groups.flat().every((option) => Number.isFinite(option.count))
  const staged = groups.map((options) => options.filter((option) => option.on)).filter((options) => options.length > 0)
  const rules = [
    [!countable, () => staged.flat().length || null],
    [staged.length === 0, () => Math.max(...groups.map(total))],
    [true, () => Math.min(...staged.map(total))],
  ]
  return rules.find(([hit]) => hit)[1]()
}

/**
 * How many values are staged in all: the number on the trigger.
 *
 * @param {{on: boolean}[][]} groups
 */
export const stagedTotal = (groups) => groups.flat().filter((option) => option.on).length

/** What follows Apply: ` (5)`, or nothing when there is no number. */
export const applySuffix = (count) => (Number.isFinite(count) ? ` (${count})` : "")

/**
 * The values of the groups as the events carry them: a list for a multiple group, the chosen value (or `""`) for a
 * single one.
 *
 * @param {{name: string, type: string, values: string[]}[]} groups
 * @returns {Record<string, string[] | string>}
 */
export const payloadOf = (groups) =>
  Object.fromEntries(groups.map(({name, type, values}) => [name, type === "single" ? (values[0] ?? "") : values]))

/**
 * What a closing menu does with what was staged: Apply keeps it, anything else (Esc, a click outside) goes back
 * to what the server rendered, and a live menu has nothing to take back.
 *
 * @param {{mode: string, applying: boolean}} state
 * @returns {"keep" | "revert"}
 */
export const onClose = ({mode, applying}) => (mode === "apply" && !applying ? "revert" : "keep")

const CUSTOM = /^custom:(\d{4}-\d{2}-\d{2})\.\.(\d{4}-\d{2}-\d{2})$/

/**
 * The value of a custom period, as a single group carries it: `custom:2026-11-01..2026-11-13`, or `""` when a day is
 * missing or the days are the wrong way round.
 *
 * @param {string} from ISO day
 * @param {string} to ISO day
 */
export const customValue = (from, to) => (CUSTOM.test(`custom:${from}..${to}`) && from <= to ? `custom:${from}..${to}` : "")

/**
 * The two ISO days of a custom period value, or `null` for a preset, `""` or a malformed text.
 *
 * @param {string | null | undefined} value
 * @returns {{from: string, to: string} | null}
 */
export const parseCustom = (value) => {
  const [, from, to] = CUSTOM.exec(value ?? "") ?? []
  return from && from <= to ? {from, to} : null
}

/**
 * The text of the row of a custom period: `01/11/2026 – 13/11/2026` in pt_BR, the ISO days otherwise; the server
 * writes the same text.
 *
 * @param {{from: string, to: string}} range
 * @param {string} locale
 */
export const rangeLabel = ({from, to}, locale) => {
  const day = (iso) => (locale === "pt_BR" ? iso.split("-").reverse().join("/") : iso)
  return `${day(from)} – ${day(to)}`
}

/**
 * What the row of a custom period shows for a value: the period, or the row's own text for a preset.
 *
 * @param {string} value
 * @param {{label: string, locale: string}} row
 */
export const customText = (value, {label, locale}) => {
  const range = parseCustom(value)
  return range ? rangeLabel(range, locale) : label
}
