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

  test "at max the input is disabled, says so and a counter shows" do
    html =
      render(~H|<.tags_input id="t" name="tags" value={~w(a b c)} max={3} placeholder="Add…" />|)

    assert [_] =
             find(html, "input[data-search][disabled][placeholder='Limit reached']")
             |> Enum.to_list()

    assert LazyHTML.text(find(html, "[data-counter]")) |> String.trim() == "3 / 3"
    assert find(html, "[data-counter][hidden]") |> Enum.to_list() == []
    assert LazyHTML.attribute(find(html, "#t"), "data-placeholder") == ["Add…"]
    assert LazyHTML.attribute(find(html, "#t"), "data-limit-placeholder") == ["Limit reached"]
  end

  test "under max the input is on and the counter is hidden; limit_placeholder is overridable" do
    html =
      render(~H|<.tags_input
  id="t"
  name="tags"
  value={~w(a)}
  max={3}
  placeholder="Add…"
  limit_placeholder="Limite atingido"
/>|)

    assert [_] =
             find(html, "input[data-search][placeholder='Add…']:not([disabled])")
             |> Enum.to_list()

    assert [_] = find(html, "[data-counter][hidden]") |> Enum.to_list()
    assert LazyHTML.attribute(find(html, "#t"), "data-limit-placeholder") == ["Limite atingido"]
  end

  test "without max there is no counter" do
    html = render(~H|<.tags_input id="t" name="tags" value={~w(a)} />|)
    assert find(html, "[data-counter]") |> Enum.to_list() == []
    refute LazyHTML.attribute(find(html, "#t"), "data-placeholder") != []
  end

  test "the create row hint and label travel as data attributes" do
    html =
      render(~H|<.tags_input id="t" name="tags" create_label="Adicionar" create_hint="Enter" />|)

    assert LazyHTML.attribute(find(html, "#t"), "data-create-hint") == ["Enter"]
    assert LazyHTML.attribute(find(html, "#t"), "data-create-label") == ["Adicionar"]

    html = render(~H|<.tags_input id="t" name="tags" create_hint={nil} />|)
    assert LazyHTML.attribute(find(html, "#t"), "data-create-hint") == []
  end

  test "option and item slots are forwarded" do
    html =
      render(~H"""
      <.tags_input id="t" name="tags" options={[%{value: 1, label: "Jo", job: "Dev"}]} value={[1]}>
        <:option :let={o}><b class="opt">{o.data.job}</b></:option>
        <:item :let={o}><i class="chip">{o.label}</i></:item>
      </.tags_input>
      """)

    assert html |> find(".option b.opt") |> LazyHTML.text() == "Dev"
    assert html |> find(".ts-control span.item i.chip") |> LazyHTML.text() == "Jo"
  end

  test "field wiring" do
    assigns = %{__changed__: nil, form: Phoenix.Component.to_form(%{"tags" => ["x"]}, as: :post)}
    html = rendered_to_string(~H|<.tags_input field={@form[:tags]} label="Tags" />|)
    assert find(html, "#post_tags") |> Enum.count() == 1

    assert find(html, "select[name='post[tags][]'] option[value=x][selected]") |> Enum.count() ==
             1

    assert html |> find("label > span") |> LazyHTML.text() == "Tags"
  end

  test "suggestions can carry a hint, and the create row can sit under them" do
    html =
      render(~H"""
      <.tags_input
        id="t"
        name="tags"
        create_position="bottom"
        compact
        suggestions={[%{label: "Prioridade", value: "Prioridade", hint: "12 usos"}, "Privado"]}
      />
      <.tags_input id="u" name="u" />
      """)

    assert html |> find("#t .option [data-hint]") |> LazyHTML.text() =~ "12 usos"
    assert [_] = find(html, "#t .option [data-hint]") |> Enum.to_list()
    assert "compact" in classes(html, "#t")
    assert LazyHTML.attribute(find(html, "#t"), "data-create-position") == ["bottom"]
    assert LazyHTML.attribute(find(html, "#u"), "data-create-position") == []
    refute "compact" in classes(html, "#u")

    # the create row is the last child of the list when `create_position` is bottom, the first otherwise
    assert [_] = find(html, "#t [role=listbox] > :last-child[data-create-row]") |> Enum.to_list()
    assert [_] = find(html, "#u [role=listbox] > :first-child[data-create-row]") |> Enum.to_list()
  end

  test "a disabled field draws its tags without remove buttons" do
    html =
      render(~H"""
      <.tags_input id="t" name="tags" value={~w(a b)} removable disabled />
      <.tags_input id="u" name="u" value={~w(a b)} removable />
      """)

    assert [] == find(html, "#t .item .remove, #t [data-remove]") |> Enum.to_list()
    refute "plugin-remove_button" in classes(html, "#t")
    assert "plugin-remove_button" in classes(html, "#u")
    assert LazyHTML.attribute(find(html, "#t"), "data-remove-label") == []
  end

  test "the counter sits on the help line when there is one, under the control otherwise" do
    html =
      render(~H"""
      <.tags_input id="t" name="t" value={~w(a b c)} max={3} help="Remova um." />
      <.tags_input id="u" name="u" value={~w(a b c)} max={3} />
      """)

    assert "absolute" in classes(html, "#t [data-counter]")
    assert "end-0" in classes(html, "#t [data-counter]")
    assert "text-end" in classes(html, "#u [data-counter]")
    refute "absolute" in classes(html, "#u [data-counter]")
  end
end
