/**
 * What the date picker decides about a range without a DOM: the two hidden inputs of a range split into a start
 * and an end field, the dates a preset sets, and whether a preset is the current choice.
 */

/** The `{name, value}` pairs of a range submitted as two fields; an end not picked yet is empty text. */
export const rangeInputs = (values, startName, endName) => [
  {name: startName, value: values[0] ?? ""},
  {name: endName, value: values[1] ?? ""},
]

/** The dates a preset sets: both ends in range mode, its first day otherwise. */
export const presetDates = ({from, to}, mode) => (mode === "range" ? [from, to].sort() : [from])

/** Whether the chosen dates are exactly what the preset would set. */
export const presetActive = (preset, dates, mode) => {
  const wanted = presetDates(preset, mode)
  const sorted = mode === "range" ? [...dates].sort() : dates
  return wanted.length === sorted.length && wanted.every((date, index) => date === sorted[index])
}
