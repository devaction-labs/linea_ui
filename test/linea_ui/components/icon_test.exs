defmodule LineaUI.Components.IconTest do
  use LineaUI.ComponentCase, async: false

  alias LineaUI.Components.Icon

  setup do
    on_exit(fn -> Application.delete_env(:linea_ui, :icons) end)
  end

  test "icon draws a Hugeicons class and passes any other class through" do
    html = render(~H|<.icon name="huge-search-01" class="size-4" />|)
    assert ["huge-search-01", "size-4"] == classes(html, "span")
    assert [_] = find(html, "span[aria-hidden=true]") |> Enum.to_list()

    other = render(~H|<.icon name="fa-solid fa-house" />|)
    assert ["fa-solid", "fa-house", "size-5"] == classes(other, "i")
  end

  test "glyph draws LineOne's SVG by default" do
    html = render(~H|<.glyph name={:close} />|)

    assert [_] =
             find(html, "svg[viewBox='0 0 24 24'] path[d='M6 18L18 6M6 6l12 12']")
             |> Enum.to_list()
  end

  test "glyph draws the Hugeicons icon when the app asks for them" do
    Application.put_env(:linea_ui, :icons, :hugeicons)
    html = render(~H|<.glyph name={:chevron_down} class="size-5" />|)
    assert ["huge-arrow-down-01", "size-5"] == classes(html, "span")
    assert find(html, "svg") |> Enum.to_list() == []
  end

  test "every glyph has both renderings" do
    for name <- LineaUI.Components.Icon.glyph_names() do
      assert Phoenix.LiveViewTest.render_component(&LineaUI.Components.Icon.glyph/1, name: name) =~
               "<svg"

      Application.put_env(:linea_ui, :icons, :hugeicons)

      assert Phoenix.LiveViewTest.render_component(&LineaUI.Components.Icon.glyph/1, name: name) =~
               "huge-"

      Application.delete_env(:linea_ui, :icons)
    end
  end

  test "both sets cover the same glyphs and every Hugeicons class is written in full" do
    lineone = Icon.glyph_table(:lineone)
    hugeicons = Icon.glyph_table(:hugeicons)

    assert Map.keys(lineone) |> Enum.sort() == Map.keys(hugeicons) |> Enum.sort()
    assert Icon.glyph_names() == Map.keys(lineone) |> Enum.sort()
    assert Enum.all?(Map.values(hugeicons), &(&1 =~ ~r/^huge-[a-z0-9]+(-[a-z0-9]+)*$/))
  end

  test "stroked glyphs take a stroke width, filled ones draw currentColor, bare ones carry no paint" do
    stroked = render(~H|<.glyph name={:calendar} stroke_width="1.5" />|)
    assert [svg] = find(stroked, "svg") |> Enum.to_list()
    assert LazyHTML.attribute(svg, "stroke-width") == ["1.5"]
    assert LazyHTML.attribute(svg, "fill") == ["none"]

    filled = render(~H|<.glyph name={:search_solid} />|)
    assert [filled_svg] = find(filled, "svg") |> Enum.to_list()
    assert LazyHTML.attribute(filled_svg, "fill") == ["currentColor"]
    assert LazyHTML.attribute(filled_svg, "stroke") == []

    bare = render(~H|<.glyph name={:editor_bold} class={nil} />|)
    assert [bare_svg] = find(bare, "svg") |> Enum.to_list()
    assert LazyHTML.attribute(bare_svg, "viewBox") == ["0 0 18 18"]
    assert LazyHTML.attribute(bare_svg, "class") in [[], [""]]
    assert LazyHTML.attribute(bare_svg, "fill") == []
    assert find(bare, "svg path.ql-stroke") |> Enum.count() == 2
  end

  test "multi-path glyphs keep every path" do
    html = render(~H|<.glyph name={:editor_picker_background} class={nil} />|)
    assert find(html, "svg g.ql-fill rect") |> Enum.count() > 10
  end
end
