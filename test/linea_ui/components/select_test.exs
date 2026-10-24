defmodule LineaUI.Components.SelectTest do
  use LineaUI.ComponentCase, async: true

  alias LineaUI.Components.Select.Options

  describe "native" do
    test "outline md by default, with the label above" do
      html = render(~H|<.select native name="e" label="Event" options={~w(A B)} value="B" />|)
      classes = classes(html, "select")
      assert "form-select" in classes
      assert "border-slate-300" in classes
      assert "mt-1.5" in classes
      assert "rounded-lg" in classes
      assert html |> find("label > span") |> LazyHTML.text() == "Event"
      assert html |> find("option[selected]") |> LazyHTML.attribute("value") == ["B"]
    end

    test "variants, sizes and shapes" do
      assert "bg-slate-150" in classes(
               render(~H|<.select native variant="filled" options={[]} />|),
               "select"
             )

      assert "h-8" in classes(render(~H|<.select native size="sm" options={[]} />|), "select")
      assert "h-12" in classes(render(~H|<.select native size="lg" options={[]} />|), "select")

      assert "rounded-full" in classes(
               render(~H|<.select native shape="pill" options={[]} />|),
               "select"
             )

      refute "mt-1.5" in classes(render(~H|<.select native options={[]} />|), "select")
    end

    test "multiple, disabled, prompt and groups" do
      html =
        render(~H"""
        <.select
          native
          multiple
          disabled
          prompt="Pick"
          value={["b"]}
          options={[{"G", [{"A", "a"}, {"B", "b"}]}, "C"]}
        />
        """)

      assert "form-multiselect" in classes(html, "select")
      assert find(html, "select[multiple][disabled]") |> Enum.count() == 1
      assert html |> find("option[value='']") |> LazyHTML.text() == "Pick"
      assert html |> find("optgroup[label=G] option") |> Enum.count() == 2
      assert html |> find("option[selected]") |> LazyHTML.attribute("value") == ["b"]
    end

    test "field wiring, help and errors" do
      assigns = %{__changed__: nil, form: Phoenix.Component.to_form(%{"kind" => "b"}, as: :party)}

      html =
        rendered_to_string(
          ~H|<.select native field={@form[:kind]} options={~w(a b)} help="Pick" errors={["is bad"]} />|
        )

      assert find(html, "select[name='party[kind]'][id=party_kind]") |> Enum.count() == 1
      assert html |> find("option[selected]") |> LazyHTML.attribute("value") == ["b"]
      assert "border-error" in classes(html, "select")
      assert html |> find(".text-error") |> LazyHTML.text() =~ "is bad"
      assert html |> find(".text-slate-400") |> LazyHTML.text() =~ "Pick"
    end
  end

  describe "listbox" do
    test "the hook, the hidden select and the chips" do
      html =
        render(~H"""
        <.select
          id="s"
          name="state"
          options={[{"Alabama", "AL"}, {"Alaska", "AK"}]}
          value={["AK"]}
          multiple
          removable
          clearable
          placeholder="Pick"
        />
        """)

      assert find(html, "#s[phx-hook='LineaUI.Select'].ts-wrapper.multi.has-items")
             |> Enum.count() == 1

      assert find(html, "#s.plugin-remove_button.plugin-clear_button") |> Enum.count() == 1
      assert html |> find("#s") |> LazyHTML.attribute("data-value") == [~s(["AK"])]

      assert html
             |> find("select[name='state[]'] option[selected]")
             |> LazyHTML.attribute("value") == ["AK"]

      assert find(html, "input[type=hidden][name='state[]'][value='']") |> Enum.count() == 1
      assert html |> find(".ts-control [data-ts-item]") |> LazyHTML.text() =~ "Alaska"
      assert find(html, ".ts-control [data-ts-item] [data-remove]") |> Enum.count() == 1
      assert find(html, ".ts-control [data-clear]") |> Enum.count() == 1
      assert html |> find("[data-search]") |> LazyHTML.attribute("placeholder") == ["Pick"]

      assert html |> find(".ts-dropdown .option") |> LazyHTML.attribute("data-value") == [
               "AL",
               "AK"
             ]

      assert find(html, "[data-templates] template[data-value=AL]") |> Enum.count() == 1
    end

    test "a single select with a value is full and hides its input" do
      html = render(~H|<.select id="s" name="e" options={~w(A B)} value="B" />|)
      assert find(html, "#s.single.full.input-hidden") |> Enum.count() == 1

      assert html |> find("select[name=e] option[selected]") |> LazyHTML.attribute("value") == [
               "B"
             ]
    end

    test "an empty single select submits an empty value" do
      html = render(~H|<.select id="s" name="e" options={~w(A B)} />|)
      assert html |> find("select[name=e] option") |> LazyHTML.attribute("value") == [""]
    end

    test "groups, disabled options, create, max and search attrs" do
      html =
        render(~H"""
        <.select
          id="s"
          name="e"
          options={[{"G", [%{label: "A", value: "a", disabled: true}]}]}
          create
          persist={false}
          max={2}
          multiple
          on_search="find"
          debounce={100}
          restore_on_backspace
        />
        """)

      assert html |> find(".optgroup .optgroup-header") |> LazyHTML.text() == "G"
      assert find(html, ".option[data-disabled][aria-disabled=true]") |> Enum.count() == 1
      assert find(html, ".option[data-selectable]") |> Enum.count() == 0
      wrapper = find(html, "#s")
      assert LazyHTML.attribute(wrapper, "data-create") == ["true"]
      assert LazyHTML.attribute(wrapper, "data-persist") == ["false"]
      assert LazyHTML.attribute(wrapper, "data-max") == ["2"]
      assert LazyHTML.attribute(wrapper, "data-on-search") == ["find"]
      assert LazyHTML.attribute(wrapper, "data-debounce") == ["100"]
      assert LazyHTML.attribute(wrapper, "data-restore") == ["true"]
    end

    test "option and item slots" do
      html =
        render(~H"""
        <.select id="s" name="a" options={[%{value: 1, label: "Jo", job: "Dev"}]} value={1} multiple>
          <:option :let={o}><b class="opt">{o.data.job}</b></:option>
          <:item :let={o}><i class="chip">{o.label}</i></:item>
        </.select>
        """)

      assert html |> find(".option b.opt") |> LazyHTML.text() == "Dev"
      assert html |> find(".ts-control span.item i.chip") |> LazyHTML.text() == "Jo"
    end

    test "field wiring names a multiple select with []" do
      form = Phoenix.Component.to_form(%{"states" => ["AL"]}, as: :place)
      assigns = %{__changed__: nil, form: form}

      html =
        rendered_to_string(~H|<.select field={@form[:states]} options={["AL", "AK"]} multiple />|)

      assert find(html, "#place_states") |> Enum.count() == 1

      assert find(html, "select[name='place[states][]'] option[value=AL][selected]")
             |> Enum.count() == 1
    end
  end

  test "an option with keywords carries them for the search to match" do
    html =
      render(~H"""
      <.select
        id="c"
        name="c"
        options={[
          %{label: "Brazil", value: "BR", keywords: ["brasil", "tupiniquim"]},
          %{label: "Chile", value: "CL", keywords: "cl"},
          %{label: "Peru", value: "PE"}
        ]}
      />
      """)

    assert find(html, ~s(.option[data-value="BR"])) |> LazyHTML.attribute("data-keywords") ==
             ["brasil tupiniquim"]

    assert find(html, ~s(.option[data-value="CL"])) |> LazyHTML.attribute("data-keywords") == ["cl"]
    assert find(html, ~s(.option[data-value="PE"])) |> LazyHTML.attribute("data-keywords") == []
  end

  test "Options reads every shape" do
    assert [
             %{label: "a", value: "a"},
             %{label: "B", value: "b"},
             %{type: :group, label: "G", options: [%{value: "x"}]},
             %{label: "M", value: "2", disabled: true}
           ] =
             Options.normalize([
               "a",
               {"B", "b"},
               {"G", ["x"]},
               %{label: "M", value: 2, disabled: true}
             ])

    assert [%{label: "c", value: "1"}] = Options.normalize(c: 1)
    assert Options.values(nil) == []
    assert Options.values([1, "", nil, :a]) == ["1", "a"]
    assert Options.find([], "z").label == "z"
  end

  test "native inline is as wide as its content" do
    html =
      render(~H"""
      <.select native inline id="a" name="a" options={~w(x y)} />
      <.select native id="b" name="b" options={~w(x y)} />
      """)

    assert "w-auto" in classes(html, "#a")
    refute "w-full" in classes(html, "#a")
    assert "pr-9" in classes(html, "#a")
    assert "w-full" in classes(html, "#b")
  end

  test "the listbox id falls back to the name, and the no-results text keeps its %{query}" do
    html = render(~H|<.select name="state" options={["A"]} no_results="None for %{query}" />|)
    assert find(html, "#state[phx-hook='LineaUI.Select']") |> Enum.count() == 1
    assert html |> find("select[name=state]") |> LazyHTML.attribute("id") == ["state-input"]
    assert html |> find("[data-no-results]") |> LazyHTML.text() == "None for %{query}"

    html = render(~H|<.select options={["A"]} />|)
    assert [id] = html |> find("[phx-hook='LineaUI.Select']") |> LazyHTML.attribute("id")
    assert id =~ "select-"
    assert html |> find("select") |> LazyHTML.attribute("name") == [id]
  end

  test "the search is in the control by default, in a panel on top of the list, or off" do
    control = render(~H|<.select id="s" name="e" options={~w(A B)} />|)
    assert control |> find("#s") |> LazyHTML.attribute("data-search-mode") == ["control"]
    assert control |> find(".ts-control [data-search]") |> LazyHTML.attribute("readonly") == []
    assert find(control, "[data-panel-search]") |> Enum.count() == 0

    panel =
      render(
        ~H|<.select id="s" name="e" options={~w(A B)} search="panel" search_placeholder="Find" />|
      )

    assert panel |> find("#s") |> LazyHTML.attribute("data-search-mode") == ["panel"]
    assert panel |> find(".ts-control [data-search]") |> LazyHTML.attribute("readonly") == [""]

    assert panel
           |> find(".ts-dropdown .ts-search input[data-panel-search]")
           |> LazyHTML.attribute("placeholder") == ["Find"]

    assert find(panel, ".ts-dropdown .ts-search svg") |> Enum.count() == 1

    none = render(~H|<.select id="s" name="e" options={~w(A B)} search="none" />|)
    assert none |> find("#s") |> LazyHTML.attribute("data-search-mode") == ["none"]
    assert none |> find(".ts-control [data-search]") |> LazyHTML.attribute("readonly") == [""]
    assert find(none, "[data-panel-search]") |> Enum.count() == 0
  end
end
