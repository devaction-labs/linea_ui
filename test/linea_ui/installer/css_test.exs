defmodule LineaUI.Installer.CssTest do
  use ExUnit.Case, async: true

  alias LineaUI.Installer.Css

  @phoenix File.read!("test/fixtures/phoenix_1_8/app.css")

  @fonts ~s|@import "../../deps/linea_ui/assets/css/fonts.css";|
  @styles ~s|@import "../../deps/linea_ui/assets/css/linea_ui.css";|

  test "imports the fonts and styles right after Tailwind's import" do
    lines = @phoenix |> Css.import_styles() |> String.split("\n")
    tailwind = Enum.find_index(lines, &(&1 == ~s|@import "tailwindcss" source(none);|))

    assert Enum.slice(lines, tailwind + 1, 2) == [@fonts, @styles]
  end

  test "importing twice changes nothing" do
    once = Css.import_styles(@phoenix)
    assert Css.import_styles(once) == once
  end

  test "adds only the import that is missing" do
    css = ~s|@import "tailwindcss";\n#{@styles}\n|

    assert Css.import_styles(css) == ~s|@import "tailwindcss";\n#{@fonts}\n#{@styles}\n|
  end

  test "accepts single quotes and no source modifier" do
    assert Css.import_styles("@import 'tailwindcss';\n") =~ @styles
  end

  test "leaves a stylesheet without Tailwind's import alone" do
    css = "body { color: red }\n"

    refute Css.tailwind?(css)
    assert Css.import_styles(css) == css
  end

  test "source(none) is detected and gets a @source for the templates after the last @source" do
    assert Css.source_none?(@phoenix)
    refute Css.source_none?(~s|@import "tailwindcss";|)

    lines = @phoenix |> Css.import_styles() |> Css.add_source() |> String.split("\n")
    added = Enum.find_index(lines, &(&1 == ~s|@source "../../deps/linea_ui/lib";|))

    assert Enum.at(lines, added - 1) =~ "_build/dev/phoenix-colocated"
  end

  test "adds the @source after the styles import when there is no other" do
    css = ~s|@import "tailwindcss" source(none);\n| |> Css.import_styles() |> Css.add_source()

    assert css ==
             ~s|@import "tailwindcss" source(none);\n#{@fonts}\n#{@styles}\n@source "../../deps/linea_ui/lib";\n|
  end

  test "adding the @source twice changes nothing" do
    once = @phoenix |> Css.import_styles() |> Css.add_source()
    assert Css.add_source(once) == once
  end

  test "adds the Hugeicons plugin after the styles import, once" do
    once = @phoenix |> Css.import_styles() |> Css.add_hugeicons()

    assert once =~
             ~s|#{@styles}\n@plugin "../../deps/linea_ui/assets/css/hugeicons.cjs" {\n  dir: "deps/hugeicons/icons";\n}|

    assert Css.add_hugeicons(once) == once
  end

  test "knows when daisyUI is loaded" do
    assert Css.daisyui?(@phoenix)
    refute Css.daisyui?(Css.replace_daisyui(@phoenix))
  end

  test "replacing daisyUI removes its plugins, themes, comments and the data-theme dark variant" do
    css = Css.replace_daisyui(@phoenix)

    refute css =~ "daisyui"
    refute css =~ "heroicons"
    refute css =~ "daisyUI"
    refute css =~ "data-theme"
    assert css =~ ~s|@import "tailwindcss" source(none);|
    assert css =~ "@custom-variant phx-click-loading"
    assert css =~ "[data-phx-session]"
  end

  test "replacing daisyUI twice changes nothing" do
    once = Css.replace_daisyui(@phoenix)
    assert Css.replace_daisyui(once) == once
  end
end
