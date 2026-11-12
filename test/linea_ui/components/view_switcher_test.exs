defmodule LineaUI.Components.ViewSwitcherTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp texts(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

  defp views do
    [
      %{label: "List", value: "list", icon: "huge-left-to-right-list-bullet"},
      %{label: "Board", value: :board, count: 3}
    ]
  end

  defp link_views do
    [
      %{label: "List", value: "list", patch: "/invoices?view=list"},
      %{label: "Board", value: "board", patch: "/invoices?view=board"}
    ]
  end

  defp options do
    [
      %{label: "Simple", value: "gallery", icon: "huge-grid-view", description: "Gallery view of invoices"},
      %{label: "List", value: "list", added: true},
      %{label: "Feed", value: "feed", disabled: true}
    ]
  end

  test "a tab per view, the chosen one pressed, sending on_change with its value" do
    html = render(~H|<.view_switcher id="v" value={:board} on_change="set_view" views={views()} />|)

    assert attr_of(html, "#v", "role") == ["group"]
    # the count follows the label with no whitespace between them (the gap is CSS)
    assert texts(html, "#v .linea-views-tab") == ["List", "Board3"]
    assert attr_of(html, "#v .linea-views-tab", "aria-pressed") == ["false", "true"]
    assert attr_of(html, "#v .linea-views-tab", "phx-click") == ["set_view", "set_view"]
    assert attr_of(html, "#v .linea-views-tab", "phx-value-view") == ["list", "board"]
    assert texts(html, "#v .linea-views-count") == ["3"]
    assert find(html, "#v .linea-views-add") |> Enum.empty?()
    assert find(html, "#v .linea-views-sep") |> Enum.empty?()
  end

  test "a view with patch is a link, current when chosen" do
    html = render(~H|<.view_switcher id="v" value="list" views={link_views()} />|)

    assert attr_of(html, "#v a.linea-views-tab", "href") == ["/invoices?view=list", "/invoices?view=board"]
    assert attr_of(html, "#v a.linea-views-tab", "aria-current") == ["page"]
  end

  test "a disabled view with a destination is a disabled button, not a link" do
    html = render(~H|<.view_switcher id="v" views={[%{label: "Feed", value: "feed", patch: "/feed", disabled: true}]} />|)

    assert find(html, "#v a") |> Enum.empty?()
    assert attr_of(html, "#v button.linea-views-tab", "disabled") == [""]
    assert attr_of(html, "#v button.linea-views-tab", "aria-disabled") == ["true"]
  end

  test "the menu: a dropdown with a title and an option per view on offer" do
    html = render(~H|<.view_switcher id="v" value="list" on_add="add_view" views={views()} options={options()} />|)

    assert attr_of(html, "#v-add", "phx-hook") == ["LineaUI.Dropdown"]
    assert texts(html, "#v .linea-views-add") == ["View"]
    assert texts(html, "#v-add .linea-views-title") == ["Add a new view"]
    assert attr_of(html, "#v-add .linea-views-option", "role") == ["menuitem", "menuitem", "menuitem"]
    assert attr_of(html, "#v-add .linea-views-option", "phx-click") == ["add_view", "add_view", "add_view"]
    assert attr_of(html, "#v-add .linea-views-option", "phx-value-view") == ["gallery", "list", "feed"]
    assert attr_of(html, "#v-add .linea-views-option", "aria-disabled") == ["true"]
    assert attr_of(html, "#v-add .linea-views-option", "disabled") == [""]
    assert texts(html, "#v-add .linea-views-text") == ["Simple Gallery view of invoices", "List", "Feed"]
    assert find(html, "#v-add .linea-views-check") |> Enum.count() == 1
    assert find(html, "#v .linea-views-sep") |> Enum.count() == 1
  end

  test "the texts and one column" do
    html =
      render(
        ~H|<.view_switcher id="v" options={options()} add_label="Visualização" menu_title="Adicionar visualização" columns={1} />|
      )

    assert texts(html, "#v .linea-views-add") == ["Visualização"]
    assert texts(html, "#v-add .linea-views-title") == ["Adicionar visualização"]
    assert find(html, "#v-add .linea-views-menu.is-single") |> Enum.count() == 1
  end
end
