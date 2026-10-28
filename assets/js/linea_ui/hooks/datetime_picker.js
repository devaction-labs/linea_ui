/**
 * `<.datetime_picker>`: a date and a time chosen in one panel. A single picker shows a calendar with the list of
 * times beside it (a date pick updates the value, a time pick updates it and closes); a range shows two months and
 * a start and an end time and applies on "Select range"; on a narrow screen the panel is one calendar with the
 * time as a dropdown and a "Select" button, and nothing changes until it is pressed. The value is wall-clock
 * text (`2026-10-14T10:30`), never converted. The panel floats like a popover (`Floating`), the server's value
 * wins when it changes, otherwise the browser's choice survives patches.
 */
import {notify} from "../lib/dom.js"
import {dayTarget, sameDayIn, shiftMonth, toIso} from "../lib/dates.js"
import {formatDate} from "../lib/calendar_view.js"
import {formatTime, formatValue, nearestSlot, parseTimeText, suggestSlots} from "../lib/datetime_format.js"
import {buildRules, isSlotAvailable, parseDefaultTime, slotTimes} from "../lib/datetime_rules.js"
import {anchorDay, fromValues, isComplete, isDayAvailable, pickDay, pickTime, rulesFor, showMonth, slotsFor, toValues, viewFor} from "../lib/datetime_state.js"
import {PAGE, gridTarget, yearPage} from "../lib/datetime_pick.js"
import {renderPanel, renderSuggestions} from "../lib/datetime_view.js"
import {rangeInputs} from "../lib/date_range.js"
import {escapeHtml} from "../lib/date_picker_view.js"
import {iconSet} from "../lib/glyphs.js"
import {runKey, wrap} from "../lib/keys.js"
import {sameValues} from "../lib/select_box.js"
import {Floating} from "./popover.js"

const MOBILE = "(max-width: 639.98px)"
const FOCUS_FRAMES = 4

const json = (text, fallback) => {
  try {
    return JSON.parse(text)
  } catch {
    return fallback
  }
}

const localNow = (today) => {
  const now = new Date()
  const pad = (number) => String(number).padStart(2, "0")
  return {date: today || toIso(now.getFullYear(), now.getMonth(), now.getDate()), time: `${pad(now.getHours())}:${pad(now.getMinutes())}`}
}

