# Building LineaUI components

LineaUI turns the LineOne UI kit (ThemeForest, Tailwind v4) into Phoenix LiveView function
components, with the ergonomics of Fluxon UI: `use LineaUI`, one module per component,
compile-time style maps, `merge/1` so `class` overrides defaults, overlays opened by id.
The result must look **identical** to LineOne, light and dark.

## Sources

- LineOne demo pages (markup and classes): `/home/alex/Documents/Singnetum/themeforest-CN8rjpHg-lineone-multipurpose-admin-and-webapp-ui-kit-based-on-tailwind-css/lineone-html-es6/src/html/*.html`
- LineOne behavior: `.../lineone-html-es6/src/js/` (`components/`, `pages/<page>.js`, `libs/`), CSS: `.../src/css/`
- Third-party CSS LineOne skins (tom-select, flatpickr, quill, filepond, swiper, apexcharts, gridjs, simplebar): `reference/css/` — port the look, not the library.
- `python3 scripts/lineone_classes.py <page> [class-prefix]` prints every class of a demo page by section.
- Fluxon (API ergonomics only, commercial — never copy its code): `/home/alex/ElixirProjects/signetum/deps/fluxon/lib/components/*.ex`, docs in `/home/alex/ElixirProjects/signetum/.claude/skills/fluxon/references/`.
- devaction_ui (MIT, the same author's — hooks may be ported and adapted): `/home/alex/ElixirProjects/devaction_ui/assets/js/devaction_ui/` and `lib/devaction_ui/`. Its pure logic is already vendored in `assets/js/linea_ui/lib/` (placement, keys, dates, menu_logic, overlay_logic, select_logic, listbox_logic, toast_logic, tooltip_logic, date_picker_view, dropzone_logic, editor_logic, sortable_logic, kanban_logic, numbers, text, dom, controls), with tests.

`lib/linea_ui/components/button.ex` is the reference component. Read it first.

## Component rules

- Module `LineaUI.Components.<Name>` in `lib/linea_ui/components/<name>.ex`, `use LineaUI.Component`
  (brings `Phoenix.Component`, `merge/1`, `JS`, and `LineaUI.Component.Helpers`: `gen_id/1`,
  `assign_field/1`, `translate_error/1`, `bool/1`, `colors/0`).
- The stub module for every planned component already exists and is already imported by
  `use LineaUI` (`lib/linea_ui.ex`). You may add further `LineaUI.Components.*` helper modules,
  but every public component lives in a module listed there.
- Public function names are global (everything is imported together): prefix by component
  (`dropdown_item`, `tab_panel`). Never define a name Phoenix.Component already has
  (`link form focus_wrap inputs_for live_file_input dynamic_tag intersperse async_result live_title live_img_preview portal`).
- Elixir style is strict: no `if`/`else`/`unless` (multi-clause functions, `case`, `with`, `cond`;
  `:if` in HEEx is fine); no `#` comments; `@moduledoc` with usage examples and a `@doc` per public
  function; `attr`/`slot` with `values:` for enums and `doc:` where not obvious; `attr :class, :any`
  merged **last**; `attr :rest, :global` on every public component; no `String.to_atom`; assertive
  map access.
- Class strings are **literal** in source (Tailwind scans `lib/`): write full strings in `@styles`
  maps, never interpolate class fragments.
- Vocabulary, taken from LineOne: `color` in `neutral primary secondary accent info success warning error`
  (accept only what LineOne shows for that component); `variant` names from LineOne's section titles
  (`solid soft outline bordered flat glow`...); `size` in `xs sm md lg xl`; `shape` where LineOne has
  rounded/pill/square/mask shapes. Dark mode is LineOne's `.dark` class (`dark:` variant); keep every
  `dark:` class LineOne has (primary becomes accent in dark).
- Text comes only through attrs and slots (no Gettext). Icons come through slots; the glyphs a
  component draws itself (chevrons, close ×, check) are LineOne's inline SVGs.
- Form components take `field={@form[:x]}` (`assign_field/1`), plus `name`, `value`, `id`, `errors`,
  `label`, `help`, `disabled`.
- Interaction: prefer `Phoenix.LiveView.JS` (toggle, show/hide, transitions, `toggle_attribute`) and
  native elements (`<details>`, `<dialog>`, `popover`) where they reproduce LineOne's behavior. When a
  hook is needed, it lives in the hook file you own and is registered as `"LineaUI.<Name>"`
  (`export default {"LineaUI.Name": {mounted() {...}}}`; one file may export several hooks).
  `assets/js/linea_ui/index.js` already imports every hook file — do not edit it.
- Pure logic goes in `assets/js/linea_ui/lib/<name>.js` with a `<name>.test.js` (`node:test`).
- Client-owned state must survive LiveView patches: `JS.ignore_attributes(["open", "data-state"...])`
  in a `phx-mounted`, or `phx-update="ignore"` on client-only subtrees. Hooks clean up in `destroyed()`.
- Overlays (anything `LineaUI.open/close/toggle` targets) listen on their root element for the DOM
  events `linea:open`, `linea:close`, `linea:toggle`, and on `window` for `phx:linea:open|close|toggle`
  whose `detail.id` is a `#selector` matching them. Escape and outside click close the innermost one.
  They accept `on_open`/`on_close` `JS` attrs. `aria-*` and focus handling as a real component would.
- Extra CSS (keyframes, pseudo-elements, third-party look) goes in the `assets/css/parts/<yours>.css`
  file, inside `@layer components { }`. Do not edit `assets/css/linea_ui.css`.

## LiveView integration (required)

The components are LiveView-first, not static markup with JS on top.

- **Server and client both drive state.** Every stateful component (overlays, tabs, accordion,
  collapse, select, pickers, carousel, sidebar...) takes its state from an attr (`open`, `selected`,
  `value`, `page`, `expanded`) *and* works client-side without a round trip. When the server changes
  the attr, the server wins; a choice made in the browser survives patches that did not change it
  (the vendored `resolveSelection` pattern in devaction_ui's `tabs.js`).
- **The server hears what the client did.** `on_open`, `on_close`, `on_change`, `on_select`... accept
  an event name (string) or a `%JS{}`; Esc or an outside click that closes a modal still runs
  `on_close`, so a server-held `open` assign can be synced. A component that emits events takes a
  `target` attr (`phx-target`), and hooks push with `this.pushEventTo(this.el, ...)` so the closest
  LiveComponent gets them. Document the payload of every event in the `@doc`.
- **Server pushes reach hooks.** `LineaUI.open/close/toggle(socket, id)` and component-specific
  pushes (`send_toast`) work from `handle_event`/`handle_info`; hooks subscribe with `handleEvent`
  and filter by id.
- **Forms just work.** Inside `<.form phx-change phx-submit>`: every custom control submits through a
  real (hidden) input with the field's `name`, and dispatches a bubbling `input` event when its value
  changes so `phx-change` fires; it does not re-fire when the server only echoes the same value;
  `phx-debounce`/`phx-throttle` pass through `rest`; errors follow `used_input?/1`; `phx-feedback`
  is not used (LiveView 1.x). Uploads use `allow_upload`/`live_file_input`.
- **Lists accept streams.** Table, data table, timeline, menu list, treeview rows take `rows={@streams.x}`
  with `row_id` like Phoenix core's table, and render `phx-update="stream"` when given a stream.
- **Loading states** use LiveView's classes (`phx-click-loading:`, `phx-submit-loading:`) — Tailwind
  variants for them are expected in the app's CSS (the preview defines them).
- **Hooks** implement `mounted`, `updated` (re-read data attrs), `destroyed` (remove window/document
  listeners, timers, observers), never keep a stale element reference across patches, and never
  register a listener twice.
- **Tests with a real LiveView** for every component that emits or receives events: `use LineaUI.LiveCase`
  (`live_isolated`, `render_click`, `render_change`, `assert_push_event`, `render_hook`). Test
  LiveViews live in the test file or `test/support/live/<component>_live.ex`.

## Tests

`test/linea_ui/components/<name>_test.exs`, `use LineaUI.ComponentCase, async: true`:

```elixir
html = render(~H"<.badge color=\"success\">Paid</.badge>")
assert "bg-success" in classes(html, "span")
assert [_] = find(html, "span") |> Enum.to_list()
```

Cover each attr value that changes markup, slots, `field` wiring and errors, and the hook wiring
(`phx-hook`, `data-*`). JS logic gets node tests.

## Preview pages

One page per LineOne demo page, `preview/lib/preview_web/pages/<name>.ex`:

```elixir
defmodule PreviewWeb.Pages.Badge do
  use PreviewWeb.Page, title: "Badge", category: :elements, lineone: "elements-badge"

  def render(assigns) do
    ~H"""
    <.example title="Basic Badge" text="...the same text LineOne shows...">
      <.badge>Default</.badge>
    </.example>
    """
  end
end
```

Reproduce **every section** of the LineOne page, same titles, texts and order, built only from
LineaUI components (that is the proof the API covers the design). Stateful demos override
`mount/1`, `handle_event/3`, `handle_info/2`. `category` is `:elements | :components | :forms | :layout`.
`<.example class=...>` replaces the default `inline-space mt-5 flex flex-wrap` content wrapper when the
original section lays out differently.

## Your worktree

```bash
M=/home/alex/ElixirProjects/linea_ui
ln -s $M/deps deps && cp -r $M/_build _build
ln -s $M/preview/deps preview/deps && cp -r $M/preview/_build preview/_build
cd preview && mix tailwind.install --if-missing && mix esbuild.install --if-missing
LINEA_PREVIEW_PORT=<your port> mix phx.server   # run in the background; restart after adding modules if a page 404s
```

The original page is served by the preview itself at `http://localhost:<port>/lineone/<page>.html`.

## Verification (all of it, before you finish)

1. `mix format`, `mix compile --warnings-as-errors`, `mix test`, `mix js.test` in the package root;
   `cd preview && mix compile --warnings-as-errors`.
2. Screenshots, light and dark, of each of your preview pages next to the original:
   ```bash
   node scripts/shot.mjs http://localhost:<port>/<slug> /tmp/<x>/ours.png --select=main
   node scripts/shot.mjs http://localhost:<port>/lineone/<page>.html /tmp/<x>/orig.png --select=main --wait=2500
   # add --dark for dark mode; --eval="document.querySelector('#x').click()" to open things first
   ```
   Look at both images and fix every difference (spacing, radius, color, font size, shadow, icon).
   The preview header differs from LineOne's (no breadcrumb); compare the cards.
3. Exercise the interactive parts through `--eval` (open, close, select, type) and look at the result.

Commit on your branch with clear messages (no AI attribution lines). Touch only the files you own.
If you need a change in a shared file (`lib/linea_ui.ex`, `component/helpers.ex`, `component_case.ex`,
`index.js`, `linea_ui.css`, preview infrastructure), do not make it: describe it in your final report.
Your final report lists the components and functions you built, their attrs in one line each, what
differs from LineOne and why, and anything left undone.
