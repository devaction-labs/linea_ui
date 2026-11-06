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
    assert [] = find(html, "#b kbd") |> Enum.to_list()
  end

  test "show_esc writes an Esc key chip in the close button" do
    html = render(~H|<.bulk_bar id="b" count={2} show_esc />|)

    assert find(html, "#b [data-bulk-clear] kbd.linea-bulk-esc") |> LazyHTML.text() == "Esc"
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
    assert attr_of(html, "#b .linea-bulk-btn", "phx-click") == ["delete"]
    assert attr_of(html, "#b .linea-bulk-btn[data-variant=danger]", "phx-value-kind") == ["soft"]
    # disabled stays focusable (aria-disabled, no native disabled) and runs nothing
    primary = "#b .linea-bulk-btn[data-variant=primary]"
    assert attr_of(html, primary, "aria-disabled") == ["true"]
    assert attr_of(html, primary, "disabled") == []
    assert attr_of(html, primary, "phx-click") == []
    assert attr_of(html, "#b .linea-bulk-btn[data-variant=danger]", "aria-disabled") == []

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

  test "solid writes the count in bold, without badge or separators, and closes only with on_clear" do
    html =
      render(~H"""
      <.bulk_bar id="b" variant="solid" count={3} label="selecionado" label_plural="selecionados">
        <:action variant="soft">Aprovar</:action>
        <:action variant="ghost">Exportar</:action>
      </.bulk_bar>
      """)

    with_clear = render(~H|<.bulk_bar id="b" variant="solid" count={3} on_clear="clear" />|)

    assert String.trim(find(html, "#b .linea-bulk-text") |> LazyHTML.text()) == "3 selecionados"
    assert [] = find(html, "#b .linea-bulk-badge, #b .linea-bulk-sep") |> Enum.to_list()
    assert [] = find(html, "#b [data-bulk-clear]") |> Enum.to_list()
    assert attr_of(html, "#b .linea-bulk-btn", "data-variant") == ["soft", "ghost"]
    assert attr_of(with_clear, "#b [data-bulk-clear]", "phx-click") == ["clear"]
  end

  test "progress shows the label, a meter and the fraction" do
    html =
      render(
        ~H|<.bulk_bar id="b" count={12} label="Emitindo 12 notas…" progress={5} progress_max={12} />|
      )

    assert String.trim(find(html, "#b .linea-bulk-text") |> LazyHTML.text()) ==
             "Emitindo 12 notas…"

    assert attr_of(html, "#b [role=progressbar]", "aria-valuenow") == ["5"]
    assert find(html, "#b .linea-bulk-fraction") |> LazyHTML.text() == "5/12"
    assert [] = find(html, "#b .linea-bulk-badge") |> Enum.to_list()
  end

  test "a confirmed action opens a card whose confirm button runs the action" do
    html =
      render(~H"""
      <.bulk_bar id="b" count={3}>
        <:action
          variant="danger"
          phx-click="delete"
          confirm="Excluir 3?"
          confirm_text="Some."
          confirm_label="Excluir"
          cancel_label="Cancelar"
        >
          Excluir
        </:action>
      </.bulk_bar>
      """)

    [trigger] = attr_of(html, "#b > .linea-bulk-btn", "phx-click")
    assert trigger =~ "#b-confirm-0"
    assert find(html, "#b-confirm-0 .linea-bulk-confirm-title") |> LazyHTML.text() == "Excluir 3?"
    [confirm] = attr_of(html, "#b-confirm-0 .linea-bulk-btn[data-variant=danger]", "phx-click")
    assert confirm =~ "delete"

    assert find(html, "#b-confirm-0 .linea-bulk-btn[data-variant=ghost]") |> LazyHTML.text() =~
             "Cancelar"
  end
end
