defmodule LineaUI.Components.ThemeSwitch do
  @moduledoc """
  The light / dark / system choice of the canvas "ThemeSwitch" board, wired to the kit's dark mode.

      <.theme_switch id="theme" />
      <.theme_switch id="theme" variant="icons" size="sm" />
      <.theme_switch id="theme" variant="switch" />
      <.theme_switch id="theme" system={false} light_label="Claro" dark_label="Escuro" />

  `variant` is `"segmented"` (icon and label, a pill whose thumb slides to the choice), `"icons"` (the same with the
  labels visually hidden, for a top bar) or `"switch"` (a sun/moon switch: on is dark). `size="sm"` is the compact
  one; `system={false}` leaves only light and dark.

  The segmented and icons variants are a `radiogroup` of `radio` buttons (arrow keys move the choice); the switch is
  one `switch` button. The labels are the accessible names (`label` names the group or the switch).

  ## What it does

  The `LineaUI.ThemeSwitch` hook (register the kit's hooks) reads the stored choice, puts the `dark` class on
  `<html>` and keeps `data-value` / `aria-checked` in step. A click stores the choice in `localStorage["theme"]`
  (`"light"`, `"dark"` or `"system"`) and the dark mode it resolves to in `localStorage["dark-mode"]`, the key
  `theme_toggle/1` uses, so both agree. "System" follows `prefers-color-scheme` live. Every `theme_switch` and
  `theme_toggle` on the page listens to the same `change:darkmode` window event and follows. Put `<.theme_script />`
  in the root layout's `<head>` so the first paint already has the theme.

  The server renders the light choice; the hook owns `data-value`, `aria-checked` and `tabindex`, and
  `phx-mounted={JS.ignore_attributes(...)}` keeps a LiveView patch from resetting them.
  """

  use LineaUI.Component

  attr(:id, :string, required: true)

  attr(:variant, :string,
    default: "segmented",
    values: ~w(segmented icons switch),
    doc: "`segmented` (icons and labels), `icons` (icons only) or `switch` (sun/moon)."
  )

  attr(:size, :string, default: "md", values: ~w(md sm))
  attr(:system, :boolean, default: true, doc: "Offer \"system\"; `false` leaves light and dark.")
  attr(:light_label, :string, default: "Light")
  attr(:dark_label, :string, default: "Dark")
  attr(:system_label, :string, default: "System")

  attr(:label, :string,
    default: nil,
    doc: "Names the group (default `\"Theme\"`) or the switch (default `\"Dark mode\"`)."
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def theme_switch(%{variant: "switch"} = assigns) do
    assigns =
      assign_derived(assigns, :classes, [:class], fn -> merge(["sg-theme-sw", assigns.class]) end)

    ~H"""
    <button
      type="button"
      id={@id}
      class={@classes}
      role="switch"
      aria-checked="false"
      aria-label={@label || "Dark mode"}
      phx-hook="LineaUI.ThemeSwitch"
      phx-mounted={JS.ignore_attributes(["aria-checked"])}
      {@rest}
    >
      <span class="end"><.glyph name="sun" /></span>
      <span class="end"><.glyph name="moon" /></span>
      <span class="k">
        <span class="sun"><.glyph name="sun" /></span>
        <span class="moon"><.glyph name="moon" /></span>
      </span>
    </button>
    """
  end

  def theme_switch(assigns) do
    assigns =
      assigns
      |> assign_derived(:classes, [:variant, :size, :system, :class], fn ->
        merge([
          "sg-theme",
          assigns.variant == "icons" && "icons",
          !assigns.system && "two",
          assigns.size == "sm" && "sm",
          assigns.class
        ])
      end)
      |> assign_derived(:options, [:system, :light_label, :dark_label, :system_label], fn ->
        [{"light", assigns.light_label}, {"dark", assigns.dark_label}] ++
          if assigns.system, do: [{"system", assigns.system_label}], else: []
      end)

    ~H"""
    <div
      id={@id}
      class={@classes}
      role="radiogroup"
      aria-label={@label || "Theme"}
      data-value="light"
      data-system={!@system && "false"}
      phx-hook="LineaUI.ThemeSwitch"
      phx-mounted={JS.ignore_attributes(["data-value"])}
      {@rest}
    >
      <button
        :for={{{value, text}, index} <- Enum.with_index(@options)}
        type="button"
        role="radio"
        aria-checked={bool(index == 0)}
        tabindex={if index == 0, do: "0", else: "-1"}
        data-theme-value={value}
        title={@variant == "icons" && text}
        phx-mounted={JS.ignore_attributes(["aria-checked", "tabindex"])}
      >
        <.glyph name={icon_for(value)} /><span class="lbl">{text}</span>
      </button>
    </div>
    """
  end

  defp icon_for("system"), do: "monitor"
  defp icon_for(value), do: if(value == "dark", do: "moon", else: "sun")

  attr(:name, :string, required: true)

  defp glyph(%{name: "sun"} = assigns) do
    ~H"""
    <svg class="i" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4" /><path d="M12 2.5v2M12 19.5v2M4.6 4.6l1.4 1.4M18 18l1.4 1.4M2.5 12h2M19.5 12h2M4.6 19.4L6 18M18 6l1.4-1.4" /></svg>
    """
  end

  defp glyph(%{name: "moon"} = assigns) do
    ~H"""
    <svg class="i" viewBox="0 0 24 24" aria-hidden="true"><path d="M20.5 14.1A8.5 8.5 0 0 1 9.9 3.5a8.5 8.5 0 1 0 10.6 10.6z" /></svg>
    """
  end

  defp glyph(%{name: "monitor"} = assigns) do
    ~H"""
    <svg class="i" viewBox="0 0 24 24" aria-hidden="true"><rect
      x="3"
      y="4"
      width="18"
      height="12.5"
      rx="2.5"
    /><path d="M8.5 20.5h7M12 16.5v4" /></svg>
    """
  end
end
