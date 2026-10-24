# LineaUI

Phoenix LiveView components with the LineOne design (Tailwind CSS v4), used the way Fluxon is
used: `use LineaUI`, one function per component, `class` that overrides the defaults, overlays
opened by id, and hooks that survive LiveView patches. No JavaScript dependencies.

> **Credits.** The code of this package is DevAction's. The visual design it reproduces derives from
> [LineOne](https://themeforest.net/search/lineone) by PiniaStudio (ThemeForest) and is credited to its
> author. See [LICENSE](LICENSE).

## Installation

```elixir
# mix.exs
{:linea_ui, "~> 0.1"}
```

```css
/* assets/css/app.css — remove daisyUI and its theme plugins */
@import "tailwindcss";
@import "../../deps/linea_ui/assets/css/fonts.css";
@import "../../deps/linea_ui/assets/css/linea_ui.css";
```

```js
// assets/js/app.js
import {Hooks as LineaHooks} from "linea_ui"

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: {...colocatedHooks, ...LineaHooks},
  params: {_csrf_token: csrfToken},
})
```

```elixir
# lib/my_app_web/endpoint.ex — serves the Poppins and Inter fonts
plug Plug.Static, at: "/linea_ui", from: {:linea_ui, "priv/static"}

# lib/my_app_web.ex, inside html_helpers/0
use LineaUI, avoid_conflicts: true   # keeps CoreComponents' button/input/table/label/error/header
```

Dark mode is LineOne's: the `dark` class on `<html>`, remembered in `localStorage["dark-mode"]`.
To avoid a flash, put this in the root layout's `<head>`:

```html
<script>localStorage.getItem("dark-mode") === "dark" && document.documentElement.classList.add("dark")</script>
```

Errors are translated with the app's own function:

```elixir
config :linea_ui, :translate_error, &MyAppWeb.CoreComponents.translate_error/1
```

## Icons

The small glyphs the components draw themselves (the chevron of a select, the cross of a toast, the
check of a checkbox, the arrows of a pager, the tools of the text editor...) are LineOne's own SVGs
by default. An app can have them drawn with [Hugeicons](https://hugeicons.com) (the free Stroke
Rounded set) instead:

```elixir
# mix.exs: the SVGs are vendored, not compiled
{:hugeicons, github: "hugeicons/hugeicons", ref: "3365154e0ae2461fbfb6249b89649127207a4f9e",
 sparse: "icons", app: false, compile: false, depth: 1}

# config/config.exs
config :linea_ui, :icons, :hugeicons   # :lineone is the default
```

```css
/* assets/css/app.css, after the linea_ui.css import: turns every huge-* class into a CSS mask */
@plugin "../../deps/linea_ui/assets/css/hugeicons.cjs" {
  dir: "deps/hugeicons/icons";
}
```

`dir` is the folder of the SVGs, relative to where Tailwind runs (the app's root). The setting is read when
the page renders; the components whose hooks draw glyphs in the browser (toast, date picker) get it from a
`data-icons` attribute. Restart the app after changing it. Glyphs that are artwork (the two-tone icons of the
sidebar, the arrows of tooltips and popovers, the spinner) and the carets and check marks LineOne bakes into
its CSS (native select, tom-select, checkbox, radio, switch, table sorting) stay LineOne's in both sets.

For your own icons use `<.icon name="huge-search-01" class="size-5" />` (any other class name, such as
`fa-solid fa-house`, passes through). Write the name in full in the source, never interpolated: Tailwind
only sees what is written, and a name that is not in the set renders nothing.

## Claude Code skill

```bash
mix linea_ui.install      # after adding the dependency, and after every upgrade
```

writes `.claude/skills/linea-ui/` — a short `SKILL.md` index (the rules every component shares
and one line per component) and `references/<component>.md` with the attrs, allowed values,
slots and examples of each, generated from the installed components themselves, so it never
drifts from the code. Only the index is loaded up front; a reference is read when its component
is used. The task also points `AGENTS.md`/`CLAUDE.md` at the skill (once) and prints the
remaining setup lines. `mix linea_ui.gen.skill --path <dir>` writes only the skill.

## Usage

```heex
<.button color="primary" phx-click={LineaUI.open("new-order")}>New order</.button>

<.modal id="new-order">
  <.form for={@form} phx-submit="save">
    <.input field={@form[:customer]} label="Customer" />
    <.button type="submit" color="primary">Save</.button>
  </.form>
</.modal>
```

```elixir
{:noreply, LineaUI.close(socket, "new-order")}
```

### Overlay layers

The overlays take their `z-index` from CSS custom properties, so an app can raise them (above another kit's
overlays during a migration, say) in its own `app.css`, after the import:

```css
:root {
  --linea-z-overlay: 100;   /* drawers */
  --linea-z-modal: 100;     /* modals */
  --linea-z-popover: 1000;  /* dropdowns, popovers, select and picker panels */
  --linea-z-tooltip: 10003;
  --linea-z-toast: 10010;
}
```

The values above are the defaults. Drawers and modals stack in the order they open: each one already open adds
10 to the next (`--linea-layer`), so a modal opened from a drawer, or a drawer opened from another, is drawn on
top, and Esc closes only the top one.

## Development

```bash
mix test && mix js.test                       # package
cd preview && LINEA_PREVIEW_PORT=4200 mix phx.server
```

`preview/` is a Phoenix app with one page per LineOne demo page; the original LineOne page is
served next to it at `/lineone/<page>.html`. `node scripts/shot.mjs` takes the screenshots used to
compare them. `CONVENTIONS.md` is the guide for writing components.
