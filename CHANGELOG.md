# Changelog

## Unreleased

- `toast`: `aura` (`true`, `:dual`, `:glow`; `aura_size` `xs sm lg`; `aura_color`) runs a ring of light around a toast,
  `aura/1` does the same around any element, and a toast with a `value` is a progress toast that fills, turns into a
  success at 100 and leaves by itself (`update_toast(socket, id, value: 64)`).
- `drawer`: a sheet is `variant="float"` by default (12px margins, 16px corners, the whole height, a fixed footer);
  `variant="flush"` keeps the panel against the edge. `placement="bottom"` is the phone's sheet with a grab handle.
  `sheet_header/1`, `sheet_body/1` and `sheet_footer/1` lay a sheet out by hand.
- `avatar`: `name` (initials, `color="auto"` for a color that is stable per name), pixel sizes `24 32 40 48 64`,
  presence dots (`online away busy offline`), `kind` (`company customer supplier assistant invite`) and
  `avatar_group` `more` for the "+N".
- `text_editor`: `slash` menu, `variables` chips, an `:ai` button (`on_ai`, `insert_html/3`), a `footer` with the word
  count, and `variant="comment"` with `mentions`, `on_submit` and Ctrl+Enter.
- `app_shell`: `layout="framed"` with `framed_sidebar/1`, `rail_link/1`, `rail_module/1`, `rail_toggle/1` and
  `rail_user/1` (a menu that collapses to a 60px rail and is a top bar below 768px); `page_header` `variant="page"`
  with `description`, `clock`, `bell` and the `:badge`, `:notifications` and `:tabs` slots.

## 0.3.0

- `dropdown_item`: a link item takes `target`, `rel`, `download`, `hreflang`, `referrerpolicy` and `replace`, so
  it can open in a new tab or download a file.
- `drawer`: the panel no longer carries `transform-gpu`, so an open drawer is not a containing block for
  `position: fixed`; a modal or confirm rendered inside a drawer now covers the viewport and stacks above it
  (it stays in the LiveView's DOM, so patches keep working).
- `table_head` `:col`, `table_row` `:cell` and `table_foot` `:cell`: attributes they do not use (`id`, `data-*`,
  `phx-*`, `aria-*`, `title`) land on the `<th>`/`<td>`; the slots no longer warn about undeclared attributes.
- `table_skeleton`: covered by a test that its attributes (`data-role`, `phx-*`) reach the `<table>`.
- `date_picker` / `datetime_picker` / `time_picker`: a value that does not parse (not ISO, blank, out of range, not
  a string or date) renders as empty instead of raising; `DatePicker.Shell.format/4` returns `""` for it.
- `tabs`: a `:tab` with `patch`, `navigate` or `href` (and `replace`) renders as a `<.link>` with
  `aria-current="page"` when selected, for navigation tabs; a tab only gets `aria-controls` when a `:panel` with
  its name exists.
- `input`: `:prefix` and `:suffix` take `interactive` (the box takes clicks, for a send or clear button) and
  `class`.
- `select`: the `@doc` explains the native variant as the fixed-choice, non-searchable select.

## 0.2.0

- One-command installer: `mix igniter.install linea_ui` adds the dependency and sets the app up, with the
  diff confirmed by the user. `mix linea_ui.install` is now an Igniter task (`igniter` is an optional
  dependency; without it the task keeps writing the skill and printing the setup lines). It imports the
  fonts and styles in `app.css` (with `@source` for `source(none)`), registers `LineaHooks` in `app.js`,
  adds the fonts' `Plug.Static` to the endpoint, adds `use LineaUI, avoid_conflicts: true` to
  `html_helpers/0`, writes the Claude Code skill and the `AGENTS.md`/`CLAUDE.md` pointer (creating
  `AGENTS.md` when neither exists). Idempotent. Flags: `--hugeicons`, `--replace-daisyui`, `--no-skill`.
- `avoid_conflicts: true` also drops `theme_toggle`, which Phoenix 1.8's generated `Layouts` defines.
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
