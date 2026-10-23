defmodule LineaUI.Components.TagsInputTest do
  use LineaUI.ComponentCase, async: true

  test "a comma separated value becomes chips and a name[] select" do
    html =
      render(~H"""
      <.tags_input
        id="t"
        name="tags"
        value="awesome, neat"
        removable
        clearable
        placeholder="Enter tags"
      />
      """)

    assert find(html, "#t[phx-hook='LineaUI.Select'][data-mode=tags].ts-wrapper.multi")
           |> Enum.count() == 1

    assert html |> find("#t") |> LazyHTML.attribute("data-create") == ["true"]

    assert html |> find("[data-ts-item]") |> Enum.map(&LazyHTML.attribute(&1, "data-value")) == [
             ["awesome"],
             ["neat"]
           ]

    assert html |> find("select[name='tags[]'] option[selected]") |> LazyHTML.attribute("value") ==
             ["awesome", "neat"]

    assert find(html, "[data-ts-item] [data-remove]") |> Enum.count() == 2
    assert find(html, "[data-clear]") |> Enum.count() == 1
  end

  test "a list value, max, persist and restore" do
    html =
      render(
        ~H|<.tags_input id="t" name="tags" value={["a"]} max={3} persist={false} restore_on_backspace />|
      )

    wrapper = find(html, "#t")
    assert LazyHTML.attribute(wrapper, "data-max") == ["3"]
    assert LazyHTML.attribute(wrapper, "data-persist") == ["false"]
    assert LazyHTML.attribute(wrapper, "data-restore") == ["true"]
    assert LazyHTML.attribute(wrapper, "data-value") == [~s(["a"])]
  end

  test "suggestions are offered as options" do
    html = render(~H|<.tags_input id="t" name="tags" suggestions={~w(elixir erlang)} />|)

    assert html |> find(".ts-dropdown .option") |> LazyHTML.attribute("data-value") == [
             "elixir",
             "erlang"
           ]
  end

  test "field wiring" do
    assigns = %{__changed__: nil, form: Phoenix.Component.to_form(%{"tags" => ["x"]}, as: :post)}
    html = rendered_to_string(~H|<.tags_input field={@form[:tags]} label="Tags" />|)
    assert find(html, "#post_tags") |> Enum.count() == 1

    assert find(html, "select[name='post[tags][]'] option[value=x][selected]") |> Enum.count() ==
             1

    assert html |> find("label > span") |> LazyHTML.text() == "Tags"
  end
end
