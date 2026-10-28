/**
 * The panel of the date-time picker as HTML, from a plain description of what it shows (`vm`): the month grids,
 * the time list, the time dropdown or field, and the footer with the confirm button. No DOM: the hook writes the
 * string and listens to the `data-*` hooks it carries (`data-day`, `data-nav`, `data-time`, `data-time-select`,
 * `data-time-input`, `data-suggest`, `data-confirm`, `data-cancel`).
 */
import {bandCell, daysInMonth, leadingDays, previewRange, shiftMonth, toIso, weekdayIndex} from "./dates.js"
import {escapeHtml} from "./date_picker_view.js"
import {fill, formatTime} from "./datetime_format.js"
import {glyphHtml} from "./glyphs.js"

const DAY = "relative mx-auto flex size-9 items-center justify-center rounded-lg text-sm text-slate-600 outline-hidden transition-colors focus-visible:ring-2 focus-visible:ring-primary/50 dark:text-navy-100 dark:focus-visible:ring-accent/50"
const EDGE = "bg-primary font-medium text-white hover:bg-primary-focus dark:bg-accent dark:hover:bg-accent-focus"
const IDLE = "hover:bg-slate-150 dark:hover:bg-navy-500"
const OFF = "cursor-not-allowed text-slate-300 dark:text-navy-400"
const TODAY = "font-semibold text-primary after:absolute after:bottom-[5px] after:left-1/2 after:-ml-0.5 after:size-1 after:rounded-full after:bg-current after:content-[''] dark:text-accent-light"
const SLOT_OFF = "cursor-not-allowed text-slate-400 line-through opacity-50 dark:text-navy-300"
const NAV = "flex size-8 items-center justify-center rounded-lg text-slate-500 outline-hidden transition-colors hover:bg-slate-150 focus-visible:ring-2 focus-visible:ring-primary/50 dark:text-navy-200 dark:hover:bg-navy-500 dark:focus-visible:ring-accent/50"
const OPTION = "flex w-full items-center rounded-lg px-3 py-1.5 text-left text-sm outline-hidden transition-colors focus-visible:ring-2 focus-visible:ring-primary/50 dark:focus-visible:ring-accent/50"
const FIELD = "w-full rounded-lg border border-slate-300 bg-transparent px-3 py-2 text-sm text-slate-700 placeholder:text-slate-400/70 hover:border-slate-400 focus:border-primary disabled:pointer-events-none disabled:bg-zinc-100 disabled:opacity-70 dark:border-navy-450 dark:text-navy-100 dark:hover:border-navy-400 dark:focus:border-accent dark:disabled:bg-navy-600"
const CANCEL = "inline-flex h-9 items-center justify-center rounded-lg border border-slate-300 px-4 text-sm font-medium text-slate-700 outline-hidden transition-colors hover:bg-slate-150 focus-visible:ring-2 focus-visible:ring-primary/50 dark:border-navy-450 dark:text-navy-100 dark:hover:bg-navy-500 dark:focus-visible:ring-accent/50"
const CONFIRM = "inline-flex h-9 items-center justify-center rounded-lg bg-primary px-4 text-sm font-medium text-white outline-hidden transition-colors hover:bg-primary-focus focus-visible:ring-2 focus-visible:ring-primary/50 disabled:pointer-events-none disabled:opacity-60 dark:bg-accent dark:hover:bg-accent-focus dark:focus-visible:ring-accent/50"

const attr = escapeHtml

/** The classes of the cell behind a day: the band of a range is painted here, rounded at its ends and at the ends of the week. */
export const bandClass = ({paints, roundStart, roundEnd}) =>
  [paints && "bg-primary/10 dark:bg-accent/15", roundStart && "rounded-l-lg", roundEnd && "rounded-r-lg"].filter(Boolean).join(" ")

/** The classes of the button of a day, from what it is: an end of the choice, out of reach, today. */
export const dayClass = ({edge, off, today}) =>
  [DAY, edge ? EDGE : off ? OFF : IDLE, today && !edge && TODAY].filter(Boolean).join(" ")

/** The classes of an option of the time list: a closed slot is struck through and dimmed. */
export const optionClass = ({selected, disabled}) =>
  [OPTION, selected ? EDGE : disabled ? SLOT_OFF : "text-slate-600 hover:bg-slate-150 dark:text-navy-100 dark:hover:bg-navy-500"].join(" ")

const range = (vm) => {
  const {start, end} = vm.state
  return vm.mode === "range" ? previewRange({from: start?.date ?? null, to: end?.date ?? null}, vm.hover) : {from: start?.date ?? null, to: null}
}

