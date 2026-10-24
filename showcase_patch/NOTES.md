# Showcase patch: datetime_picker

Copy the six examples into the showcase:

    cp showcase_patch/examples/datetime_picker_*.html.heex \
       ~/ElixirProjects/linea_showcase/lib/linea_showcase_web/examples/

Examples are picked up by file name (`<component>_<nn>.html.heex`, the component being the
`LineaUI.Docs` key `datetime_picker`), so nothing else registers them. Two edits are needed in
the showcase repo:

1. `lib/linea_showcase_web/catalog.ex`: add `datetime_picker` to the `forms` list of
   `@categories`, right after `date_picker`:

       ... phone_input tags_input color_picker date_picker datetime_picker time_picker signature_pad ...

   and, to get the "new" badge, add it to `@new_components`:

       @new_components ~w(command_palette segmented empty_state color_picker calendar signature_pad fab filter_menu timer datetime_picker)a

2. `lib/linea_showcase_web/examples/date_picker_07.html.heex` ("Date and time") shows the old
   flatpickr `datetime_picker` with `time_24hr`, `minute_step` and `default_hour`. That function now
   belongs to the new component and those attrs are gone, so delete the file (the new examples
   replace it) and renumber nothing: the other `date_picker_NN` files keep their names.

The examples use `@form` (the demo form `LineaShowcaseWeb.DocLive` provides) and the
`booking:picked` event that `date_picker_09` already uses, so the toast shows each change.

# Showcase patch: card

The card was rebuilt to look like Flux's. Copy the fourteen examples over the old ones
(`card_07` to `card_13` are replaced, `card_14` to `card_20` are new; `card_01` to `card_06` stay):

    cp showcase_patch/examples/card_*.html.heex \
       ~/ElixirProjects/linea_showcase/lib/linea_showcase_web/examples/

The showcase must also rebuild its CSS (`mix tailwind linea_showcase`): the card's rules moved to
`assets/css/parts/card.css`, imported by `linea_ui.css`, so a running dev server needs its Tailwind
watcher restarted to see the new `@import`.

`card_09` (Surfaces) and every example use the showcase's own `dark:` wrappers, so each one shows
correctly in both themes; none uses `@form` or events. Icons: the dots of `card_07` and `card_16` are an
inline SVG (Hugeicons has no horizontal ellipsis); `card_17` uses `huge-filter-horizontal` and
`card_20` `huge-arrow-up-right-01`.
