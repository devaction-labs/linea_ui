defmodule LineaUI.Components.Icon do
  @moduledoc """
  Icons: Hugeicons Stroke Rounded by name, and the small glyphs LineaUI's own components draw (the cross of a
  toast, the chevron of a select, the check of a checkbox).

      <.icon name="huge-search-01" class="size-4" />
      <.glyph name={:chevron_down} class="size-4" />

  `icon/1` draws `huge-*` classes from Hugeicons (the free Stroke Rounded set, which the app vendors and
  `assets/css/hugeicons.cjs` turns into classes; see the README) and passes any other class name through, so
  `name="fa-solid fa-house"` works with Font Awesome. Write the name in full, never interpolated, or Tailwind
  cannot see the class.

  `glyph/1` is for the components: it draws LineOne's own SVG by default and the matching Hugeicons icon when the
  app sets

      config :linea_ui, :icons, :hugeicons

  The setting is read when the page renders; the hooks that draw glyphs in the browser read it from the
  `data-icons` attribute of their element.
  """

  use LineaUI.Component

  @lineone %{
    close: "M6 18L18 6M6 6l12 12",
    check: "M5 13l4 4L19 7",
    chevron_down: "M19 9l-7 7-7-7",
    chevron_up: "M5 15l7-7 7 7",
    chevron_left: "M15 19l-7-7 7-7",
    chevron_right: "M9 5l7 7-7 7",
    plus: "M12 4v16m8-8H4",
    minus: "M20 12H4",
    search: "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
  }

  @hugeicons %{
    close: "huge-cancel-01",
    check: "huge-tick-02",
    chevron_down: "huge-arrow-down-01",
    chevron_up: "huge-arrow-up-01",
    chevron_left: "huge-arrow-left-01",
    chevron_right: "huge-arrow-right-01",
    plus: "huge-plus-sign",
    minus: "huge-minus-sign",
    search: "huge-search-01"
  }

  @doc "The glyph names `glyph/1` knows."
  @spec glyph_names() :: [atom()]
  def glyph_names, do: @lineone |> Map.keys() |> Enum.sort()

  @doc "The icon set the app asked for: `:lineone` (the default) or `:hugeicons`."
  @spec icon_set() :: :lineone | :hugeicons
  def icon_set, do: Application.get_env(:linea_ui, :icons, :lineone)

  @doc "A Hugeicons icon by class name, or any other icon font class."
  attr :name, :string,
    required: true,
    doc: "`huge-search-01`, or any class such as `fa-solid fa-house`."

  attr :class, :any, default: "size-5"
  attr :rest, :global

  def icon(%{name: "huge-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} aria-hidden="true" {@rest}></span>
    """
  end

  def icon(assigns) do
    ~H"""
    <i class={[@name, @class]} aria-hidden="true" {@rest}></i>
    """
  end

  @doc "One of the glyphs LineaUI's components draw, in the icon set of the app."
  attr :name, :atom, required: true, values: Map.keys(@lineone)
  attr :class, :any, default: "size-4"
  attr :stroke_width, :any, default: "2", doc: "Only for LineOne's SVG; Hugeicons draw their own."
  attr :rest, :global

  def glyph(assigns), do: glyph(icon_set(), assigns)

  defp glyph(:hugeicons, assigns) do
    assigns = assign(assigns, :huge, Map.fetch!(@hugeicons, assigns.name))

    ~H"""
    <span class={[@huge, @class]} aria-hidden="true" {@rest}></span>
    """
  end

  defp glyph(:lineone, assigns) do
    assigns = assign(assigns, :path, Map.fetch!(@lineone, assigns.name))

    ~H"""
    <svg
      class={@class}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width={@stroke_width}
      aria-hidden="true"
      {@rest}
    >
      <path stroke-linecap="round" stroke-linejoin="round" d={@path} />
    </svg>
    """
  end
end