const dayCell = (iso, number, column, vm, shown) => {
  const band = bandCell(shown, iso, column)
  const edge = iso === shown.from || iso === shown.to
  const off = vm.isOff(iso)
  const [weekday, month] = [vm.names.weekdays[new Date(`${iso}T00:00:00Z`).getUTCDay()], vm.names.months[Number(iso.slice(5, 7)) - 1]]
  const label = fill(vm.labels.datetime_day, {weekday, month, day: number, year: iso.slice(0, 4)})
  return (
    `<div role="gridcell" aria-selected="${edge || band.paints}" class="${bandClass(band)}">` +
    `<button type="button" data-day="${iso}" tabindex="${iso === vm.focus ? 0 : -1}" aria-label="${attr(label)}"` +
    `${off ? ' aria-disabled="true"' : ""}${iso === vm.today ? ' aria-current="date"' : ""} class="${dayClass({edge, off, today: iso === vm.today})}">${number}</button></div>`
  )
}

/**
 * One month: its header with the buttons to the previous (`side.previous`) and the next (`side.next`) month,
 * the weekday names and the grid of days.
 */
export const renderMonth = (month, side, vm) => {
  const shown = range(vm)
  const title = fill(vm.labels.datetime_title, {month: vm.names.months[month.month], year: month.year})
  const titleId = `${vm.id}-title-${month.year}-${month.month}`
  const blanks = leadingDays(month, vm.weekStart)
  const cells = [
    ...Array.from({length: blanks}, () => '<div role="gridcell"></div>'),
    ...Array.from({length: daysInMonth(month)}, (_, index) => {
      const iso = toIso(month.year, month.month, index + 1)
      return dayCell(iso, index + 1, weekdayIndex(iso, vm.weekStart), vm, shown)
    }),
  ]
  const rows = Array.from({length: Math.ceil(cells.length / 7)}, (_, row) => `<div role="row" class="grid grid-cols-7 gap-y-0.5">${cells.slice(row * 7, row * 7 + 7).join("")}</div>`)
  const nav = (direction, label, glyph, shows) =>
    shows
      ? `<button type="button" data-nav="${direction}" aria-label="${attr(label)}" class="${NAV}">${glyphHtml(glyph, vm.icons, {className: "size-4"})}</button>`
      : '<span class="size-8"></span>'
  const heads = Array.from({length: 7}, (_, index) => vm.names.weekdays[(index + vm.weekStart) % 7])

  return (
    `<div class="w-full min-w-0 sm:w-[17.5rem]" data-month="${month.year}-${month.month}">` +
    `<div class="flex h-8 items-center justify-between">${nav(-1, vm.labels.datetime_previous, "angle_left", side.previous)}` +
    `<span id="${titleId}" aria-live="polite" class="text-sm font-medium text-slate-700 dark:text-navy-100">${attr(title)}</span>` +
    `${nav(1, vm.labels.datetime_next, "angle_right", side.next)}</div>` +
    `<div role="grid" aria-labelledby="${titleId}" class="mt-2">` +
    `<div role="row" class="grid grid-cols-7">${heads.map((name) => `<span role="columnheader" aria-label="${attr(name)}" class="py-1 text-center text-xs font-medium text-slate-400 dark:text-navy-300">${attr(name.slice(0, 3))}</span>`).join("")}</div>` +
    `${rows.join("")}</div></div>`
  )
}

/** The listbox of times beside a single calendar: the chosen time is highlighted, a closed slot is dimmed. */
export const renderTimeList = (slots, selected, vm) => {
  const stop = slots.find((slot) => slot.time === selected && !slot.disabled) ?? slots.find((slot) => !slot.disabled)
  const options = slots
    .map(
      (slot) =>
        `<button type="button" role="option" data-time="${slot.time}" aria-selected="${slot.time === selected}"${slot.disabled ? ' aria-disabled="true"' : ""} ` +
        `tabindex="${slot === stop ? 0 : -1}" class="${optionClass({selected: slot.time === selected, disabled: slot.disabled})}">${formatTime(slot.time, vm.hour12)}</button>`,
    )
    .join("")
  return (
    `<div class="relative w-40 shrink-0 border-l border-slate-150 dark:border-navy-600">` +
    `<div role="listbox" aria-label="${attr(vm.labels.datetime_times)}" data-time-list class="scrollbar-sm absolute inset-0 space-y-0.5 overflow-y-auto p-1.5">` +
    `${options || `<p class="px-3 py-2 text-sm text-slate-400 dark:text-navy-300">${attr(vm.labels.datetime_no_times)}</p>`}</div></div>`
  )
}

const controlLabel = (which, vm) => (vm.mode === "range" ? vm.labels[`datetime_${which}`] : vm.labels.datetime_time)

const select = (which, slots, moment, vm) => {
  const placeholder = moment?.time ? "" : '<option value="" selected disabled hidden>–</option>'
  const options = slots
    .map((slot) => `<option value="${slot.time}"${slot.time === moment?.time ? " selected" : ""}${slot.disabled ? " disabled" : ""}>${formatTime(slot.time, vm.hour12)}</option>`)
    .join("")
  return (
    `<select id="${vm.id}-time-${which}" data-time-select="${which}" aria-label="${attr(controlLabel(which, vm))}"${slots.length === 0 ? " disabled" : ""} ` +
    `class="${FIELD} dark:*:bg-navy-700 dark:*:text-navy-100">${slots.length === 0 ? "<option>–</option>" : placeholder + options}</select>`
  )
}

