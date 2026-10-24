import assert from "node:assert/strict"
import test from "node:test"
import {COUNTRIES, byIso, flag} from "./phone_countries.js"
import {
  arrange,
  codeOf,
  digitsOf,
  e164,
  formatNational,
  initialCountry,
  leadOf,
  mainOf,
  nameOf,
  nationalOf,
  resolve,
  restrict,
  search,
  stripTrunk,
} from "./phone_logic.js"

const br = byIso("BR")
const us = byIso("US")

test("the table covers every country once, with a calling code and a pattern", () => {
  assert.equal(COUNTRIES.length, new Set(COUNTRIES.map((country) => country.iso)).size)
  assert.ok(COUNTRIES.length >= 240)
  COUNTRIES.forEach((country) => {
    assert.match(country.iso, /^[A-Z]{2}$/)
    assert.match(country.code, /^\d{1,3}$/)
    assert.ok(country.patterns.every((pattern) => /#/.test(pattern)), country.iso)
    assert.ok(country.en && country.pt, country.iso)
  })
})

test("flags are the regional indicators of the ISO code", () => {
  assert.equal(flag("BR"), "🇧🇷")
  assert.equal(flag("us"), "🇺🇸")
  assert.equal(byIso("br"), br)
  assert.equal(byIso("ZZ"), undefined)
  assert.equal(byIso(undefined), undefined)
})

test("national formats of the countries with a known pattern", () => {
  const format = (iso, digits) => formatNational(digits, byIso(iso))
  assert.equal(format("BR", "11912345678"), "(11) 91234-5678")
  assert.equal(format("BR", "1134567890"), "(11) 3456-7890")
  assert.equal(format("US", "2015550123"), "(201) 555-0123")
  assert.equal(format("CA", "4165550123"), "(416) 555-0123")
  assert.equal(format("PT", "912345678"), "912 345 678")
  assert.equal(format("AR", "1112345678"), "11 1234-5678")
  assert.equal(format("MX", "5512345678"), "55 1234 5678")
  assert.equal(format("GB", "7911123456"), "7911 123456")
  assert.equal(format("DE", "15112345678"), "151 12345678")
  assert.equal(format("FR", "612345678"), "6 12 34 56 78")
  assert.equal(format("ES", "612345678"), "612 34 56 78")
  assert.equal(format("IT", "3123456789"), "312 345 6789")
  assert.equal(format("ZW", "771234567"), "77 123 4567")
})

test("an unfinished number shows only the separators that have a digit after them", () => {
  assert.equal(formatNational("", br), "")
  assert.equal(formatNational("1", br), "(1")
  assert.equal(formatNational("11", br), "(11")
  assert.equal(formatNational("119", br), "(11) 9")
  assert.equal(formatNational("1191234", br), "(11) 9123-4")
  assert.equal(formatNational("201", us), "(201")
  assert.equal(formatNational("2015", us), "(201) 5")
})

test("brazilian landlines turn into mobiles with the eleventh digit", () => {
  assert.equal(formatNational("119123456", br), "(11) 9123-456")
  assert.equal(formatNational("1191234567", br), "(11) 9123-4567")
  assert.equal(formatNational("11912345678", br), "(11) 91234-5678")
})

test("digits past the pattern are appended as typed", () => {
  assert.equal(formatNational("201555012399", us), "(201) 555-012399")
})

test("digits, trunk prefix and the length of the national number", () => {
  assert.equal(digitsOf("+55 (11) 91234-5678"), "5511912345678")
  assert.equal(stripTrunk("011912345678", br), "11912345678")
  assert.equal(stripTrunk("11912345678", br), "11912345678")
  assert.equal(stripTrunk("12015550123", us), "2015550123")
  assert.equal(stripTrunk("0612345678", byIso("IT")), "0612345678")
  assert.equal(stripTrunk("89123456789", byIso("RU")), "9123456789")
  assert.equal(nationalOf("(11) 91234-5678", br), "11912345678")
  assert.equal(nationalOf("1".repeat(30), br).length, 13)
})

test("E.164 is the plus, the calling code and the national digits", () => {
  assert.equal(e164("11912345678", br), "+5511912345678")
  assert.equal(e164("2015550123", us), "+12015550123")
  assert.equal(e164("", br), "")
})

test("calling codes are read from the start of an international number", () => {
  assert.equal(codeOf("5511912345678"), "55")
  assert.equal(codeOf("12015550123"), "1")
  assert.equal(codeOf("351912345678"), "351")
  assert.equal(codeOf("447911123456"), "44")
  assert.equal(codeOf("5"), null)
  assert.equal(codeOf(""), null)
  assert.equal(codeOf("999"), null)
})

test("countries sharing a calling code are told apart by their prefixes", () => {
  assert.equal(mainOf("1").iso, "US")
  assert.equal(mainOf("7").iso, "RU")
  assert.equal(mainOf("44").iso, "GB")
  assert.equal(mainOf("55").iso, "BR")
  assert.equal(mainOf("999"), null)
  assert.equal(leadOf("1", "8765550123").iso, "JM")
  assert.equal(leadOf("1", "4165550123").iso, "CA")
  assert.equal(leadOf("1", "2015550123"), null)
  assert.equal(leadOf("44", "7911123456").iso, "GG")
  assert.equal(leadOf("7", "7011234567").iso, "KZ")
  assert.equal(leadOf("7", "9123456789"), null)
})

test("a pasted international number picks the country and shows the national format", () => {
  const pasted = resolve("+55 11 91234-5678", us)
  assert.equal(pasted.country.iso, "BR")
  assert.equal(pasted.display, "(11) 91234-5678")
  assert.equal(pasted.value, "+5511912345678")

  const nanp = resolve("+1 201 555 0123", br)
  assert.equal(nanp.country.iso, "US")
  assert.equal(nanp.display, "(201) 555-0123")
  assert.equal(nanp.value, "+12015550123")

  assert.equal(resolve("+1 (876) 555-0123", br).country.iso, "JM")
  assert.equal(resolve("+1 (416) 555-0123", br).country.iso, "CA")
  assert.equal(resolve("+351 912 345 678", br).display, "912 345 678")
  assert.equal(resolve("+44 (0)7911 123456", br).value, "+447911123456")
})

test("an international number stays as typed until its calling code is complete", () => {
  assert.deepEqual(resolve("+", br), {country: br, national: "", display: "+", value: ""})
  assert.equal(resolve("+5", br).display, "+5")
  assert.equal(resolve("+999 12", br).display, "+999 12")
  const done = resolve("+55", us)
  assert.equal(done.country.iso, "BR")
  assert.equal(done.display, "")
})

test("a national number is formatted for the current country and keeps the plain value", () => {
  const typed = resolve("11912", br)
  assert.equal(typed.display, "(11) 912")
  assert.equal(typed.value, "+5511912")
  assert.equal(resolve("", br).value, "")
  assert.equal(resolve("011 91234-5678", br).value, "+5511912345678")
  assert.equal(resolve("1 (201) 555-0123", us).display, "(201) 555-0123")
})

test("an area code of another country with the same calling code switches the country while typing", () => {
  assert.equal(resolve("876555", us).country.iso, "JM")
  assert.equal(resolve("876555", us, {refine: false}).country.iso, "US")
  assert.equal(resolve("20155", byIso("JM")).country.iso, "JM")
})

test("a country outside the pool is not picked from a pasted number", () => {
  const pool = COUNTRIES.filter((country) => ["BR", "PT"].includes(country.iso))
  assert.equal(resolve("+351 912 345 678", br, {pool}).country.iso, "PT")
  assert.equal(resolve("+1 201 555 0123", br, {pool}).display, "+1 201 555 0123")
  assert.equal(resolve("+1 201 555 0123", br, {pool}).value, "")
})

test("restrict keeps the allowed countries and drops the excluded ones", () => {
  assert.equal(restrict(COUNTRIES).length, COUNTRIES.length)
  assert.deepEqual(restrict(COUNTRIES, {only: ["BR", "US"]}).map((c) => c.iso), ["BR", "US"])
  assert.equal(restrict(COUNTRIES, {except: ["BR"]}).length, COUNTRIES.length - 1)
  assert.deepEqual(restrict(COUNTRIES, {only: ["BR", "US"], except: ["US"]}).map((c) => c.iso), ["BR"])
})

test("the list is sorted by the name in the locale, with the first countries on top", () => {
  const some = restrict(COUNTRIES, {only: ["AT", "BR", "DE", "ES", "US"]})
  assert.deepEqual(arrange(some, {locale: "pt-BR"}).map((c) => c.iso), ["DE", "AT", "BR", "ES", "US"])
  assert.deepEqual(arrange(some, {locale: "en"}).map((c) => c.iso), ["AT", "BR", "DE", "ES", "US"])
  assert.deepEqual(arrange(some, {locale: "en", first: ["US", "BR"]}).map((c) => c.iso), ["US", "BR", "AT", "DE", "ES"])
  assert.deepEqual(arrange(some, {locale: "en", first: ["XX"]}).map((c) => c.iso), ["AT", "BR", "DE", "ES", "US"])
  assert.equal(nameOf(br, "pt-BR"), "Brasil")
  assert.equal(nameOf(br, "en"), "Brazil")
})

test("search finds by name in both languages, ISO code and calling code, ignoring case and accents", () => {
  const list = arrange(COUNTRIES, {locale: "en"})
  const isos = (term) => search(list, term, "en").map((c) => c.iso)
  assert.equal(isos("brazil")[0], "BR")
  assert.equal(isos("BRASIL")[0], "BR")
  assert.equal(isos("br")[0], "BR")
  assert.equal(isos("55")[0], "BR")
  assert.equal(isos("+55")[0], "BR")
  assert.equal(isos("+351")[0], "PT")
  assert.ok(isos("alemanha").includes("DE"))
  assert.ok(isos("germ").includes("DE"))
  assert.equal(isos("cote")[0], "CI")
  assert.equal(isos("aland")[0], "AX")
  assert.equal(isos("usa")[0], "US")
  assert.equal(isos("uk")[0], "GB")
  assert.equal(isos("xyzzy").length, 0)
  assert.equal(isos("  ").length, COUNTRIES.length)
})

test("a code search lists the country with exactly that code before the ones that merely start with it", () => {
  const isos = search(arrange(COUNTRIES, {locale: "en"}), "5", "en").map((c) => c.iso)
  assert.ok(isos.indexOf("BR") < isos.length)
  const first = search(arrange(COUNTRIES, {locale: "en"}), "1", "en")[0]
  assert.equal(first.code, "1")
})

test("the initial country is the one asked for when the pool has it", () => {
  assert.equal(initialCountry("pt", COUNTRIES).iso, "PT")
  assert.equal(initialCountry("XX", COUNTRIES).iso, "AC")
  assert.equal(initialCountry(undefined, COUNTRIES).iso, "AC")
  const pool = restrict(COUNTRIES, {only: ["US", "CA"]})
  assert.equal(initialCountry("BR", pool).iso, "CA")
  assert.equal(initialCountry("BR", pool, ["US", "CA"]).iso, "US")
  assert.equal(initialCountry("BR", pool, ["XX"]).iso, "CA")
})
