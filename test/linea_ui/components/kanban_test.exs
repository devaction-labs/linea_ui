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
    assert "dark:bg-navy-900" in classes(html, "section")
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
          {"neutral", "bg-slate-500/[.13]", "bg-slate-500"},
          {"info", "bg-info-focus/[.13]", "bg-info-focus"},
          {"warning", "bg-warning-focus/[.13]", "bg-warning-focus"},
          {"primary", "bg-primary/[.13]", "bg-primary"},
          {"teal", "bg-teal-500/10", "bg-teal-500"},
          {"success", "bg-success-focus/[.13]", "bg-success-focus"}
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
    assert find(empty, "section > div[data-empty]") |> Enum.count() == 1
    assert find(empty, "div[data-empty] svg[viewBox]") |> Enum.count() == 1
  end

  test "the column and the lost aside tint when a card is over them and draw no ring or outline" do
    html =
      render(~H"""
      <.kanban_column id="c" label="S" />
      <.kanban_lost label="Lost" list="lost" />
      """)

    for tag <- ["section", "aside"] do
      assert "data-[over]:bg-primary/10" in classes(html, tag)
      assert "dark:data-[over]:bg-accent/[.18]" in classes(html, tag)
      refute Enum.any?(classes(html, tag), &(&1 =~ ~r/data-\[over\]:(ring|outline)/))
    end
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

  test "a card is a grabbable surface with no native drag, and the warning ring on risk" do
    html =
      render(~H"""
      <.kanban_card id="c1" item="2462" class="extra">Body</.kanban_card>
      """)

    assert attr_of(html, "article#c1", "draggable") == []
    assert attr_of(html, "article#c1", "data-id") == ["2462"]
    assert "rounded-xl" in classes(html, "article")
    assert "cursor-grab" in classes(html, "article")
    assert "data-[dragging]:shadow-none" in classes(html, "article")
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

  test "a column over its limit turns the pill and the bar red, and the words of the limit are the consumer's" do
    html =
      render(~H"""
      <.kanban id="b" aria-label="Funnel">
        <.kanban_column
          id="over"
          label="Doing"
          count={4}
          limit={3}
          meta="limit of 3"
          total="4 of 3"
          progress={100}
        />
        <.kanban_column id="ok" label="Todo" count={2} limit={3} meta="limit of 3" progress={50} />
        <.kanban_column id="off" label="Done" count={2} disabled />
      </.kanban>
      """)

    assert [_] = find(html, ~s|#b[role="group"][aria-label="Funnel"]|) |> Enum.to_list()
    assert [_] = find(html, ~s|#over[data-wip="exceeded"]|) |> Enum.to_list()
    assert [] = find(html, "#ok[data-wip]") |> Enum.to_list()
    assert find(html, "#over > div:first-child span:nth-child(2)") |> LazyHTML.text() =~ "4"
    refute find(html, "#over > div:first-child span:nth-child(2)") |> LazyHTML.text() =~ "/"
    assert "text-error-focus" in classes(html, "#over > div:first-child span:nth-child(2)")
    assert "bg-error-focus/10" in classes(html, "#over > div:first-child span:nth-child(2)")
    refute "text-error-focus" in classes(html, "#ok > div:first-child span:nth-child(2)")
    refute "text-error-focus" in classes(html, "#over > div:nth-child(2) > span")
    assert find(html, "#over > div:nth-child(2)") |> LazyHTML.text() =~ "4 of 3"
    assert "bg-error-focus" in classes(html, "#over span.block")
    refute "bg-error-focus" in classes(html, "#ok span.block")
    assert "data-[disabled=true]:opacity-60" in classes(html, "#off")
  end

  test "a card with grip draws the drag handle that shows on hover" do
    plain = render(~H|<.kanban_card id="a">A</.kanban_card>|)
    assert [] = find(plain, "article [data-grip]") |> Enum.to_list()

    html = render(~H|<.kanban_card id="a" grip>A</.kanban_card>|)
    assert [_] = find(html, ~s|article [data-grip][aria-hidden="true"]|) |> Enum.to_list()
    assert find(html, "article [data-grip] i") |> Enum.count() == 6
    assert "group-hover:opacity-90" in classes(html, "[data-grip]")
    assert "opacity-0" in classes(html, "[data-grip]")
  end
end
