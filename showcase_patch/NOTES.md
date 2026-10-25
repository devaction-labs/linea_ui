# Showcase patch for LineaUI 0.5.1

LineaUI now ships the drag and drop (`LineaUI.Sortable`, native HTML5 DnD with a pointer-events path for touch) and the
kanban components (`kanban/1`, `kanban_column/1`, `kanban_card/1`, `kanban_lost/1`). The showcase no longer needs
SortableJS or its own hooks.

## Copy

From this folder into the showcase, same paths:

- `lib/linea_showcase_web/templates/pages/signetum_kanban.ex` (the board is the new components; the colocated `.Kanban`
  hook is gone; `move` now receives `%{"id", "from", "to", "index"}` and keeps the order inside a column)
- `lib/linea_showcase_web/templates/apps/kanban.ex` (`phx-hook="LineaUI.Sortable"`, `data-axis="x"` on the column row,
  the private `kanban_card/1` is renamed `task_card/1` because `kanban_card/1` is now imported from LineaUI)
- `lib/linea_showcase_web/templates/apps/todo.ex` (`phx-hook="LineaUI.Sortable"`)

## Delete

- `assets/js/showcase/sortable.js`
- its import and its spread in `assets/js/showcase/index.js` (`import Sortable from "./sortable.js"` and `...Sortable`),
  and the "drag and drop in the kanban and todo apps" mention in that file's header comment
- the `sortablejs` dependency in `assets/package.json` (and `package-lock.json`; `npm install` refreshes it)

`assets/js/app.js` already spreads `LineaHooks`, which now holds `LineaUI.Sortable`. The CSS needs nothing new:
`linea_ui.css` imports `parts/sortable.css`, and the showcase's `app.css` imports `linea_ui.css`.

## Notes

- The Signetum template's `brl/1` crashes on `0` (an empty column); the patch sums with a float so the empty column shows
  `R$ 0,00`.
- Touch: hold a card for a moment, then drag. For the keyboard the funnel keeps the arrow button in the card (`advance`).
