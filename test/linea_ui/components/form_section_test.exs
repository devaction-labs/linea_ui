defmodule LineaUI.Components.FormSectionTest do
  use LineaUI.ComponentCase, async: true

  test "stacked: the title over a two-column grid, closed by a line" do
    html =
      render(~H"""
      <.form_section id="c" title="Contato"><span id="f1" /><span id="f2" /></.form_section>
      """)

    assert "stacked" in classes(html, "section")
    assert "divider" in classes(html, "section")
    assert LazyHTML.text(find(html, "h4#c-title")) =~ "Contato"
    assert LazyHTML.attribute(find(html, "section"), "aria-labelledby") == ["c-title"]
    assert "c2" in classes(html, ".lc-fs-grid")
    assert [_, _] = find(html, ".lc-fs-grid > span") |> Enum.to_list()
  end

  test "aside: the title and the description in a column, no line by default" do
    html =
      render(~H"""
      <.form_section title="Endereço" description="Usado na NF-e" layout="aside" columns={1}>
        <span />
      </.form_section>
      """)

    assert "aside" in classes(html, "section")
    refute "divider" in classes(html, "section")
    assert LazyHTML.text(find(html, ".lc-fs-desc")) =~ "Usado na NF-e"
    assert "c1" in classes(html, ".lc-fs-grid")
  end

  test "divider={false} drops the line and the action sits by the title" do
    html =
      render(~H"""
      <.form_section title="Senha" divider={false}>
        <:action><a id="more">Ver</a></:action>
        <span />
      </.form_section>
      """)

    refute "divider" in classes(html, "section")
    assert [_] = find(html, "h4 #more") |> Enum.to_list()
  end
end
