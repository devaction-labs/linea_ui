# Changelog

## 0.2.0

- One-command installer: `mix igniter.install linea_ui` adds the dependency and sets the app up, with the
  diff confirmed by the user. `mix linea_ui.install` is now an Igniter task (`igniter` is an optional
  dependency; without it the task keeps writing the skill and printing the setup lines). It imports the
  fonts and styles in `app.css` (with `@source` for `source(none)`), registers `LineaHooks` in `app.js`,
  adds the fonts' `Plug.Static` to the endpoint, adds `use LineaUI, avoid_conflicts: true` to
  `html_helpers/0`, writes the Claude Code skill and the `AGENTS.md`/`CLAUDE.md` pointer (creating
  `AGENTS.md` when neither exists). Idempotent. Flags: `--hugeicons`, `--replace-daisyui`, `--no-skill`.
- `avoid_conflicts: true` also drops `theme_toggle`, which Phoenix 1.8's generated `Layouts` defines.

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
