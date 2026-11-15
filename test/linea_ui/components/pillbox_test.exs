defmodule LineaUI.Components.PillboxTest do
  use LineaUI.ComponentCase, async: true

  defp options,
    do: [
      %{label: "Tintas", value: "tintas", count: 128},
      %{label: "Ferramentas", value: "ferramentas", count: 86},
      %{label: "Acessórios", value: "acessorios", count: 54}
    ]

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp texts(html, selector),
    do:
      html
      |> find(selector)
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

  test "the chosen options are pills in the field, with a check box and a count in the list" do
    html =
      render(~H"""
      <.pillbox name="cats" value={["tintas", "acessorios"]} options={options()} />
      """)

    assert "pillbox" in classes(html, "#cats")
    assert attr_of(html, "#cats", "phx-hook") == ["LineaUI.Select"]
    assert attr_of(html, "#cats", "data-look") == ["pillbox"]
    assert attr_of(html, "#cats", "data-overflow") == ["count"]

    assert attr_of(html, "#cats .ts-control [data-ts-item]", "data-value") == [
             "tintas",
             "acessorios"
           ]

    assert texts(html, "#cats .ts-control .item-text") == ["Tintas", "Acessórios"]
    assert Enum.count(find(html, "#cats .ts-control .remove")) == 2
    assert Enum.count(find(html, "#cats [role=option] .sg-box")) == 3
    assert texts(html, "#cats [role=option] [data-hint]") == ["128", "86", "54"]
  end

  test "posts a list: name[] with an empty entry first, and the chosen values selected" do
    html = render(~H|<.pillbox name="cats" value={["tintas"]} options={options()} />|)

    assert attr_of(html, "#cats input[type=hidden]", "name") == ["cats[]"]
    assert attr_of(html, "#cats select[multiple]", "name") == ["cats[]"]
    assert attr_of(html, "#cats select option[selected]", "value") == ["tintas"]
  end

  test "takes id, name, value and errors from a form field" do
    html =
      render(~H"""
      <.pillbox field={field()} label="Categories" options={options()} />
      """)

    assert attr_of(html, "select[multiple]", "name") == ["product[cats][]"]
    assert attr_of(html, "select option[selected]", "value") == ["tintas"]
    assert "is-invalid" in classes(html, ".ts-wrapper")
    assert texts(html, "label") |> Enum.join() =~ "Categories"
  end

  test "an error shows its message and rings the field" do
    html =
      render(~H"""
      <.pillbox
        name="cats"
        label="Categories"
        errors={["Choose at least 2 categories."]}
        options={options()}
      />
      """)

    assert "is-invalid" in classes(html, "#cats")
    assert html =~ "Choose at least 2 categories."
    assert attr_of(html, "#cats [data-search]", "aria-invalid") == ["true"]
  end

  test "one line is the default; wrap lets the pills break" do
    one = render(~H|<.pillbox name="a" options={options()} />|)
    wrap = render(~H|<.pillbox name="b" options={options()} overflow="wrap" />|)

    assert attr_of(one, "#a", "data-overflow") == ["count"]
    assert attr_of(wrap, "#b", "data-overflow") == []
  end

  test "the +N pill is named by hidden_label" do
    html = render(~H|<.pillbox name="a" options={options()} hidden_label="%{count} hidden" />|)
    assert attr_of(html, "#a", "data-hidden-label") == ["%{count} hidden"]
  end

  test "create adds the key and the label of the last row; the search field is the panel" do
    html =
      render(~H"""
      <.pillbox name="a" options={options()} create create_label="Criar" search_placeholder="Buscar…" />
      """)

    assert attr_of(html, "#a", "data-create") == ["true"]
    assert attr_of(html, "#a", "data-create-label") == ["Criar"]
    assert attr_of(html, "#a", "data-create-hint") == ["↵"]
    assert attr_of(html, "#a", "data-create-position") == ["bottom"]
    assert attr_of(html, "#a [data-panel-search]", "placeholder") == ["Buscar…"]
  end

  test "clear draws the clear button" do
    assert Enum.count(
             find(
               render(~H|<.pillbox name="a" value={["tintas"]} options={options()} clear />|),
               "#a .clear-button"
             )
           ) == 1

    assert Enum.empty?(
             find(
               render(~H|<.pillbox name="a" value={["tintas"]} options={options()} />|),
               "#a .clear-button"
             )
           )
  end

  test "readonly keeps the values in the form but takes the x, the clear button and the list" do
    html =
      render(~H"""
      <.pillbox name="a" value={["tintas"]} options={options()} readonly clear label="Branches" />
      """)

    assert "readonly" in classes(html, "#a")
    assert attr_of(html, "#a", "data-readonly") == ["true"]
    assert Enum.empty?(find(html, "#a .remove"))
    assert Enum.empty?(find(html, "#a .clear-button"))
    assert attr_of(html, "#a select option[selected]", "value") == ["tintas"]
    assert attr_of(html, "#a select", "disabled") == []
  end

  test "disabled leaves the values out of the form" do
    html = render(~H|<.pillbox name="a" value={["tintas"]} options={options()} disabled />|)

    assert "disabled" in classes(html, "#a")
    assert attr_of(html, "#a select", "disabled") == [""]
    assert Enum.empty?(find(html, "#a .remove"))
  end

  test "people: the pill gets an avatar with the initials and the color" do
    html = render(~H|<.pillbox name="p" value={["1", "2"]} options={people()} />|)

    assert texts(html, "#p .ts-control .sg-av") == ["MC", "RA"]

    assert attr_of(html, "#p .ts-control .sg-av", "style") == [
             "background:#8a5cd6",
             "background:#1a7f4b"
           ]

    assert Enum.empty?(find(html, "#p [role=option] .sg-av"))
  end

  test "a created value or a value outside the options still shows as a pill" do
    html = render(~H|<.pillbox name="a" value={["Retorno"]} options={options()} />|)
    assert texts(html, "#a .ts-control .item-text") == ["Retorno"]
  end

  defp field do
    form = Phoenix.Component.to_form(%{"cats" => ["tintas"]}, as: :product)
    %{form[:cats] | errors: [{"Choose at least 2 categories.", []}]}
  end

  test "on_load_more, has_more and loading_label are forwarded to the listbox" do
    html =
      render(~H"""
      <.pillbox name="a" options={options()} on_load_more="more" has_more loading_label="Carregando…" />
      """)

    assert attr_of(html, "#a", "data-on-load-more") == ["more"]
    assert attr_of(html, "#a", "data-has-more") == ["true"]
    assert texts(html, "#a [data-loading-row]") == ["Carregando…"]

    done = render(~H|<.pillbox name="a" options={options()} on_load_more="more" />|)
    assert attr_of(done, "#a", "data-has-more") == []
    assert attr_of(done, "#a [data-loading-row]", "class") == []
  end

  defp people do
    [
      %{label: "Marina Costa", value: "1", color: "#8a5cd6"},
      %{label: "Rafael Augusto Costa", value: "2", color: "#1a7f4b", initials: "RA"}
    ]
  end

  describe "single choice" do
    test "multiple={false} is one pill, submitted as name, with no check boxes" do
      html =
        render(~H"""
        <.pillbox name="product" value="tintas" options={options()} multiple={false} />
        """)

      assert "pillbox" in classes(html, "#product")
      assert "single" in classes(html, "#product")
      refute "multi" in classes(html, "#product")
      assert attr_of(html, "#product", "data-multiple") == ["false"]
      assert attr_of(html, "#product", "data-look") == ["pillbox"]
      assert attr_of(html, "#product", "data-search-mode") == ["panel"]
      assert attr_of(html, "#product .ts-control [data-ts-item]", "data-value") == ["tintas"]
      assert attr_of(html, "select[data-input]", "name") == ["product"]
      assert find(html, "select[data-input][multiple]") |> Enum.count() == 0
      assert find(html, "#product .option .sg-box") |> Enum.count() == 0
      assert find(html, "#product [data-panel-search]") |> Enum.count() == 1
    end

    test "the multiple pillbox keeps its check boxes and name[]" do
      html = render(~H|<.pillbox name="cats" options={options()} />|)
      assert find(html, "#cats .option .sg-box") |> Enum.count() == 3
      assert attr_of(html, "select[data-input]", "name") == ["cats[]"]
    end
  end

  describe "size" do
    test "md by default, sm and lg set data-size for the 32 / 48px field" do
      assert attr_of(render(~H|<.pillbox name="a" options={options()} />|), "#a", "data-size") ==
               []

      assert attr_of(
               render(~H|<.pillbox name="a" options={options()} size="sm" />|),
               "#a",
               "data-size"
             ) ==
               ["sm"]

      assert attr_of(
               render(~H|<.pillbox name="a" options={options()} size="lg" />|),
               "#a",
               "data-size"
             ) ==
               ["lg"]
    end
  end

  describe "panel width" do
    test "panel_min_width and panel_class reach the list" do
      html =
        render(
          ~H|<.pillbox name="a" options={options()} panel_min_width="24rem" panel_class="shadow-xl" />|
        )

      assert attr_of(html, "#a-dropdown", "style") == ["min-width:24rem"]
      assert "shadow-xl" in classes(html, "#a-dropdown")

      assert attr_of(
               render(~H|<.pillbox name="a" options={options()} />|),
               "#a-dropdown",
               "style"
             ) == []
    end
  end
end
