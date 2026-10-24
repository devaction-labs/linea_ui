# Changelog

## Unreleased

- `table`: hand-written tables. Without `rows`, `table/1` renders its inner block and new `table_head`,
  `table_body`, `table_row`, `table_cell`, `table_foot`, `table_empty`, `table_checkbox`,
  `table_expand_toggle` and `table_detail_row` take its look: per-row attributes and `on_click`, streams,
  colspans, a totals footer, an empty row that works with streams, detail rows, selection with an
  indeterminate select-all, sortable headers with `aria-sort`. The slot API gains `row_class`, `row_attrs`,
  `sticky_header`, a `:foot` slot and a stream-aware `:empty`; selected rows are tinted with a primary bar.
- `table_skeleton`: placeholder rows in the table's look while it loads.
- `data_table`: passes `row_class`, `row_attrs`, `sticky_header` and `:foot` through to the table.
- `pagination`: `total_entries`/`page_size` add a "Showing 1–15 of 128" summary (text set by `summary`) and
  work out `total_pages`; `page_sizes` adds a rows-per-page select pushing `on_page_size` with
  `%{"page_size" => "30"}`.

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
