defmodule LineaUI.Components.TabBarCanvasTest do
  use LineaUI.ComponentCase, async: true

  defp texts(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "the default bar is unchanged: icon only, linea-tabbar" do
    html =
      render(~H"""
      <.tab_bar current="/b">
        <:tab navigate="/a" label="A"><i /></:tab>
        <:tab navigate="/b" label="B"><i /></:tab>
      </.tab_bar>
      """)

    assert ["linea-tabbar"] == classes(html, "nav")
    assert ["linea-tabbar-tab"] == classes(html, "a")
    assert texts(html, "a") == ["", ""]
  end

  test "variant canvas is the sg-m-tab with the label under the icon and the current tab on" do
    html =
      render(~H"""
      <.tab_bar variant="canvas" current="/b">
        <:tab navigate="/a" label="Início"><svg class="i" /></:tab>
        <:tab navigate="/b" label="Tarefas"><svg class="i" /></:tab>
      </.tab_bar>
      """)

    assert ["sg-m-tab"] == classes(html, "nav")
    assert texts(html, "nav > a") == ["Início", "Tarefas"]
    assert attr_of(html, "a.on", "aria-current") == ["page"]
    assert texts(html, "a.on") == ["Tarefas"]
    assert [_, _] = Enum.to_list(find(html, "nav > a > svg.i"))
  end

  test "a tab takes its own class" do
    html =
      render(~H"""
      <.tab_bar variant="canvas" current="/b">
        <:tab navigate="/a" label="A" class="mine"><i /></:tab>
        <:tab navigate="/b" label="B" class="tasks"><i /></:tab>
      </.tab_bar>
      """)

    assert ["mine"] == classes(html, "a[href='/a']")
    assert ["on", "tasks"] == classes(html, "a[href='/b']")

    default =
      render(~H"""
      <.tab_bar>
        <:tab navigate="/a" label="A" class="mine"><i /></:tab>
      </.tab_bar>
      """)

    assert ["linea-tabbar-tab", "mine"] == classes(default, "a")
  end

  defp prefix_bar(variant) do
    assigns = %{variant: variant, __changed__: nil}

    rendered_to_string(~H"""
    <.tab_bar variant={@variant} current="/app/tasks/NXP-1" match="prefix">
      <:tab navigate="/" label="Início"><i /></:tab>
      <:tab navigate="/app/tasks" label="Tarefas"><i /></:tab>
      <:tab navigate="/app/tasks-old" label="Velhas"><i /></:tab>
    </.tab_bar>
    """)
  end

  test "match prefix lights the tab of a parent path, in both variants" do
    for variant <- ["default", "canvas"] do
      assert attr_of(prefix_bar(variant), "a[aria-current=page]", "href") == ["/app/tasks"]
    end
  end

  test "exact is the default and a tab can override the match" do
    html =
      render(~H"""
      <.tab_bar current="/app/tasks/NXP-1">
        <:tab navigate="/app/tasks" label="Tarefas"><i /></:tab>
      </.tab_bar>
      """)

    assert find(html, "a[aria-current]") |> Enum.empty?()

    html =
      render(~H"""
      <.tab_bar current="/app/tasks/NXP-1">
        <:tab navigate="/app/tasks" label="Tarefas" match="prefix"><i /></:tab>
      </.tab_bar>
      """)

    assert attr_of(html, "a[aria-current=page]", "href") == ["/app/tasks"]
  end
end
