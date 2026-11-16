defmodule LineaUI.Components.BadgeTest do
  use LineaUI.ComponentCase, async: true

  test "daisyUI's badge with its text, soft by default" do
    html = render(~H|<.badge>Novo</.badge>|)
    assert classes(html, "span") == ["badge", "badge-soft"]
    assert String.trim(LazyHTML.text(find(html, "span"))) == "Novo"
  end

  test "color, variant, size and shape map to daisyUI's modifiers" do
    assert ["badge", "badge-success", "badge-soft"] ==
             classes(render(~H|<.badge color="success">x</.badge>|), "span")

    assert "badge-error" in classes(render(~H|<.badge color="error">x</.badge>|), "span")
    assert "badge-neutral" in classes(render(~H|<.badge color="dark">x</.badge>|), "span")

    assert ["badge", "badge-primary"] ==
             classes(render(~H|<.badge color="primary" variant="solid">x</.badge>|), "span")

    assert "badge-outline" in classes(render(~H|<.badge variant="outline">x</.badge>|), "span")
    assert "badge-sm" in classes(render(~H|<.badge size="sm">x</.badge>|), "span")
    assert "rounded-full" in classes(render(~H|<.badge shape="pill">x</.badge>|), "span")
  end

  test "dot draws a status dot in the badge's color" do
    html = render(~H|<.badge dot>Ativo</.badge>|)
    assert [_] = find(html, "span.badge > span.status") |> Enum.to_list()
    assert find(render(~H|<.badge>Ativo</.badge>|), "span.status") |> Enum.to_list() == []
  end

  test "on_remove adds the remove button" do
    html = render(~H|<.badge id="f" on_remove="drop">Filtro</.badge>|)
    assert [_] = find(html, "#f > button[aria-label=Remove]") |> Enum.to_list()
  end

  test "class and attributes land on the badge" do
    html = render(~H|<.badge id="b" class="ml-2" data-x="1">x</.badge>|)
    assert "ml-2" in classes(html, "#b")
    assert LazyHTML.attribute(find(html, "#b"), "data-x") == ["1"]
  end
end
