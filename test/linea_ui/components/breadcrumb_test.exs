defmodule LineaUI.Components.BreadcrumbTest do
  use LineaUI.ComponentCase, async: true

  test "links for the trail, plain text and aria-current for the last step" do
    html =
      render(~H"""
      <.breadcrumb>
        <:item href="/">Home</:item>
        <:item navigate="/elements">Elements</:item>
        <:item>Breadcrumb</:item>
      </.breadcrumb>
      """)

    assert [_] = find(html, "nav[aria-label=Breadcrumb] > ul") |> Enum.to_list()
    assert [_, _] = find(html, "li > a") |> Enum.to_list()
    assert [current] = find(html, "[aria-current=page]") |> Enum.to_list()
    assert String.trim(LazyHTML.text(current)) == "Breadcrumb"
    assert [_, _] = find(html, "li > svg") |> Enum.to_list()
    assert "text-primary" in classes(html, "a")
  end

  test "a custom separator and the bordered variant" do
    html =
      render(~H"""
      <.breadcrumb variant="bordered">
        <:separator><span class="sep">/</span></:separator>
        <:item href="/">Home</:item>
        <:item>Now</:item>
      </.breadcrumb>
      """)

    assert [_] = find(html, "span.sep") |> Enum.to_list()
    assert [] = find(html, "li > svg") |> Enum.to_list()
    assert "border-slate-200" in classes(html, "a")
    assert "px-2" in classes(html, "a")
    assert "py-[5px]" in classes(html, "a")
  end

  test "the current page is soft and cut with an ellipsis, with its title" do
    html =
      render(~H"""
      <.breadcrumb>
        <:item href="/">Home</:item>
        <:item title="A very long page name">A very long page name</:item>
      </.breadcrumb>
      """)

    assert "text-slate-600" in classes(html, "[aria-current=page]")
    assert "min-w-0" in classes(html, "[aria-current=page]")
    assert "truncate" in classes(html, "[aria-current=page] > span")

    assert [_] =
             find(html, "[aria-current=page][title='A very long page name']") |> Enum.to_list()
  end

  test "items with phx-click are buttons and pass their attributes on" do
    assigns = %{path: [%{id: "1", name: "Docs"}, %{id: "2", name: "Pics"}]}

    html =
      rendered_to_string(~H"""
      <.breadcrumb>
        <:item :for={f <- @path} phx-click="open" phx-value-id={f.id} phx-target="#fm">{f.name}</:item>
        <:item id="now" data-kind="current">Now</:item>
      </.breadcrumb>
      """)

    assert [_, _] =
             find(html, "button[type=button][phx-click=open][phx-target='#fm']") |> Enum.to_list()

    assert ["1", "2"] = find(html, "button") |> LazyHTML.attribute("phx-value-id")
    assert "text-primary" in classes(html, "button")
    assert [_] = find(html, "div#now[data-kind=current][aria-current=page]") |> Enum.to_list()
  end
end
