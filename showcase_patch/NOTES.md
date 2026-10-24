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
