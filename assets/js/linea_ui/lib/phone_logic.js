/**
 * What `<.phone_input>` decides without a DOM: the national format of the digits typed, the E.164 number built from
 * them, the country a pasted international number belongs to (telling apart the countries that share a calling code,
 * such as the NANP's +1), and which countries the picker lists and in what order. Formatting only helps the person
 * read what they typed; it does not validate the number.
 */
import {COUNTRIES, MAIN, byIso, flag} from "./phone_countries.js"
import {fold} from "./text.js"

/** The most digits an E.164 number has, calling code included. */
export const MAX_DIGITS = 15

const CODES = new Set(COUNTRIES.map((country) => country.code))

const ALIASES = {
  AE: ["uae"],
  CI: ["ivory coast"],
  CZ: ["czech republic", "republica tcheca"],
  GB: ["uk", "great britain", "inglaterra"],
  MK: ["macedonia"],
  MM: ["burma"],
  NL: ["holland", "holanda"],
  SZ: ["swaziland"],
  TL: ["east timor"],
  TR: ["turkey"],
  US: ["usa", "eua", "america"],
}

/** Only the digits of `text`. */
export const digitsOf = (text) => text.replace(/\D/g, "")

/** `digits` without the trunk prefix the country dials before a national number (`0` in Brazil, `1` in the NANP). */
export const stripTrunk = (digits, country) =>
  country.trunk !== "" && digits.startsWith(country.trunk) ? digits.slice(country.trunk.length) : digits

/** The most national digits a country takes, so that the whole number stays within E.164's 15. */
export const maxNational = (country) => MAX_DIGITS - country.code.length

/** The national digits of what was typed for a country: no trunk prefix, no more than E.164 allows. */
export const nationalOf = (text, country) => stripTrunk(digitsOf(text), country).slice(0, maxNational(country))

const capacity = (pattern) => [...pattern].filter((char) => char === "#").length

const patternFor = (patterns, count) => patterns.find((pattern) => capacity(pattern) >= count) ?? patterns.at(-1)

const fill = (pattern, digits) => {
  const {text, used} = [...pattern].reduce(
    (state, char) =>
      state.used >= digits.length
        ? state
        : char === "#"
          ? {text: state.text + state.pending + digits[state.used], pending: "", used: state.used + 1}
          : {...state, pending: state.pending + char},
    {text: "", pending: "", used: 0},
  )
  return text + digits.slice(used)
}

/**
 * The national digits written in the country's pattern, as far as the digits go: the separators appear when a digit
 * follows them, so an unfinished number never ends in `)` or a space. Digits past the pattern are appended as typed.
 */
export const formatNational = (digits, country) => fill(patternFor(country.patterns, digits.length), digits)

/** The E.164 number of national digits (`+5511912345678`); empty when there are none. */
export const e164 = (national, country) => (national === "" ? "" : `+${country.code}${national}`)

/** The calling code an international number starts with, or `null` while the digits do not make one yet. */
export const codeOf = (digits) => [1, 2, 3].map((size) => digits.slice(0, size)).find((code) => CODES.has(code)) ?? null

const sharing = (code, pool) => pool.filter((country) => country.code === code)

/** The country of a calling code when nothing else tells: the main one of the code, else the first in the pool. */
export const mainOf = (code, pool = COUNTRIES) =>
  sharing(code, pool).find((country) => country.iso === MAIN[code]) ?? sharing(code, pool)[0] ?? null

/** The country of the pool whose `leads` prefix the national digits (the longest prefix wins), or `null`. */
export const leadOf = (code, national, pool = COUNTRIES) =>
  sharing(code, pool)
    .flatMap((country) => country.leads.filter((lead) => national.startsWith(lead)).map((lead) => ({country, size: lead.length})))
    .sort((a, b) => b.size - a.size)[0]?.country ?? null

/**
 * What typing, pasting or loading `text` means for the field.
 *
 * A text starting with `+` is an international number: its calling code picks the country (from `pool`) and the rest
 * is the national number; while the code is not complete, or its country is not in the pool, the text stays as
 * typed and no number is formed yet. Any other text is the national number of `current`; with `refine`, a number
 * whose first digits belong to another country of the same calling code (an area code) switches to it.
 *
 * Returns `{country, national, display, value}`: the country, its national digits, the text to show, and the E.164 value.
 */
