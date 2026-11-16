defmodule LineaUI.Daisy do
  @moduledoc false
  # The daisyUI classes the components share, so a component that draws a button (an upload label, a menu
  # trigger) gets the same classes as `<.button>`. Kept out of the component modules, which `use LineaUI` imports.

  import LineaUI.ClassMerge, only: [merge: 1]

  @colors ~w(primary secondary info success warning error)

  @doc """
  The classes of daisyUI's `btn` for the attrs of `<.button>`: `color`, `variant`, `size`, `shape`, `icon`,
  `pip` and `class` (missing keys take `<.button>`'s defaults).
  """
  @spec btn(map()) :: String.t()
  def btn(attrs) do
    variant = attrs[:variant] || "solid"
    icon = attrs[:icon] == true

    merge([
      "btn",
      btn_color(attrs[:color] || "neutral", variant),
      btn_variant(variant),
      btn_size(attrs[:size] || "md"),
      btn_shape(attrs[:shape] || "rounded", icon),
      icon && "btn-square",
      attrs[:pip] && "indicator",
      attrs[:class]
    ])
  end

  defp btn_color(color, _variant) when color in @colors, do: "btn-" <> color
  defp btn_color("mono", _variant), do: "btn-neutral"
  defp btn_color("white", _variant), do: "[--btn-color:#fff] [--btn-fg:#0a0a0a]"
  defp btn_color("current", _variant), do: "[--btn-color:currentColor]"

  # the neutral filled button is the panel with a hairline border, so it shows on any surface
  defp btn_color("neutral", variant) when variant in ~w(solid glow),
    do:
      "[--btn-color:var(--color-base-100)] [--btn-border:color-mix(in_oklab,var(--color-base-content)_14%,transparent)]"

  defp btn_color(_neutral, _variant), do: nil

  defp btn_variant("outline"), do: "btn-outline"
  defp btn_variant("soft"), do: "btn-soft"

  defp btn_variant("bordered"),
    do:
      "btn-soft [--btn-border:color-mix(in_oklab,var(--btn-color,var(--color-base-content))_28%,transparent)]"

  defp btn_variant(variant) when variant in ~w(flat ghost), do: "btn-ghost"
  defp btn_variant("dim"), do: "btn-ghost text-base-content/60 hover:text-base-content"
  defp btn_variant("glass"), do: "glass text-white"

  defp btn_variant("glow"),
    do:
      "shadow-[0_8px_20px_-8px_color-mix(in_oklab,var(--btn-color,var(--color-base-content))_70%,transparent)]"

  defp btn_variant(_solid), do: nil

  defp btn_size("md"), do: nil
  defp btn_size(size), do: "btn-" <> size

  defp btn_shape("pill", true), do: "btn-circle"
  defp btn_shape("pill", false), do: "rounded-full"
  defp btn_shape("square", _icon), do: "rounded-[calc(var(--radius-field)*.6)]"
  defp btn_shape(_rounded, _icon), do: nil
end
