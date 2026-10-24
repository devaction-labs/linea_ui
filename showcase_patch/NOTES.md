# Registering the card examples

Copy `examples/card_07.html.heex` to `card_12.html.heex` into
`linea_showcase/lib/linea_showcase_web/examples/`. Examples are discovered by file name (the
`@files` wildcard in `LineaShowcaseWeb.Examples`), so nothing else is registered; recompile the
showcase (touch `examples.ex` if the watcher misses the new files) and the `card` doc page lists
them after `card_06`.

The showcase must run against this `linea_ui` (path dependency) so `card_header/1`,
`card_body/1`, `card_footer/1`, `card_bleed/1`, the `size` and `body` attrs, the new `variant`
values and `table` `bleed` exist, and its stylesheet must be rebuilt so Tailwind scans the new
classes in `lib/`.

* `card_07` parts and actions on the leading side
* `card_08` body treatments
* `card_09` surfaces
* `card_10` sizes
* `card_11` image bleed
* `card_12` table bleed
