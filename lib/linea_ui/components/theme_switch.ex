defmodule LineaUI.Components.ThemeSwitch do
  @moduledoc """
  The canvas's theme switch: light, dark or the system's, already wired to LineaUI's dark mode.

      <.theme_switch />                                   <%!-- Light · Dark · System, with icons --%>
      <.theme_switch variant="icons" size="sm" />         <%!-- the compact one for a topbar --%>
      <.theme_switch variant="switch" />                  <%!-- a sun/moon switch, light or dark --%>
      <.theme_switch light_label="Claro" dark_label="Escuro" system_label="Sistema" />

  The choice is kept in `localStorage["theme"]` (`"light"`, `"dark"` or `"system"`). It sets the `dark` class of
  `<html>` and the dark mode key, so `theme_toggle/1`, `theme_script/1` and every other switch on the page follow;
  with `system` the page follows `prefers-color-scheme`, live. Put `theme_script/1` in the root layout's `<head>`
  so the stored theme applies before the first paint.

  `on_change` gets `%{"theme" => "light" | "dark" | "system", "dark" => boolean}` (an event name) or runs (a `%JS{}`).

  ## Variants

    * `segmented` (default) — the options as a pill with a thumb that slides to the chosen one, an icon and a label
      on each. `system={false}` leaves only light and dark.
    * `icons` — the same, icons only (the labels stay for screen readers), for a topbar or a menu.
    * `switch` — a sun/moon switch (`role="switch"`): light or dark, no system.

  The segmented one is a `radiogroup`: the arrow keys move the choice.
  """

  use LineaUI.Component

  alias LineaUI.Components.Icon

  attr :id, :string, default: "theme-switch"
  attr :variant, :string, default: "segmented", values: ~w(segmented icons switch)
  attr :size, :string, default: "md", values: ~w(sm md)
  attr :system, :boolean, default: true, doc: "Offer the system's theme (segmented and icons)."
  attr :label, :string, default: "Theme", doc: "The accessible name of the group."
  attr :light_label, :string, default: "Light"
  attr :dark_label, :string, default: "Dark"
  attr :system_label, :string, default: "System"
  attr :on_change, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil, doc: "The `phx-target` of `on_change`."
  attr :class, :any, default: nil
  attr :rest, :global

  def theme_switch(%{variant: "switch"} = assigns) do
    ~H"""
    <button
      type="button"
      id={@id}
      role="switch"
      aria-checked="false"
      aria-label={@dark_label}
      phx-hook="LineaUI.ThemeSwitch"
      phx-mounted={JS.ignore_attributes(["aria-checked", "data-value"])}
      data-variant="switch"
      data-change-event={event_name(@on_change)}
      data-on-change={js_command(@on_change)}
      data-target={@target}
      class={merge(["sg-theme-sw", @class])}
      {@rest}
    >
      <span class="end"><Icon.icon name="huge-sun-03" /></span>
      <span class="end"><Icon.icon name="huge-moon-02" /></span>
      <span class="k" aria-hidden="true">
        <Icon.icon name="huge-sun-03" class="sun" />
        <Icon.icon name="huge-moon-02" class="moon" />
      </span>
    </button>
    """
  end

  def theme_switch(assigns) do
    assigns =
      assign(assigns, :options, [
        {"light", assigns.light_label, "huge-sun-03"},
        {"dark", assigns.dark_label, "huge-moon-02"}
        | if(assigns.system, do: [{"system", assigns.system_label, "huge-computer"}], else: [])
      ])

    ~H"""
    <div
      id={@id}
      role="radiogroup"
      aria-label={@label}
      phx-hook="LineaUI.ThemeSwitch"
      phx-update="ignore"
      data-variant={@variant}
      data-value="system"
      data-change-event={event_name(@on_change)}
      data-on-change={js_command(@on_change)}
      data-target={@target}
      class={
        merge([
          "sg-theme",
          @variant == "icons" && "icons",
          @size == "sm" && "sm",
          !@system && "two",
          @class
        ])
      }
      {@rest}
    >
      <button
        :for={{value, label, icon} <- @options}
        type="button"
        role="radio"
        aria-checked="false"
        tabindex="-1"
        title={@variant == "icons" && label}
        data-theme-value={value}
      >
        <Icon.icon name={icon} />
        <span class="lbl">{label}</span>
      </button>
    </div>
    """
  end

  defp event_name(event) when is_binary(event), do: event
  defp event_name(_other), do: nil

  defp js_command(%JS{} = js), do: js
  defp js_command(_other), do: nil
end
