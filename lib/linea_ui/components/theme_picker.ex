defmodule LineaUI.Components.ThemePicker do
  @moduledoc """
  Lets the user choose a named theme (`LineaUI.Theme`), as daisyUI's theme controller does: a menu in the top bar
  or a grid of previews on a settings page. Each option previews its own palette (its swatches carry the theme's
  `data-theme`), in the light or dark mode the page is in.

      <.theme_picker id="palette" />
      <.theme_picker id="palette" variant="grid" />
      <.theme_picker id="palette" themes={~w(linea ocean forest)} label="Tema" />

  The theme is a palette, apart from the mode: `theme_switch/1` still picks light, dark or system, and the picker
  picks which palette is light or dark. So the two sit side by side.

  ## What it does

  The `LineaUI.ThemePicker` hook puts the chosen id on `<html data-theme>`, keeps it in
  `localStorage["linea-theme"]`, marks the option (`aria-checked`) and tells every picker on the page through the
  `change:theme` window event. `on_change` also sends the choice to the LiveView (`%{"theme" => id}`), to keep it on
  the user's profile, say. Put `<.theme_script theme="..." />` in the root layout's `<head>` so the stored theme is
  on before the first paint; `default` (or `config :linea_ui, :theme`) is the one shown when nothing is stored.

  `themes` takes ids or maps (`%{id, label}`) and defaults to `LineaUI.Theme.all/0`: the kit's twelve plus the
  app's (`config :linea_ui, :themes, extra: [%{id: "acme", label: "Acme"}]`, CSS from
  `mix linea_ui.gen.theme`).
  """

  use LineaUI.Component

  alias LineaUI.Components.Dropdown
  alias LineaUI.Theme

  attr :id, :string, required: true

  attr :variant, :string,
    default: "menu",
    values: ~w(menu grid),
    doc:
      "`menu` (a button that opens the list) or `grid` (previews to click, for a settings page)."

  attr :themes, :list,
    default: nil,
    doc: "Ids or `%{id, label}` maps; default `LineaUI.Theme.all/0`."

  attr :default, :string,
    default: nil,
    doc:
      "The theme shown when nothing is stored (default `config :linea_ui, :theme`, else `\"linea\"`)."

  attr :label, :string, default: "Theme", doc: "Names the menu button and the group."

  attr :placement, :string,
    default: "bottom-end",
    doc: "Where the menu opens (the `menu` variant)."

  attr :on_change, :string, default: nil, doc: "An event pushed with `%{\"theme\" => id}`."
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def theme_picker(assigns) do
    assigns =
      assigns
      |> assign_derived(:options, [:themes], fn -> options(assigns.themes) end)
      |> assign_derived(:current, [:default], fn ->
        assigns.default || Application.get_env(:linea_ui, :theme) || "linea"
      end)

    assigns = assign(assigns, :current_label, label_of(assigns.options, assigns.current))

    ~H"""
    <div
      id={@id}
      class={merge(["sg-tp", @variant == "grid" && "grid", @class])}
      phx-hook="LineaUI.ThemePicker"
      data-variant={@variant}
      data-default={@current}
      data-value={@current}
      data-change-event={@on_change}
      data-target={@target}
      phx-mounted='[["ignore_attrs",{"attrs":["data-value"]}]]'
      {@rest}
    >
      <Dropdown.dropdown
        :if={@variant == "menu"}
        id={"#{@id}-menu"}
        placement={@placement}
        class="sg-tp-pop"
      >
        <:toggle>
          <button type="button" class="sg-tp-btn" aria-label={@label} aria-haspopup="menu">
            <.palette_glyph />
            <span class="sg-tp-name" data-theme-current>{@current_label}</span>
            <svg class="i sm cv" viewBox="0 0 24 24" aria-hidden="true"><path d="M7 10l5 5 5-5" /></svg>
          </button>
        </:toggle>
        <div class="sg-tp-h">{@label}</div>
        <button
          :for={option <- @options}
          type="button"
          role="menuitemradio"
          class="sg-tp-opt"
          aria-checked={bool(option.id == @current)}
          data-theme-value={option.id}
          data-label={option.label}
          phx-mounted='[["ignore_attrs",{"attrs":["aria-checked"]}]]'
        >
          <.swatch id={option.id} />
          <span class="lbl">{option.label}</span>
          <svg class="i sm ck" viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5" /></svg>
        </button>
      </Dropdown.dropdown>
      <div :if={@variant == "grid"} class="sg-tp-grid" role="radiogroup" aria-label={@label}>
        <button
          :for={option <- @options}
          type="button"
          role="radio"
          class="sg-tp-card"
          aria-checked={bool(option.id == @current)}
          tabindex={if option.id == @current, do: "0", else: "-1"}
          data-theme-value={option.id}
          data-label={option.label}
          phx-mounted='[["ignore_attrs",{"attrs":["aria-checked","tabindex"]}]]'
        >
          <span class="sg-tp-prev" data-theme={option.id} aria-hidden="true">
            <span class="card"><i class="t1"></i><i class="t2"></i><span class="btn"></span></span>
            <span class="dots"><i class="a"></i><i class="b"></i><i class="c"></i></span>
          </span>
          <span class="lbl">{option.label}</span>
        </button>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true

  defp swatch(assigns) do
    ~H"""
    <span class="sg-tp-sw" data-theme={@id} aria-hidden="true"><i class="a"></i><i class="b"></i><i class="c"></i><i class="d"></i></span>
    """
  end

  defp palette_glyph(assigns) do
    ~H"""
    <svg class="i" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 21.5a9.5 9.5 0 1 1 9.5-9.5c0 2.2-1.8 3.4-3.6 3.4h-2.1a1.9 1.9 0 0 0-1.4 3.2c.5.6.3 2.9-2.4 2.9z" /><circle
      cx="7.6"
      cy="11.3"
      r="1.2"
    /><circle cx="10.4" cy="7.4" r="1.2" /><circle cx="15.2" cy="7.6" r="1.2" /></svg>
    """
  end

  defp options(nil), do: Enum.map(Theme.all(), &%{id: &1.id, label: &1.label})

  defp options(themes) do
    Enum.map(themes, fn
      %{} = theme ->
        id = to_string(theme[:id] || theme["id"])
        %{id: id, label: theme[:label] || theme["label"] || label(id)}

      id ->
        id = to_string(id)
        %{id: id, label: (Theme.get(id) || %{label: label(id)}).label}
    end)
  end

  defp label(id), do: id |> String.replace("-", " ") |> String.capitalize()

  defp label_of(options, id), do: Enum.find_value(options, label(id), &(&1.id == id && &1.label))
end