export const DatetimePicker = {
  ...Floating,

  mounted() {
    this.cfg = this.config()
    this.server = this.el.dataset.value
    this.value = fromValues(json(this.server, []), this.cfg)
    this.draft = this.value
    this.hover = null
    this.suggesting = null
    this.media = window.matchMedia(MOBILE)
    const sent = [...this.el.querySelectorAll("[data-hidden] input")].map((input) => input.value).filter(Boolean)
    sameValues(sent, toValues(this.value, this.cfg.mode)) || this.write()

    this.setupFloating()
    document.removeEventListener("click", this.onOutside)
    this.onOutside = (event) => this.isOpen() && !event.composedPath().includes(this.el) && this.close(false)
    document.addEventListener("click", this.onOutside)
    this.onTrigger = () => this.toggle()
    this.onTriggerKey = (event) => this.triggerKey(event)
    this.onClick = (event) => this.click(event)
    this.onKey = (event) => this.key(event)
    this.onChange = (event) => this.changed(event)
    this.onInput = (event) => this.typed(event)
    this.onOver = (event) => this.over(event)
    this.onFocusIn = (event) => !this.refocusing && event.target.matches("[data-time-input]") && this.suggest(event.target.dataset.timeInput, "")
    this.onFocusOut = (event) => this.leaving(event)
    this.onMedia = () => this.isOpen() && this.render()
    this.onMouseDown = (event) => event.target.closest("[data-suggest]") && event.preventDefault()
    this.stop = (event) => event.target.closest("[data-panel]") && event.stopPropagation()

    const panel = this.panel()
    this.trigger().addEventListener("click", this.onTrigger)
    this.trigger().addEventListener("keydown", this.onTriggerKey)
    panel.addEventListener("click", this.onClick)
    panel.addEventListener("keydown", this.onKey)
    panel.addEventListener("change", this.onChange)
    panel.addEventListener("input", this.onInput)
    panel.addEventListener("mouseover", this.onOver)
    panel.addEventListener("mousedown", this.onMouseDown)
    panel.addEventListener("focusin", this.onFocusIn)
    this.el.addEventListener("focusout", this.onFocusOut)
    this.el.addEventListener("input", this.stop)
    this.el.addEventListener("change", this.stop)
    this.media.addEventListener("change", this.onMedia)
  },

  updated() {
    this.updatedFloating()
    this.cfg = this.config()
    const incoming = this.el.dataset.value
    const next = fromValues(json(incoming, []), this.cfg)
    const changed = incoming !== this.server && !sameValues(toValues(next, this.cfg.mode), toValues(this.value, this.cfg.mode))
    this.server = incoming
    changed && ((this.value = next), (this.draft = next), this.write())
    this.isOpen() && this.render()
  },

  destroyed() {
    this.destroyedFloating()
    this.media.removeEventListener("change", this.onMedia)
  },

  q(selector) {
    return this.el.querySelector(selector)
  },

  isDisabled() {
    return this.el.dataset.disabled === "true"
  },

  config() {
    const data = this.el.dataset
    const now = localNow(data.today)
    const rules = buildRules(
      {min: data.min, max: data.max, minTime: data.minTime, maxTime: data.maxTime, unavailable: json(data.unavailable, [])},
      now,
    )
    return {
      mode: data.mode,
      rules,
      times: slotTimes(data.interval, rules),
      defaults: parseDefaultTime(data.defaultTime),
      hour12: data.hour12 === "true",
      timeMode: data.timeMode,
      weekStart: Number(data.weekStart || 0),
      names: json(data.names, {months: [], weekdays: []}),
      labels: json(data.labels, {}),
      today: now.date,
    }
  },

  layout() {
    return this.media.matches ? "mobile" : "desktop"
  },

  immediate() {
    return this.cfg.mode === "single" && this.layout() === "desktop"
  },

  months() {
    return this.cfg.mode === "range" && this.layout() === "desktop" ? 2 : 1
  },

  open() {
    const can = !this.isOpen() && !this.isDisabled()
    can && (this.begin(), Floating.open.call(this), this.scrollList(), this.focusSoon())
    return can
  },

  begin() {
    this.cfg = this.config()
    this.draft = this.value
    this.hover = null
    this.focusIso = anchorDay(this.draft, this.cfg.today, this.cfg.rules)
    this.view = viewFor(this.draft, this.cfg.today, this.cfg.rules)
    this.picking = null
    this.render()
  },

  conceal(returnFocus) {
    Floating.conceal.call(this, returnFocus)
    this.draft = this.value
    this.hover = null
    this.suggesting = null
    this.picking = null
  },

  ctx() {
    return {mode: this.cfg.mode, rules: this.cfg.rules, times: this.cfg.times, defaults: this.cfg.defaults}
  },

  viewModel() {
    const {cfg, draft} = this
    const ctx = this.ctx()
    const slotState = this.slotState()
    const names = cfg.names
    const dateFormat = this.el.dataset.dateFormat
    const visible = Array.from({length: this.months()}, (_, index) => shiftMonth(this.view, index))
    const inView = visible.some(({year, month}) => this.focusIso.startsWith(`${year}-${String(month + 1).padStart(2, "0")}`))
    return {
      id: this.el.id,
      mode: cfg.mode,
      layout: this.layout(),
      timeMode: cfg.timeMode,
      hour12: cfg.hour12,
      view: this.view,
      picking: this.picking,
      page: this.page,
      rules: cfg.rules,
      state: draft,
      hover: this.hover,
      focus: inView ? this.focusIso : toIso(this.view.year, this.view.month, 1),
      today: cfg.today,
      weekStart: cfg.weekStart,
      names,
      labels: cfg.labels,
      icons: iconSet(this.el),
      isOff: (iso) => !isDayAvailable(iso, draft, ctx),
      slots: {start: slotsFor(slotState, "start", ctx), end: slotsFor(slotState, "end", ctx)},
      dateText: (iso) => formatDate(iso, null, dateFormat, names),
      canConfirm: isComplete(draft, cfg.mode),
    }
  },

  surface() {
    return this.q("[data-surface]")
  },

  render() {
    const kept = this.focusKey()
    this.surface().innerHTML = renderPanel(this.viewModel())
    this.refocusing = true
    kept && this.surface().querySelector(kept)?.focus({preventScroll: true})
    this.refocusing = false
    this.scrollList()
  },

  focusKey() {
    const active = document.activeElement
    const own = active && this.surface().contains(active)
    const keys = own && [
      [active.dataset.day, `[data-day="${active.dataset.day}"]`],
      [active.dataset.time, `[data-time="${active.dataset.time}"]`],
      [active.dataset.nav, `[data-nav="${active.dataset.nav}"]`],
      [active.dataset.pickMonth, `[data-pick-month="${active.dataset.pickMonth}"]`],
      [active.dataset.pickYear, `[data-pick-year="${active.dataset.pickYear}"]`],
      [active.id, `[id="${active.id}"]`],
      [active.hasAttribute?.("data-confirm"), "[data-confirm]"],
      [active.hasAttribute?.("data-cancel"), "[data-cancel]"],
    ]
    return keys && keys.find(([present]) => present)?.[1]
  },

  scrollList() {
    const list = this.q("[data-time-list]")
    const chosen = list?.querySelector('[aria-selected="true"]')
    chosen && (list.scrollTop = chosen.offsetTop - list.clientHeight / 2 + chosen.offsetHeight / 2)
  },

  focusSoon(frames = FOCUS_FRAMES) {
    const target = this.surface().querySelector('[data-day][tabindex="0"]')
    target?.focus({preventScroll: true})
    const landed = target && this.surface().contains(document.activeElement)
    !landed && frames > 0 && this.isOpen() && requestAnimationFrame(() => this.focusSoon(frames - 1))
  },

  triggerKey(event) {
    const input = this.control().tagName === "INPUT"
    const open = () => (this.open() || this.focusSoon(), true)
    runKey({ArrowDown: open, Enter: () => input && open(), " ": () => input && open()}, event)
  },

  click(event) {
    const target = event.target
    const day = target.closest("[data-day]")
    const nav = target.closest("[data-nav]")
    const pick = target.closest("[data-pick]")
    const item = target.closest("[data-pick-item]")
    const time = target.closest("[data-time]")
    const suggestion = target.closest("[data-suggest]")
    const confirm = target.closest("[data-confirm]")
    const cancel = target.closest("[data-cancel]")
    const action =
      (day && (() => this.chooseDay(day.dataset.day))) ||
      (nav && (() => this.navigate(Number(nav.dataset.nav)))) ||
      (pick && (() => this.togglePick(pick))) ||
      (item && (() => this.choosePick(item))) ||
      (time && (() => this.chooseTime("start", time.dataset.time))) ||
      (suggestion && (() => this.chooseTime(suggestion.dataset.which, suggestion.dataset.suggest))) ||
      (confirm && (() => this.confirm())) ||
      (cancel && (() => this.close(true)))
    action && action()
  },

  chooseDay(iso) {
    const off = !isDayAvailable(iso, this.draft, this.ctx())
    const next = off ? this.draft : pickDay(this.draft, iso, this.ctx())
    this.draft = next
    this.focusIso = iso
    this.hover = null
    this.immediate() && !off && this.commit(next)
    this.render()
  },

  momentOf(which) {
    const {start, end} = this.draft
    return which === "end" ? end : (start ?? (this.cfg.mode === "single" ? {date: this.focusIso, time: null} : null))
  },

  slotState() {
    return this.draft.start || this.cfg.mode !== "single" ? this.draft : {...this.draft, start: this.momentOf("start")}
  },

  applyTime(which, time) {
    const moment = this.momentOf(which)
    const open = Boolean(moment?.date) && isSlotAvailable(moment.date, time, rulesFor(this.draft, which, this.cfg.rules))
    open && (this.draft = this.draft.start ? pickTime(this.draft, which, time) : {start: {date: moment.date, time}, end: null})
    return open
  },

  chooseTime(which, time) {
    const applied = this.applyTime(which, time)
    applied && (this.suggesting = null)
    applied && this.immediate() ? (this.commit(this.draft), this.render(), this.close(true)) : this.render()
    return applied
  },

  confirm() {
    const done = isComplete(this.draft, this.cfg.mode)
    done && (this.commit(this.draft), this.close(true))
  },

  navigate(delta) {
    const years = this.picking?.kind === "year"
    years ? (this.page = yearPage(this.page ?? this.view.year) + delta * PAGE) : (this.view = shiftMonth(this.view, delta * (this.picking ? 12 : 1)))
    this.render()
  },

  /** The month or year button of a header: opens its grid, or closes it when it is the one already open. */
  togglePick(button) {
    const kind = button.dataset.pick
    const index = Number(button.id.split("-").at(-1))
    const same = this.picking?.kind === kind && this.picking.index === index
    this.picking = same ? null : {kind, index}
    this.page = shiftMonth(this.view, index).year
    this.render()
    same ? this.focusSoon() : this.surface().querySelector('[data-pick-item][tabindex="0"]')?.focus({preventScroll: true})
  },

  /** A month or a year of the open grid: the view moves there and the days come back, with the focus on a day. */
  choosePick(item) {
    const index = this.picking.index
    const shown = shiftMonth(this.view, index)
    const month = item.dataset.pickMonth !== undefined ? Number(item.dataset.pickMonth) : shown.month
    const year = item.dataset.pickYear !== undefined ? Number(item.dataset.pickYear) : shown.year
    const off = item.getAttribute("aria-disabled") === "true"
    const target = shiftMonth({year, month}, -index)
    off || ((this.view = target), (this.focusIso = sameDayIn(this.focusIso, shiftMonth(target, index))), (this.picking = null))
    this.render()
    off || this.focusSoon()
  },

  /** Esc inside a grid goes back to the days, with the focus on the button that opened it. */
  leavePick(event) {
    const {kind, index} = this.picking
    this.picking = null
    event.stopPropagation()
    this.render()
    this.surface().querySelector(`[id="${this.el.id}-pick-${kind}-${index}"]`)?.focus({preventScroll: true})
  },

  pickKey(event) {
    const items = [...event.target.closest("[data-pick-grid]").querySelectorAll("[data-pick-item]")]
    const target = gridTarget(event.key, items.indexOf(event.target), items.length)
    const go = () => {
      items.forEach((item) => (item.tabIndex = -1))
      items[target].tabIndex = 0
      items[target].focus()
    }
    target !== null && (event.preventDefault(), go())
  },

  changed(event) {
    const select = event.target.closest("[data-time-select]")
    select && (event.stopPropagation(), this.chooseTime(select.dataset.timeSelect, select.value))
  },

  over(event) {
    const day = event.target.closest("[data-day]")
    const wanted = this.cfg.mode === "range" && this.draft.start && !this.draft.end && day && day.dataset.day !== this.hover
    wanted && ((this.hover = day.dataset.day), this.paint())
  },

  paint() {
    const holder = document.createElement("div")
    holder.innerHTML = renderPanel(this.viewModel())
    const fresh = new Map([...holder.querySelectorAll("[data-day]")].map((button) => [button.dataset.day, button]))
    this.surface()
      .querySelectorAll("[data-day]")
      .forEach((button) => {
        const next = fresh.get(button.dataset.day)
        button.className = next.className
        button.parentElement.className = next.parentElement.className
        button.parentElement.setAttribute("aria-selected", next.parentElement.getAttribute("aria-selected"))
      })
  },

  key(event) {
    const target = event.target
    const escaping = event.key === "Escape" && this.picking
    escaping && this.leavePick(event)
    const handlers = [
      [escaping, () => event.preventDefault()],
      [target.matches("[data-pick-item]"), () => this.pickKey(event)],
      [target.matches("[data-day]"), () => this.dayKey(event)],
      [target.matches("[data-time]"), () => this.optionKey(event)],
      [target.matches("[data-time-input]"), () => this.inputKey(event)],
    ]
    handlers.find(([applies]) => applies)?.[1]()
  },

  dayKey(event) {
    const iso = event.target.dataset.day
    const target = dayTarget(event.key, iso, this.cfg.weekStart, event.shiftKey)
    const move = () => {
      this.focusIso = target
      this.view = showMonth(this.view, this.months(), target)
      this.render()
      this.surface().querySelector(`[data-day="${target}"]`)?.focus({preventScroll: true})
    }
    target && (event.preventDefault(), move())
  },

  optionKey(event) {
    const options = [...this.surface().querySelectorAll('[data-time]:not([aria-disabled="true"])')]
    const index = options.indexOf(event.target)
    const go = (to) => () => {
      options.forEach((option) => (option.tabIndex = -1))
      options[to].tabIndex = 0
      options[to].focus()
    }
    runKey(
      {
        ArrowDown: go(Math.min(index + 1, options.length - 1)),
        ArrowUp: go(Math.max(index - 1, 0)),
        Home: go(0),
        End: go(options.length - 1),
      },
      event,
    )
  },

  suggestionsOf(which) {
    return this.q(`[data-suggestions="${which}"]`)
  },

  suggest(which, text) {
    const list = this.suggestionsOf(which)
    const shown = suggestSlots(slotsFor(this.slotState(), which, this.ctx()), text, this.cfg.hour12)
    const moment = which === "end" ? this.draft.end : this.draft.start
    const near = nearestSlot(shown, moment?.time)
    const light = {id: this.el.id, labels: this.cfg.labels, hour12: this.cfg.hour12}
    this.suggesting = which
    list.innerHTML = renderSuggestions(which, shown, moment?.time, null, light)
    list.hidden = false
    this.q(`[data-time-input="${which}"]`).setAttribute("aria-expanded", "true")
    const option = near && list.querySelector(`[data-suggest="${near.time}"]`)
    option && (list.scrollTop = option.offsetTop - list.clientHeight / 2 + option.offsetHeight / 2)
  },

  hideSuggestions() {
    const which = this.suggesting
    const list = which && this.suggestionsOf(which)
    const input = which && this.q(`[data-time-input="${which}"]`)
    list && ((list.hidden = true), input.setAttribute("aria-expanded", "false"), input.removeAttribute("aria-activedescendant"))
    this.suggesting = null
    return Boolean(list)
  },

  activeOptions(which) {
    return [...this.suggestionsOf(which).querySelectorAll('[data-suggest]:not([aria-disabled="true"])')]
  },

  activate(input, delta) {
    const which = input.dataset.timeInput
    this.suggesting === which || this.suggest(which, "")
    const options = this.activeOptions(which)
    const current = options.findIndex((option) => option.hasAttribute("data-active"))
    const target = options[wrap(current, delta, options.length)]
    options.forEach((option) => option.toggleAttribute("data-active", option === target))
    target && (input.setAttribute("aria-activedescendant", target.id), target.scrollIntoView({block: "nearest"}))
  },

  typed(event) {
    const input = event.target.closest("[data-time-input]")
    input && (event.stopPropagation(), input.removeAttribute("aria-invalid"), this.suggest(input.dataset.timeInput, input.value))
  },

  inputKey(event) {
    const input = event.target
    const which = input.dataset.timeInput
    runKey(
      {
        ArrowDown: () => this.activate(input, 1),
        ArrowUp: () => this.activate(input, -1),
        Enter: () => this.enterTime(which, input),
        Escape: () => (this.hideSuggestions() ? event.stopPropagation() : false),
      },
      event,
    )
  },

  enterTime(which, input) {
    const active = this.activeOptions(which).find((option) => option.hasAttribute("data-active"))
    const time = active ? active.dataset.suggest : parseTimeText(input.value)
    const applied = time && this.chooseTime(which, time)
    applied || input.setAttribute("aria-invalid", "true")
    this.hideSuggestions()
  },

  leaving(event) {
    const input = event.target.matches?.("[data-time-input]") ? event.target : null
    const inside = event.relatedTarget && this.el.contains(event.relatedTarget)
    input && this.settle(input)
    const gone = event.relatedTarget && !inside && this.isOpen()
    gone && this.close(false)
  },

  settle(input) {
    const which = input.dataset.timeInput
    const time = parseTimeText(input.value)
    const applied = time && time !== this.momentOf(which)?.time && this.applyTime(which, time)
    applied && this.immediate() && this.commit(this.draft)
    this.hideSuggestions()
    this.syncControls()
  },

  syncControls() {
    this.surface()
      .querySelectorAll("[data-time-input]")
      .forEach((input) => {
        const moment = input.dataset.timeInput === "end" ? this.draft.end : this.draft.start
        input.value = moment?.time ? formatTime(moment.time, this.cfg.hour12) : ""
      })
    const confirm = this.q("[data-confirm]")
    confirm && (confirm.disabled = !isComplete(this.draft, this.cfg.mode))
  },

  commit(state) {
    this.value = state
    this.write()
    notify(this.q("[data-hidden] input") ?? this.el)
    this.announceValue()
    const event = this.el.dataset.onChange
    const values = toValues(state, this.cfg.mode)
    const value = this.cfg.mode === "single" ? (values[0] ?? "") : values
    const target = this.el.getAttribute("phx-target")
    event && this.pushEventTo(target || this.el, event, {id: this.el.id, value})
  },

  announceValue() {
    const status = this.q("[data-status]")
    status && (status.textContent = this.displayText())
  },

  displayText() {
    const data = this.el.dataset
    return formatValue(this.value, {mode: this.cfg.mode, format: data.format, names: this.cfg.names, separator: data.separator})
  },

  write() {
    const {startName, endName} = this.el.dataset
    startName && endName ? this.writeSplit(startName, endName) : this.writeList()
    const display = this.q("[data-display]")
    display && (display.value = this.displayText())
  },

  inputsHtml(entries) {
    const disabled = this.isDisabled() ? " disabled" : ""
    return entries.map(({name, value}) => `<input type="hidden" name="${escapeHtml(name)}" value="${escapeHtml(value)}"${disabled}>`).join("")
  },

  writeSplit(startName, endName) {
    this.q("[data-hidden]").innerHTML = this.inputsHtml(rangeInputs(toValues(this.value, this.cfg.mode), startName, endName))
  },

  writeList() {
    const name = this.el.dataset.name
    const values = toValues(this.value, this.cfg.mode)
    const empty = name.endsWith("[]") || values.length === 0 ? [{name, value: ""}] : []
    this.q("[data-hidden]").innerHTML = this.inputsHtml([...empty, ...values.map((value) => ({name, value}))])
  },
}

export default {"LineaUI.DatetimePicker": DatetimePicker}
