defmodule LineaUI.Components.SegmentedTest do
  use LineaUI.ComponentCase, async: true

  alias Phoenix.LiveView.JS

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp texts(html, selector),
    do:
      html
      |> find(selector)
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

  defp options do
    [
      %{label: "All", value: "all", count: 128},
      %{label: "Draft", value: "draft", count: 9},
      %{label: "Billed", value: "billed", disabled: true}
    ]
  end

  test "a group of toggle buttons, the chosen one pressed" do
    html = render(~H|<.segmented id="status" value="draft" options={options()} />|)

    assert attr_of(html, "#status", "role") == ["group"]
    assert attr_of(html, "#status", "phx-hook") == ["LineaUI.Segmented"]
    assert attr_of(html, "#status", "data-value") == ["draft"]
    assert attr_of(html, "#status button", "type") == ["button", "button", "button"]
    assert attr_of(html, "#status button", "aria-pressed") == ["false", "true", "false"]
    assert attr_of(html, "#status button", "data-value") == ["all", "draft", "billed"]
    assert attr_of(html, "#status button", "id") == ["status-0", "status-1", "status-2"]
  end

  test "counts follow the label and a disabled option is disabled" do
    html = render(~H|<.segmented id="status" value="all" options={options()} />|)

    assert texts(html, "#status button") == ["All 128", "Draft 9", "Billed"]

    assert attr_of(html, "#status button", "disabled") == [""]
    assert attr_of(html, "#status button[disabled]", "data-value") == ["billed"]
  end

  test "strings and tuples are options too" do
    html =
      render(~H"""
      <.segmented id="a" value="Week" options={["Week", "Month"]} />
      <.segmented id="b" value="w" options={[{"Week", "w"}, {"Month", "m"}]} />
      """)

    assert attr_of(html, "#a button", "data-value") == ["Week", "Month"]
    assert attr_of(html, "#b button", "data-value") == ["w", "m"]
    assert attr_of(html, "#b button", "aria-pressed") == ["true", "false"]
  end

  test "no value presses nothing" do
    html = render(~H|<.segmented id="s" options={["A", "B"]} />|)

    assert attr_of(html, "#s button", "aria-pressed") == ["false", "false"]
    assert attr_of(html, "#s", "data-value") == [""]
  end

  test "a named control submits through a hidden input" do
    html = render(~H|<.segmented id="s" name="view" value="List" options={["List", "Kanban"]} />|)

    assert attr_of(html, "#s input[type=hidden]", "name") == ["view"]
    assert attr_of(html, "#s input[type=hidden]", "value") == ["List"]
    assert attr_of(html, "#s input[type=hidden]", "data-value-input") == [""]
    assert attr_of(html, "#s input[type=hidden]", "phx-update") == ["ignore"]
  end

  test "an anonymous control has no hidden input" do
    html = render(~H|<.segmented id="s" value="A" options={["A", "B"]} />|)
    assert find(html, "input") |> Enum.count() == 0
  end

  test "a form field fills id, name, value and errors" do
    form = to_form(%{"regime" => "normal"}, as: :company)
    assigns = %{__changed__: nil, form: form}

    html =
      rendered_to_string(~H"""
      <.segmented field={@form[:regime]} options={[{"Simples", "simples"}, {"Normal", "normal"}]} />
      """)

    assert attr_of(html, "input[type=hidden]", "name") == ["company[regime]"]
    assert attr_of(html, "input[type=hidden]", "value") == ["normal"]
    assert attr_of(html, "button", "aria-pressed") == ["false", "true"]
    assert attr_of(html, "[role=group]", "id") == ["company_regime"]
  end

  test "label names the group, help and errors follow it" do
    html =
      render(~H"""
      <.segmented
        id="s"
        value="A"
        options={["A"]}
        label="Period"
        help="Pick one"
        errors={["is required"]}
      />
      """)

    assert texts(html, "#s-label") == ["Period"]
    assert attr_of(html, "#s", "aria-labelledby") == ["s-label"]
    assert html =~ "Pick one"
    assert html =~ "is required"
  end

  test "sizes and full width" do
    html =
      render(~H"""
      <.segmented id="sm" value="A" options={["A"]} size="sm" />
      <.segmented id="lg" value="A" options={["A"]} size="lg" full />
      """)

    assert "h-6.5" in classes(html, "#sm button")
    assert "inline-flex" in classes(html, "#sm")
    assert "h-10" in classes(html, "#lg button")
    assert "flex-1" in classes(html, "#lg button")
    assert "w-full" in classes(html, "#lg")
  end

  test "disabled disables every segment and the field" do
    html = render(~H|<.segmented id="s" name="v" value="A" options={["A", "B"]} disabled />|)

    assert attr_of(html, "#s button", "disabled") == ["", ""]
    assert attr_of(html, "#s input", "disabled") == [""]
  end

  test "on_change reaches the hook as an encoded command, with the target" do
    html =
      render(~H"""
      <.segmented id="a" options={["A"]} on_change="pick" target="#form" />
      <.segmented id="b" options={["A"]} on_change={JS.push("chosen")} />
      """)

    assert [a] = attr_of(html, "#a", "data-on-change")
    assert a =~ "pick"
    assert a =~ "#form"
    assert attr_of(html, "#a", "phx-target") == ["#form"]
    assert [b] = attr_of(html, "#b", "data-on-change")
    assert b =~ "chosen"
  end

  test "class and rest land on the group" do
    html =
      render(
        ~H|<.segmented id="s" options={["A"]} class="w-64" aria-label="Period" data-x="1" />|
      )

    assert "w-64" in classes(html, "#s")
    assert attr_of(html, "#s", "aria-label") == ["Period"]
    assert attr_of(html, "#s", "data-x") == ["1"]
  end
end
