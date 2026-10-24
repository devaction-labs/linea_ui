# Changelog

## Unreleased

- `drawer`: the design's sheet — `title`, `description` and a `:header` slot with a close button, `:back` and
  `:actions` slots, a scrolling body (`body_class`), a `:footer` slot (end-aligned, top border, tinted bar),
  `size` (`sm` 400px, `md` 560px, `lg` 760px, `xl` 1080px, full width on phones), `placement`, `lock_scroll`.
  A bare drawer renders as before.
- Overlay layers are CSS custom properties (`--linea-z-overlay`, `--linea-z-modal`, `--linea-z-popover`,
  `--linea-z-tooltip`, `--linea-z-toast`) with today's values as defaults; drawers and modals stack in the order
  they open (a modal opened from a drawer is above it), and Esc or a backdrop click closes only the top one.
- `toaster`/toasts: `kind` (`neutral info success warning error loading`) with an icon, `description`, `actions`
  (event, `%JS{}`, link or dismiss), a toast with a known `id` is replaced in place (loading, then the answer),
  `update_toast/3`, `dismiss_toast/1,2`, `clear_toasts/0,1`, `send_toast/2` with the title in the options,
  `duration: :infinity`, `persist_errors` on the toaster. Existing calls are unchanged.
- `dropdown_submenu`: a nested menu that opens to the side on hover, click or →, back with ← or Esc, flipping
  side when the screen has no room.
- `scroll_area`: a box with LineOne's thin scrollbar (6px, transparent track, thumb on hover), vertical,
  horizontal or both; `scrollbar-sm` now also styles Firefox, and `scrollbar-always` keeps the thumb shown.
- `glyph`: `info_circle`, `warning`, `check_circle` and `error_circle`.

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
