defmodule LineaUI.Components.CoverTest do
  use LineaUI.ComponentCase, async: true

  test "a band with its title, in the accent or the neutral tone" do
    html = render(~H|<.cover id="c" title="Distribuidora Sertão" height={110} />|)
    neutral = render(~H|<.cover id="n" tone="neutral" />|)

    assert find(html, "#c .linea-cover-title") |> LazyHTML.text() == "Distribuidora Sertão"
    assert LazyHTML.attribute(find(html, "#c"), "style") == ["height: 110px"]
    assert LazyHTML.attribute(find(neutral, "#n"), "data-tone") == ["neutral"]
  end

  test "with an avatar the title and subtitle go beside it, under the band" do
    html =
      render(~H"""
      <.cover id="c" title="Distribuidora Sertão" subtitle="Cliente desde 2021">
        <:avatar><span id="av">DS</span></:avatar>
      </.cover>
      """)

    assert [_] = find(html, "#c > .linea-cover") |> Enum.to_list()
    assert [_] = find(html, "#c .linea-cover-head .linea-cover-avatar #av") |> Enum.to_list()
    assert find(html, "#c .linea-cover-sub") |> LazyHTML.text() == "Cliente desde 2021"
    assert [] = find(html, "#c .linea-cover-title") |> Enum.to_list()
  end
end
