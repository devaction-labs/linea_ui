defmodule LineaUI.Components.IconTest do
  use LineaUI.ComponentCase, async: false

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
end
