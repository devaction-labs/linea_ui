/**
 * The date, date-time and time pickers: flatpickr's calendar and time row, drawn by `calendar_view.js` into the
 * popup the server renders, the text of the input and the hidden inputs the form submits. The server's value
 * wins when it changes; otherwise the browser's choice survives patches.
 */
import {dayTarget, monthOf, shiftMonth} from "../lib/dates.js"
import {notify} from "../lib/dom.js"
import {clampTime, dayName, formatDate, isDisabled, pickDate, readTime, renderDays, renderTime, setUnit, stepTime, timeText} from "../lib/calendar_view.js"
import {escapeHtml} from "../lib/date_picker_view.js"
import {presetActive, presetDates, rangeInputs} from "../lib/date_range.js"
import {iconSet} from "../lib/glyphs.js"
import {sameValues} from "../lib/select_box.js"

const DAY_LABEL = "%{weekday}, %{month} %{day}, %{year}"
const COMMANDS = ["open", "close", "toggle", "clear"]
const GAP = 2

const readValues = (el) => JSON.parse(el.dataset.value || "[]")

const fromValues = (values, kind) =>
  ({
    date: () => ({dates: values, time: null}),
    datetime: () => ({dates: values.slice(0, 1).map((value) => value.slice(0, 10)), time: readTime(values[0], null)}),
    time: () => ({dates: [], time: readTime(values[0], null)}),
  })[kind]()

