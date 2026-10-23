/**
 * Input masks in the manner of Cleave.js, the library LineOne's demos use: `format(value, kind, options)`
 * turns whatever was typed into the masked text, `raw(value, kind, options)` strips it back to what the
 * server wants, and `caretFor` keeps the caret after the same typed character. Delimiters appear only
 * before the character that follows them, so deleting backwards never fights the mask.
 * Nothing here reads the DOM.
 */

const alnum = /[A-Za-z0-9]/
const digitsOf = (value) => String(value ?? "").replace(/\D/g, "")

const chunk = (text, blocks, delimiters) => {
  let out = ""
  let at = 0
  for (let i = 0; i < blocks.length && at < text.length; i++) {
    out += (i > 0 ? delimiters[Math.min(i - 1, delimiters.length - 1)] ?? "" : "") + text.slice(at, at + blocks[i])
    at += blocks[i]
  }
  return out
}

const delimitersOf = (options, fallback) =>
  options.delimiters ?? [options.delimiter ?? fallback]

const stripPrefix = (text, prefix) => {
  let i = 0
  while (i < prefix.length && text[i] === prefix[i]) i++
  return text.slice(i)
}

const removeAll = (text, chars) =>
  chars.reduce((acc, char) => (char === "" ? acc : acc.split(char).join("")), text)

const blocksRaw = (value, options) => {
  const prefix = options.prefix ?? ""
  const plain = stripPrefix(removeAll(String(value ?? ""), delimitersOf(options, " ")), prefix)
  const cased = options.uppercase ? plain.toUpperCase() : options.lowercase ? plain.toLowerCase() : plain
  return options.numeric ? digitsOf(cased) : cased
}

const formatBlocks = (value, options) => {
  const prefix = options.prefix ?? ""
  const blocks = options.blocks ?? [Infinity]
  const content = prefix + blocksRaw(value, options)
  return chunk(content, blocks, delimitersOf(options, " ")) || prefix
}

/** The card brand's blocks, from the first digits. */
export const cardBlocks = (digits) => {
  if (/^3[47]/.test(digits)) return [4, 6, 5]
  if (/^3(?:0[0-5]|09|[689])/.test(digits)) return [4, 6, 4]
  if (/^1/.test(digits)) return [4, 5, 6]
  return [4, 4, 4, 4]
}

const formatCard = (value, options) => {
  const digits = digitsOf(value)
  return chunk(digits, cardBlocks(digits), [options.delimiter ?? " "])
}

const dateLimits = {d: [3, 31], m: [1, 12]}
const timeLimits = {h: [2, 23], m: [5, 59], s: [5, 59]}

const partLength = (letter) => (letter === "Y" ? 4 : 2)

const takePart = (digits, letter, limits) => {
  if (limits[letter] === undefined) return [digits.slice(0, partLength(letter)), Math.min(digits.length, partLength(letter))]
  const [first, max] = limits[letter]
  if (Number(digits[0]) > first) return [`0${digits[0]}`, 1]
  const part = digits.slice(0, 2)
  if (part.length < 2) return [part, part.length]
  if (Number(part) > max) return [String(max), 2]
  if (part === "00" && limits === dateLimits) return ["01", 2]
  return [part, 2]
}

const formatParts = (value, pattern, delimiter, limits) => {
  let digits = digitsOf(value)
  const parts = []
  for (const letter of pattern) {
    if (digits === "") break
    const [part, used] = takePart(digits, letter, limits)
    parts.push(part)
    digits = digits.slice(used)
  }
  return parts.join(delimiter)
}

const groupInteger = (integer, style) => {
  if (style === "none") return integer
  if (style === "lakh") {
    const last = integer.slice(-3)
    const rest = integer.slice(0, -3)
    return rest === "" ? last : `${rest.replace(/\B(?=(\d{2})+$)/g, ",")},${last}`
  }
  const size = style === "wan" ? 4 : 3
  return integer.replace(new RegExp(`\\B(?=(\\d{${size}})+$)`, "g"), ",")
}

const numeralParts = (value, options) => {
  const mark = options.decimal_mark ?? "."
  const text = String(value ?? "")
  const negative = !options.positive && text.trimStart().startsWith("-")
  const [integerText, ...decimalTexts] = text.split(mark)
  const integer = digitsOf(integerText).replace(/^0+(?=\d)/, "")
  const decimals = digitsOf(decimalTexts.join("")).slice(0, options.decimals ?? 2)
  return {negative, integer, decimals, hasMark: decimalTexts.length > 0 && (options.decimals ?? 2) > 0, mark}
}

const formatNumeral = (value, options) => {
  const {negative, integer, decimals, hasMark, mark} = numeralParts(value, options)
  const delimiter = options.delimiter ?? ","
  const grouped = groupInteger(integer, options.thousands ?? "thousand").replace(/,/g, delimiter)
  const whole = hasMark && integer === "" ? "0" : grouped
  return `${negative ? "-" : ""}${whole}${hasMark ? mark + decimals : ""}`
}

const formatters = {
  blocks: formatBlocks,
  credit_card: formatCard,
  date: (value, options) => formatParts(value, options.pattern ?? ["d", "m", "Y"], options.delimiter ?? "/", dateLimits),
  time: (value, options) => formatParts(value, options.pattern ?? ["h", "m", "s"], options.delimiter ?? ":", timeLimits),
  phone: (value, options) => chunk(digitsOf(value), options.blocks ?? [3, 3, 4], [options.delimiter ?? " "]),
  numeral: formatNumeral,
}

/** `value` with the mask `kind` applied. */
export const format = (value, kind, options = {}) => (formatters[kind] ?? ((v) => String(v ?? "")))(value, options)

/** The unmasked value of a masked text: digits for cards, phones, dates and times, a plain number for numerals. */
export const raw = (value, kind, options = {}) => {
  if (kind === "blocks") return blocksRaw(value, options)
  if (kind === "numeral") {
    const {negative, integer, decimals} = numeralParts(value, options)
    return integer === "" && decimals === "" ? "" : `${negative ? "-" : ""}${integer || "0"}${decimals ? "." + decimals : ""}`
  }
  return digitsOf(value)
}

/** How many letters and digits come before `position` in `text`. */
export const significantBefore = (text, position) =>
  [...text.slice(0, position)].filter((char) => alnum.test(char)).length

/** The position in `formatted` right after its `count`-th letter or digit. */
export const caretFor = (formatted, count) => {
  if (count <= 0) return 0
  let seen = 0
  for (let i = 0; i < formatted.length; i++) {
    if (alnum.test(formatted[i])) seen++
    if (seen === count) return i + 1
  }
  return formatted.length
}

/** `text` without the last letter or digit before `position`, for a backspace that only hit a delimiter. */
export const dropBefore = (text, position) => {
  for (let i = position - 1; i >= 0; i--) {
    if (alnum.test(text[i])) return {text: text.slice(0, i) + text.slice(i + 1), position: i}
  }
  return {text, position}
}
