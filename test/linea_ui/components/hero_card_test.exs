defmodule LineaUI.Components.HeroCardTest do
  use LineaUI.ComponentCase, async: true

  defp text(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

  test "the text on the left and the picture on the right" do
    html =
      render(~H"""
      <.hero_card
        eyebrow="Bem-vindo de volta"
        title="Metas do ano"
        description="Metas do trimestre."
        src="/hero.jpg"
      >
        <:actions><a id="new" href="/metas/nova">Nova meta</a></:actions>
      </.hero_card>
      """)

    assert ["linea-hero"] == classes(html, "section")
    assert text(html, ".linea-hero-eyebrow") == ["Bem-vindo de volta"]
    assert text(html, "h2.linea-hero-title") == ["Metas do ano"]
    assert text(html, ".linea-hero-desc") == ["Metas do trimestre."]
    assert [_] = find(html, ".linea-hero-actions #new") |> Enum.to_list()
    assert html |> find(".linea-hero-art img") |> LazyHTML.attribute("src") == ["/hero.jpg"]
  end

  test "the art slot, the icon, the heading tag and the size" do
    html =
      render(~H"""
      <.hero_card title="Revisar a API v2" heading="h1" size="lg" variant="panel" position="right">
        <:icon><svg id="spark"></svg></:icon>
        <:art><.summit /></:art>
      </.hero_card>
      """)

    assert text(html, "h1") == ["Revisar a API v2"]
    assert html |> find("section") |> LazyHTML.attribute("data-size") == ["lg"]
    assert html |> find("section") |> LazyHTML.attribute("data-variant") == ["panel"]
    assert [_] = find(html, ".linea-hero-eyebrow #spark") |> Enum.to_list()

    assert [_] =
             find(html, ".linea-hero-art svg[preserveAspectRatio='xMidYMax slice']")
             |> Enum.to_list()

    assert html |> find(".linea-hero-art") |> LazyHTML.attribute("style") == [
             "--hero-position: right"
           ]

    assert find(html, ".linea-hero-art img") |> Enum.to_list() == []
  end

  test "without a picture there is no art box" do
    html = render(~H|<.hero_card title="Só texto" />|)
    assert find(html, ".linea-hero-art") |> Enum.to_list() == []
    assert find(html, ".linea-hero-eyebrow") |> Enum.to_list() == []
  end

  test "summit gradient ids default to the hs prefix" do
    svg = render(~H"<.summit />")

    assert svg =~ ~s(id="hs-sky")
    assert svg =~ "url(#hs-sky)"
  end

  test "summit takes its own id prefix, leaving no hs- behind" do
    svg = render(~H|<.summit id="hero2" />|)

    assert svg =~ ~s(id="hero2-sky")
    assert svg =~ "url(#hero2-sky)"
    refute svg =~ "hs-"
  end
end
