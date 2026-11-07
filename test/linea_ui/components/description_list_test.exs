defmodule LineaUI.Components.DescriptionListTest do
  use LineaUI.ComponentCase, async: true

  test "pairs in a grid of cols columns, with a dash for a missing value" do
    html =
      render(~H"""
      <.description_list id="d" cols={3}>
        <:item label="Emissão">06/11/2026</:item>
        <:item label="CNPJ" mono>12.345.678/0001-90</:item>
        <:item label="Frete" />
      </.description_list>
      """)

    assert LazyHTML.attribute(find(html, "#d"), "style") == [
             "grid-template-columns: repeat(3, minmax(0, 1fr))"
           ]

    assert find(html, "#d dt") |> Enum.map(&LazyHTML.text/1) == ["Emissão", "CNPJ", "Frete"]
    assert "font-mono" in classes(html, "#d div:nth-child(2) dd")
    assert find(html, "#d div:nth-child(3) dd") |> LazyHTML.text() == "—"
  end

  test "inline puts the label and the value on one line" do
    html =
      render(~H|<.description_list id="d" cols={1} layout="inline">
  <:item label="IE">Isento</:item>
</.description_list>|)

    assert LazyHTML.attribute(find(html, "#d"), "data-layout") == ["inline"]
  end
end
