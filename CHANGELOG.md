# Changelog

## Unreleased

- `number_input`: a locale-aware numeric field (pt-BR `1.234,56` by default, `en`, or explicit separators) with
  fixed (`decimals`) or maximum (`max_decimals`) decimals, `min`/`max`/`step`, optional `steppers`, `prefix`/`suffix`
  boxes; it shows the formatted number and submits the machine value (`1234.56`) through a hidden input, and takes
  integers, floats, numeric strings and `Decimal`s (`LineaUI.NumberInput` hook).
- `autocomplete`: a text input with suggestions in the Tom Select look: client filtering or server search
  (`on_search`, debounced, `target`, `search_threshold`, loading row), `:option` slot, keyboard navigation,
  `clearable`, `open_on_focus`, `free_text`, `display_value`, and a `no_results` text with `%{query}`
  (`LineaUI.Autocomplete` hook).
- `select`: the listbox's `id` falls back to `name` before a generated one, and `no_results` replaces `%{query}`
  with the search text.

## 0.1.1

- LICENSE and README: the design is credited to its author; the text no longer asks users for a license of
  the original kit.

## 0.1.0

First release.

- 47 Phoenix LiveView components reproducing the LineOne design: buttons, badges, tags, avatars, alerts,
  cards, progress, spinners, skeletons, tooltips, typography, breadcrumbs, tabs, steps, timeline, pagination,
  tables and data tables, treeview, menu list, carousel, charts (ApexCharts supplied by the app), accordion,
  collapse, modal, drawer, dropdown, popover, toasts (stacked, open under the pointer), clipboard, the
  application shell, and the form controls: input (with masks), input group, textarea, checkbox, radio,
  switch, range, select, tags input, date, date-time and time pickers, text editor and upload.
- Server-driven and client-driven state for every stateful component, events with a `target`, streams for
  lists, `LineaUI.open/close/toggle` for overlays, `field={@form[:name]}` for form controls.
- Two icon sets: LineOne's own glyphs (default) and Hugeicons Stroke Rounded
  (`config :linea_ui, :icons, :hugeicons`), plus `<.icon>` for any Hugeicons name.
- `mix linea_ui.install` and `mix linea_ui.gen.skill` write a Claude Code skill generated from the
  components' own attributes and docs.
