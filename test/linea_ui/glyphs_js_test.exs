defmodule LineaUI.GlyphsJsTest do
  use ExUnit.Case, async: true

  alias LineaUI.Components.Icon

  @source Path.expand("../../assets/js/linea_ui/lib/glyphs.js", __DIR__)
  @table ~r/export const GLYPHS = (\{.*?\n\})\n/s

  defp js_table do
    [_, json] = Regex.run(@table, File.read!(@source))
    Jason.decode!(json)
  end

  test "the glyphs the hooks draw are the glyphs of icon.ex, in both sets" do
    lineone = Icon.glyph_table(:lineone)
    hugeicons = Icon.glyph_table(:hugeicons)

    for {name, entry} <- js_table() do
      key = String.to_existing_atom(name)
      assert Map.has_key?(lineone, key), "#{name} is not a glyph of icon.ex"

      expected = lineone[key]

      assert entry["lineone"] == %{
               "view" => expected.view,
               "paint" => Atom.to_string(expected.paint),
               "body" => expected.body
             },
             "#{name}: LineOne's SVG differs from icon.ex"

      assert entry["hugeicons"] == hugeicons[key],
             "#{name}: the Hugeicons class differs from icon.ex"
    end
  end

  test "the hooks draw at least the glyphs they use today" do
    assert Enum.sort(Map.keys(js_table())) == ["angle_left", "angle_right", "close"]
  end
end
