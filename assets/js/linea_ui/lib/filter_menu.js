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
