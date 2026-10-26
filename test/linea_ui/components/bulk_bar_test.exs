defmodule LineaUI.Components.BulkBarTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "nothing renders while nothing is selected" do
    html = render(~H|<.bulk_bar id="b" count={0} on_clear="clear" />|)

    assert find(html, "#b") |> Enum.count() == 0
  end

  test "a labelled region with the count and the text for one or for several" do
    one =
      render(
        ~H|<.bulk_bar id="b" count={1} label="order selected" label_plural="orders selected" />|
      )

    many =
      render(
        ~H|<.bulk_bar id="b" count={3} label="order selected" label_plural="orders selected" />|
      )

    assert attr_of(one, "#b", "role") == ["region"]
    assert attr_of(one, "#b", "aria-label") == ["1 order selected"]
    assert String.trim(find(one, "#b .linea-bulk-badge") |> LazyHTML.text()) == "1"
    assert attr_of(many, "#b", "aria-label") == ["3 orders selected"]
    assert attr_of(many, "#b", "phx-hook") == ["LineaUI.BulkBar"]
  end

  test "the plural falls back to the label" do
    html = render(~H|<.bulk_bar id="b" count={5} label="selected" />|)

    assert attr_of(html, "#b", "aria-label") == ["5 selected"]
  end

  test "floating pins the bar; floating false lays it out in place" do
    floating = render(~H|<.bulk_bar id="b" count={2} />|)
    inline = render(~H|<.bulk_bar id="b" count={2} floating={false} />|)

    assert "fixed" in classes(floating, "#b")
    assert attr_of(floating, "#b", "data-floating") == ["true"]
    refute "fixed" in classes(inline, "#b")
    assert attr_of(inline, "#b", "data-floating") == ["false"]
  end

  test "the close button runs on_clear, to the target, and is labelled with Esc" do
    html =
      render(
        ~H|<.bulk_bar id="b" count={2} on_clear="clear" target="#list" clear_label="Limpar" />|
      )

    assert attr_of(html, "#b [data-bulk-clear]", "phx-click") == ["clear"]
    assert attr_of(html, "#b [data-bulk-clear]", "phx-target") == ["#list"]
    assert attr_of(html, "#b [data-bulk-clear]", "aria-label") == ["Limpar (Esc)"]
  end

  test "select all shows only with an event and more in all than selected" do
    shown =
      render(
        ~H|<.bulk_bar id="b" count={12} total={128} on_select_all="all" select_all_label="Todos os %{total}" />|
      )

    all_selected = render(~H|<.bulk_bar id="b" count={128} total={128} on_select_all="all" />|)
    no_event = render(~H|<.bulk_bar id="b" count={12} total={128} />|)

    assert String.trim(find(shown, "#b .linea-bulk-link") |> LazyHTML.text()) == "Todos os 128"
    assert attr_of(shown, "#b .linea-bulk-link", "phx-click") == ["all"]
    assert find(all_selected, "#b .linea-bulk-link") |> Enum.count() == 0
    assert find(no_event, "#b .linea-bulk-link") |> Enum.count() == 0
  end

  test "actions are buttons with a variant, an icon, a disabled state and their own attributes" do
    html =
      render(~H"""
      <.bulk_bar id="b" count={2}>
        <:action variant="primary" disabled phx-click="apply">Apply</:action>
        <:action variant="danger" icon="huge-delete-02" phx-click="delete" phx-value-kind="soft">
          Delete
        </:action>
        <:action>Plain</:action>
      </.bulk_bar>
      """)

    assert attr_of(html, "#b .linea-bulk-btn", "data-variant") == ["primary", "danger", "default"]
    assert attr_of(html, "#b .linea-bulk-btn", "phx-click") == ["apply", "delete"]
    assert attr_of(html, "#b .linea-bulk-btn[data-variant=danger]", "phx-value-kind") == ["soft"]
    assert attr_of(html, "#b .linea-bulk-btn[data-variant=primary]", "disabled") == [""]

    assert find(
             html,
             "#b .linea-bulk-btn[data-variant=danger] [class*=huge-delete-02], #b .linea-bulk-btn[data-variant=danger] svg"
           )
           |> Enum.count() > 0

    assert attr_of(html, "#b .linea-bulk-btn", "type") == ["button", "button", "button"]
  end

  test "a field slot is wrapped to be skinned" do
    html =
      render(~H"""
      <.bulk_bar id="b" count={2}>
        <:field><input id="inner" name="status" /></:field>
      </.bulk_bar>
      """)

    assert find(html, "#b .linea-bulk-field #inner") |> Enum.count() == 1
  end

  test "the variant is a data attribute and the extra attributes go to the root" do
    html = render(~H|<.bulk_bar id="b" count={2} variant="soft" class="mt-2" data-x="1" />|)

    assert attr_of(html, "#b", "data-variant") == ["soft"]
    assert attr_of(html, "#b", "data-x") == ["1"]
    assert "mt-2" in classes(html, "#b")
  end
end
