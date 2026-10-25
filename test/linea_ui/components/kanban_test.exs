defmodule LineaUI.Components.KanbanTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "the board is the sortable hook, with its group, event and target" do
    html =
      render(~H"""
      <.kanban id="funnel" event="move" target="#orders" class="min-h-[600px]">
        <p>columns</p>
      </.kanban>
      """)

    assert attr_of(html, "#funnel", "phx-hook") == ["LineaUI.Sortable"]
    assert attr_of(html, "#funnel", "data-event") == ["move"]
    assert attr_of(html, "#funnel", "data-target") == ["#orders"]
    assert attr_of(html, "#funnel", "data-group") == ["funnel"]
    assert attr_of(html, "#funnel", "data-disabled") == []
    assert "overflow-x-auto" in classes(html, "#funnel")
    assert "min-h-[600px]" in classes(html, "#funnel")
  end

  test "an explicit group replaces the id, and a disabled board says so" do
    html =
      render(~H"""
      <.kanban id="funnel" group="orders" disabled>
        <p>x</p>
      </.kanban>
      """)

    assert attr_of(html, "#funnel", "data-group") == ["orders"]
    assert attr_of(html, "#funnel", "data-disabled") == ["true"]
    assert attr_of(html, "#funnel", "data-event") == []
    assert attr_of(html, "#funnel", "data-target") == []
  end

  test "a column is the drop list of its cards" do
    html =
      render(~H"""
      <.kanban_column id="col-open" list="open" label="Open" count={2}>
        <.kanban_card id="c1" item="1">One</.kanban_card>
        <.kanban_card id="c2" item="2">Two</.kanban_card>
      </.kanban_column>
      """)

    assert attr_of(html, "section#col-open", "data-list") == ["open"]
    assert attr_of(html, "section#col-open", "aria-label") == ["Open"]
    assert attr_of(html, "section#col-open", "data-disabled") == []
    assert attr_of(html, "section > article", "data-id") == ["1", "2"]
    assert "w-[272px]" in classes(html, "section")
    assert "rounded-[14px]" in classes(html, "section")
    assert "data-[over]:ring-primary" in classes(html, "section")
    assert "dark:bg-navy-800" in classes(html, "section")
    assert LazyHTML.text(find(html, "section > div")) =~ "2"
  end

  test "the list and the card item default to the id" do
    html =
      render(~H"""
      <.kanban_column id="open" label="Open">
        <.kanban_card id="c1">One</.kanban_card>
      </.kanban_column>
      """)

    assert attr_of(html, "section", "data-list") == ["open"]
    assert attr_of(html, "article", "data-id") == ["c1"]
  end

  test "the color picks the icon tile and the bar" do
    for {color, tile, bar} <- [
          {"neutral", "bg-slate-150", "bg-slate-400"},
          {"info", "bg-info/10", "bg-info"},
          {"warning", "bg-warning/10", "bg-warning"},
          {"primary", "bg-primary/10", "bg-primary"},
          {"teal", "bg-teal-500/10", "bg-teal-500"},
          {"success", "bg-success/10", "bg-success"}
        ] do
      assigns = %{color: color}

      html =
        rendered_to_string(~H"""
        <.kanban_column id="c" label="Stage" color={@color} progress={50}>
          <:icon><i>i</i></:icon>
        </.kanban_column>
        """)

      assert tile in classes(html, "section > div > span")
      assert bar in classes(html, "section [aria-hidden=true] > span")
    end
  end

  test "the stats line, the bar and the header slots are drawn only when given" do
    plain = render(~H|<.kanban_column id="c" label="Stage" />|)

    assert find(plain, "[aria-hidden=true]") |> Enum.count() == 0
    assert find(plain, "section > div") |> Enum.count() == 1
    assert find(plain, "section > div > span") |> Enum.count() == 1

    full =
      render(~H"""
      <.kanban_column id="c" label="Stage" count={3} meta="60% chance" total="R$ 10,00" progress={60}>
        <:icon><i id="glyph">i</i></:icon>
        <:actions><button id="menu">...</button></:actions>
      </.kanban_column>
      """)

    assert find(full, "#glyph") |> Enum.count() == 1
    assert find(full, "section > div > span.ml-auto #menu") |> Enum.count() == 1
    assert LazyHTML.text(find(full, "section > div.justify-between")) =~ "60% chance"
    assert LazyHTML.text(find(full, "section > div.justify-between b")) == "R$ 10,00"
    assert attr_of(full, "section [aria-hidden=true] > span", "style") == ["width: 60%"]
  end

  test "the progress is held between 0 and 100" do
    over = render(~H|<.kanban_column id="c" label="S" progress={140} />|)
    under = render(~H|<.kanban_column id="c" label="S" progress={-5} />|)

    assert attr_of(over, "[aria-hidden=true] > span", "style") == ["width: 100%"]
    assert attr_of(under, "[aria-hidden=true] > span", "style") == ["width: 0%"]
  end

  test "the empty state shows only for a column with no cards" do
    template = fn count ->
      assigns = %{count: count}

      rendered_to_string(~H"""
      <.kanban_column id="c" label="S" count={@count}>
        <:empty title="Nothing here">Drag one here.</:empty>
      </.kanban_column>
      """)
    end

    empty = template.(0)
    assert LazyHTML.text(find(empty, "section")) =~ "Nothing here"
    assert LazyHTML.text(find(empty, "section")) =~ "Drag one here."

    assert find(template.(2), "b") |> Enum.count() == 0
  end

  test "the footer comes after the cards" do
    html =
      render(~H"""
      <.kanban_column id="c" label="S" count={1}>
        <.kanban_card id="c1">One</.kanban_card>
        <:footer><button id="add">Add</button></:footer>
      </.kanban_column>
      """)

    assert find(html, "section > article + #add") |> Enum.count() == 1
  end

  test "a card is a draggable surface, with the warning ring on risk" do
    html =
      render(~H"""
      <.kanban_card id="c1" item="2462" class="extra">Body</.kanban_card>
      """)

    assert attr_of(html, "article#c1", "draggable") == ["true"]
    assert attr_of(html, "article#c1", "data-id") == ["2462"]
    assert "rounded-xl" in classes(html, "article")
    assert "cursor-grab" in classes(html, "article")
    assert "data-[dragging]:opacity-45" in classes(html, "article")
    assert "extra" in classes(html, "article")
    refute Enum.any?(classes(html, "article"), &String.starts_with?(&1, "!shadow"))

    risky = render(~H|<.kanban_card id="c1" risk>Body</.kanban_card>|)
    assert Enum.any?(classes(risky, "article"), &String.starts_with?(&1, "!shadow"))
  end

  test "the lost aside is vertical, and a drop list only with a list id" do
    plain = render(~H|<.kanban_lost label="Lost" count={3} meta="R$ 6.410,00" />|)

    assert attr_of(plain, "aside", "aria-label") == ["Lost"]
    assert attr_of(plain, "aside", "data-list") == []
    assert "w-[52px]" in classes(plain, "aside")
    assert LazyHTML.text(find(plain, "aside")) =~ "Lost · R$ 6.410,00"
    assert LazyHTML.text(find(plain, "aside")) =~ "3"

    assert find(plain, "aside i.huge-cancel-circle, aside [class*=cancel-circle]") |> Enum.count() ==
             1

    target = render(~H|<.kanban_lost label="Lost" list="lost" />|)
    assert attr_of(target, "aside", "data-list") == ["lost"]
    assert LazyHTML.text(find(target, "aside")) =~ "Lost"
    refute LazyHTML.text(find(target, "aside")) =~ "·"
  end

  test "the lost icon can be replaced" do
    html =
      render(~H"""
      <.kanban_lost label="Lost">
        <:icon><b id="own">x</b></:icon>
      </.kanban_lost>
      """)

    assert find(html, "aside #own") |> Enum.count() == 1
  end
end
