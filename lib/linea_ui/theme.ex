defmodule LineaUI.Theme do
  @moduledoc """
  Named themes, in the spirit of daisyUI's: each one is a palette with its own neutrals, accent and corners, in a
  light and a dark version, chosen by `data-theme` on `<html>` (or on any block) and kept apart from the
  light / dark / system choice of `theme_switch/1`. So "ocean" in the dark mode is ocean's dark version.

      <html data-theme="ocean" class="dark">

  The kit ships twelve (`themes/0`) in `assets/css/parts/themes.css`, built from the seeds below by
  `mix linea_ui.themes` (the default one, `linea`, is the teal of the kit). An app makes its own with
  `mix linea_ui.gen.theme acme --accent "#7c3aed"` (or `css/1` with a seed) and lists it in the picker through
  `config :linea_ui, :themes, [%{id: "acme", label: "Acme"}]`. `theme_picker/1` lets the user choose; the choice
  is kept in `localStorage["linea-theme"]` and `theme_script/1` applies it before the first paint.

  ## A seed

  | key           | what                                                                                   |
  |---------------|----------------------------------------------------------------------------------------|
  | `id`          | the `data-theme` value (`[a-z0-9-]`, not `light` or `dark`)                            |
  | `label`       | the name the picker shows                                                              |
  | `accent`      | the accent of the light version, a hex                                                 |
  | `dark_accent` | the accent of the dark version (default: the light one, lifted to read on dark)        |
  | `neutral`     | the hue of the grays (degrees, or `"neutral"`, `"cool"`, `"slate"`, `"warm"`, `"stone"`) |
  | `chroma`      | how tinted the grays are (0 for pure grays, 0.02 for a clear tint)                     |
  | `radius`      | `"none"`, `"sm"`, `"md"` (the kit's) or `"lg"`                                         |
  | `paper`       | `true` tints the cards too (a cream or paper look), not only the page                 |
  | `dark_lift`   | how much lighter the dark version's surfaces are (0 is the kit's near-black, 0.1 a slate) |

  Every token the components read is derived from these: surfaces, lines, text, the accent and its soft, ink and
  on-accent colors, charts, heat map, focus ring, and the Tailwind colors (`primary`, `slate-*`, `navy-*`) the
  utility classes use.
  """

  alias LineaUI.Theme.Color

  @radius %{
    "none" => [r_sm: 4, r: 4, r_lg: 6, r_xl: 8, pill: 4, pill_in: 3, pill_xs: 3],
    "sm" => [r_sm: 6, r: 8, r_lg: 10, r_xl: 12, pill: 6, pill_in: 4, pill_xs: 4],
    "md" => [r_sm: 8, r: 10, r_lg: 14, r_xl: 16, pill: 8, pill_in: 6, pill_xs: 6],
    "lg" => [r_sm: 10, r: 12, r_lg: 18, r_xl: 22, pill: 10, pill_in: 8, pill_xs: 8]
  }

  @neutrals %{"neutral" => 90, "cool" => 285, "slate" => 257, "warm" => 50, "stone" => 70}

  @themes [
    %{
      id: "linea",
      label: "Linea",
      accent: "#0d8f91",
      dark_accent: "#2bbfbd",
      neutral: "neutral",
      chroma: 0,
      radius: "md",
      on_accent: "#ffffff"
    },
    %{
      id: "graphite",
      label: "Graphite",
      accent: "#18181b",
      dark_accent: "#e4e4e7",
      neutral: "cool",
      chroma: 0.006,
      radius: "sm"
    },
    %{
      id: "ocean",
      label: "Ocean",
      accent: "#2563eb",
      dark_accent: "#4f8ff7",
      neutral: "slate",
      chroma: 0.02,
      radius: "md"
    },
    %{
      id: "indigo",
      label: "Indigo",
      accent: "#4f46e5",
      dark_accent: "#818cf8",
      neutral: 275,
      chroma: 0.012,
      radius: "lg"
    },
    %{
      id: "violet",
      label: "Violet",
      accent: "#7c3aed",
      dark_accent: "#a78bfa",
      neutral: 295,
      chroma: 0.01,
      radius: "lg"
    },
    %{
      id: "plum",
      label: "Plum",
      accent: "#a21caf",
      dark_accent: "#e879f9",
      neutral: 320,
      chroma: 0.01,
      radius: "md"
    },
    %{
      id: "rose",
      label: "Rose",
      accent: "#e11d48",
      dark_accent: "#fb7185",
      neutral: 15,
      chroma: 0.008,
      radius: "lg"
    },
    %{
      id: "sunset",
      label: "Sunset",
      accent: "#c2410c",
      dark_accent: "#fb923c",
      neutral: "warm",
      chroma: 0.008,
      radius: "lg"
    },
    %{
      id: "amber",
      label: "Amber",
      accent: "#f59e0b",
      dark_accent: "#fbbf24",
      neutral: "stone",
      chroma: 0.01,
      radius: "md"
    },
    %{
      id: "sand",
      label: "Sand",
      accent: "#b4532a",
      dark_accent: "#e08a5f",
      neutral: 80,
      chroma: 0.016,
      radius: "sm",
      paper: true
    },
    %{
      id: "forest",
      label: "Forest",
      accent: "#15803d",
      dark_accent: "#4ade80",
      neutral: 150,
      chroma: 0.012,
      radius: "md"
    },
    %{
      id: "nord",
      label: "Nord",
      accent: "#4c6d96",
      dark_accent: "#88c0d0",
      neutral: 250,
      chroma: 0.025,
      radius: "none",
      dark_lift: 0.1
    }
  ]

  @reserved ~w(light dark)

  @doc "The themes the kit ships, as seeds."
  @spec themes() :: [map()]
  def themes, do: @themes

  @doc """
  The themes the picker offers: the kit's, then the app's (`config :linea_ui, :themes`, maps with `id` and
  `label`), the app's winning on a repeated id. With `config :linea_ui, :themes, only: [...]` the kit's are cut to
  those ids.
  """
  @spec all() :: [map()]
  def all do
    config = Application.get_env(:linea_ui, :themes, [])

    {only, extra} =
      if Keyword.keyword?(config), do: {config[:only], config[:extra] || []}, else: {nil, config}

    kit =
      if only,
        do: Enum.filter(@themes, &(&1.id in Enum.map(only, fn id -> to_string(id) end))),
        else: @themes

    ids = MapSet.new(extra, &to_string(&1[:id] || &1["id"]))
    Enum.reject(kit, &(&1.id in ids)) ++ Enum.map(extra, &normalize/1)
  end

  @doc "A theme by id, among `all/0`."
  @spec get(String.t()) :: map() | nil
  def get(id), do: Enum.find(all(), &(&1.id == to_string(id)))

  defp normalize(theme) do
    Map.new(theme, fn {k, v} -> {if(is_binary(k), do: String.to_atom(k), else: k), v} end)
    |> Map.update(:id, nil, &to_string/1)
    |> Map.put_new_lazy(:label, fn ->
      theme |> Map.get(:id, theme["id"]) |> to_string() |> String.capitalize()
    end)
  end

  @doc """
  A seed for a theme from an accent and options, validated, as `mix linea_ui.gen.theme` builds it.

      iex> LineaUI.Theme.seed("acme", accent: "#7c3aed").radius
      "md"
  """
  @spec seed(String.t(), keyword()) :: map()
  def seed(id, opts) do
    id = to_string(id)

    unless id =~ ~r/^[a-z][a-z0-9-]*$/ and id not in @reserved,
      do:
        raise(
          ArgumentError,
          "a theme id is [a-z0-9-], starts with a letter and is not light or dark: #{inspect(id)}"
        )

    accent = hex!(opts[:accent] || raise(ArgumentError, "a theme needs an accent (a hex color)"))
    radius = to_string(opts[:radius] || "md")

    unless Map.has_key?(@radius, radius),
      do: raise(ArgumentError, "radius is none, sm, md or lg: #{inspect(radius)}")

    %{
      id: id,
      label: opts[:label] || id |> String.replace("-", " ") |> String.capitalize(),
      accent: accent,
      dark_accent: opts[:dark_accent] && hex!(opts[:dark_accent]),
      neutral: neutral_opt(opts[:neutral]),
      chroma: opts[:chroma] || 0.008,
      radius: radius,
      paper: opts[:paper] == true,
      dark_lift: opts[:dark_lift] || 0
    }
  end

  defp neutral_opt(nil), do: "neutral"
  defp neutral_opt(value) when is_number(value), do: value

  defp neutral_opt(value) do
    case Integer.parse(to_string(value)) do
      {hue, ""} ->
        hue

      _ when is_map_key(@neutrals, value) ->
        value

      _ ->
        raise ArgumentError,
              "neutral is a hue (0-360) or one of #{Enum.join(Map.keys(@neutrals), ", ")}"
    end
  end

  defp hex!(value) do
    value = String.downcase(to_string(value))

    cond do
      value =~ ~r/^#[0-9a-f]{6}$/ -> value
      value =~ ~r/^#[0-9a-f]{3}$/ -> Color.to_hex(Color.oklch(value))
      true -> raise ArgumentError, "a color is #rrggbb: #{inspect(value)}"
    end
  end

  # ---------------------------------------------------------------- tokens

  @doc "The light and dark tokens of a seed, as `%{light: [{name, value}], dark: [...]}`."
  @spec tokens(map()) :: %{light: [{String.t(), String.t()}], dark: [{String.t(), String.t()}]}
  def tokens(seed) do
    hue = hue(seed[:neutral] || "neutral")
    chroma = seed[:chroma] || 0
    n = fn l -> gray(l, chroma, hue) end
    lift = seed[:dark_lift] || 0
    d = fn l -> gray(l + lift * (1 - l), chroma * 1.2, hue) end
    radius = @radius[seed[:radius] || "md"]
    accent = seed.accent
    dark_accent = seed[:dark_accent] || lifted(accent)
    {light_ink, dark_ink} = {n.(0.145), d.(0.985)}

    shared = radius_tokens(radius) ++ tailwind_grays(n, d)

    light =
      [
        {"canvas", n.(0.985)},
        {"main", n.(0.985)},
        {"panel", if(seed[:paper], do: n.(0.995), else: "#ffffff")},
        {"raised", if(seed[:paper], do: n.(0.995), else: "#ffffff")},
        {"sunken", n.(0.97)},
        {"hover", n.(0.97)},
        {"line", n.(0.94)},
        {"line-strong", n.(0.885)},
        {"ink", light_ink},
        {"fg", n.(0.205)},
        {"muted", n.(0.556)},
        {"faint", n.(0.715)},
        {"solid", n.(0.205)},
        {"on-solid", n.(0.985)},
        {"ctl", if(seed[:paper], do: n.(0.995), else: "#ffffff")},
        {"ctl-line", Color.alpha(light_ink, 0.1)},
        {"ctl-line-strong", Color.alpha(light_ink, 0.18)},
        {"ctl-hover", Color.alpha(light_ink, 0.035)},
        {"ctl-fill", Color.alpha(light_ink, 0.04)},
        {"ctl-fill-hover", Color.alpha(light_ink, 0.075)},
        {"ctl-track", Color.alpha(light_ink, 0.12)},
        {"track", Color.alpha(light_ink, 0.12)},
        {"ring", Color.alpha(light_ink, 0.32)},
        {"ring-line", n.(0.715)},
        {"tip", n.(0.205)},
        {"on-tip", n.(0.985)}
      ] ++
        accent_tokens(accent, :light, seed[:on_accent], light_panel(seed)) ++
        status_tokens(:light) ++ heat(accent, n.(0.955), [0.2, 0.45, 0.75])

    dark =
      [
        {"canvas", d.(0.191)},
        {"main", d.(0.145)},
        {"panel", d.(0.205)},
        {"raised", d.(0.205)},
        {"sunken", d.(0.248)},
        {"hover", d.(0.269)},
        {"line", Color.alpha(dark_ink, 0.1)},
        {"line-strong", Color.alpha(dark_ink, 0.15)},
        {"ink", dark_ink},
        {"fg", d.(0.922)},
        {"muted", d.(0.709)},
        {"faint", d.(0.556)},
        {"solid", d.(0.922)},
        {"on-solid", d.(0.205)},
        {"ctl", Color.alpha(dark_ink, 0.045)},
        {"ctl-line", Color.alpha(dark_ink, 0.15)},
        {"ctl-line-strong", Color.alpha(dark_ink, 0.24)},
        {"ctl-hover", Color.alpha(dark_ink, 0.05)},
        {"ctl-fill", Color.alpha(dark_ink, 0.07)},
        {"ctl-fill-hover", Color.alpha(dark_ink, 0.11)},
        {"ctl-track", Color.alpha(dark_ink, 0.16)},
        {"track", Color.alpha(dark_ink, 0.15)},
        {"ring", Color.alpha(dark_ink, 0.22)},
        {"ring-line", d.(0.556)},
        {"tip", d.(0.922)},
        {"on-tip", d.(0.205)}
      ] ++
        accent_tokens(dark_accent, :dark, seed[:dark_on_accent], d.(0.205)) ++
        status_tokens(:dark) ++ heat(dark_accent, d.(0.269), [0.25, 0.45, 0.7])

    %{
      light: light ++ shared ++ tailwind(accent, light, :light),
      dark: dark ++ shared ++ tailwind(dark_accent, dark, :dark)
    }
  end

  defp accent_tokens(accent, scheme, on_accent, panel) do
    {l, c, h} = Color.oklch(accent)
    on = on_accent || on(accent)

    case scheme do
      :light ->
        [
          {"accent", accent},
          {"accent-ink", readable({max(l - 0.12, 0.3), c * 0.85, h}, panel, -0.02)},
          {"accent-soft", toward(accent, 0.955, 0.17)},
          {"accent-2", toward(accent, l + (0.95 - l) * 0.58, 0.8)},
          {"accent-3", toward(accent, l + (0.95 - l) * 0.85, 0.42)},
          {"on-accent", on},
          {"c1", accent}
        ]

      :dark ->
        [
          {"accent", accent},
          {"accent-ink", readable({min(l + 0.08, 0.92), c * 0.9, h}, panel, 0.02)},
          {"accent-soft", Color.alpha(accent, 0.14)},
          {"accent-2", toward(accent, l - (l - 0.205) * 0.3, 0.8)},
          {"accent-3", toward(accent, l - (l - 0.205) * 0.6, 0.55)},
          {"on-accent", on},
          {"c1", accent}
        ]
    end
  end

  defp status_tokens(:light) do
    [
      {"pos", "#1a7f4b"},
      {"pos-soft", "#e5f3eb"},
      {"neg", "#dc2626"},
      {"neg-soft", "#fef2f2"},
      {"warn", "#a16207"},
      {"warn-soft", "#fbf3dc"},
      {"info", "#2f5fd0"},
      {"info-soft", "#e8eefc"},
      {"danger", "#dc2626"},
      {"on-danger", "#ffffff"}
    ]
  end

  defp status_tokens(:dark) do
    [
      {"pos", "#4cc584"},
      {"pos-soft", "rgb(76 197 132/.13)"},
      {"neg", "#f87171"},
      {"neg-soft", "rgb(248 113 113/.12)"},
      {"warn", "#e6b24a"},
      {"warn-soft", "rgb(230 178 74/.13)"},
      {"info", "#7aa2ff"},
      {"info-soft", "rgb(122 162 255/.13)"},
      {"danger", "#b4363a"},
      {"on-danger", "#ffffff"}
    ]
  end

  defp heat(accent, base, steps) do
    {l, _c, _h} = Color.oklch(accent)
    {base_l, _, _} = Color.oklch(base)

    steps =
      steps
      |> Enum.with_index(1)
      |> Enum.map(fn {t, i} ->
        {"heat#{i}", toward(accent, base_l + (l - base_l) * t, 0.3 + 0.7 * t)}
      end)

    [{"heat0", base}] ++ steps ++ [{"heat4", accent}]
  end

  # white on the accent when it reads (4.5:1), else the darker or lighter text that reads best
  defp on(accent) do
    {_l, c, h} = Color.oklch(accent)
    dark = Color.to_hex({0.2, min(c, 0.06), h})

    cond do
      Color.contrast("#ffffff", accent) >= 4.5 -> "#ffffff"
      Color.contrast(dark, accent) >= Color.contrast("#ffffff", accent) -> dark
      true -> "#ffffff"
    end
  end

  # a text color moved in lightness until it reads on `surface` (4.5:1)
  defp readable({l, c, h}, surface, step) do
    hex = Color.to_hex({l, c, h})

    if Color.contrast(hex, surface) >= 4.5 or l <= 0.05 or l >= 0.98,
      do: hex,
      else: readable({l + step, c, h}, surface, step)
  end

  defp light_panel(seed),
    do:
      if(seed[:paper],
        do: gray(0.995, seed[:chroma] || 0, hue(seed[:neutral] || "neutral")),
        else: "#ffffff"
      )

  # the accent's hue at another lightness, with a share of its chroma
  defp toward(accent, lightness, share) do
    {_l, c, h} = Color.oklch(accent)
    Color.to_hex({lightness, c * share, h})
  end

  defp radius_tokens(radius) do
    Enum.map(radius, fn {key, px} ->
      {key |> Atom.to_string() |> String.replace("_", "-"), "#{px}px"}
    end)
  end

  # tokens that refer to others: redeclared on the themed element, so a block inside another theme reads its own
  defp tailwind(accent, tokens, scheme) do
    get = fn name -> tokens |> List.keyfind(name, 0) |> elem(1) end

    [
      {"pop", get.("panel")},
      {"seg-on", if(scheme == :light, do: get.("panel"), else: Color.alpha(get.("ink"), 0.08))},
      {"control-on", get.("solid")},
      {"on-control", get.("on-solid")},
      {"tint", get.("hover")},
      {"color-primary", accent},
      {"color-primary-focus", get.("accent-ink")},
      {"color-accent", accent},
      {"color-accent-focus", get.("accent-ink")},
      {"color-accent-light", get.("accent-ink")}
    ]
  end

  defp tailwind_grays(n, d) do
    slate = [
      {"50", 0.985},
      {"100", 0.97},
      {"150", 0.94},
      {"200", 0.922},
      {"300", 0.885},
      {"400", 0.715},
      {"500", 0.556},
      {"600", 0.439},
      {"700", 0.269},
      {"800", 0.205},
      {"900", 0.145},
      {"950", 0.115}
    ]

    navy = [
      {"50", 0.985},
      {"100", 0.955},
      {"200", 0.922},
      {"300", 0.709},
      {"400", 0.556},
      {"450", 0.348},
      {"500", 0.301},
      {"600", 0.269},
      {"700", 0.226},
      {"750", 0.205},
      {"800", 0.248},
      {"900", 0.191}
    ]

    Enum.map(slate, fn {step, l} -> {"color-slate-#{step}", n.(l)} end) ++
      Enum.map(navy, fn {step, l} -> {"color-navy-#{step}", d.(l)} end)
  end

  defp hue(name) when is_binary(name), do: Map.fetch!(@neutrals, name)
  defp hue(degrees), do: degrees

  # grays carry less tint near white and black, as Tailwind's slate and zinc do
  defp gray(l, 0, _hue), do: Color.to_hex({l, 0.0, 0.0})

  defp gray(l, chroma, hue) do
    k = (1 - abs(l - 0.55) * 1.4) |> max(0.25) |> min(1.0)
    Color.to_hex({l, chroma * k, hue})
  end

  # the light accent made readable on a dark surface
  defp lifted(accent) do
    {l, c, h} = Color.oklch(accent)
    Color.to_hex({max(l, 0.72), c * 0.9, h})
  end

  # ---------------------------------------------------------------- CSS

  @doc """
  The CSS of a theme: its light version on `[data-theme="id"]` and its dark one where that meets the `dark` class
  (on the same element, above it or under it) or a `data-theme="dark"` block (above or under it).
  """
  @spec css(map()) :: String.t()
  def css(seed) do
    %{light: light, dark: dark} = tokens(seed)
    id = seed.id

    """
    [data-theme="#{id}"]{color-scheme:light;#{declarations(light)}}
    .dark[data-theme="#{id}"],:is(.dark,[data-theme="dark"]) [data-theme="#{id}"],[data-theme="#{id}"] :is(.dark,[data-theme="dark"]){color-scheme:dark;#{declarations(dark)}}
    """
  end

  defp declarations(tokens),
    do: Enum.map_join(tokens, fn {name, value} -> "--#{name}:#{value};" end)

  @doc "The stylesheet of the kit's themes (`assets/css/parts/themes.css`)."
  @spec stylesheet() :: String.t()
  def stylesheet do
    """
    /*
      The named themes of the kit (LineaUI.Theme): a palette in a light and a dark version per `data-theme`, the
      dark one where it meets the `dark` class. Generated by `mix linea_ui.themes` from the seeds in
      lib/linea_ui/theme.ex: do not edit by hand.
    */
    """ <> Enum.map_join(@themes, "", &css/1)
  end
end
