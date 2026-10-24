defmodule LineaUI.Components.ChoiceTest do
  use LineaUI.ComponentCase, async: true

  alias LineaUI.Components.DatePicker

  doctest LineaUI.Components.DatePicker, only: [date_range_preset: 3]

  describe "radio_group variant chip and card" do
    test "chips: a hidden real radio, the label, the count and the checked tone" do
      html =
        render(~H"""
        <.radio_group
          id="st"
          name="status"
          value="draft"
          variant="chip"
          color="primary"
          options={[
            %{label: "Todos", value: "all", count: 128},
            %{label: "Rascunho", value: "draft", count: 4}
          ]}
        />
        """)

      assert "flex" in classes(html, "[role=radiogroup]")
      assert "gap-2" in classes(html, "[role=radiogroup]")

      assert [_] =
               find(html, "input#st-1[type=radio][name=status][value=draft][checked]")
               |> Enum.to_list()

      assert "sr-only" in classes(html, "input")
      refute "form-radio" in classes(html, "input")
      label = classes(html, "label")
      assert "rounded-full" in label
      assert "has-checked:bg-primary" in label
      assert "dark:has-checked:bg-accent" in label

      assert html |> find("label") |> Enum.map(&LazyHTML.text/1) |> Enum.map(&String.split/1) == [
               ["Todos", "128"],
               ["Rascunho", "4"]
             ]
    end

    test "cards: the visible radio, the icon, title, description and per-slot count" do
      html =
        render(~H"""
        <.radio_group name="plan" variant="card" color="success" class="grid-cols-2">
          <:radio value="a" description="For one store" icon="huge-store-01" count={3}>Basic</:radio>
          <:radio value="b" disabled>Pro</:radio>
        </.radio_group>
        """)

      assert "grid" in classes(html, "[role=radiogroup]")
      assert "grid-cols-2" in classes(html, "[role=radiogroup]")
      assert "form-radio" in classes(html, "input")
      assert "is-basic" in classes(html, "input")
      card = classes(html, "label")
      assert "has-checked:border-success" in card
      assert "border-slate-300" in card
      assert [_] = find(html, "label span.huge-store-01, label .huge-store-01") |> Enum.to_list()
      assert html |> find("label") |> Enum.at(0) |> LazyHTML.text() =~ "For one store"
      assert html |> find("label") |> Enum.at(0) |> LazyHTML.text() =~ "3"
      assert [_] = find(html, "input[value=b][disabled]") |> Enum.to_list()
    end

    test "basic radios are unchanged" do
      html = render(~H|<.radio_group name="r" options={["a"]} />|)
      assert "inline-space" in classes(html, "[role=radiogroup]")
      assert "form-radio" in classes(html, "input")
    end
  end

  describe "checkbox_group variant chip and card" do
    test "chips submit name[] for every checked value" do
      html =
        render(~H"""
        <.checkbox_group
          name="ch[]"
          value={["email"]}
          variant="chip"
          options={[%{label: "E-mail", value: "email", count: 3}, {"SMS", "sms"}]}
        />
        """)

      assert [_] = find(html, "input[type=hidden][name='ch[]'][value='']") |> Enum.to_list()

      assert [_] =
               find(html, "input[type=checkbox][name='ch[]'][value=email][checked]")
               |> Enum.to_list()

      assert "sr-only" in classes(html, "input[type=checkbox]")
      assert "has-checked:bg-slate-700" in classes(html, "label")
    end

    test "cards with descriptions" do
      html =
        render(~H"""
        <.checkbox_group name="ch" variant="card" color="primary">
          <:checkbox value="email" description="Daily digest">E-mail</:checkbox>
        </.checkbox_group>
        """)

      assert "form-checkbox" in classes(html, "input[type=checkbox]")
      assert "has-checked:border-primary" in classes(html, "label")
      assert html |> find("label") |> LazyHTML.text() =~ "Daily digest"
    end
  end

  describe "tags_input option-picking mode" do
    test "create off, server search and the labels of chosen values" do
      html =
        render(~H"""
        <.tags_input
          id="t"
          name="tag_ids"
          value={["t3"]}
          options={[%{value: "t1", label: "Urgent"}]}
          selected_options={[%{value: "t3", label: "Retail"}]}
          create={false}
          on_search="search_tags"
          removable
        />
        """)

      wrapper = find(html, "#t")
      assert LazyHTML.attribute(wrapper, "data-create") == ["false"]
      assert LazyHTML.attribute(wrapper, "data-on-search") == ["search_tags"]
      assert LazyHTML.attribute(wrapper, "data-debounce") == ["300"]
      assert html |> find("#t-control [data-ts-item]") |> LazyHTML.text() =~ "Retail"
      assert html |> find(".ts-dropdown .option") |> LazyHTML.attribute("data-value") == ["t1"]

      assert html |> find("[data-templates] template") |> LazyHTML.attribute("data-value") == [
               "t1",
               "t3"
             ]

      assert html
             |> find("select[name='tag_ids[]'] option[selected]")
             |> LazyHTML.attribute("value") == ["t3"]
    end

    test "free-text mode keeps its defaults" do
      html = render(~H|<.tags_input id="t" name="tags" suggestions={["a"]} />|)
      assert html |> find("#t") |> LazyHTML.attribute("data-create") == ["true"]
      assert html |> find("#t") |> LazyHTML.attribute("data-debounce") == ["0"]
      assert html |> find(".ts-dropdown .option") |> LazyHTML.attribute("data-value") == ["a"]
    end
  end

  describe "date_picker range in two fields" do
    test "start_name and end_name submit two inputs" do
      html =
        render(
          ~H|<.date_picker id="p" start_name="from" end_name="to" value={{~D[2026-10-01], nil}} />|
        )

      wrapper = find(html, "#p")
      assert LazyHTML.attribute(wrapper, "data-mode") == ["range"]
      assert LazyHTML.attribute(wrapper, "data-start-name") == ["from"]
      assert LazyHTML.attribute(wrapper, "data-end-name") == ["to"]

      assert html
             |> find("[data-hidden] input[type=hidden]")
             |> Enum.map(&{LazyHTML.attribute(&1, "name"), LazyHTML.attribute(&1, "value")}) ==
               [{["from"], ["2026-10-01"]}, {["to"], [""]}]

      assert find(html, "input[name='p[]']") |> Enum.count() == 0
    end

    test "start_field and end_field: names, id, value and errors once used" do
      form =
        Phoenix.Component.to_form(%{"from" => "2026-10-01", "to" => "2026-10-31"},
          as: :f,
          errors: [to: {"must be after the start", []}]
        )

      form = %{form | params: %{"from" => "2026-10-01", "to" => "2026-10-31"}}
      assigns = %{form: form}

      html =
        rendered_to_string(~H|<.date_picker start_field={@form[:from]} end_field={@form[:to]} />|)

      assert html |> find("#f_from_range") |> LazyHTML.attribute("data-value") == [
               ~s(["2026-10-01","2026-10-31"])
             ]

      assert [_] =
               find(html, "input[type=hidden][name='f[from]'][value='2026-10-01']")
               |> Enum.to_list()

      assert [_] =
               find(html, "input[type=hidden][name='f[to]'][value='2026-10-31']")
               |> Enum.to_list()

      assert html =~ "must be after the start"
    end

    test "pt_BR: names, dd/mm/aaaa and até" do
      html =
        render(~H|<.date_picker
  id="p"
  name="p"
  mode="range"
  locale="pt_BR"
  value={{~D[2026-10-01], ~D[2026-10-31]}}
/>|)

      assert html |> find("#p-display") |> LazyHTML.attribute("value") == [
               "01/10/2026 até 31/10/2026"
             ]

      assert html |> find("#p") |> LazyHTML.attribute("data-separator") == [" até "]
      [names] = html |> find("#p") |> LazyHTML.attribute("data-names")
      assert names =~ "Outubro"
      assert names =~ "Segunda"

      html =
        render(
          ~H|<.date_picker id="q" name="q" locale="pt_BR" display_format="j F Y" value="2026-10-24" />|
        )

      assert html |> find("#q-display") |> LazyHTML.attribute("value") == ["24 Outubro 2026"]
    end

    test "presets are computed from today and rendered for the calendar" do
      html =
        render(~H"""
        <.date_picker
          id="p"
          start_name="from"
          end_name="to"
          today={~D[2026-10-24]}
          week_start={1}
          presets={[
            {"Hoje", "today"},
            {"Esta semana", "this_week"},
            {"Mês passado", "last_month"},
            {"Q3", {~D[2026-07-01], ~D[2026-09-30]}},
            %{label: "Natal", from: "2026-12-25", to: "2026-12-25"}
          ]}
        />
        """)

      assert find(html, "#p template[data-presets]") |> Enum.count() == 1
      buttons = html |> unwrap_templates() |> find("[data-preset]")

      assert Enum.map(
               buttons,
               &{LazyHTML.text(&1) |> String.trim(), LazyHTML.attribute(&1, "data-from"),
                LazyHTML.attribute(&1, "data-to")}
             ) == [
               {"Hoje", ["2026-10-24"], ["2026-10-24"]},
               {"Esta semana", ["2026-10-19"], ["2026-10-25"]},
               {"Mês passado", ["2026-09-01"], ["2026-09-30"]},
               {"Q3", ["2026-07-01"], ["2026-09-30"]},
               {"Natal", ["2026-12-25"], ["2026-12-25"]}
             ]

      assert html |> render_template_classes() |> Enum.member?("data-active:bg-primary")
    end

    test "every named preset" do
      today = ~D[2026-10-24]

      assert DatePicker.date_range_preset("yesterday", today) == {~D[2026-10-23], ~D[2026-10-23]}
      assert DatePicker.date_range_preset("last_7_days", today) == {~D[2026-10-18], today}
      assert DatePicker.date_range_preset("last_30_days", today) == {~D[2026-09-25], today}
      assert DatePicker.date_range_preset("this_week", today) == {~D[2026-10-18], ~D[2026-10-24]}

      assert DatePicker.date_range_preset("last_week", today, 1) ==
               {~D[2026-10-12], ~D[2026-10-18]}

      assert DatePicker.date_range_preset("this_month", today) == {~D[2026-10-01], ~D[2026-10-31]}

      assert DatePicker.date_range_preset("last_month", ~D[2026-01-15]) ==
               {~D[2025-12-01], ~D[2025-12-31]}

      assert DatePicker.date_range_preset("this_year", today) == {~D[2026-01-01], ~D[2026-12-31]}
      assert DatePicker.date_range_preset("last_year", today) == {~D[2025-01-01], ~D[2025-12-31]}
      assert length(DatePicker.preset_keys()) == 10
    end
  end

  defp unwrap_templates(html), do: String.replace(html, ~r{</?template[^>]*>}, "")

  defp render_template_classes(html) do
    html
    |> unwrap_templates()
    |> find("[data-preset]")
    |> LazyHTML.attribute("class")
    |> List.first("")
    |> String.split()
  end
end