/** The suggestions of the time field as options of its listbox; `active` is the one the arrow keys are on. */
export const renderSuggestions = (which, slots, selected, active, vm) =>
  slots.length === 0
    ? `<li role="presentation" class="px-3 py-2 text-sm text-slate-400 dark:text-navy-300">${attr(vm.labels.datetime_no_times)}</li>`
    : slots
        .map(
          (slot) =>
            `<li role="option" id="${vm.id}-suggest-${which}-${slot.time.replace(":", "")}" data-suggest="${slot.time}" data-which="${which}" aria-selected="${slot.time === selected}"` +
            `${slot.disabled ? ' aria-disabled="true"' : ""}${slot.time === active ? " data-active" : ""} class="${optionClass({selected: slot.time === selected, disabled: slot.disabled})} cursor-pointer data-active:bg-slate-150 dark:data-active:bg-navy-500">${formatTime(slot.time, vm.hour12)}</li>`,
        )
        .join("")

const combo = (which, slots, moment, vm) => {
  const listId = `${vm.id}-suggestions-${which}`
  return (
    `<div class="relative" data-combo="${which}">` +
    `<input type="text" id="${vm.id}-time-${which}" role="combobox" aria-autocomplete="list" aria-expanded="false" aria-controls="${listId}" aria-label="${attr(controlLabel(which, vm))}" ` +
    `autocomplete="off" spellcheck="false" data-time-input="${which}" placeholder="${attr(vm.labels.datetime_time_placeholder)}" value="${moment?.time ? formatTime(moment.time, vm.hour12) : ""}"${slots.length === 0 ? " disabled" : ""} class="${FIELD}">` +
    `<ul id="${listId}" role="listbox" hidden data-suggestions="${which}" aria-label="${attr(vm.labels.datetime_times)}" class="scrollbar-sm absolute inset-x-0 bottom-full z-20 mb-1 max-h-52 space-y-0.5 overflow-y-auto rounded-lg border border-slate-150 bg-white p-1 shadow-soft dark:border-navy-500 dark:bg-navy-700 dark:shadow-none">` +
    `${renderSuggestions(which, slots, moment?.time, null, vm)}</ul></div>`
  )
}

const control = (which, vm) => {
  const moment = which === "end" ? vm.state.end : vm.state.start
  const slots = vm.slots[which]
  return vm.timeMode === "input" ? combo(which, slots, moment, vm) : select(which, slots, moment, vm)
}

const controlBlock = (which, vm) => {
  const moment = which === "end" ? vm.state.end : vm.state.start
  const dateText = moment?.date ? vm.dateText(moment.date) : "–"
  return (
    `<div class="min-w-0 flex-1 basis-36">` +
    `<div class="text-xs font-medium text-slate-500 dark:text-navy-200">${attr(controlLabel(which, vm))}</div>` +
    `<div class="mb-1.5 truncate text-sm text-slate-700 dark:text-navy-100" data-date-text="${which}">${attr(dateText)}</div>` +
    `${control(which, vm)}</div>`
  )
}

const needsFooter = (vm) => vm.mode === "range" || vm.layout === "mobile" || vm.timeMode === "input"

const footer = (vm) => {
  const ends = vm.mode === "range" ? ["start", "end"] : ["start"]
  const confirm = vm.mode === "range" || vm.layout === "mobile"
  const label = vm.mode === "range" ? vm.labels.datetime_select_range : vm.labels.datetime_select
  return (
    `<div class="flex flex-wrap items-end gap-3 border-t border-slate-150 p-3 dark:border-navy-600">` +
    ends.map((which) => controlBlock(which, vm)).join("") +
    (confirm
      ? `<div class="flex w-full gap-2 sm:w-auto">` +
        `<button type="button" data-cancel class="${CANCEL} flex-1 sm:flex-none">${attr(vm.labels.datetime_cancel)}</button>` +
        `<button type="button" data-confirm class="${CONFIRM} flex-1 sm:flex-none"${vm.canConfirm ? "" : " disabled"}>${attr(label)}</button></div>`
      : "") +
    `</div>`
  )
}

/** The whole panel: the months (one, or two side by side for a range on a wide screen), the time list or the footer. */
export const renderPanel = (vm) => {
  const count = vm.mode === "range" && vm.layout === "desktop" ? 2 : 1
  const months = Array.from({length: count}, (_, index) =>
    renderMonth(shiftMonth(vm.view, index), {previous: index === 0, next: index === count - 1}, vm),
  )
  const list = vm.mode === "single" && vm.layout === "desktop" && vm.timeMode === "list" ? renderTimeList(vm.slots.start, vm.state.start?.time, vm) : ""
  return (
    `<div class="${vm.layout === "mobile" ? "w-[min(21rem,calc(100vw-1rem))]" : "w-max"} max-w-full">` +
    `<div class="flex ${vm.layout === "mobile" ? "flex-col" : ""}">` +
    `<div class="flex gap-4 p-3 ${count === 1 ? "min-w-0 flex-1" : ""}">${months.join("")}</div>${list}</div>` +
    `${needsFooter(vm) ? footer(vm) : ""}</div>`
  )
}
