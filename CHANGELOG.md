# Changelog

## Unreleased

- `radio_group` and `checkbox_group`: `variant="card"` (a bordered card per option with title, description,
  optional icon and count, ringed in `color` when chosen) and `variant="chip"` (pill chips with an optional
  count badge, the status filter of a list), over real radio/checkbox inputs; options may also be maps with
  `:description`, `:count`, `:icon`, `:color` and `:disabled`, and the slots take `count` and `icon`.
- `tags_input`: an option-picking mode: `options`, `create={false}`, `on_search` (debounced by `debounce`,
  sent to `target`) and `selected_options` for the labels of chosen values the current options no longer
  hold; chosen chips keep their labels across server searches. The free-text mode is unchanged.
- `date_picker`: a range submitted as two fields (`start_field`/`end_field` or `start_name`/`end_name`),
  `presets` under the calendar (named periods computed from `today` by the new `date_range_preset/3`, or
  explicit `{from, to}`), and `locale="pt_BR"` (month and weekday names, `dd/mm/aaaa`, "até"), with
  `range_separator`; `datetime_picker` takes `locale` too.

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