export const resolve = (text, current, {pool = COUNTRIES, refine = true} = {}) => {
  const international = text.trim().startsWith("+")
  const code = international ? codeOf(digitsOf(text)) : null
  const base = international ? (code === null ? null : mainOf(code, pool)) : current
  const stay = {country: current, national: "", display: text, value: ""}
  return base === null
    ? stay
    : settle(international ? digitsOf(text).slice(code.length) : digitsOf(text), base, international || refine, pool)
}

const settle = (digits, base, refine, pool) => {
  const national = stripTrunk(digits, base).slice(0, maxNational(base))
  const country = (refine && leadOf(base.code, national, pool)) || base
  return {country, national, display: formatNational(national, country), value: e164(national, country)}
}

/** The countries of `list` allowed by `only` (ISO codes; empty means all) and not named in `except`. */
export const restrict = (list, {only = [], except = []} = {}) =>
  list.filter((country) => (only.length === 0 || only.includes(country.iso)) && !except.includes(country.iso))

/** The name of a country in a locale: pt-BR names for `pt` locales, English for the rest. */
export const nameOf = (country, locale) => (locale.toLowerCase().startsWith("pt") ? country.pt : country.en)

/** The calling code of a list row: `+1`, and for a country with up to three area codes of its own, `+1 787, 939`. */
export const dialLabel = (country) =>
  country.leads.length > 0 && country.leads.length <= 3 && country.leads.every((lead) => lead.length === 3)
    ? `+${country.code} ${country.leads.join(", ")}`
    : `+${country.code}`

/** The list in the order of the picker: the `first` ISO codes in the order given, then the rest by name in the locale. */
export const arrange = (list, {locale = "en", first = []} = {}) => {
  const collator = new Intl.Collator(locale)
  const rank = (country) => first.indexOf(country.iso)
  const head = first.flatMap((iso) => list.filter((country) => country.iso === iso))
  const tail = list.filter((country) => rank(country) === -1).sort((a, b) => collator.compare(nameOf(a, locale), nameOf(b, locale)))
  return [...head, ...tail]
}

const aliases = (country) => ALIASES[country.iso] ?? []

const names = (country) => fold([country.en, country.pt, ...aliases(country)].join(" "))

const startsWord = (text, query) => text.split(/[\s(),'-]+/).some((word) => word.startsWith(query))

const rankOf = (country, query, locale) => {
  const code = query.replace(/^\+/, "")
  const numeric = /^\d+$/.test(code)
  const name = fold(nameOf(country, locale))
  return [
    [query.length === 2 && country.iso.toLowerCase() === query, 0],
    [numeric && country.code === code, 0],
    [aliases(country).includes(query), 0],
    [name.startsWith(query), 1],
    [numeric && country.code.startsWith(code), 2],
    [startsWord(names(country), query), 3],
    [names(country).includes(query), 4],
  ].find(([hit]) => hit)?.[1] ?? null
}

/**
 * The countries that match a search, best first: by ISO code, by calling code (`55` or `+55`) and by name in either
 * language or a common alias, ignoring case and accents. A blank search keeps the list as it is.
 */
export const search = (list, term, locale = "en") => {
  const query = fold(term.trim())
  return query === ""
    ? list
    : list
        .map((country, index) => ({country, index, rank: rankOf(country, query, locale)}))
        .filter(({rank}) => rank !== null)
        .sort((a, b) => a.rank - b.rank || a.index - b.index)
        .map(({country}) => country)
}

/**
 * The country to start with: the one asked for when the pool has it, else the first of `first` (ISO codes) the pool
 * has, else the first of the pool.
 */
export const initialCountry = (iso, pool, first = []) =>
  [iso, ...first].map((code) => pool.find((country) => country.iso === String(code ?? "").toUpperCase())).find(Boolean) ?? pool[0] ?? byIso("BR")

/**
 * The mark at the start of a picker row: the mono ISO code (`PT`), or with `flags` the flag emoji of the country.
 */
export const markHtml = (country, flags = false) =>
  flags
    ? `<span class="shrink-0 text-base leading-none" aria-hidden="true">${flag(country.iso)}</span>`
    : `<span class="w-6 shrink-0 font-mono text-[11px] font-semibold text-slate-400 dark:text-navy-300">${country.iso}</span>`
