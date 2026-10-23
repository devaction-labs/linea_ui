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
  end
end
