# LineaUI

Phoenix LiveView components with the LineOne design (Tailwind CSS v4), used the way Fluxon is
used: `use LineaUI`, one function per component, `class` that overrides the defaults, overlays
opened by id, and hooks that survive LiveView patches. No JavaScript dependencies.

> LineOne is a ThemeForest item. This package reproduces it under the buyer's license and is
> private: do not publish it to Hex.

## Installation

```elixir
# mix.exs
{:linea_ui, path: "../linea_ui"}   # or git: "<repository>", tag: "v0.1.0"
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

## Development

```bash
mix test && mix js.test                       # package
cd preview && LINEA_PREVIEW_PORT=4200 mix phx.server
```

`preview/` is a Phoenix app with one page per LineOne demo page; the original LineOne page is
served next to it at `/lineone/<page>.html`. `node scripts/shot.mjs` takes the screenshots used to
compare them. `CONVENTIONS.md` is the guide for writing components.
