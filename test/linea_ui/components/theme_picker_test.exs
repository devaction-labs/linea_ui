defmodule LineaUI.Components.ThemePickerTest do
  use LineaUI.ComponentCase, async: false

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp texts(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

  setup do
    on_exit(fn ->
      Application.delete_env(:linea_ui, :theme)
      Application.delete_env(:linea_ui, :themes)
    end)
  end

  describe "menu (default)" do
    test "a button with the current theme and a menu of the kit's twelve" do
      html = render(~H|<.theme_picker id="p" />|)

      assert attr_of(html, "#p", "phx-hook") == ["LineaUI.ThemePicker"]
      assert attr_of(html, "#p", "data-default") == ["linea"]
      assert attr_of(html, "#p", "data-variant") == ["menu"]
      assert attr_of(html, "#p .lo-tp-btn", "aria-label") == ["Theme"]
      assert texts(html, "#p [data-theme-current]") == ["Linea"]

      values = attr_of(html, "#p [role=menuitemradio]", "data-theme-value")

      assert values ==
               ~w(linea graphite ocean indigo violet plum rose sunset amber sand forest nord)

      assert attr_of(html, "#p .lo-tp-sw", "data-theme") == values
      assert attr_of(html, "#p [aria-checked=true]", "data-theme-value") == ["linea"]
      assert texts(html, "#p .lo-tp-opt .lbl") |> Enum.take(3) == ~w(Linea Graphite Ocean)
    end

    test "default, a list of themes, the label and the change event" do
      html =
        render(~H"""
        <.theme_picker
          id="p"
          default="ocean"
          themes={["linea", "ocean", %{id: "acme", label: "Acme Co"}, "my-brand"]}
          label="Tema"
          on_change="save_theme"
        />
        """)

      assert attr_of(html, "#p", "data-default") == ["ocean"]
      assert attr_of(html, "#p", "data-change-event") == ["save_theme"]
      assert texts(html, "#p [data-theme-current]") == ["Ocean"]
      assert texts(html, "#p .lo-tp-h") == ["Tema"]
      assert texts(html, "#p .lo-tp-opt .lbl") == ["Linea", "Ocean", "Acme Co", "My brand"]
      assert attr_of(html, "#p [aria-checked=true]", "data-theme-value") == ["ocean"]
    end

    test "the app's default and its own themes" do
      Application.put_env(:linea_ui, :theme, "sand")

      Application.put_env(:linea_ui, :themes,
        only: ~w(linea sand),
        extra: [%{id: "acme", label: "Acme"}]
      )

      html = render(~H|<.theme_picker id="p" />|)

      assert attr_of(html, "#p", "data-default") == ["sand"]
      assert attr_of(html, "#p [data-theme-value]", "data-theme-value") == ~w(linea sand acme)
    end
  end

  describe "grid" do
    test "a radiogroup of previews, each in its own theme" do
      html = render(~H|<.theme_picker id="g" variant="grid" default="forest" />|)

      assert "grid" in classes(html, "#g")
      assert attr_of(html, "#g .lo-tp-grid", "role") == ["radiogroup"]
      assert find(html, "#g [role=radio]") |> Enum.count() == 12
      assert find(html, "#g .lo-tp-btn") |> Enum.empty?()
      assert attr_of(html, "#g [role=radio][aria-checked=true]", "data-theme-value") == ["forest"]
      assert attr_of(html, "#g [role=radio][tabindex='0']", "data-theme-value") == ["forest"]
      assert attr_of(html, "#g .lo-tp-prev", "data-theme") |> Enum.take(2) == ~w(linea graphite)
    end

    test "the first option takes Tab when the current theme is not among them" do
      html = render(~H|<.theme_picker id="g" variant="grid" themes={~w(ocean forest)} />|)

      assert attr_of(html, "#g [role=radio]", "tabindex") == ["0", "-1"]
      assert attr_of(html, "#g [role=radio]", "aria-checked") == ["false", "false"]
    end
  end

  describe "linea_logo" do
    test "the drop in the hexagon, with the theme's accent" do
      html = render(~H|<.linea_logo />|)

      assert attr_of(html, "svg.lo-logo-mark", "aria-label") == ["LineaUI"]
      assert attr_of(html, "svg.lo-logo-mark", "width") == ["32"]
      assert find(html, "svg path") |> Enum.count() == 3
      assert "accent" in classes(html, "path.drop")
      assert [ring] = attr_of(html, "path.ring", "stroke")
      assert ring =~ ~r/^url\(#linea-logo-\d+-r\)$/

      ids = render(~H"<.linea_logo /><.linea_logo />") |> attr_of("linearGradient", "id")
      assert length(Enum.uniq(ids)) == 4
      assert find(html, ".lo-logo-word") |> Enum.empty?()
    end

    test "size, tone, id and the wordmark" do
      html = render(~H|<.linea_logo id="hero" size={20} tone="mono" wordmark />|)

      assert "small" in classes(html, "svg")
      assert "mono" in classes(html, "path.drop")
      assert attr_of(html, "linearGradient", "id") == ["hero-r", "hero-b"]
      assert texts(html, ".lo-logo-word") == ["LineaUI"]
    end

    test "the word follows the mark like the canvas, or takes word_size" do
      word = fn html -> attr_of(html, ".lo-logo-word", "style") end
      assert word.(render(~H|<.linea_logo size={28} wordmark />|)) == ["font-size:17px"]
      assert word.(render(~H|<.linea_logo size={40} wordmark />|)) == ["font-size:24px"]
      assert word.(render(~H|<.linea_logo size={56} wordmark />|)) == ["font-size:30px"]
      assert word.(render(~H|<.linea_logo size={96} wordmark />|)) == ["font-size:30px"]

      html = render(~H|<.linea_logo size={28} word_size={20} wordmark />|)
      assert attr_of(html, ".lo-logo-word", "style") == ["font-size:20px"]
    end
  end

  describe "theme_script" do
    test "applies the stored theme, else the default, before the first paint" do
      html = render(~H|<.theme_script theme="ocean" />|)

      assert attr_of(html, "script", "data-theme-default") == ["ocean"]
      assert html =~ ~s|localStorage.getItem("linea-theme")|
      assert html =~ "document.documentElement.dataset.theme"

      Application.put_env(:linea_ui, :theme, "sand")
      assert attr_of(render(~H|<.theme_script />|), "script", "data-theme-default") == ["sand"]
    end
  end
end