export const Picker = {
  mounted() {
    this.isOpen = false
    this.hover = null
    this.focusIso = null
    this.server = this.el.dataset.value
    this.load(readValues(this.el))
    this.view = monthOf(this.dates[0] ?? this.el.dataset.today ?? "1970-01-01")

    this.onClick = (event) => this.click(event)
    this.onPointerDown = (event) => {
      const inCalendar = event.target.closest("[data-calendar]")
      const field = event.target.closest("input:not([data-display]), select")
      inCalendar && !field && event.preventDefault()
    }
    this.onOutside = (event) => this.isOpen && !this.el.contains(event.target) && this.close()
    this.onKeyDown = (event) => this.key(event)
    this.onChange = (event) => this.changed(event)
    this.onOver = (event) => this.over(event)
    this.onFocusOut = (event) => this.leaving(event)
    this.onCommand = (event) => this[event.type.replace("linea:", "")]()
    this.onPushed = (event) => event.detail?.id && this.el.matches(event.detail.id) && this[event.type.replace("phx:linea:", "")]()

    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("pointerdown", this.onPointerDown)
    this.el.addEventListener("keydown", this.onKeyDown)
    this.el.addEventListener("change", this.onChange)
    this.el.addEventListener("input", this.onInput = (event) => event.target.closest("[data-calendar]") && event.stopPropagation())
    this.el.addEventListener("mouseover", this.onOver)
    this.el.addEventListener("focusout", this.onFocusOut)
    document.addEventListener("pointerdown", this.onOutside)
    COMMANDS.forEach((name) => {
      this.el.addEventListener(`linea:${name}`, this.onCommand)
      window.addEventListener(`phx:linea:${name}`, this.onPushed)
    })
    this.el.dataset.inline === "true" && this.render()
  },

  updated() {
    const incoming = this.el.dataset.value
    const next = readValues(this.el)
    const changed = incoming !== this.server && !sameValues(next, this.hiddenValues())
    this.server = incoming
    changed && (this.load(next), this.write())
    ;(this.isOpen || this.el.dataset.inline === "true") && this.render()
  },

  destroyed() {
    document.removeEventListener("pointerdown", this.onOutside)
    COMMANDS.forEach((name) => window.removeEventListener(`phx:linea:${name}`, this.onPushed))
  },

  kind() {
    return this.el.dataset.kind
  },

  mode() {
    return this.el.dataset.mode
  },

  load(values) {
    const {dates, time} = fromValues(values, this.kind())
    this.dates = dates
    this.time = time
  },

  q(selector) {
    return this.el.querySelector(selector)
  },

  timeRules() {
    const data = this.el.dataset
    return {min: data.minTime || null, max: data.maxTime || null, minuteStep: Number(data.minuteStep || 5), hourStep: Number(data.hourStep || 1)}
  },

  defaultTime() {
    return clampTime({hour: Number(this.el.dataset.defaultHour || 12), minute: 0}, this.timeRules())
  },

  names() {
    return JSON.parse(this.el.dataset.names || "{}")
  },

  labels() {
    return JSON.parse(this.el.dataset.labels || "{}")
  },

  state() {
    const data = this.el.dataset
    return {
      view: this.view,
      dates: this.dates,
      mode: this.mode(),
      today: data.today,
      hover: this.hover,
      weekStart: Number(data.weekStart || 0),
      names: this.names(),
      labels: this.labels(),
      dayLabel: (iso) => dayName(iso, this.labels().picker_day ?? DAY_LABEL, this.names()),
      focus: this.focusIso,
      icons: iconSet(this.el),
      rules: {
        min: data.min || null,
        max: data.max || null,
        dates: JSON.parse(data.disabledDates || "[]"),
        weekdays: JSON.parse(data.disabledWeekdays || "[]"),
      },
    }
  },

  render(keepInputs = false) {
    const kept = this.focusKey(keepInputs)
    const kind = this.kind()
    const time = this.time ?? this.defaultTime()
    const days = kind === "time" ? "" : renderDays(this.state())
    const clock =
      kind === "date"
        ? ""
        : renderTime({...time, twentyFour: this.el.dataset.time24 === "true", ...this.timeRules(), labels: this.labels(), stacked: kind === "time"})
    this.q("[data-calendar]").innerHTML = days + clock + this.presetsHtml()
    this.paintPresets()
    const again = kept && this.q("[data-calendar]").querySelector(kept)
    again && again.focus({preventScroll: true})
  },

  focusKey(keepInputs) {
    const active = document.activeElement
    const own = active && this.q("[data-calendar]").contains(active)
    const keys = own && [
      [active.dataset.date, `[data-date="${active.dataset.date}"]`],
      [active.dataset.month, `[data-month="${active.dataset.month}"]`],
      [active.dataset.step, `[data-unit="${active.dataset.unit}"][data-step="${active.dataset.step}"]`],
      [active.hasAttribute("data-ampm"), "[data-ampm]"],
      [keepInputs && active.hasAttribute("data-hour"), "[data-hour]"],
      [keepInputs && active.hasAttribute("data-minute"), "[data-minute]"],
    ]
    return keys && keys.find(([present]) => present)?.[1]
  },

  presetsHtml() {
    const template = this.q("template[data-presets]")
    return template ? template.innerHTML : ""
  },

  paintPresets() {
    const mode = this.mode()
    this.el.querySelectorAll("[data-calendar] [data-preset]").forEach((button) => {
      const active = presetActive({from: button.dataset.from, to: button.dataset.to}, this.dates, mode)
      button.toggleAttribute("data-active", active)
      button.setAttribute("aria-pressed", String(active))
    })
  },

  pickPreset(button) {
    this.dates = presetDates({from: button.dataset.from, to: button.dataset.to}, this.mode())
    this.view = monthOf(this.dates.at(-1))
    this.commit()
    this.el.dataset.inline === "true" ? this.render() : this.dismiss()
  },

  open() {
    const display = this.q("[data-display]")
    const can = !display.disabled && !this.isOpen
    const anchor = this.dates.at(-1) ?? this.el.dataset.today ?? "1970-01-01"
    can && ((this.isOpen = true), (this.focusIso = anchor), (this.view = monthOf(anchor)), this.render(), this.show())
    return can
  },

  openByKey() {
    this.open()
    this.isOpen && this.kind() !== "time" && this.q("[data-calendar] [data-date][tabindex='0']")?.focus({preventScroll: true})
  },

  show() {
    const calendar = this.q("[data-calendar]")
    calendar.classList.add("open")
    this.q("[data-display]").setAttribute("aria-expanded", "true")
    this.el.dataset.inline !== "true" && this.place(calendar)
    const hour = this.kind() === "time" && calendar.querySelector("[data-hour]")
    hour && (hour.focus(), hour.select())
  },

  place(calendar) {
    const rect = this.q("[data-display]").getBoundingClientRect()
    const height = calendar.offsetHeight
    const below = window.innerHeight - rect.bottom
    const above = below < height + GAP && rect.top > below
    calendar.classList.toggle("arrowTop", !above)
    calendar.classList.toggle("arrowBottom", above)
    calendar.style.top = above ? "auto" : `calc(100% + ${GAP}px)`
    calendar.style.bottom = above ? `calc(100% + ${GAP}px)` : ""
  },

  close() {
    const calendar = this.q("[data-calendar]")
    this.isOpen = false
    this.hover = null
    this.el.dataset.inline !== "true" && calendar.classList.remove("open")
    this.q("[data-display]").setAttribute("aria-expanded", "false")
  },

  dismiss() {
    const calendar = this.q("[data-calendar]")
    const inside = calendar.contains(document.activeElement)
    this.close()
    inside && this.q("[data-display]").focus({preventScroll: true})
  },

  leaving(event) {
    const gone = event.relatedTarget && !this.el.contains(event.relatedTarget)
    gone && this.isOpen && this.el.dataset.inline !== "true" && this.close()
  },

  toggle() {
    this.isOpen ? this.close() : this.open()
  },

  clear() {
    this.dates = []
    this.time = null
    this.commit()
    this.isOpen && this.render()
  },

  click(event) {
    const preset = event.target.closest("[data-calendar] [data-preset]")
    const day = event.target.closest("[data-date]")
    const month = event.target.closest("[data-month]")
    const arrow = event.target.closest(".numInputWrapper [data-step]")
    const ampm = event.target.closest("[data-ampm]")
    const stuck = (arrow || ampm)?.getAttribute("aria-disabled") === "true"
    const display = event.target.closest("[data-display]")
    const action =
      (preset && (() => this.pickPreset(preset))) ||
      (day && (() => this.pickDay(day))) ||
      (month && (() => this.moveMonth(Number(month.dataset.month)))) ||
      (stuck && (() => false)) ||
      (arrow && (() => this.stepArrow(arrow))) ||
      (ampm && (() => this.setTime({...this.currentTime(), hour: (this.currentTime().hour + 12) % 24}))) ||
      (display && (() => this.open()))
    action && action()
  },

  pickDay(day) {
    const iso = day.dataset.date
    this.focusIso = iso
    const blocked = isDisabled(iso, this.state().rules)
    const mode = this.mode()
    !blocked && ((this.dates = pickDate(this.dates, iso, mode)), this.kind() === "datetime" && !this.time && (this.time = this.defaultTime()))
    !blocked && this.commit()
    !blocked && this.paintPresets()
    const done = !blocked && this.kind() === "date" && (mode === "single" || (mode === "range" && this.dates.length === 2))
    done ? this.dismiss() : this.isOpen && this.render()
  },

  moveMonth(delta) {
    this.view = shiftMonth(this.view, delta)
    this.render()
  },

  currentTime() {
    return this.time ?? this.defaultTime()
  },

  stepArrow(arrow) {
    const input = arrow.parentElement.querySelector("input")
    const delta = Number(arrow.dataset.step)
    const unit = input.hasAttribute("data-hour") ? "hour" : "minute"
    const year = input.hasAttribute("data-year")
    year ? ((this.view = {...this.view, year: this.view.year + delta}), this.render()) : this.setTime(stepTime(this.currentTime(), unit, delta, this.timeRules()))
  },

  setTime(time, keepInputs = false) {
    this.time = clampTime(time, this.timeRules())
    this.commit()
    this.render(keepInputs)
  },

  changed(event) {
    const target = event.target
    const twentyFour = this.el.dataset.time24 === "true"
    const handlers = [
      [target.matches("[data-month-select]"), () => ((this.view = {...this.view, month: Number(target.value)}), this.render())],
      [target.matches("[data-year]"), () => ((this.view = {...this.view, year: Number(target.value) || this.view.year}), this.render())],
      [target.matches("[data-hour]"), () => this.setTime(setUnit(this.currentTime(), "hour", Number(target.value), twentyFour))],
      [target.matches("[data-minute]"), () => this.setTime(setUnit(this.currentTime(), "minute", Number(target.value), twentyFour))],
    ]
    const found = handlers.find(([applies]) => applies)
    found && (event.stopPropagation(), found[1]())
  },

  over(event) {
    const day = event.target.closest("[data-date]")
    const wanted = this.mode() === "range" && this.dates.length === 1 && day && day.dataset.date !== this.hover
    wanted && ((this.hover = day.dataset.date), this.paintDays())
  },

  paintDays() {
    const holder = document.createElement("div")
    holder.innerHTML = renderDays(this.state())
    const fresh = [...holder.querySelectorAll("[data-date]")]
    this.el.querySelectorAll("[data-calendar] [data-date]").forEach((cell, index) => (cell.className = fresh[index].className))
  },

  key(event) {
    const onDay = event.target.matches("[data-date]")
    onDay && event.key !== "Escape" ? this.dayKey(event) : this.fieldKey(event)
  },

  fieldKey(event) {
    const onDisplay = event.target.matches("[data-display]")
    const time = event.target.matches("[data-hour], [data-minute]")
    const unit = event.target.matches("[data-hour]") ? "hour" : "minute"
    const handlers = {
      Escape: () => this.dismiss(),
      Enter: () => onDisplay && (this.isOpen ? this.close() : this.openByKey()),
      ArrowDown: () => (time ? this.setTime(stepTime(this.currentTime(), unit, -1, this.timeRules()), true) : onDisplay && this.openByKey()),
      ArrowUp: () => time && this.setTime(stepTime(this.currentTime(), unit, 1, this.timeRules()), true),
    }
    const handler = handlers[event.key]
    handler && (onDisplay || time || event.key === "Escape") && (event.preventDefault(), handler())
  },

  dayKey(event) {
    const day = event.target
    const target = dayTarget(event.key, day.dataset.date, Number(this.el.dataset.weekStart || 0), event.shiftKey)
    const picks = event.key === "Enter" || event.key === " "
    const move = () => {
      const month = monthOf(target)
      this.focusIso = target
      this.view = month.year === this.view.year && month.month === this.view.month ? this.view : month
      this.render()
      this.q(`[data-calendar] [data-date="${target}"]`)?.focus({preventScroll: true})
    }
    target ? (event.preventDefault(), move()) : picks && (event.preventDefault(), this.pickDay(day))
  },

  hiddenValues() {
    const sorted = this.mode() === "range" ? [...this.dates].sort() : this.dates
    return {
      date: () => sorted,
      datetime: () => (sorted[0] ? [`${sorted[0]} ${timeText(this.currentTime())}`] : []),
      time: () => (this.time ? [timeText(this.time)] : []),
    }[this.kind()]()
  },

  displayText() {
    const format = this.el.dataset.format
    const names = this.names()
    const joiner = this.mode() === "range" ? (this.el.dataset.separator ?? " to ") : ", "
    return {
      date: () => this.hiddenValues().map((iso) => formatDate(iso, null, format, names)).join(joiner),
      datetime: () => this.dates.slice(0, 1).map((iso) => formatDate(iso, this.currentTime(), format, names)).join(""),
      time: () => (this.time ? formatDate("1970-01-01", this.time, format, names) : ""),
    }[this.kind()]()
  },

  write() {
    const {startName, endName} = this.el.dataset
    startName && endName ? this.writeSplit(startName, endName) : this.writeList()
    this.q("[data-display]").value = this.displayText()
  },

  writeSplit(startName, endName) {
    const disabled = this.q("[data-display]").disabled ? " disabled" : ""
    this.q("[data-hidden]").innerHTML = rangeInputs(this.hiddenValues(), startName, endName)
      .map(({name, value}) => `<input type="hidden" name="${escapeHtml(name)}" value="${escapeHtml(value)}"${disabled}>`)
      .join("")
  },

  writeList() {
    const name = this.el.dataset.name
    const values = this.hiddenValues()
    const list = name.endsWith("[]")
    const disabled = this.q("[data-display]").disabled ? " disabled" : ""
    const empty = list || values.length === 0 ? `<input type="hidden" name="${escapeHtml(name)}" value=""${disabled}>` : ""
    this.q("[data-hidden]").innerHTML =
      empty + values.map((value) => `<input type="hidden" name="${escapeHtml(name)}" value="${escapeHtml(value)}"${disabled}>`).join("")
  },

  commit() {
    this.write()
    notify(this.q("[data-hidden] input"))
    const event = this.el.dataset.onChange
    const values = this.hiddenValues()
    const value = this.mode() === "single" ? (values[0] ?? "") : values
    const target = this.el.getAttribute("phx-target")
    event && this.pushEventTo(target || this.el, event, {id: this.el.id, value})
  },
}

export default {"LineaUI.DatePicker": Picker}
