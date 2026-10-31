# Changelog

## 0.8.14

- `card_table`: `title`, `description` and `<:actions>` draw a heading above the table (title, line under it, buttons at the right), so a list no longer needs a card around it just to say what it is.
- `card_table`: with no rows the column titles are hidden and the empty message sits in a dashed box, so the table no longer shows headers over nothing.

## 0.8.13

- Dark theme: the default `card` (and `kpi_card`) is one step lighter, `navy-600` instead of `navy-700`, with a `navy-450` edge, so it no longer melts into a page painted `navy-700`. `kpi_card` also gets a thin `navy-450` ring in dark. The tinted variants and the panels inside a card are unchanged.

## 0.8.12

- Dark theme: the row lines of a table inside a card disappeared on the lighter panels of 0.8.11 (both were about `rgb(57 71 100)`). Inside a `.card` the row lines and cell borders of any table (`table/1`, `data_table`) are now white at 9%. Outside a card and in light nothing changes.

## 0.8.11

- Dark theme: the tinted cards (`soft`, `muted`, `filled`) were one faint step from the page and their edges disappeared (about 1.06:1). The tints are stronger (`soft` 9% to 12%, `muted` and `filled` 16% to 20%, edges 26 to 38% and 34 to 45% in dark; light gets the same small raise), and a tinted card inside another tinted card now has its own fill: level 2 is recessed (`rgb(0 0 0 / .18)` in dark) and level 3 is raised again, each with an edge, so a list box inside a card and the rows inside the box can all be told apart.

## 0.8.10

- `card_table`: a panel opened with the mouse closes 350 ms after the pointer leaves the row and the panel (the delay also crosses the gap between them), and stays while the pointer is on it, text is selected in it or the focus is inside it. Opened with Enter or Space it stays until `Esc`, a click outside or another row.

## 0.8.9

- `card_table`: the panel of a row is now a small popover you can use. A click on the row (any part that is not a control, or Enter and Space) opens it and it stays until you close it with `Esc`, a click outside or another row; every line has a copy button with a tooltip (`copy_label`, `copied_label`, `panel_label`); using a control of the row (the action menu, a checkbox) closes it, so it never competes with a dropdown. It no longer closes when the mouse leaves. **Needs the `LineaUI.CardTable` hook** (`...LineaHooks`) and a rebuilt JS bundle.

## 0.8.8

- `card_table`: the panel of a row (the `detail` slots, or the columns that left) opens when the row is clicked or reached with Tab, instead of on hover; it closes when the mouse leaves the row or the open row is clicked again (the new `LineaUI.CardTable` hook), and the open row stays above the row the mouse moves over. The copy button keeps its hover tooltip.

## 0.8.7

