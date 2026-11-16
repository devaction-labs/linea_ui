defmodule LineaUI.ThemeTest do
  use ExUnit.Case, async: false

  alias LineaUI.Theme
  alias LineaUI.Theme.Color

  doctest LineaUI.Theme
  doctest LineaUI.Theme.Color

  defp get(tokens, name), do: tokens |> List.keyfind(name, 0) |> elem(1)

  describe "color math" do
    test "hex goes to OKLCH and back" do
      for hex <- ~w(#0d8f91 #fafafa #0a0a0a #2563eb #f59e0b #ffffff #000000 #7c3aed) do
        assert hex |> Color.oklch() |> Color.to_hex() == hex
      end
    end

    test "a color out of the gamut keeps its lightness and loses chroma" do
      assert {l, c, _} = {0.6, 0.5, 140.0} |> Color.to_hex() |> Color.oklch()
      assert_in_delta l, 0.6, 0.01
      assert c < 0.5
    end

    test "alpha, mix and contrast" do
      assert Color.alpha("#0a0a0a", 0.1) == "rgb(10 10 10/.1)"
      assert Color.mix("#000000", "#ffffff", 1.0) == "#000000"
      assert Color.mix("#000000", "#ffffff", 0.0) == "#ffffff"
      assert_in_delta Color.contrast("#000000", "#ffffff"), 21.0, 0.01
      assert Color.light?("#fbbf24")
      refute Color.light?("#2563eb")
    end
  end

  describe "the kit's themes" do
    test "twelve, with unique ids that are neither light nor dark" do
      ids = Enum.map(Theme.themes(), & &1.id)
      assert length(ids) == 12
      assert ids == Enum.uniq(ids)
      assert hd(ids) == "linea"
      refute Enum.any?(ids, &(&1 in ~w(light dark)))
    end

    test "every theme defines the same tokens in light and dark" do
      names =
        Theme.themes() |> hd() |> Theme.tokens() |> Map.fetch!(:light) |> Enum.map(&elem(&1, 0))

      for theme <- Theme.themes(), scheme <- [:light, :dark] do
        tokens = Theme.tokens(theme) |> Map.fetch!(scheme)
        assert Enum.map(tokens, &elem(&1, 0)) == names, "#{theme.id} #{scheme}"

        assert Enum.all?(tokens, fn {_, value} ->
                 value =~ ~r/^(#[0-9a-f]{6}|rgb\(\d+ \d+ \d+\/[.\d]+\)|\d+px|\.\d+rem|0)$/
               end)
      end

      assert "accent" in names and "color-primary" in names and "color-navy-900" in names and
               "pill" in names
    end

    test "text reads on every surface" do
      for theme <- Theme.themes(), scheme <- [:light, :dark] do
        t = Theme.tokens(theme) |> Map.fetch!(scheme)
        at = "#{theme.id} #{scheme}"

        assert Color.contrast(get(t, "ink"), get(t, "canvas")) >= 12, at
        assert Color.contrast(get(t, "fg"), get(t, "panel")) >= 10, at
        assert Color.contrast(get(t, "muted"), get(t, "panel")) >= 4.5, at
        assert Color.contrast(get(t, "accent-ink"), get(t, "panel")) >= 4.5, at
        assert Color.contrast(get(t, "on-solid"), get(t, "solid")) >= 10, at

        unless theme.id == "linea" and scheme == :light do
          assert Color.contrast(get(t, "on-accent"), get(t, "accent")) >= 4.5, at
        end
      end
    end

    test "every theme sets daisyUI's variables, with content colors that read" do
      for theme <- Theme.themes(), scheme <- [:light, :dark] do
        t = Theme.tokens(theme) |> Map.fetch!(scheme)
        at = "#{theme.id} #{scheme}"
        names = Enum.map(t, &elem(&1, 0))

        assert Enum.all?(["color-primary", "color-accent" | Theme.daisy_names()], &(&1 in names)),
               at

        assert get(t, "color-base-100") == get(t, "panel"), at
        assert get(t, "color-base-content") == get(t, "fg"), at
        assert get(t, "color-primary") == get(t, "accent"), at
        assert get(t, "radius-field") == get(t, "r"), at

        for color <- ~w(secondary neutral info success warning error) do
          assert Color.contrast(get(t, "color-#{color}-content"), get(t, "color-#{color}")) >=
                   4.5,
                 "#{at} #{color}"
        end
      end
    end

    test "the bridge writes every token of the kit over daisyUI's variables" do
      names =
        Theme.themes() |> hd() |> Theme.tokens() |> Map.fetch!(:light) |> Enum.map(&elem(&1, 0))

      own = ["color-primary", "color-accent" | Theme.daisy_names()]

      assert Enum.sort(Enum.map(Theme.bridge(), &elem(&1, 0))) == Enum.sort(names -- own)
      assert Enum.all?(Theme.bridge(), fn {_, value} -> value =~ "var(--" end)
    end

    test "the stylesheet gives the page linea's daisyUI variables and bridges daisyUI's themes" do
      css = Theme.stylesheet()

      assert css =~
               ~S|:where(:root,.sg:not(:is(.dark,[data-theme]) *)),[data-theme="light"]{--color-primary:#0d8f91;|

      assert css =~ ~S|:is(.dark,[data-theme="dark"]){--color-primary:#2bbfbd;|
      assert css =~ ~S|:where([data-theme]){--canvas:var(--color-base-200);|
    end

    test "the text on any accent reaches 4.5:1" do
      for accent <- ~w(#777777 #808080 #0d8f91 #ff0000 #ffff00 #00ff00 #1e90ff #ff69b4),
          scheme <- [:light, :dark] do
        t =
          Theme.seed("x", accent: accent, dark_accent: accent)
          |> Theme.tokens()
          |> Map.fetch!(scheme)

        assert Color.contrast(get(t, "on-accent"), get(t, "accent")) >= 4.5, accent
      end
    end

    test "linea is the canvas palette, exactly" do
      %{light: light, dark: dark} = Theme.tokens(hd(Theme.themes()))

      for {name, value} <- [
            {"canvas", "#f4f3f0"},
            {"line", "#e8e6e1"},
            {"line-strong", "#d9d6cf"},
            {"muted", "#6c6b70"},
            {"ink", "#17171a"},
            {"accent", "#0d8f91"},
            {"neg", "#c2410c"},
            {"heat0", "#ecebe7"},
            {"on-accent", "#ffffff"},
            {"r-sm", "8px"},
            {"r", "12px"},
            {"r-lg", "16px"},
            {"r-xl", "22px"},
            {"pill", "999px"}
          ],
          do: assert(get(light, name) == value, name)

      for {name, value} <- [
            {"canvas", "#111113"},
            {"main", "#111113"},
            {"panel", "#19191c"},
            {"raised", "#1f1f23"},
            {"accent-soft", "rgb(43 191 189/.14)"},
            {"neg", "#f08a5b"},
            {"heat4", "#2bbfbd"},
            {"pill", "999px"}
          ],
          do: assert(get(dark, name) == value, name)
    end

    test "tokens of a seed are written over the generated ones, and daisyUI's follow" do
      %{light: light, dark: dark} = Theme.tokens(hd(Theme.themes()))

      assert get(light, "color-base-300") == "#e8e6e1"
      assert get(light, "color-base-200") == "#efeeea"
      assert get(light, "color-neutral") == "#17171a"
      assert get(light, "color-error") == "#c2410c"
      assert get(light, "radius-selector") == "8px"
      assert get(light, "radius-field") == "12px"
      assert get(light, "radius-box") == "16px"
      assert get(light, "color-primary") == "#0d8f91"
      assert get(dark, "color-base-100") == "#19191c"
      assert get(dark, "color-base-300") == "#232327"

      seed = %{id: "t", accent: "#7c3aed", tokens: %{light: %{"line" => "#123456"}}}
      t = Theme.tokens(seed)
      assert get(t.light, "line") == "#123456"
      assert get(t.light, "color-base-300") == "#123456"
      assert get(t.dark, "line") == get(Theme.tokens(Map.delete(seed, :tokens)).dark, "line")

      assert_raise ArgumentError, ~r/does not have: nope/, fn ->
        Theme.tokens(%{seed | tokens: %{light: %{"nope" => "#000000"}}})
      end
    end

    test "the other themes do not take the canvas's tokens" do
      for theme <- tl(Theme.themes()) do
        refute Map.has_key?(theme, :tokens), theme.id
      end
    end

    test "themes.css is the stylesheet the seeds build" do
      assert File.read!("assets/css/parts/themes.css") == Theme.stylesheet(),
             "run mix linea_ui.themes"
    end

    test "linea_ui.css imports the themes after the finish" do
      css = File.read!("assets/css/linea_ui.css")
      [before, _] = String.split(css, ~s(@import "./parts/themes.css";))
      assert before =~ ~s(@import "./parts/canvas-refine.css";)
      assert css =~ ~s(@import "./parts/canvas-theme-picker.css";)
    end
  end

  describe "css/1" do
    test "a light block on data-theme and a dark one where it meets the dark class" do
      css = Theme.css(Theme.seed("acme", accent: "#7c3aed"))
      [light, dark] = String.split(css, "\n", trim: true)

      assert light =~ ~r/^\[data-theme="acme"\]\{color-scheme:light;--canvas:#/

      assert dark =~
               ~S|.dark[data-theme="acme"],:is(.dark,[data-theme="dark"]) [data-theme="acme"]:not(:is(.dark,[data-theme="dark"]) [data-theme="light"] [data-theme="acme"]:not(:is(.dark,[data-theme="dark"]) [data-theme="light"] :is(.dark,[data-theme="dark"]) [data-theme="acme"])),[data-theme="acme"] :is(.dark,[data-theme="dark"]):not([data-theme]:not([data-theme="acme"],[data-theme="light"],[data-theme="dark"])):not([data-theme="acme"] [data-theme]:not([data-theme="acme"],[data-theme="light"],[data-theme="dark"]) *),|

      assert light =~ "--accent:#7c3aed;"
      assert light =~ "--color-primary:#7c3aed;"
    end
  end

  describe "seed/2" do
    test "fills the defaults" do
      assert %{id: "my-brand", label: "My brand", radius: "md", neutral: "neutral", paper: false} =
               Theme.seed("my-brand", accent: "#7C3AED")

      assert Theme.seed("x", accent: "#abc").accent == "#aabbcc"
      assert Theme.seed("x", accent: "#7c3aed", neutral: "80").neutral == 80
      assert Theme.seed("x", accent: "#7c3aed", neutral: "warm").neutral == "warm"
    end

    test "refuses what would not work" do
      assert_raise ArgumentError, ~r/theme id/, fn -> Theme.seed("dark", accent: "#7c3aed") end
      assert_raise ArgumentError, ~r/theme id/, fn -> Theme.seed("Acme", accent: "#7c3aed") end
      assert_raise ArgumentError, ~r/accent/, fn -> Theme.seed("acme", []) end
      assert_raise ArgumentError, ~r/#rrggbb/, fn -> Theme.seed("acme", accent: "purple") end

      assert Theme.seed("acme", accent: "#7c3aed", radius: "canvas").radius == "canvas"

      assert_raise ArgumentError, ~r/radius is none, sm, md, lg or canvas/, fn ->
        Theme.seed("acme", accent: "#7c3aed", radius: "xl")
      end

      assert_raise ArgumentError, ~r/neutral/, fn ->
        Theme.seed("acme", accent: "#7c3aed", neutral: "pink")
      end
    end
  end

  describe "all/0" do
    setup do
      on_exit(fn -> Application.delete_env(:linea_ui, :themes) end)
    end

    test "the kit's, then the app's" do
      assert length(Theme.all()) == 12

      Application.put_env(:linea_ui, :themes, extra: [%{id: "acme", label: "Acme"}])
      assert List.last(Theme.all()) == %{id: "acme", label: "Acme"}

      Application.put_env(:linea_ui, :themes, only: ~w(linea ocean), extra: [%{id: :acme}])
      assert Enum.map(Theme.all(), & &1.id) == ~w(linea ocean acme)
      assert Theme.get("acme").label == "Acme"

      Application.put_env(:linea_ui, :themes, [%{id: "ocean", label: "Mar"}])
      assert Theme.get("ocean").label == "Mar"
      assert length(Theme.all()) == 12
    end
  end

  describe "mix linea_ui.gen.theme" do
    @tag :tmp_dir
    test "writes the theme's CSS", %{tmp_dir: dir} do
      path = Path.join(dir, "acme.css")
      Mix.shell(Mix.Shell.Process)

      Mix.Tasks.LineaUi.Gen.Theme.run([
        "acme",
        "--accent",
        "#7c3aed",
        "--radius",
        "lg",
        "--out",
        path
      ])

      css = File.read!(path)
      assert css =~ ~s([data-theme="acme"]{color-scheme:light;)
      assert css =~ "--r-lg:18px;"
      assert_received {:mix_shell, :info, [message]}
      assert message =~ ~s(extra: [%{id: "acme", label: "Acme"}])
    after
      Mix.shell(Mix.Shell.IO)
    end

    test "fails on a bad seed" do
      assert_raise Mix.Error, ~r/accent/, fn -> Mix.Tasks.LineaUi.Gen.Theme.run(["acme"]) end
      assert_raise Mix.Error, ~r/usage/, fn -> Mix.Tasks.LineaUi.Gen.Theme.run([]) end
    end
  end
end
