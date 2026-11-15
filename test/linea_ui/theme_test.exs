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
                 value =~ ~r/^(#[0-9a-f]{6}|rgb\(\d+ \d+ \d+\/[.\d]+\)|\d+px)$/
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

    test "linea reproduces the kit's own colors" do
      %{light: light, dark: dark} = Theme.tokens(hd(Theme.themes()))

      assert get(light, "canvas") == "#fafafa"
      assert get(light, "line") == "#ebebeb"
      assert get(light, "muted") == "#737373"
      assert get(light, "accent") == "#0d8f91"
      assert get(light, "on-accent") == "#ffffff"
      assert get(light, "r-lg") == "14px"
      assert get(dark, "canvas") == "#141414"
      assert get(dark, "main") == "#0a0a0a"
      assert get(dark, "panel") == "#171717"
      assert get(dark, "accent") == "#2bbfbd"
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
               ~S|.dark[data-theme="acme"],:is(.dark,[data-theme="dark"]) [data-theme="acme"]:not(:is(.dark,[data-theme="dark"]) [data-theme="light"] [data-theme="acme"]:not(:is(.dark,[data-theme="dark"]) [data-theme="light"] :is(.dark,[data-theme="dark"]) [data-theme="acme"])),[data-theme="acme"] :is(.dark,[data-theme="dark"]):not([data-theme="acme"] [data-theme]:not([data-theme="acme"],[data-theme="light"],[data-theme="dark"]) *){color-scheme:dark;|

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

      assert_raise ArgumentError, ~r/radius/, fn ->
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
