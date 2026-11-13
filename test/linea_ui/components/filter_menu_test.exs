defmodule LineaUI.Components.FilterMenuTest do
  use LineaUI.ComponentCase, async: true

  doctest LineaUI.Components.FilterMenu

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)
  defp text_of(html, selector), do: html |> find(selector) |> LazyHTML.text() |> String.trim()

  defp orders(value \\ %{}) do
    [
      %{
        name: "filter[status]",
        label: "Status",
        icon: "huge-checkmark-circle-02",
        value: Map.get(value, :status, []),
        options: [
          {"Invoiced", "invoiced", 3},
          {"Approved", "approved", 2},
          {"Draft", "draft", 2},
          {"Canceled", "canceled", 1}
        ]
      },
      %{
        name: "filter[channel]",
        label: "Channel",
        value: Map.get(value, :channel, []),
        options: [{"Counter", "counter", 4}, {"Online", "online", 4}]
      },
      %{
        name: "filter[sort]",
        label: "Sort by",
        caption: "Sort by",
        display: :section,
        type: :single,
        value: Map.get(value, :sort, "recent"),
        options: [{"Most recent", "recent"}, {"Highest value", "value"}]
      }
    ]
  end

  defp period_groups do
    [
      %{
        name: "period",
        label: "Period",
        type: :single,
        value: "week",
        options: [{"Day", "day"}, {"Week", "week"}]
      },
      %{
        name: "sort",
        label: "Sort",
        display: :section,
        type: :single,
        value: "recent",
        options: [{"Recent", "recent"}]
      }
    ]
  end

  defp tag_groups do
    [
      %{
        name: "tag",
        label: "Tag",
        value: ["a", "b"],
        options: [{"A", "a"}, {"B", "b"}, {"C", "c"}]
      }
    ]
  end

  test "the trigger is an outline button with the filter icon, the label and a hidden count" do
    html = render(~H|<.filter_menu id="f" groups={orders()} />|)

    assert attr_of(html, "#f-filter", "phx-hook") == ["LineaUI.FilterMenu"]
    assert attr_of(html, "#f", "phx-hook") == ["LineaUI.Dropdown"]
    assert attr_of(html, "#f", "data-keep-submenus") == ["true"]
    assert attr_of(html, "#f", "data-close-on-select") == ["false"]
    assert "sg-btn" in classes(html, "#f [data-trigger] button")

    assert text_of(html, "#f [data-trigger] button > span:not([data-filter-applied])") ==
             "Filters"

    assert [_] = find(html, "#f [data-trigger] button svg") |> Enum.to_list()
    assert attr_of(html, "[data-filter-applied]", "hidden") == [""]
  end

  test "label, icon, variant, dashed and size style the trigger" do
    html =
      render(~H"""
      <.filter_menu
        id="f"
        label="Filtrar"
        icon="huge-filter"
        variant="soft"
        color="primary"
        size="sm"
        dashed
        groups={orders()}
      />
      """)

    assert text_of(html, "#f [data-trigger] button > span:not([data-filter-applied])") ==
             "Filtrar"

    assert [_] = find(html, "#f [data-trigger] button span.huge-filter") |> Enum.to_list()
    assert find(html, "#f [data-trigger] button svg") |> Enum.to_list() == []
    assert "border-dashed" in classes(html, "#f [data-trigger] button")
    assert "soft" in classes(html, "#f [data-trigger] button")
    assert "sm" in classes(html, "#f [data-trigger] button")
  end

  test "the locale names the trigger, Clear and Apply" do
    html = render(~H|<.filter_menu id="f" locale="pt_BR" groups={orders()} />|)

    assert text_of(html, "#f [data-trigger] button > span:not([data-filter-applied])") ==
             "Filtros"

    assert text_of(html, "[data-menu-action=clear]") == "Limpar"
    assert text_of(html, "[data-menu-action=apply]") =~ "Aplicar"
  end

  test "a submenu group is a row with its icon, a panel of checkboxes and the option counts" do
    html = render(~H|<.filter_menu id="f" groups={orders()} />|)

    assert attr_of(html, "[data-submenu]", "data-filter-group") == [
             "filter[status]",
             "filter[channel]"
           ]

    assert attr_of(html, "[data-submenu]", "data-filter-type") == ["multiple", "multiple"]

    assert text_of(html, "[data-submenu]:first-of-type > [data-submenu-trigger] > span") =~
             "Status"

    assert [_] =
             find(
               html,
               "[data-submenu]:first-of-type > [data-submenu-trigger] span.huge-checkmark-circle-02"
             )
             |> Enum.to_list()

    status = find(html, "[data-filter-group='filter[status]'] [role=menuitemcheckbox]")
    assert Enum.count(status) == 4
    assert LazyHTML.attribute(status, "data-count") == ["3", "2", "2", "1"]

    assert find(html, "[data-filter-group='filter[status]'] [data-choice-input]")
           |> LazyHTML.attribute("name") == List.duplicate("filter[status][]", 4)

    assert find(html, "[data-filter-group='filter[status]'] [data-choice-input]")
           |> LazyHTML.attribute("value") == ["invoiced", "approved", "draft", "canceled"]
  end

  test "a section is flat in the menu under its caption, with radios named by the group" do
    html = render(~H|<.filter_menu id="f" groups={orders()} />|)

    assert [_] = find(html, "[role=menu] > [role=separator]") |> Enum.to_list()
    assert attr_of(html, "[role=group]", "data-filter-group") == ["filter[sort]"]
    assert attr_of(html, "[role=group]", "data-filter-type") == ["single"]
    assert text_of(html, "[role=group] [role=presentation]") == "Sort by"
    assert find(html, "[data-submenu] [role=menuitemradio]") |> Enum.to_list() == []

    radios = find(html, "[role=group] [role=menuitemradio]")
    assert Enum.count(radios) == 2
    assert LazyHTML.attribute(radios, "aria-checked") == ["true", "false"]

    assert find(html, "[role=group] [data-choice-input]") |> LazyHTML.attribute("name") == [
             "filter[sort]",
             "filter[sort]"
           ]

    assert find(html, "[role=group] [data-choice-input][type=radio]") |> Enum.count() == 2
  end

  test "a single group in a submenu counts its radio and a section never counts" do
    html = render(~H|<.filter_menu id="f" groups={period_groups()} />|)

    assert attr_of(html, "[data-submenu]", "data-count-radios") == ["true"]
    assert text_of(html, "[data-submenu-count]") == "1"
    assert text_of(html, "[data-filter-applied]") == "1"
    assert attr_of(html, "[data-submenu] [data-choice-input]", "type") == ["radio", "radio"]
  end

  test "values check the options and count per group and on the trigger" do
    html =
      render(
        ~H|<.filter_menu id="f" groups={orders(%{status: ["invoiced", "approved"], channel: ["online"]})} />|
      )

    assert find(html, "[data-filter-group='filter[status]'] [aria-checked=true]")
           |> LazyHTML.attribute("data-server-checked") == ["true", "true"]

    assert find(html, "[data-submenu-count]")
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == ["2", "1"]

    assert text_of(html, "[data-filter-applied]") == "3"
    assert attr_of(html, "[data-filter-applied]", "hidden") == []
  end

  test "Apply counts the records the staged filters leave, as the canvas does" do
    one = render(~H|<.filter_menu id="f" groups={orders(%{status: ["invoiced", "approved"]})} />|)

    both =
      render(
        ~H|<.filter_menu id="f" groups={orders(%{status: ["invoiced", "approved"], channel: ["counter"]})} />|
      )

    none = render(~H|<.filter_menu id="f" groups={orders()} />|)

    assert text_of(one, "[data-menu-action=apply]") == "Apply (5)"
    assert text_of(both, "[data-menu-action=apply]") == "Apply (4)"
    assert text_of(none, "[data-menu-action=apply]") == "Apply (8)"
  end

  test "options without a count fall back to the number of ticked values and results wins" do
    plain = render(~H|<.filter_menu id="f" groups={tag_groups()} />|)
    exact = render(~H|<.filter_menu id="f" groups={tag_groups()} results={7} />|)

    empty =
      render(
        ~H|<.filter_menu id="f" groups={[%{name: "tag", label: "Tag", options: [{"A", "a"}]}]} />|
      )

    assert text_of(plain, "[data-menu-action=apply]") == "Apply (2)"
    assert text_of(exact, "[data-menu-action=apply]") == "Apply (7)"
    assert attr_of(exact, "#f-filter", "data-results") == ["7"]
    assert text_of(empty, "[data-menu-action=apply]") == "Apply"
    assert attr_of(plain, "#f-filter", "data-results") == []
  end

  test "apply mode has Apply as a button for the hook, live mode only Clear" do
    apply = render(~H|<.filter_menu id="f" groups={orders()} />|)
    live = render(~H|<.filter_menu id="f" mode="live" groups={orders()} />|)

    assert attr_of(apply, "#f-filter", "data-mode") == ["apply"]
    assert attr_of(apply, "[data-menu-action=apply]", "type") == ["button"]
    assert attr_of(live, "#f-filter", "data-mode") == ["live"]
    assert find(live, "[data-menu-action=apply]") |> Enum.to_list() == []
    assert [_] = find(live, "[data-menu-action=clear]") |> Enum.to_list()
  end

  test "events and the target go on the hook element, the close is announced to it" do
    html =
      render(
        ~H|<.filter_menu id="f" groups={orders()} on_change="c" on_apply="a" on_clear="x" target="#owner" />|
      )

    assert attr_of(html, "#f-filter", "data-on-change") == ["c"]
    assert attr_of(html, "#f-filter", "data-on-apply") == ["a"]
    assert attr_of(html, "#f-filter", "data-on-clear") == ["x"]
    assert attr_of(html, "#f-filter", "phx-target") == ["#owner"]
    assert attr_of(html, "#f-filter", "data-filter-id") == ["f"]
    assert attr_of(html, "#f", "data-on-close") |> hd() =~ "linea:filter-close"
  end

  test "the menu keeps the dropdown's roles, a wide panel and extra attributes" do
    html = render(~H|<.filter_menu id="f" groups={orders()} class="w-80" data-test="x" />|)

    assert attr_of(html, "#f-menu [role=menu]", "role") |> hd() == "menu"
    assert "min-w-57.5" in classes(html, "#f-menu [role=menu]")
    assert "w-80" in classes(html, "#f-menu [role=menu]")
    assert attr_of(html, "#f-filter", "data-test") == ["x"]
    assert attr_of(html, "[data-submenu-trigger]", "aria-haspopup") == ["menu", "menu"]
  end

  test "a group slot takes your own items and counts its value" do
    html =
      render(~H"""
      <.filter_menu id="f">
        <:group name="tags[]" label="Tags" value={["b"]}>
          <.dropdown_checkbox name="tags[]" value="a" checked={false} data-count={2}>
            A
          </.dropdown_checkbox>
          <.dropdown_checkbox name="tags[]" value="b" checked={true} data-count={3}>
            B
          </.dropdown_checkbox>
        </:group>
      </.filter_menu>
      """)

    assert attr_of(html, "[data-submenu]", "data-filter-group") == ["tags[]"]

    assert find(html, "[data-submenu] [role=menuitemcheckbox]")
           |> LazyHTML.attribute("data-count") == ["2", "3"]

    assert text_of(html, "[data-submenu-count]") == "1"
    assert text_of(html, "[data-filter-applied]") == "1"
    assert text_of(html, "[data-menu-action=apply]") == "Apply (1)"
  end

  test "a group needs a name and a label" do
    assert_raise FunctionClauseError, fn ->
      render(~H|<.filter_menu id="f" groups={[%{label: "No name"}]} />|)
    end
  end

  defp date_groups(extra) do
    [
      Map.merge(
        %{
          name: "filter[period]",
          label: "Period",
          caption: "Period",
          display: :section,
          type: :single,
          options: [{"Today", "today"}, {"7 days", "7d"}, {"This month", "month"}]
        },
        extra
      )
    ]
  end

  test "custom adds a row after a separator that opens an inline range calendar" do
    html = render(~H|<.filter_menu id="f" groups={date_groups(%{custom: true, value: "7d"})} />|)

    assert [_] = find(html, "[role=group] > [role=separator]") |> Enum.to_list()
    assert attr_of(html, "[data-filter-custom]", "data-label") == ["Custom…"]
    assert attr_of(html, "[data-filter-custom]", "data-locale") == ["en"]
    assert attr_of(html, "[data-filter-custom]", "data-server-value") == [""]
    assert attr_of(html, "[data-filter-custom]", "data-selected") == []
    assert text_of(html, "[data-filter-custom] > [data-submenu-trigger]") == "Custom…"
    assert find(html, "[data-filter-custom] > [data-submenu-trigger] svg") |> Enum.count() >= 1

    assert [{"input", attrs, _}] = html |> find("input[data-custom-input]") |> LazyHTML.to_tree()
    assert {"type", "radio"} in attrs
    assert {"name", "filter[period]"} in attrs
    assert {"value", ""} in attrs
    refute List.keymember?(attrs, "checked", 0)
    assert {"data-choice-input", ""} in attrs

    assert attr_of(html, "[data-filter-custom] [data-kind]", "data-mode") == ["range"]
    assert attr_of(html, "[data-filter-custom] [data-kind]", "data-inline") == ["true"]
    assert attr_of(html, "[data-filter-custom] [data-kind]", "data-skin") == ["linea"]
    assert attr_of(html, "[data-filter-custom] [data-kind]", "phx-hook") == ["LineaUI.DatePicker"]

    assert attr_of(html, "[data-filter-custom] [data-kind]", "data-start-name") == [
             "filter[period]--from"
           ]

    assert attr_of(html, "[data-filter-custom] [data-kind]", "data-end-name") == [
             "filter[period]--to"
           ]

    assert attr_of(html, "[data-filter-custom] [data-kind]", "data-value") == ["[]"]
  end

  test "the presets stay radios and the row is the only submenu of a section" do
    html = render(~H|<.filter_menu id="f" groups={date_groups(%{custom: true, value: "7d"})} />|)

    assert LazyHTML.attribute(find(html, "[role=group] [role=menuitemradio]"), "aria-checked") ==
             ["false", "true", "false"]

    assert [_] = find(html, "[data-submenu]") |> Enum.to_list()
    assert attr_of(html, "[role=group]", "data-filter-group") == ["filter[period]"]
    assert text_of(html, "[data-filter-applied]") == "0"
  end

  test "a custom value shows the period on the row, checks the radio and unchecks the presets" do
    html = render(~H|<.filter_menu
  id="f"
  groups={date_groups(%{custom: "Outro…", value: "custom:2026-11-03..2026-11-10"})}
/>|)

    assert text_of(html, "[data-filter-custom] > [data-submenu-trigger]") ==
             "2026-11-03 – 2026-11-10"

    assert attr_of(html, "[data-filter-custom]", "data-label") == ["Outro…"]
    assert attr_of(html, "[data-filter-custom]", "data-selected") == ["true"]

    assert attr_of(html, "[data-filter-custom]", "data-server-value") == [
             "custom:2026-11-03..2026-11-10"
           ]

    assert LazyHTML.attribute(find(html, "[role=group] [role=menuitemradio]"), "aria-checked") ==
             ["false", "false", "false"]

    assert [{"input", attrs, _}] = html |> find("input[data-custom-input]") |> LazyHTML.to_tree()
    assert {"value", "custom:2026-11-03..2026-11-10"} in attrs
    assert List.keymember?(attrs, "checked", 0)

    assert attr_of(html, "[data-filter-custom] [data-kind]", "data-value") == [
             ~s(["2026-11-03","2026-11-10"])
           ]
  end

  test "the period reads in the locale of the menu" do
    html = render(~H|<.filter_menu
  id="f"
  locale="pt_BR"
  groups={date_groups(%{custom: true, value: "custom:2026-11-03..2026-11-10"})}
/>|)

    assert text_of(html, "[data-filter-custom] > [data-submenu-trigger]") ==
             "03/11/2026 – 10/11/2026"

    assert attr_of(html, "[data-filter-custom]", "data-label") == ["Personalizado…"]
    assert attr_of(html, "[data-filter-custom]", "data-locale") == ["pt_BR"]
  end

  test "a value that is not a period leaves the row as it is, and no custom means no row" do
    html = render(~H|<.filter_menu
  id="f"
  groups={date_groups(%{custom: true, value: "custom:2026-11-10..2026-11-03"})}
/>|)
    assert attr_of(html, "[data-filter-custom]", "data-selected") == []
    assert text_of(html, "[data-filter-custom] > [data-submenu-trigger]") == "Custom…"

    html = render(~H|<.filter_menu id="f" groups={date_groups(%{value: "today"})} />|)
    assert find(html, "[data-filter-custom]") |> Enum.to_list() == []
    assert find(html, "input[data-custom-input]") |> Enum.to_list() == []
  end

  test "custom_range/1 reads the value of a period" do
    alias LineaUI.Components.FilterMenu

    assert FilterMenu.custom_range("custom:2026-11-13..2026-11-13") ==
             {~D[2026-11-13], ~D[2026-11-13]}

    assert FilterMenu.custom_range("custom:2026-11-13..2026-11-01") == nil
    assert FilterMenu.custom_range("custom:2026-11-01") == nil
    assert FilterMenu.custom_range("custom:2026-13-01..2026-13-02") == nil
    assert FilterMenu.custom_range("custom:") == nil
    assert FilterMenu.custom_range("today") == nil
    assert FilterMenu.custom_range(nil) == nil
  end
end
