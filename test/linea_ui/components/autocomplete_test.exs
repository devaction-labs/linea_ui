defmodule LineaUI.Components.AutocompleteTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "the hook, the hidden value, the label shown and the options" do
    html =
      render(~H"""
      <.autocomplete
        name="customer"
        value="2"
        options={[{"Ana", "1"}, {"Bruno", "2"}, %{label: "Off", value: "3", disabled: true}]}
        placeholder="Pick"
        on_search="search"
        debounce={150}
        search_threshold={2}
        open_on_focus
        no_results={"Nothing for \"%{query}\""}
        aria-label="Customer"
        phx-debounce="100"
      />
      """)

    root = "[phx-hook='LineaUI.Autocomplete']"
    assert attr_of(html, root, "id") == ["customer"]
    assert attr_of(html, root, "data-value") == ["2"]
    assert attr_of(html, root, "data-label") == ["Bruno"]
    assert attr_of(html, root, "data-on-search") == ["search"]
    assert attr_of(html, root, "data-debounce") == ["150"]
    assert attr_of(html, root, "data-threshold") == ["2"]
    assert attr_of(html, root, "data-open-on-focus") == ["true"]
    assert attr_of(html, root, "data-free-text") == ["false"]
    assert "has-items" in classes(html, root)
    assert attr_of(html, "input[type=hidden][name=customer]", "value") == ["2"]
    assert attr_of(html, "input[type=hidden][name=customer]", "phx-debounce") == ["100"]
    assert attr_of(html, "#customer-input", "value") == ["Bruno"]
    assert attr_of(html, "#customer-input", "role") == ["combobox"]
    assert attr_of(html, "#customer-input", "placeholder") == ["Pick"]
    assert attr_of(html, "#customer-input", "aria-label") == ["Customer"]
    assert attr_of(html, "#customer-input", "name") == []
    assert attr_of(html, ".option", "data-value") == ["1", "2", "3"]
    assert attr_of(html, ".option[data-disabled]", "data-value") == ["3"]
    assert html |> find("[data-no-results]") |> LazyHTML.text() == "Nothing for \"%{query}\""
    assert html |> find("[data-loading]") |> LazyHTML.text() == "Searching…"
  end

  test "field wiring, errors, label and display_value" do
    form = to_form(%{"product_id" => "9"}, as: :item)
    assigns = %{__changed__: nil, form: form}

    html =
      rendered_to_string(~H"""
      <.autocomplete
        field={@form[:product_id]}
        options={[]}
        label="Product"
        help="Search by SKU"
        errors={["is invalid"]}
        display_value="Coffee"
        clearable
        size="sm"
        disabled
      />
      """)

    assert attr_of(html, "input[type=hidden][name='item[product_id]']", "value") == ["9"]
    assert attr_of(html, "[phx-hook='LineaUI.Autocomplete']", "id") == ["item_product_id"]
    assert attr_of(html, "#item_product_id-input", "value") == ["Coffee"]
    assert html |> find("label > span") |> LazyHTML.text() =~ "Product"
    assert html |> find(".text-error") |> LazyHTML.text() =~ "is invalid"
    root = classes(html, "[phx-hook='LineaUI.Autocomplete']")
    assert "plugin-clear_button" in root
    assert "is-invalid" in root
    assert "disabled" in root
    assert "[&_.ts-control]:py-1" in root
    assert [_] = find(html, "button[type=button][data-clear]") |> Enum.to_list()
    assert attr_of(html, "[data-clear]", "aria-label") == ["Clear"]
    assert [_] = find(html, "[data-clear] svg[aria-hidden=true]") |> Enum.to_list()
    assert attr_of(html, "[role=listbox]", "aria-busy") == ["false"]
  end

  test "the clear button name can be set" do
    html =
      render(~H"""
      <.autocomplete name="x" options={[]} clearable clear_label="Limpar" />
      """)

    assert attr_of(html, "[data-clear]", "aria-label") == ["Limpar"]
  end

  test "value without a matching option, free text, groups, the option and prefix slots" do
    html =
      render(~H"""
      <.autocomplete name="x" value="raw" options={["a"]} />
      <.autocomplete id="city" name="city" value="Santos" free_text options={["Salvador"]} />
      <.autocomplete
        id="rich"
        name="rich"
        options={[{"Group", [%{label: "Tea", value: "t", sku: "T1"}]}]}
      >
        <:option :let={option}><b>{option.label}</b> {option.data.sku}</:option>
        <:prefix><svg class="search" /></:prefix>
      </.autocomplete>
      <.autocomplete />
      """)

    assert attr_of(html, "#x-input", "value") == ["raw"]
    assert attr_of(html, "#city-input", "value") == ["Santos"]
    assert attr_of(html, "#city", "data-free-text") == ["true"]
    assert html |> find("#rich .optgroup-header") |> LazyHTML.text() == "Group"
    assert html |> find("#rich .option b") |> LazyHTML.text() == "Tea"
    assert html |> find("#rich .option") |> LazyHTML.text() =~ "T1"
    assert [] == find(html, "#rich .option [data-text]") |> Enum.to_list()
    assert [_] = find(html, "#rich-control svg.search") |> Enum.to_list()
    assert [_, _, _, generated] = attr_of(html, "[phx-hook='LineaUI.Autocomplete']", "id")
    assert generated =~ "autocomplete-"
  end
end
