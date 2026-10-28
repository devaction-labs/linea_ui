defmodule LineaUI.Components.PhoneInputTest do
  use LineaUI.ComponentCase, async: true

  alias LineaUI.Components.PhoneInput.Countries
  alias LineaUI.Components.PhoneInput.Format

  doctest Format

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  describe "Format.e164/2" do
    test "national numbers are read in the country given" do
      assert Format.e164("(11) 91234-5678", "BR") == {:ok, "+5511912345678"}
      assert Format.e164("11 3456-7890", "br") == {:ok, "+551134567890"}
      assert Format.e164("(201) 555-0123", "US") == {:ok, "+12015550123"}
      assert Format.e164("912 345 678", "PT") == {:ok, "+351912345678"}
      assert Format.e164("07911 123456", "GB") == {:ok, "+447911123456"}
      assert Format.e164("06 12 34 56 78", "FR") == {:ok, "+33612345678"}
      assert Format.e164("06 1234 5678", "IT") == {:ok, "+390612345678"}
      assert Format.e164("55 1234 5678", "MX") == {:ok, "+525512345678"}
    end

    test "the country defaults to Brazil" do
      assert Format.e164("11 91234-5678") == {:ok, "+5511912345678"}
    end

    test "the trunk prefix is dropped" do
      assert Format.e164("011 91234-5678", "BR") == {:ok, "+5511912345678"}
      assert Format.e164("1 (201) 555-0123", "US") == {:ok, "+12015550123"}
      assert Format.e164("8 (912) 345-67-89", "RU") == {:ok, "+79123456789"}
    end

    test "international numbers ignore the country given" do
      assert Format.e164("+55 11 91234-5678", "US") == {:ok, "+5511912345678"}
      assert Format.e164("+1 (201) 555-0123", "BR") == {:ok, "+12015550123"}
      assert Format.e164("+351 912 345 678", "BR") == {:ok, "+351912345678"}
      assert Format.e164("+44 (0)7911 123456", "BR") == {:ok, "+447911123456"}
      assert Format.e164("  +5511912345678  ", "BR") == {:ok, "+5511912345678"}
    end

    test "errors" do
      assert Format.e164("", "BR") == {:error, :blank}
      assert Format.e164(" () - ", "BR") == {:error, :blank}
      assert Format.e164(nil, "BR") == {:error, :blank}
      assert Format.e164("+", "BR") == {:error, :unknown_country}
      assert Format.e164("+999 123456", "BR") == {:error, :unknown_country}
      assert Format.e164("123", "BR") == {:error, :invalid_length}
      assert Format.e164("123456789012345", "BR") == {:error, :invalid_length}
      assert Format.e164("555-0123", "US") == {:error, :invalid_length}
      assert Format.e164("11 91234-5678", "ZZ") == {:error, :unknown_country}
    end
  end

  describe "Format.parse/2" do
    test "returns the country read from the number" do
      assert {:ok, %{country: "JM", code: "1", national: "8765550123"}} =
               Format.parse("+1 876 555 0123", "US")

      assert {:ok, %{country: "CA"}} = Format.parse("+1 416 555 0123", "US")
      assert {:ok, %{country: "US"}} = Format.parse("+1 201 555 0123", "BR")
      assert {:ok, %{country: "GG"}} = Format.parse("+44 7911 123456", "GB")
      assert {:ok, %{country: "GB"}} = Format.parse("+44 7400 123456", "GB")
      assert {:ok, %{country: "KZ"}} = Format.parse("+7 701 123 4567", "RU")
      assert {:ok, %{country: "RU"}} = Format.parse("+7 912 345 6789", "KZ")
      assert {:ok, %{country: "PT", code: "351"}} = Format.parse("+351912345678", "BR")
    end

    test "a national number moves to the country its first digits belong to" do
      assert {:ok, %{country: "JM", e164: "+18765550123"}} = Format.parse("876 555 0123", "US")
      assert {:ok, %{country: "US"}} = Format.parse("201 555 0123", "US")
    end
  end

  describe "Format.national/2" do
    test "formats in the country's pattern" do
      assert Format.national("+5511912345678") == "(11) 91234-5678"
      assert Format.national("1134567890", "BR") == "(11) 3456-7890"
      assert Format.national("+12015550123", "BR") == "(201) 555-0123"
      assert Format.national("912345678", "PT") == "912 345 678"
      assert Format.national("1112345678", "AR") == "11 1234-5678"
      assert Format.national("7911123456", "GB") == "7911 123456"
      assert Format.national("15112345678", "DE") == "151 12345678"
      assert Format.national("612345678", "FR") == "6 12 34 56 78"
      assert Format.national("612345678", "ES") == "612 34 56 78"
      assert Format.national("3123456789", "IT") == "312 345 6789"
      assert Format.national("5512345678", "MX") == "55 1234 5678"
    end

    test "unfinished numbers keep only the separators that have a digit after them" do
      assert Format.national("1", "BR") == "(1"
      assert Format.national("119", "BR") == "(11) 9"
      assert Format.national("1191234", "BR") == "(11) 9123-4"
      assert Format.national("2015", "US") == "(201) 5"
    end

    test "digits past the pattern are kept, up to the 15 digits of E.164" do
      assert Format.national("201555012399", "US") == "(201) 555-012399"
      assert Format.national("1234567890123456789", "BR") == "(12) 34567-890123"
    end

    test "text that is not a number is returned as it is" do
      assert Format.national("+999 1", "BR") == "+999 1"
      assert Format.national("", "BR") == ""
    end
  end

  describe "Format.flag/1 and Format.calling_code/1" do
    test "flag" do
      assert Format.flag("us") == "🇺🇸"
      assert Format.flag("PT") == "🇵🇹"
    end

    test "calling code" do
      assert Format.calling_code("pt") == "351"
      assert Format.calling_code("JM") == "1"
      assert Format.calling_code("ZZ") == nil
    end
  end

  describe "the country table" do
    test "is read from the file the browser uses" do
      assert length(Countries.all()) >= 240
      assert Countries.get("br").code == "55"
      assert Countries.get("BR").patterns == ["(##) ####-####", "(##) #####-####"]
      assert Countries.get("JM").leads == ["876", "658"]
      assert Countries.get(nil) == nil
      assert Countries.main_of("1").iso == "US"
      assert Countries.main_of("599").iso == "CW"
      assert Countries.main_of("999") == nil
      assert Countries.code_of("5511") == "55"
      assert Countries.code_of("12015550123") == "1"
      assert Countries.code_of("") == nil
    end
  end

  describe "the component" do
    test "renders the picker, the visible input and the hidden E.164 input" do
      html = render(~H|<.phone_input name="phone" country="US" value="(201) 555-0123" />|)

      root = "[phx-hook='LineaUI.PhoneInput']"
      assert attr_of(html, root, "id") == ["phone-phone"]
      assert attr_of(html, root, "data-country") == ["US"]
      assert attr_of(html, root, "data-value") == ["+12015550123"]
      assert attr_of(html, root, "data-locale") == ["pt-BR"]
      assert "ts-wrapper" in classes(html, root)

      assert attr_of(html, "input[type=hidden]", "name") == ["phone"]
      assert attr_of(html, "input[type=hidden]", "value") == ["+12015550123"]
      assert attr_of(html, "input[type=hidden]", "id") == ["phone-value"]

      assert attr_of(html, "input[data-display]", "id") == ["phone"]
      assert attr_of(html, "input[data-display]", "type") == ["tel"]
      assert attr_of(html, "input[data-display]", "name") == []
      assert attr_of(html, "input[data-display]", "value") == ["(201) 555-0123"]
      assert attr_of(html, "input[data-display]", "autocomplete") == ["tel"]

      assert html |> find("[data-flag]") |> LazyHTML.text() |> String.trim() == "🇺🇸"
      assert html |> find("[data-code]") |> LazyHTML.text() == "+1"
      assert attr_of(html, "[data-picker]", "aria-haspopup") == ["listbox"]
      assert attr_of(html, "[data-picker]", "aria-expanded") == ["false"]
      assert attr_of(html, "[data-picker]", "aria-label") == ["Country: +1"]
      assert attr_of(html, "[data-dropdown]", "hidden") == [""]
      assert attr_of(html, "[data-search]", "placeholder") == ["Search…"]
      assert html |> find("[data-no-results]") |> LazyHTML.text() == "No results found"
      assert [] == find(html, "[data-clear]") |> Enum.to_list()
    end

    test "a 1px divider separates the picker from the number and the list is as wide as the field" do
      html = render(~H|<.phone_input name="phone" />|)

      divider = classes(html, "[data-prefix] > span[aria-hidden]")
      assert "w-px" in divider
      assert "h-[18px]" in divider
      assert "w-full" in classes(html, "[data-dropdown]")
      assert "min-w-64" in classes(html, "[data-dropdown]")
      refute "w-72" in classes(html, "[data-dropdown]")
      assert "pl-[6.875rem]" in classes(html, "input[data-display]")
    end

    test "starts in Brazil when no country is given" do
      html = render(~H|<.phone_input name="phone" />|)

      assert attr_of(html, "[phx-hook='LineaUI.PhoneInput']", "data-country") == ["BR"]
      assert html |> find("[data-code]") |> LazyHTML.text() == "+55"
      assert attr_of(html, "input[data-display]", "value") == [""]
      assert attr_of(html, "input[type=hidden]", "value") == [""]
    end

    test "an E.164 value selects its own country and shows the national format" do
      html = render(~H|<.phone_input name="phone" country="US" value="+5511912345678" />|)

      assert attr_of(html, "[phx-hook='LineaUI.PhoneInput']", "data-country") == ["BR"]
      assert attr_of(html, "input[data-display]", "value") == ["(11) 91234-5678"]
      assert attr_of(html, "input[type=hidden]", "value") == ["+5511912345678"]
      assert html |> find("[data-code]") |> LazyHTML.text() == "+55"

      html = render(~H|<.phone_input name="phone" value="+18765550123" />|)
      assert attr_of(html, "[phx-hook='LineaUI.PhoneInput']", "data-country") == ["JM"]
    end

    test "a value that cannot be read stays as it is, without a submitted number" do
      html = render(~H|<.phone_input name="phone" value="+999 12" />|)

      assert attr_of(html, "input[data-display]", "value") == ["+999 12"]
      assert attr_of(html, "input[type=hidden]", "value") == [""]
      assert attr_of(html, "[phx-hook='LineaUI.PhoneInput']", "data-country") == ["BR"]
    end

    test "the picker's set and order go to the hook" do
      html =
        render(~H"""
        <.phone_input
          name="phone"
          countries={~w(br pt ar)}
          country_order={~w(PT BR)}
          except={["ar"]}
          locale="en"
        />
        """)

      root = "[phx-hook='LineaUI.PhoneInput']"
      assert attr_of(html, root, "data-only") == ["BR,PT,AR"]
      assert attr_of(html, root, "data-except") == ["AR"]
      assert attr_of(html, root, "data-order") == ["PT,BR"]
      assert attr_of(html, root, "data-locale") == ["en"]
    end

    test "a country the picker does not offer gives way to the first one it does" do
      html = render(~H|<.phone_input name="phone" country="US" countries={~w(PT ES)} />|)

      assert attr_of(html, "[phx-hook='LineaUI.PhoneInput']", "data-country") == ["ES"]
      assert html |> find("[data-code]") |> LazyHTML.text() == "+34"

      html =
        render(
          ~H|<.phone_input name="phone" country="US" countries={~w(PT ES)} country_order={~w(PT)} />|
        )

      assert attr_of(html, "[phx-hook='LineaUI.PhoneInput']", "data-country") == ["PT"]
      assert html |> find("[data-code]") |> LazyHTML.text() == "+351"

      html =
        render(~H|<.phone_input name="phone" value="+5511912345678" countries={~w(PT ES)} />|)

      assert attr_of(html, "input[data-display]", "value") == ["+5511912345678"]
      assert attr_of(html, "input[type=hidden]", "value") == [""]
    end

    test "size, variant, shape, disabled and the clear button" do
      html =
        render(~H"""
        <.phone_input
          name="phone"
          value="+5511912345678"
          size="lg"
          variant="filled"
          shape="pill"
          clearable
          clear_label="Remove"
          picker_label="País"
          search_placeholder="Buscar"
          no_results="Nada"
          disabled
          placeholder="Phone"
          class="font-mono"
        />
        """)

      input = classes(html, "input[data-display]")
      assert "h-12" in input
      assert "bg-slate-150" in input
      assert "rounded-full" in input
      assert "font-mono" in input
      assert "pl-[6.875rem]" in input
      assert "pe-9" in input
      assert attr_of(html, "input[data-display]", "disabled") == [""]
      assert attr_of(html, "input[data-display]", "placeholder") == ["Phone"]
      assert attr_of(html, "input[type=hidden]", "disabled") == [""]
      assert attr_of(html, "[data-picker]", "disabled") == [""]
      assert attr_of(html, "[data-picker]", "aria-label") == ["País: +55"]
      assert attr_of(html, "[data-clear]", "aria-label") == ["Remove"]
      assert attr_of(html, "[data-clear]", "hidden") == []
      assert attr_of(html, "[data-search]", "placeholder") == ["Buscar"]
      assert html |> find("[data-no-results]") |> LazyHTML.text() == "Nada"
      assert "text-base" in classes(html, "[data-picker]")
    end

    test "the clear button starts hidden while the field is empty" do
      html = render(~H|<.phone_input name="phone" clearable />|)

      assert attr_of(html, "[data-clear]", "hidden") == [""]
    end

    test "the country change event and its target go to the hook" do
      html = render(~H|<.phone_input name="phone" on_country_change="country" target="#form" />|)

      root = "[phx-hook='LineaUI.PhoneInput']"
      assert attr_of(html, root, "data-on-country-change") == ["country"]
      assert attr_of(html, root, "phx-target") == ["#form"]
    end

    test "debounce goes to the hidden input and the other attributes to the visible one" do
      html =
        render(
          ~H|<.phone_input name="phone" phx-debounce="300" autocomplete="off" aria-label="Phone" />|
        )

      assert attr_of(html, "input[type=hidden]", "phx-debounce") == ["300"]
      assert attr_of(html, "input[data-display]", "phx-debounce") == []
      assert attr_of(html, "input[data-display]", "autocomplete") == ["off"]
      assert attr_of(html, "input[data-display]", "aria-label") == ["Phone"]
    end

    test "field wiring, label, help and errors" do
      form = to_form(%{"phone" => "+351912345678"}, as: :contact)
      assigns = %{__changed__: nil, form: form}

      html =
        rendered_to_string(~H"""
        <.phone_input
          field={@form[:phone]}
          label="Phone number"
          help="With area code"
          errors={["is invalid"]}
        />
        """)

      assert attr_of(html, "input[type=hidden]", "name") == ["contact[phone]"]
      assert attr_of(html, "input[type=hidden]", "value") == ["+351912345678"]
      assert attr_of(html, "input[data-display]", "id") == ["contact_phone"]
      assert attr_of(html, "input[data-display]", "value") == ["912 345 678"]
      assert attr_of(html, "input[data-display]", "aria-invalid") == ["true"]
      assert attr_of(html, "[phx-hook='LineaUI.PhoneInput']", "data-country") == ["PT"]
      assert html |> find("label > span") |> LazyHTML.text() =~ "Phone number"
      assert html |> find(".text-error") |> LazyHTML.text() =~ "is invalid"
      assert html |> LazyHTML.from_fragment() |> LazyHTML.text() =~ "With area code"
      assert "border-error" in classes(html, "input[data-display]")
    end

    test "a generated id when there is neither a field nor a name" do
      html = render(~H|<.phone_input />|)

      assert [id] = attr_of(html, "input[data-display]", "id")
      assert id =~ "phone-"
    end

    test "is imported by use LineaUI" do
      assert LineaUI.components().phone_input == LineaUI.Components.PhoneInput
    end
  end
end
