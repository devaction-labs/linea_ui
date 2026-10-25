# Showcase patch: otp, scroll_bottom, right_sidebar_tabs, chart_formatters

Files mirror `~/ElixirProjects/linea_showcase`. Copy them over the showcase's:

| Patch file | What changed |
|---|---|
| `lib/linea_showcase_web/templates/pages/auth_duas_etapas.ex` | `code/1` renders `<.otp_input field={@form[:code]} ...>` instead of six `.input` boxes, a hidden input and the `Otp` hook; the errors and the help line come from the component. |
| `lib/linea_showcase_web/templates/apps/chat.ex` | `#chat-messages` is `<.scroll_area id="chat-messages" stick_bottom ...>` (no `phx-hook="ScrollBottom"`). |
| `lib/linea_showcase_web/templates/apps/ai_chat.ex` | `#ai-messages` is `<.scroll_area id="ai-messages" stick_bottom ...>`. |
| `lib/linea_showcase_web/components/shell_parts.ex` | `right_drawer/1` passes `persist_tab` to `right_sidebar` and drops `phx-hook="RightSidebarTabs"` from the nav bar (the buttons already carry `data-tab`). |
| `lib/linea_showcase_web/templates/dashboards/personal.ex` | No `phx-hook="ChartFormatters"`; the income chart's `formatter: "thousands"` becomes `"thousands_fixed"` (see below). |
| `lib/linea_showcase_web/templates/dashboards/travel.ex` | No `phx-hook="ChartFormatters"` (`formatter: "total"` is a package built-in). |
| `lib/linea_showcase_web/templates/dashboards/crypto2.ex` | `data-formatters={...}` becomes `formatters={%{"yaxis.labels.formatter" => "thousands"}}`. |

One test line to change in `test/linea_showcase_web/templates/auth_test.exs` ("duas etapas"):

```elixir
assert html =~ ~s(phx-hook="LineaUI.Otp")
```

## Delete afterwards

- `assets/js/showcase/otp.js`
- `assets/js/showcase/scroll_bottom.js`
- `assets/js/showcase/right_sidebar_tabs.js`
- `assets/js/showcase/chart_formatters.js`

In `assets/js/showcase/index.js` remove the imports and spreads of `ChartFormatters`, `Otp`, `RightSidebarTabs` and `ScrollBottom`. What stays is `CopySource` (docs only) and `Sortable` (until the drag and drop package hook replaces it):

```js
export const Hooks = {...CopySource, ...Sortable}
```

`auth.css` has no OTP rules, so nothing to remove there.

## Chart formatters: nothing to add to the package

The package's built-in table already holds every name the dashboards use; the showcase's local `ChartFormatters` only duplicated it, with `thousands` meaning two different things in its two tables:

| Where | Showcase name and behavior | Package name |
|---|---|---|
| `crypto2` `data-formatters` (`byPath`) | `thousands`: `value / 1000` + `k` | `thousands`: same |
| `personal` `dataLabels.formatter` (`named`) | `thousands`: `toFixed(2)` + `k` above 1000, value unchanged below | `thousands_fixed`: same |
| `travel` `total: %{formatter: "total"}` | `total` | `total`: same |

The package has one `thousands` (the `byPath` one), so the only dashboard that depended on the other meaning (`personal`'s income labels) now says `thousands_fixed`, which renders the same text as before. Bare `formatter: "name"` strings inside options are resolved by the package chart itself (`resolveFormatters`), so no wrapper hook is needed around the charts.

## Behavior differences worth knowing

- `otp_input` renders the boxes without the `phx-update="ignore"` wrapper the showcase had: the hook keeps the boxes in step with the server value (an echo of what was just typed never undoes it; a different value, such as `""` after a rejected code, wins).
- `stick_bottom` follows new content only while the reader is within 32px of the end; the old `ScrollBottom` always jumped. A reader who scrolled up to an older message is no longer pulled down by a new one.
- The right sidebar remembers the panel under `linea-right-tab:<sidebar id>` in `sessionStorage` (the showcase used `showcase:right-sidebar-tab`).
