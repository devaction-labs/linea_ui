defmodule LineaUI.Components.PillSelectTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp texts(html, selector),
    do:
      html
      |> find(selector)
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

  test "one choice: a radiogroup of sg-tag labels over radios" do
    html =
      render(
        ~H|<.pill_select name="canal" value="Online" options={["Todos", "Balcão", "Online"]} />|
      )

    assert attr_of(html, "#canal", "role") == ["radiogroup"]
    assert "sg-pills" in classes(html, "#canal")
    assert attr_of(html, "#canal label", "class") == ["sg-tag", "sg-tag", "sg-tag"]
    assert attr_of(html, "#canal input", "type") == ["radio", "radio", "radio"]
    assert attr_of(html, "#canal input", "name") == ["canal", "canal", "canal"]
    assert attr_of(html, "#canal input[checked]", "value") == ["Online"]
    assert texts(html, "#canal label") == ["Todos", "Balcão", "Online"]
  end

  test "multiple: checkboxes named name[] and a hidden empty entry" do
    html =
      render(~H"""
      <.pill_select
        name="cats"
        multiple
        value={["Tintas", "Básico"]}
        options={["Tintas", "Básico", "Ferramentas"]}
      />
      """)

    assert attr_of(html, "#cats", "role") == ["group"]
    assert attr_of(html, "#cats input[type=checkbox]", "name") == ["cats[]", "cats[]", "cats[]"]
    assert attr_of(html, "#cats input[type=hidden]", "name") == ["cats[]"]
    assert attr_of(html, "#cats input[checked]", "value") == ["Tintas", "Básico"]
  end

  test "counts are a faint number after the label" do
    html =
      render(~H"""
      <.pill_select
        id="c"
        value="a"
        options={[%{label: "Todos", value: "a", count: 128}, %{label: "Online", value: "b"}]}
      />
      """)

    assert texts(html, "#c .sg-pills-count") == ["128"]
    assert texts(html, "#c label") == ["Todos128", "Online"]
  end

  test "on_change pushes the clicked value and a field fills name and value" do
    html = render(~H|<.pill_select id="p" on_change="pick" options={["A", "B"]} />|)
    assert [click | _] = attr_of(html, "#p input", "phx-click")
    assert click =~ "pick"
    assert click =~ ~s("value":"A")
  end

  test "a form field fills name and value" do
    form = to_form(%{"canal" => "B"}, as: :demo)
    assigns = %{__changed__: nil, form: form}
    html = rendered_to_string(~H|<.pill_select field={@form[:canal]} options={["A", "B"]} />|)
    assert attr_of(html, "input[checked]", "value") == ["B"]
    assert attr_of(html, "input[checked]", "name") == ["demo[canal]"]
  end
end