- `card_table`: `<:detail label=...>` slots make the panel of a pointed-at row list exactly those lines at every width above 520px (the board's "Prazo", "Recebido em", "AFM"), not only the columns that left; and a column with `copy` (a function of the row) becomes a copy button with a tooltip (`copy_label`, `copied_label`), with its content visible only in the card.

## 0.8.6

- `notification_center` and `kanban_column`: the empty state draws the LineOne illustration (a girl with a box, the new `empty_box`) instead of an icon; `kanban_column`'s `<:empty icon=...>` still shows an icon.

## 0.8.5

New components, from the design refinement:

- `kpi_card`: a metric card with the figure, the change since the last period (`trend`, `delta_tone`), a sparkline or bars drawn as SVG, a goal bar and a loading state.
- `rating` and `rating_distribution`: read-only stars with fractional values, an interactive radio group (`field`, `on_change`) and the bars of how the notes were given.
- `notification_center`: a bell with an unread dot and a popover of tabs, grouped items, read-all, footer and empty state (`on_read_all`, `on_read`, `on_change`).

Refinements:

- `table` and `data_table`: `scroll_label`, `sort_label` and `row_label` name the scrolling region, the sort buttons and the row checkboxes for screen readers.
- `chart`: the `brl`, `brl_thousands` and `number_br` formatters, `chart.defaultLocale` for month and day names, and a keyboard cursor (arrows, Home, End, Esc) on cartesian charts.
- `avatar_group`: `spread` opens the pile on hover and focus; `label` names the group.
- `email_layout`: a `:secondary` button slot beside the main one.
- `timeline_day`: a day separator ("Hoje", "Ontem") on the line of a timeline.
- `tree_item`: `selected`, `aria-expanded` on the branches and truncated labels.
- `pagination`: `page_label` names each page link; the gap is hidden from screen readers.
- `otp_input`: `state="success"` for a verified code. `input_group_addon`: `size`. `radio_group`: the radios take the error border when `errors` is set.
- `clipboard`: `copied_label` shows the green "copied" state; `icon` adds the copy icon (a check while copied) and `icon_only` makes a square button for a snippet; `clipboard_input` takes `copied_label` and `icon` too. `spinner`: the elastic timing was invalid CSS, and `prefers-reduced-motion` is respected.
- `textarea`: `counter`, `min_length`, `autogrow` and `max_rows`, a character counter (warns near the limit, red past it) and a height that follows the text, with no server round trip. `checkbox` and `checkbox_group` take the error border when `errors` is set.
- `tag` follows the design (28px tall, 8px radius, 12.5px text, focus ring) and no longer shares its box with `badge`. **Visible change:** tags in an app get a new size and radius, so check the screens that use them. `tooltip` is a little smaller (12.5px text, 6px radius).
- `toast`: `steps` and `step` make a batch toast that updates in place under the same `id`. `fab_dial`: a speed-dial of labeled actions, opened by click or keyboard.
- `chart`: `table_toggle` swaps the drawing for its data table; `legend.showValue` and `legend.showPercent` write "524 · 42%" after each name; the arrow keys also move between the slices of a donut or pie and the spokes of a radar. Fixed the keyboard cursor of cartesian charts, which raised a TypeError.
- Keyboard focus rings on `collapse`, `breadcrumb`, `pagination`, `treeview` and the kanban card.

Refinements from the second pass over the design canvas, artboard by artboard:

- `dropdown_search` is an inset field (8px margins, 32px high, 6px radius, full border) instead of a full-width bar; `dropdown_header` takes a `subtitle`; `dropdown_item` takes a `shortcut` (mono 11px text at the end of the row); default rows are 34px high, the menu box has an 8px radius and 4px vertical padding, and a disabled item is at 55% opacity.
- `popover`: the dialog has an accessible name (`aria-labelledby` the title, or the new `label` attr), the card is 272px wide by default (`class` overrides it) and the title is 15px.
- Tooltip: the solid colors use the darker shades on a light page (white text was weak on the lighter ones) and the lighter tokens in dark mode.
- `collapse`: the chevron is 16px with a 2px stroke in a softer color; new `variant` (`framed`, `flat`, `section`) and `panel_class`. `accordion`: the `primary` style with `color="warning"` has near-black text and chevron.
- `scroll_area`: a `focusable` box shows a 2px focus ring, and a new `label` makes it a named `role="region"`.
- `bulk_bar`: new `show_esc` writes an `Esc` chip in the close button; a `disabled` action is `aria-disabled` (still focusable) and renders no `phx-*` bindings; the docs no longer claim that `danger` actions ask for confirmation.
- `timeline_item` `variant="icon"` is a disc tinted 13% with its color and ringed by 1px of it; the line is 2px and stops at the last item; `ping` respects `prefers-reduced-motion`.
- New `skeleton_group/1`: `role="status"`, `aria-busy="true"` and a screen-reader-only `label`. The skeleton wave and pulse stop for `prefers-reduced-motion`, and the wave highlight is white 65% in light and white 7% in dark.
- `spinner`: the inner svg of the `svg` variant is `aria-hidden`; the ring turns in 0.75s and the grow dot pulses in 1s; the moduledoc shows the in-button and overlay patterns.
- `tag`: **visible change:** `active` is now a solid primary fill with white text and a primary border for every variant (it was a tinted primary); new `count` attr draws a small pill with a number inside the tag.
- `avatar_group`: new `overlap="auto"` (a fifth of the `size`); the avatar under the pointer lifts 2px; the "+N" avatar has an inset 1px border; new `hidden` list (with the group `id`) makes the "+N" avatar a button that opens a popover listing the people that did not fit.
- `breadcrumb`: the current page is in the soft text color and is cut with an ellipsis when long (items take a `title`); bordered links use 8px/5px padding.
- `card_table`: a row without `status` still draws the 3px left bar, in the neutral border color. `carousel`: the previous arrow comes before the next one in the DOM, and both use `aria-controls` on the track.
- `kanban_column`: new `limit` attr: over the limit the pill (the count, tinted red with a ring) and the bar turn red, `data-wip="exceeded"` is set, and the stats line stays as given (write `meta="limite de 3 em andamento" total="4 de 3"`); a `disabled` column is drawn at 60% opacity; the board is a `role="group"`.
- Typography: **visible change:** a `display` heading is semibold unless `weight` is given; `text_link` keeps the weight of the text around it and has a 1px underline; `inline_code` is mono 12.5px in the primary text color; `kbd` is mono 11.5px with an inset border and a 1px bottom shadow (the command palette and the shell use it too).
- `timer`: new `format="hh:mm"`. `treeview`: 16px chevron and a 4px gap in nested groups. `mask` lists its nine shapes; `signature_pad` documents its dark surface.
- `upload`: dragging over a bordered pond turns its border primary; the plain panel in dark uses the navy surface; the drop label has a focus ring; `upload_button/1` has `disabled` and a focus outline; `error_texts` can use `%{max}`.
- `email_layout/1`: the 16px gap above the footer sits between the card and the footer panel, and a `:note` takes an optional `icon` (an absolute http or https URL).
- `text_editor`: a "/" menu entry whose `key` is not a built-in block removes the typed "/…" and pushes the new `on_slash` event with `%{"id", "key"}`.
- `chart`: pointing at or tabbing to a legend entry puts its series in front (the others dim, a donut or pie slice grows); the entries have a focus ring.
- `data_table/1` and `table/1`: new `select_all_label`, `select_label`; `sort_label` also accepts a template with `%{label}`; `data_table/1` takes `page_label` and `summary_label` (`%{from}`, `%{to}`, `%{total}`). The `grid` search box has a magnifier icon and is 36px high. **Visible change:** a sortable header button is as wide as its content with the arrow next to the label, a hover pill and a focus ring, instead of stretching over the cell.
- Toast: a `color: :dark` card with no `kind` leads with a 10px dot with a halo.
- `input_group`: `size`, `errors`, `help` and `state`; the row is a `role="group"` named by its caption. `textarea`: focus is a primary border with a 3px glow, a disabled one keeps its border at 60% opacity. `tags_input`: at `max` the input is disabled with a `limit_placeholder` and a `3 / 3` counter, the create row shows an Enter hint and curly quotes, and the `:option` and `:item` slots are forwarded.
- `select`: the pillbox is 38px at `md` and a chosen option shows its check in a 16px slot before the label. `error/1` has `role="alert"`; the green `help_text` has a check-circle icon. `number_input`: with `steppers` the field is 40px and, with `align="center"`, the suffix sits next to the value. `phone_input`: a divider between the picker and the number, a country list as wide as the field and area codes in the list. `radio_group`: the `md` radio is 18px and `card` options have a 3px ring.
- `autocomplete`: the typed text is bold primary inside each suggestion; the loading row has a spinner and `role="status"`; the clear control is a real 22px `<button>` (`clear_label`).
- `date_picker`: a named dialog, real month buttons, a `role="grid"` of days with `aria-selected`/`aria-current` and the datetime picker's keyboard (arrows, Home/End, Page Up/Down, Enter/Space, Esc); new `labels` attribute. `time_picker`: the arrows and the AM/PM toggle are named buttons, a step that `min_time`/`max_time` stops is `aria-disabled`; new `labels` and `locale`.
- `datetime_picker`: a Cancel button in the footer, closed times struck through, today marked with a dot. `calendar`: title and arrows at the left, Today and the view switch at the right; the selected day is a 1.5px ring; month cells are 112px; the week view tints today and gives blocks a 3px left border; solid legend swatches; the "more" button reads "+2 more" with an `aria-label`.
- `table` / `data_table`: a `:col` takes `priority` (1, 2, 3) and leaves, header, cells and `:foot` cells together, when the table's own box is narrower than 720, 560 and 420px (container query); without a priority nothing changes and the wrapper is not a container. `container` makes the wrapper a container for a hand-written table, and the class `table-narrow-hide` hides an avatar or icon inside a cell under 420px.
- `time_picker`: the popup is a card with the hour and the minute as stacked columns (an up arrow, a number box and a down arrow each) and an AM/PM button beside them, with the arrows in Tab order and dimmed when `min_time` or `max_time` stop them.
- `datetime_picker`: the header of each month has a month button and a year button that open a grid of the twelve months and a page of twelve years (arrow keys, Home/End, `Esc` back to the days, months and years closed by `min`/`max` dimmed); the buttons are named by the new `datetime_choose_month` and `datetime_choose_year` labels, translated in pt_BR.
- `phone_input`: **visible change:** the button and the list rows show the ISO code (`BR +55`, `PT Portugal +351` with a mono code) instead of flag emoji, which Windows does not draw; `flags` brings the emoji back.
- `radio_group`: `variant="segmented"`, a segmented control made of real radios (form value, `field`, errors, per-option `count` and `disabled`, arrow keys and focus ring), sharing the track and sizes of `segmented`.
- `chart`: the cursor tells the page where it is: the chart element dispatches a bubbling `linea:chart:cursor` event (`detail`: `index`, `label` and the formatted `values` per series, or `null` when the cursor leaves) for the pointer and the arrow keys alike. `summary` writes a line above the plot with the label as a chip and one `name value` per series, resting on the last point with data when the cursor leaves. `on_cursor="event"` pushes the cursor to the LiveView (to `phx-target` when set), throttled to 100 ms and off by default.
- `text_editor`: opt-in `image`, `variable` and `mark` toolbar buttons (add them to a `toolbar` group). `image` opens an inline field for the address and description of a picture and inserts an `<img src alt>`; with `on_image` the event is pushed instead so the app can upload, and `TextEditor.insert_image/4` inserts the resulting URL. `variable` opens a menu of `variables` and inserts the chip. `mark` toggles a highlight (`<mark>`), also in dark mode. The HTML cleaning keeps `<mark>`, and `<img>` only in editors with the image button, `on_image` or `images`, with an `http(s)` or relative `src` (never `data:` or `javascript:`). `tool_labels` overrides the accessible names of the toolbar buttons.
- `textarea`: with a caption, help or errors the `counter` sits on the same row as them, at the right (`field/1` has a new `:aside` slot for it); alone it stays under the control.
- `accordion`: the divider between the items of the `primary` style is the color of the frame mixed 55% with white (it was a fixed shade). `dropdown_item` `color="primary"`: the text is primary and the hover is the same neutral fill as the other items, not a solid primary.
- `data_table`: the pagers use the same window as `pagination` (the current page, its neighbours, the ends and a gap where pages are left out) instead of five consecutive pages.
- `timer`: the time of the `md` ring is 26px, a size that fits `hh:mm:ss` inside the ring (`sm` 20px, `lg` 34px). The year button of the `datetime_picker` is called "Ano" in pt_BR.
- `datetime_picker`: new `layout` (`auto` by default, `compact`): `compact` always uses the narrow panel (one month and a Select button), for a picker in a sidebar or a modal; `auto` still follows the width of the screen.
- `mask`: new `label` for a block mask: it makes the block a named `role="img"`; without it the block stays plain content, so the text inside is still read.
- `table` and `data_table`: opt-in `peek` shows a panel with the label and value of the columns hidden by `priority` when a row is hovered or focused (the row gets `tabindex="0"`, the panel is a `role="group"` named by `peek_label`, drawn only while the container hides columns, opening upward for the last rows). Nothing changes without `peek`.
- `input` `mask="numeral"`: `prefix` (`"R$ "`) shows before the figure and stays out of the raw value, as `blocks` already did.

Third pass, from comparing the design canvas with the screen (preview pages `*_canvas`):

- `radio_group`: a radio shows the keyboard focus as a 2px ring (primary, accent in dark); an unchecked `chip` is `navy-500` in dark. `phone_input`: while the list is open the number's border takes the focus color and the list's search is a boxed field.
- `autocomplete` and `tags_input`: an option given as a map can carry `hint:` (a dimmed note at the right of the row). `autocomplete`: the clear button stays visible while there is a value, the icon prefix stays on the line, the rows have no check column, `sm` and `lg` are 32 and 44px, and while the server searches only the loading row shows. `tags_input`: `create_position` and `compact`; the `max` counter sits at the right of the help line; a disabled field draws its tags without remove buttons. `autocomplete`, `tags_input` and `select`: a field with errors draws a red border and focus ring; the disabled control keeps the dark surface in dark mode.
- `timeline`: `density="compact"` gives the canvas look (22px between items, a 13.5px semibold title, a 13px muted description, a 4px gap between a point and the line); `timeline_item` takes a `:details` slot for a description with markup.
- `datetime_picker`: the panel follows the canvas (uppercase weekdays, dim days of the neighbouring months, a 120px time list with the closed times struck through, a range footer with a start and an end and a bar with Cancel and the confirm button, a 12px-radius card, icon sized by `size`, a focus glow). `time_picker`: **visible change:** the 12-hour input shows `9:30 AM` instead of `09:30` (pass `display_format="H:i"` to keep the old text); the popup opens 6px under the input; the buttons show a focus outline. `date_picker` and `time_picker`: a disabled input is dimmed, an error is red in dark mode, the focus shows a glow.
- `date_picker`: new `skin="linea"`, a compact 300px calendar with the month and year as buttons, 36px rounded days, a dot under today, a continuous range band and pill presets. `calendar`: the week view has 44px hour rows, blocks inset by 2px with a bold title, an all-day row with no today tint; events of a day keep the order they came in; an outlined Today and square arrows; stronger grid lines.
- `framed_sidebar`: new `rail_workspace` (the workspace switcher); item text is slate-600 in light and navy-50 on hover and active in dark; the search and the mark take the panel color in dark; the badge and the collapsed dot use the error red of each theme; the rail tooltip is inverse. `page_header` (`variant="page"`): crumbs with a link are quiet grey with an ink hover.
- `upload`: the drop panel, the list and the errors sit in a wrapper, so the errors show in full color under the panel; the drop label and the remove icon are smaller, the circle layout dims the picture while it uploads, file sizes drop a useless ".0", and the `upload_button` focus ring shows. `button`: `loading` disables the button, marks it `aria-busy` and shows a small spinner before the label (`loading_label` names it).
- `chart`: `plotOptions.bar.dataLabels.position: "end"` writes the value past the end of a row bar; the category labels of a row chart show all of them; the minimum gap between column labels is 4px (was 10px); `donut.labels.layout: "figure"` and `labels.value.showPercent`; new `total_br` formatter; `legend.layout: "table"`; candlestick and bar charts on a date axis print dates; a date formatter that reads `opts.dateFormatter` no longer breaks the whole chart; `table_toggle` takes a `class`. `kpi_card`: `spark_type="area"` bleeds a faded area behind the text.
- `kanban_card`: new `grip` attr (the six-dot handle shown on hover and focus); the funnel colors, the dark column ring on a `navy-900` well, the empty state and the lifted ghost follow the canvas; the drop placeholder (`.linea-drop-slot`) is a neutral gray dashed block in every sortable list. `popover`: the card has the canvas border and soft shadow. `tooltip`: the neutral tooltip, its arrow and the `content` card are `navy-600` in dark.
- `accordion`: the sizes of the canvas (15px triggers, 10px frames, 13.5px panel text; basic and border-bottom rows are rounded boxes on hover and focus; a white chevron and focus ring on `primary`); new `trigger_class` on `accordion_item`. **Visible change:** accordions get new sizes. `breadcrumb`: a bordered link is 24px tall with an inset 1px shadow, links are rounded, the chevron is in the softer color. `pagination`: item labels are 12.5, 13.5 and 14.5px, the numbers of the summary are semibold, the page-size select looks like the canvas button.
- `data_table` and `table`: the `data` and `data-grid` variants are the look of `data_table/1` (40px headers, 48px rows, 16px checkboxes, thin arrow sort icons, a lavender selection with no left bar, a 10px frame with cell borders for the grid); new `wrapper_class` on `data_table`; the page gap is `...`. **Visible change:** every `data_table` gets the new look; `table/1` keeps its variants. `table_skeleton`: `shapes` per column. `empty_state`: `variant="table"`.

Review pass:

- `timeline`: the neutral point (solid, outline, icon, ping) is darker, as in the canvas (`slate-500`, `navy-200` in the dark). **Visible change.**
- `select` (`multiple`, `removable`) and `tags_input`: a disabled field draws its chips without remove buttons.
- `calendar`: in `pt_BR` the month abbreviations of a week title are lowercase (`23 out – 29 out 2026`).
- `avatar_group`: an empty `hidden` list or `more={0}` no longer draws a "+0" avatar.
- `input_group`: without an `id` the caption's id comes from the label; give each group an `id` when two share a label.
- `table`/`data_table` `peek`: the hidden columns are rendered again inside the panel, so do not put ids in cells that are hidden by priority.
- `input` mask `numeral`: a `prefix` holding the decimal mark or a digit (`"S/. "`, `"+1 "`) is no longer read back as part of the number.
- `text_editor`: a custom slash command named like an object property (`constructor`) is no longer taken for a built-in.

## 0.8.4

- `card_table`: a compact table of row cards for long lists. It answers to its own width (a container query): the columns leave by `priority` at 1180, 960 and 720px, what left shows in a panel when the row is pointed at, and below 520px each row is a card of three lines placed by the `role` of its columns. It has row selection, sortable headers, a status bar per row and a stream-friendly empty state.
- Table: the scrolling wrapper is `relative`, so an absolute child of a wide table (the `sr-only` label of the actions column) no longer escapes the clip and makes the page around it scroll sideways, which hid the start of the content behind the framed menu.
- Toast: in a closed pile the cards behind the newest draw no text (`data-behind`), so their titles can no longer show through and overlap the front card when several toasts come at once.

## 0.8.3

- `select` pillbox: the `+N` chip has room: wider padding, a minimum width, the count centered, and a margin before the field to type in, so it is no longer squeezed against the caret.

## 0.8.2

- `connection_banner/1` is a toast now (a `loading` one with the `aura` ring, shown by `phx-disconnected` and dismissed by `phx-connected`) instead of its own pill; it needs the page's `<.toaster>`. The `position` attribute is gone: the toaster's position applies.

- `rail_user/1`: the person block of the framed menu is as wide as the rail whatever the name (the dropdown and button around it are stretched, the separator spans the rail) and a long name is cut with an ellipsis, instead of growing with it.

## 0.8.1

- `connection_banner/1`: a pill with a spinner and a glowing `aura/1` ring that shows while the LiveView socket is down (`phx-disconnected`) and hides when it is back (`phx-connected`), at the top or the bottom. No JavaScript of its own; put it once in the root layout.
- `framed_sidebar/1`: the `:search` slot declares its attributes (`id`, `class`, `title`, `aria-label`, `phx-click`, `phx-target`), so using them no longer warns at compile time; `class` merges into the box.
- `bulk_bar/1`: the `:action` slot declares `id`, `title`, `aria-label`, `phx-click`, `phx-target`, `phx-disable-with` and `phx-value-id`, so a button with `phx-click` no longer warns at compile time.

## 0.8.0

- `framed_sidebar/1`: the `:search` slot takes attributes (`phx-click`, `id`, `aria-label`...); with any, the search box is one `<button class="rail-search-button">` instead of a `div`, so the whole box opens your search or command palette without wrapping its children in a button of your own (which centered the text and left the icon at the edge of the rail). The text is left aligned, the shortcut sits at the right, the icon is centered in the collapsed rail, and the box has a hover and a focus ring.
- New `email_layout/1` and its helpers `email_p/1`, `email_code/1`, `email_facts/1` and `email_steps/1` (`LineaUI.Components.Email`): the transactional e-mail of the design system. A whole HTML document for mail clients (tables, every style inline, 520px): the logo and `brand`, a card with an icon `:badge`, an `eyebrow`, a `title`, the `:body`, a main `:action` button with its address spelled out, a `:note` and a `:footer`. `theme` is `:auto` (follows `prefers-color-scheme` through `em-*` hook classes), `:light` or `:dark`; an address that is not http or https becomes `#`. The helpers: a code in boxes, label and value rows (`:mono`, `:total`) and a row of done or to-come steps.
- New `bulk_bar/1`: the floating bar of bulk actions for a table with selection (the Signetum design system's `BulkBar`). A badge with the count and a label (`label` and `label_plural`, nothing is pluralized here), a `:field` slot for a control skinned as a quiet field (a `select` there opens upwards while the bar floats), `:action` buttons (`variant` `default`, `primary`, `danger`; `icon`; `disabled`; any `phx-*` or `data-*` goes to the button), a `select all N` link (`total`, `on_select_all`, `select_all_label`) and a close that runs `on_clear`; Esc presses it (hook `LineaUI.BulkBar`, logic in `bulk_bar_logic.js`). `variant` is `inverse` (the opposite of the page) or `soft`; `floating` pins it to the bottom center, `floating={false}` lays it out in place. It renders only while `count` is above zero and is a labelled region that announces the count.
- An icon and its text no longer touch in `dropdown_item` (both variants), `menu_list`, `tabs`, `alert`, `breadcrumb`, `choice`, `accordion` and `divider`: they used `space-x-*`, which skips a text node and left the icon without a margin, so they now use `gap-*`.
- A multiple listbox `select` takes `prompt` as its placeholder when it has no `placeholder` (`prompt` was ignored there, leaving an empty control).
- A pillbox no longer asks its parent for the width of its chips (`contain: inline-size`), so a grid or flex row cannot widen its column because of them.

## 0.7.2

- `clearable` on a single `select/1`: the clear button no longer sits on top of the chevron; it is 2.25rem from the right edge, beside it.

## 0.7.1

- A pillbox (`select multiple`, the default `overflow="count"`) is as tall as an input of its size (`sm` 2rem, `md` 2.25rem, `lg` 3rem) and never grows, so a row of fields stays level; it draws a chevron, and its placeholder hides while there are chips.
- `clearable` on `select/1`: the clear button is a small SVG cross in a round hit area (it was a text glyph), beside the chevron, shown on hover or focus while there is a choice. It has `role="button"` and an `aria-label` (`clear_label`).
- `.btn` has `gap-2`: an icon and a label inside any `button` no longer touch.

## 0.7.0

(Includes the 0.6.3 toast work if you skipped it: plain notes are soft cards with an icon.)

- `select/1` with `multiple` is now a pillbox by default (`overflow="count"`): the control stays on one line and never grows; the chips that do not fit are hidden and a `+N` chip (its `title` lists the hidden labels) tells how many. It refits when chips are added or removed and when the control is resized. **Behavior change:** pass `overflow="wrap"` for the old look, chips breaking into more lines. `tags_input/1` still wraps.
- The chips of `select/1` and `tags_input/1` no longer draw tom-select's vertical divider before the `×`; the `×` is a quiet icon that darkens, with a soft background, on hover.
- Pillbox details: a chip is cut at 150px with an ellipsis (`.item-text`; the `×` stays); the `+N` chip is outlined and carries an `aria-label` (`3 more: Pix, Boleto…`, the word is `more_label`); `size="sm"` is now also the compact 32px listbox for filter bars; `footer` (with `footer_count` and `footer_hint`, `\"%{count} of %{total}\"` and `\"Esc to close\"` by default) draws a line under the list of a `multiple` select with how many are chosen.

## 0.6.3

(0.6.2 shipped the first pass of this restyle; this is the finished one.)


- The plain toast note (no `kind`, `description`, `actions`...) is now a soft rounded card instead of a solid colored box: white on a light page, navy on a dark one, and every `color` (`primary secondary info success warning error`) tints the card, its edge and its text toward that color (`light` and `dark` stay neutral), with the kind's icon at the left (info for `primary`, `secondary` and `info`; none for the neutral ones), an 8px radius and the countdown along the bottom edge. `invert` now works on plain notes too: a navy card on a light page, a white one on a dark page, keeping the tint.

## 0.6.1

- Dragging no longer draws a 2px primary outline around the list under the pointer. The `[data-list][data-over]` rule is gone from `sortable.css`; the hook still sets `data-over`, and the kanban column only tints its background. The dimmed card and the insertion line stay.
- `LineaUI.Sortable` drags on pointer events for mouse, pen and finger alike: no browser drag image any more (`kanban_card` is no longer `draggable`). A mouse or a pen starts after about 4px of movement (a click, a link or a button in the item still works; the click that ends a drag is swallowed), a finger after a 220ms hold. The item is copied into a floating ghost on the body (`.linea-drag-ghost`: lifted with a rotate and scale, a big soft shadow, leaning up to 6deg towards the movement, easing after the pointer) that glides into the slot on a drop and flies back on a cancel (Escape cancels too); the original stays as a quiet dashed placeholder (`[data-dragging]`, `opacity .35`). The insertion line is gone: the items of the list under the pointer at or after the insertion index slide away with a `transform` (visual only, the DOM is never reordered) and a dashed rounded placeholder (`.linea-drop-slot`) shows in the gap, which follows the pointer from item to item and across columns. Boards and lists under the pointer auto-scroll near their edges, with a finger too. `prefers-reduced-motion` turns the tilt and the animations off. `kanban_column` marks its empty state with `data-empty`. The `data-*` attributes and the `%{"id", "from", "to", "index"}` payload are unchanged.

## 0.6.0

- **Breaking for charts:** `chart/1` draws its charts itself, so ApexCharts is no longer needed (drop `window.ApexCharts`). `options` keeps the ApexCharts shape, but only the subset in the moduledoc is drawn; the rest is ignored. Combo charts, annotations and several y axes are not supported.
- New `otp_input/1`: a one-time code of single-character boxes. Typing moves to the next box, Backspace on an empty box goes back, the arrows, Home and End move, and a paste or an autofill spreads over the boxes (a text as long as the code always starts at the first). The code is submitted through a hidden input named like the field, which fires `input` so `phx-change` runs. `length` (default 6), `mode` (`numeric` or `alphanumeric`), `size` (`sm md lg`; `md` is the 54px box of the Signetum canvas), `mask` (dots), `separator` (a dash after a position, or a list of positions), `autofocus`, `disabled`, `on_complete` and `target` (pushed with `%{"id", "name", "value"}` when every box is filled), `field`, `label`, `help`, `errors`, `aria_label` and `digit_label`. The group has `role="group"` and every box an accessible name and `autocomplete="one-time-code"`. Hook `LineaUI.Otp`; its pure logic is in `assets/js/linea_ui/lib/otp_logic.js`.
- `scroll_area`: `stick_bottom` keeps a box that grows at its end (a chat, a stream of replies) scrolled to it while the reader has not scrolled up, with the new hook `LineaUI.ScrollBottom`. It needs a stable `id`.
- `right_sidebar`: `persist_tab` remembers, for the session, the control with `data-tab` that was clicked last and clicks it again when the drawer mounts, so the drawer reopens on the panel the person chose after a live navigation. The `sessionStorage` key is derived from the drawer's `id`.
- New hook `LineaUI.Sortable`: drag and drop of items inside and between lists with the browser's own drag and drop, no library (so no SortableJS in the app). A list is an element with `data-list` (its id), its items are its children with `data-id`; lists with the same `data-group` exchange items. A drop pushes `data-event` (to `data-target` when given, else the LiveView) with `%{"id", "from", "to", "index"}`, and nothing is pushed when the item lands where it was. Optional `data-handle` (a selector), `data-axis` (`x` for a row of items) and `data-disabled`; the hook element can be a single list or hold several. The browser never moves the DOM: the dragged item gets `data-dragging`, the list under the pointer `data-over` and a line shows the slot, so the server's render is the new order. A finger holds an item for a moment and then drags it (pointer events, with a floating copy); the board does not auto-scroll under a finger. Defaults in `assets/css/parts/sortable.css`.
- New `kanban/1`, `kanban_column/1`, `kanban_card/1` and `kanban_lost/1`: the Signetum canvas's sales funnel board (a scrolling row of 272px tinted columns with the icon tile, count pill, meta and total line, 4px progress bar, empty state and footer, white cards with the warning ring, the 52px "lost" aside). The board is one `LineaUI.Sortable` (`event`, `target`, `group`, `disabled`). A kanban of another look, and a plain sortable list such as a to-do list, use the hook alone.
- `chart` no longer needs ApexCharts: the package draws every chart itself, as SVG, with a native engine (`assets/js/linea_ui/lib/chart_*.js`, hook `LineaUI.Chart`), so the app installs no JavaScript library. **Remove `apexcharts` from the app's `package.json` and the `window.ApexCharts = ...` line from `app.js`**; `data-state` (`ready`/`waiting`) is gone with it. The component, `options` (ApexCharts-shaped), `formatters`, the `linea:chart` push event (new `series` are laid over the current ones by position, `options` are merged in) and the `linea:chart:options` DOM event work as before. The supported options are listed in the `LineaUI.Components.Chart` docs; anything else is ignored.
- Charts: `line`, `area`, `bar` (columns and rows; grouped, stacked, 100%, distributed; rounded), `rangeBar`, `candlestick`, `donut`, `pie`, `radialBar` (gauges, half circles, totals) and `radar`, with value, category and date axes, grid, legend (a click hides the series), shared and single tooltips with crosshair, hover markers and axis bubbles, data labels, gradients, drop shadow and sparklines. Layout margins follow ApexCharts' so options tuned with negative `grid.padding` land in the same place.
- Charts draw into an SVG with a title, a description and a hidden table of the data; the first draw plays a short entry animation that is skipped under `prefers-reduced-motion`. The look is in `assets/css/parts/data.css` (`.linea-chart-*`, replacing the `.apexcharts-*` rules; `ax-transparent-gridline` and `ax-rounded-b-lg` still work).
- `chart.width` sizes the chart element; `chart.animations.enabled: false` turns the entry animation off.

## 0.5.0

- **Breaking:** `datetime_picker/1` is now the new component below, not the flatpickr one of `date_picker`. It still takes `name`, `field`, `placeholder`, `min_time`, `max_time` and, as aliases, `time_24hr`, `minute_step` and `default_hour`, but the value is a wall-clock `2026-10-14T10:30` (it was `2026-10-14 10:30`) and the panel is the new one.
- `select` (listbox): an option map takes `keywords:` (a string or a list), extra terms the search matches though the list does not show them.
- `heading`: `size` (`sm base lg xl 2xl 3xl`) sets the type size apart from the level.
- Toasts: `invert` (on the toaster, or `invert: true` on one toast) reverses the colors of the cards: a dark card on a light page and a light card on a dark one, with the kind's tint kept. Like Flux's inverted toasts.
- Toasts: every toast leaves by itself after its `duration` and draws a thin countdown line at its bottom (`timer: false` on a toast or `timer={false}` on the toaster turns it off; the pointer over the stack holds it). A toast that depends on the person now stays until it is closed, with a close button and no line: one with `actions`, one with a `template`, one with `aura: :glow` (a `loading` or running progress toast already did). An explicit `duration` wins. A plain toast that stays now gets its close button too.
- `card` rebuilt on composable parts, in the proportions of Flux UI's card: new `card_header/1` (with `card_heading/1` in `base`, `lg` and `xl`, any `level`, `card_subheading/1` and `card_actions/1`), `card_body/1`, `card_footer/1` (supporting text and actions, or a heading, subheading and actions like a header) and `card_bleed/1`. New `body` (`seamless`, `divided` with `divider="inset"`, `separated`, `inset`, `flush`), `size` (`xs`, `sm`, `md`, `lg`) and `highlight` attrs, and the surfaces `outline`, `muted`, `soft` and `filled` (tints that adapt to the color behind them; the `inset` and `flush` panel is raised on a tinted card and recessed on a plain one). Actions sit in the corner centered on the heading, before the heading they go to the leading side, and small buttons hang in the padding without making the header taller; inset corners are concentric with the card's; an image or a `table` with `bleed` reaches the panel's sides, its top and bottom when first or last, and rounds only the corners it touches. Headers and footers also work outside a card (`size` sets their type) and nested in a body. The card now has a 1px edge and the default `md` padding is 1.5rem. The rules live in `assets/css/parts/card.css`.
- New `phone_input/1`: a phone number field with a country picker (flag and calling code) beside the number. The picker is a searchable list (by name in pt-BR or English, ISO code and calling code, ignoring accents) with the arrows, Enter and Esc; the number is shown in the national format as it is typed (`(11) 91234-5678`) and the form submits the E.164 number through a hidden input, while an international number typed or pasted switches the country. `country` (default `"BR"`), `country_order`, `countries`, `except`, `locale`, `variant`, `size`, `shape`, `clearable`, `on_country_change`. New `LineaUI.Components.PhoneInput.Format` with `e164/2`, `parse/2`, `national/2` for validating the submitted value on the server; the country table lives in `assets/js/linea_ui/lib/phone_countries.js` and is read by both sides. Hook `LineaUI.PhoneInput`.
- New `datetime_picker`: a date and a time in one panel, with a wall-clock value (`2026-10-14T10:30`, no time zone). A single picker shows the calendar with the list of times beside it (a new day updates the value, a time closes the panel); `mode="range"` shows two months with a start and an end time and applies on "Select range"; on a narrow screen the time becomes a dropdown and a "Select" button confirms. It takes `interval`, `time="input"` (type an exact time, suggestions in a dropdown), `default_time` (`"09:00/17:00"` for a range), `time_format` (12 or 24), `locale`, `min`/`max` (`"now"`, `"today"`, ISO), `min_time`/`max_time` and `unavailable` (days, daily ranges such as `12:00-13:00`, date-times; a comma separated text or a list), the `trigger` slot, `field`, `start_field`/`end_field`, `variant` and `size`. **Breaking:** the flatpickr `datetime_picker` that `date_picker` used to define (and its `time_24hr`, `minute_step` and `default_hour` attrs) is gone, because the two cannot share a name; the new component replaces it. `date_picker` and `time_picker` are unchanged.
- Framed shell (`framed_sidebar`): the collapsed rail scrolls when its icons do not fit the window height, so the user and the settings stay reachable on a short screen. Its tooltips are positioned on the screen (`position: fixed`, set by the `LineaUI.ShellRail` hook on hover and focus) and are no longer clipped by the scrolling list.
- `dropdown` and `dropdown_submenu`: the panel no longer has vertical padding of its own; the items sit flush to its top and bottom (the first and last follow the panel's rounded corners).
- `number_input` with `steppers`: the field now has the same height as the minus and plus buttons. The mono text made it 2px taller than they were.

## 0.4.3

- `fab`: a named slot such as `<:icon>` with no text around it no longer hides the label. The whitespace between the tags
  counted as content and replaced the `label`; now only text that is not blank replaces it.

## 0.4.2

- New `timer/1`: a shift timer that ticks in the browser from a monotonic clock (hook `LineaUI.Timer`, no round trips, no drift in a background tab). `variant="ring"` is the checker card with the progress ring, the state kicker, the mono time and the `actions` slot; `variant="mini"` is the pill with a pulsing dot for a top bar. `direction` up or down, `format` `hms` or `hm`, `elapsed`/`total`/`running` from the server win over the browser's count, `on_toggle`, `on_tick`, `on_finish` events. New `LineaUI.Timer.pause/resume/toggle/add` commands for the buttons, as `%JS{}` or pushed from the socket.
- New `fab/1`: a floating action button that retracts from a navy pill (icon tile and label) to the round bubble.
  `retract` is `hover` (default), `auto` (retracts after `retract_after` ms or on scroll, hook `LineaUI.Fab`), `never` or
  `always`; touch devices show the bubble; `expanded` forces it open from the server. Four corners via `position`,
  colors `assistant`, `primary`, `dark`, `light`, `badge`, link or button. Sits on the new `--linea-z-fab` layer (90, under modals and drawers).
- `filter_menu`: the canvas's filter menu as one component on top of the dropdown. A trigger with the applied count, a row per group that opens a panel of checkbox options with their record counts, flat sections (sort) with radios, and Clear / Apply (n). `mode="apply"` stages until Apply (closing the menu otherwise takes the ticks back), `mode="live"` pushes each tick. Inside a form every option is a real input, so `phx-submit` (and `phx-change` in live mode) get them; `on_change`, `on_apply`, `on_clear` and `target` push `%{"id", "values"}` without one. A `:group` slot takes your own items.
- `dropdown_footer` takes `show_apply` (default `true`) and wraps the number after Apply in `[data-apply-count]`; a `dropdown_submenu` with `data-count-radios` also counts its checked radios. Nothing else in the dropdown changes.

## 0.4.1

- Visual parity with the Signetum canvas, no API changes. `command_palette`: key caps are filled with an inset bottom edge, icon tiles and dividers
  follow the canvas tokens in dark, group labels track `.08em`. `segmented`: 3px tray, the active segment is ink on white
  (`navy-500` in dark) and its count takes the primary color. `empty_state`: 17px title, `slate-800` ink, softer dark rings
  and icon tile. `stepper`: dark to-do markers and bars use `navy-800`, vertical connectors are `slate-150`. `progress`:
  dark track is `navy-800` and the light `warning` fill is `#e68200`.
- `avatar`: initials in Inter semibold on a size ladder of about 36% of the avatar; a presence dot is 30% of the avatar, ringed in the card color, with the success, warning and error shades of the canvas; the "+N" of `avatar_group` is opaque; company, customer and supplier have 10px corners and the company stays navy in dark; the assistant gradient is the same in both themes and its sparkle an outline; the invite placeholder is a solid 1.5px ring.
- `text_editor`: one rounded box with a tinted toolbar of 32px buttons (hover and pressed in the primary soft), group separators, the assistant pill at the end, prose content (Poppins 14/23, headings, lists, code, spaced paragraphs), chips in the primary soft, the "/" menu with the hint under the label and the canvas shadow, a comment bar with a 32px submit; focus draws the primary border.
- `drawer` sheet: 22px side padding, 45% backdrop, flush shadow all around, deep shadow and ring in dark, grab handle without the negative margin, header and footer lines as in the canvas in dark.
Visual parity with the Signetum canvas (markup and classes only; attrs, slots and events are unchanged).

- `calendar`: the toolbar is Today, ghost arrows around the title and a segmented Month/Week switch; Inter 11px weekday heads (`slate-200` / `navy-800`), chips with 4px radius, day numbers aligned left with the round today marker, dark grid lines softened (`navy-600`), tinted legend swatches.
- `signature_pad`: dark pad (`navy-700`) with light ink on screen (the export keeps `ink`), baseline and cross at the canvas offsets, segmented Draw/Type switch, Inter status badge.
- `number_input`: with `steppers`, flat stepper cells with the canvas hover, a mono medium value and the `suffix` drawn inline in the field instead of an addon box.
- `range`: the thumb is white with a 2px ring in the color and a soft shadow, marks are Inter 11px and the chosen one is a tinted pill, more room between track and marks.
- `color_picker`: the hex field has the standard height and an ink-colored value.
- `dropdown`: checkbox, radio and submenu rows are 36px Inter 14px regular with 10px gaps, 4px checkboxes, an uppercase tracked `dropdown_label`, the count badge in Inter 11px and a larger submenu shadow.

## 0.4.0

- `framed_sidebar`: in the collapsed rail the search box is a square with the icon centered; what it hides (`rail-label`, the search text and shortcut) wins over utility classes such as the `kbd`'s own `display`.

- `page_header` `variant="page"` has a `:leading` slot before the breadcrumb, where `rail_toggle/1` collapses the menu from
  the panel's corner. A `rail_module` that is open but does not hold the current page no longer gets the selected pill.
- `page_header` with `clock`: two headers on one page no longer share the clock's id (it comes from `id`, or from the
  title when there is none). `command_palette` `shortcut` accepts `nil` without a compile warning.
- The skill keeps itself current: `mix linea_ui.install` adds the `:linea_ui_skill` compiler to the app's `mix.exs`, and
  a compile after `mix deps.update linea_ui` regenerates `.claude/skills/linea-ui/` when its version is not the
  installed one (nothing happens without a skill, when it is current, or in `:prod`). `LineaUI.Skill` gained
  `version/0`, `installed_version/1` and `write!/1`.
- `toast`: `aura` (`true`, `:dual`, `:glow`; `aura_size` `xs sm lg`; `aura_color`) runs a ring of light around a toast,
  `aura/1` does the same around any element, and a toast with a `value` is a progress toast that fills, turns into a
  success at 100 and leaves by itself (`update_toast(socket, id, value: 64)`). A toast with a `kind`, `description`,
  `actions`, `aura` or `value` is drawn as a surface card (white, `navy-700` in dark, `rounded-xl`, soft shadow) with a
  36px icon tile tinted by the kind, its actions on the right (`variant` `outline solid soft`, `color` `primary error`
  per action), the aura as a 1.5px ring on a track around the card, `bar: true` for a 3px progress bar, and a progress
  toast turned into `kind: :error` as a failure. `color: "dark"` makes the card dark. LineOne's plain colored toast
  (`color:` alone) is unchanged.
- `select`: the list of the listbox (and of `tags_input`) is the surface of the dropdown menu, not Tom Select's flat bar:
  a floating panel (`rounded-lg`, border, soft shadow, 6px padding) with rounded rows, a `slate-100` / `navy-600` hover,
  the chosen option in the primary tone with a check, and headed groups; light and dark. `search` (`control` by default,
  `panel`, `none`) says where the person searches: in the control, in a field on top of the list (`search_placeholder`),
  or nowhere. A click inside the control no longer reaches the listbox twice through its `<label>`.
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

## 0.3.1

- `dropdown` (with `dropdown_submenu`), `popover`: the panel is no longer cut off or covered inside a box that
  scrolls (every `table` sits in a horizontal scroll area, a `drawer` body scrolls) or under an ancestor with a
  `z-index`, `transform` or `filter`. It carries `popover="manual"` and opening it puts it in the browser's top
  layer (`showPopover()`), placed with `position: fixed` coordinates from the trigger's rectangle (flip and shift
  as before), following the window's and every scrolling ancestor's scroll, the window's resize and its own size
  (`ResizeObserver`); it closes when its trigger scrolls out of sight, as Popper's `hide` does. It stays in the
  LiveView's DOM where it is rendered, so patches, `phx-click` on items, `on_open`/`on_close`, keys, outside
  click and Esc are unchanged. Browsers without the Popover API get the same fixed box on `--linea-z-popover`.
- `tooltip`: the hint goes to the top layer the same way, follows scrolling and hides when its trigger scrolls
  out of sight.
- `popover`: the arrow is positioned again (it is `position: absolute` next to the card, as Popper set it).
- `dropdown`: opening it with the keyboard focuses the first (or last) item even while the items' entrance
  transition still has them hidden.
- New `lib/top_layer.js` (`canLift`, `lift`, `drop`, `clippingAncestors`) and, in `lib/anchor_logic.js`,
  `clipsOverflow` and `referenceHidden`, with node tests.
- `range`: `show_value` and `value_format` write the value beside the label, `filled` paints the track up to the thumb,
  `marks` label the track (a click sets the value), `steppers` add minus and plus buttons, `start_field`/`end_field`
  (or `start_name`/`end_name`, `value={{from, to}}`) give two thumbs on one track, and `orientation="vertical"` stands
  it up. The browser keeps all of it in step between round trips (`LineaUI.Range`, `LineaUI.RangePair`); a slider
  without these attrs renders as before.
- `dropdown` filter menu: `dropdown_checkbox` and `dropdown_radio` (`menuitemcheckbox` / `menuitemradio`) toggle without
  closing the menu, with a real input beside them when given a `name` (so `phx-change` and `phx-submit` see them),
  `data-server-checked` so the server wins only when it changes the state, and a muted `count`. `dropdown_submenu`
  takes `count` and the browser keeps its badge in step with the ticked items; `dropdown` takes `keep_submenus`.
  `dropdown_footer` adds Clear (unchecks every checkbox) and Apply (closes the menu, submits the form or runs
  `on_apply`), `dropdown_label` captions a group.
- `signature_pad`: sign with pointer events (mouse, touch, pen) or type a name; the signature leaves as SVG text in a
  hidden input (`field`, `phx-change`, `on_change`), with a Clear button, a ready/empty status, a stored SVG shown
  from `value` and `locale="pt_BR"`.
- `calendar`: a month or week grid (`role="grid"`) with colored event chips and hour blocks, a toolbar with
  previous, today, next and month/week switch, roving-tabindex keyboard navigation (arrows, Home, End, Page Up and
  Page Down, Enter), and `locale="pt_BR"`. The server holds `view` and `date`; the toolbar and the keyboard push
  `on_navigate`, `on_view`, `on_select` and `on_event`. `calendar_range/3` and `calendar_shift/3` help the handlers.
- `color_picker`: a saturation and brightness area (drag or arrow keys), hue and optional opacity sliders, a hex
  field and preset swatches; the form gets `#RRGGBB` (`#RRGGBBAA` with `alpha`) through a hidden input, with
  `field`, `phx-change`, `on_change` and `locale="pt_BR"`.

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
