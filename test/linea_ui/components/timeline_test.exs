defmodule LineaUI.Components.TimelineTest do
  use LineaUI.ComponentCase, async: true

  test "renders items with title, time and description" do
    html =
      render(~H"""
      <.timeline class="max-w-sm">
        <.timeline_item title="Video Added" time="1 hour ago" color="primary" description="New video">
          <a href="#">extra</a>
        </.timeline_item>
      </.timeline>
      """)

    assert ["timeline", "max-w-sm"] == classes(html, "ol")
    assert "bg-primary" in classes(html, ".timeline-item-point")

    assert html |> find(".timeline-item-content p.py-1") |> Enum.map(&LazyHTML.text/1) == [
             "New video"
           ]

    assert html =~ "1 hour ago"
    assert html |> find(".timeline-item-content a") |> Enum.count() == 1
  end

  test "variants, ping, line space and size" do
    html =
      render(~H"""
      <.timeline line_space size="lg">
        <.timeline_item variant="outline" color="success" />
        <.timeline_item variant="icon" color="error" ping>
          <:point><svg id="icon"></svg></:point>
        </.timeline_item>
      </.timeline>
      """)

    assert "line-space" in classes(html, "ol")
    assert "[--size:1.5rem]" in classes(html, "ol")
    assert "border-success" in classes(html, "li:first-child .timeline-item-point")
    point = classes(html, "li:last-child .timeline-item-point")
    assert "text-error" in point
    assert Enum.any?(point, &String.starts_with?(&1, "bg-[color-mix"))
    refute "bg-white" in point
    assert html |> find(".timeline-item-point #icon") |> Enum.count() == 1
    assert "motion-safe:animate-ping" in classes(html, "li:last-child .timeline-item-point span")
  end

  test "rows from a list with row_id" do
    assigns = %{rows: [%{id: 1, title: "One"}, %{id: 2, title: "Two"}]}

    html =
      rendered_to_string(~H"""
      <.timeline rows={@rows} row_id={&"ev-#{&1.id}"}>
        <:item :let={{id, row}}><.timeline_item id={id} title={row.title} /></:item>
      </.timeline>
      """)

    assert html |> find("li#ev-1, li#ev-2") |> Enum.count() == 2
    assert html |> find("ol[phx-update]") |> Enum.count() == 0
  end

  test "avatar points: bigger sizes, no disc, point_class" do
    html =
      render(~H"""
      <.timeline id="t" size="xl">
        <.timeline_item id="a" variant="avatar" title="Mores" point_class="ring-2">
          <:point><.avatar src="/a.jpg" class="size-full" /></:point>
        </.timeline_item>
      </.timeline>
      <.timeline id="u" size="2xl"></.timeline>
      """)

    assert "[--size:2rem]" in classes(html, "#t")
    assert "[--size:2.5rem]" in classes(html, "#u")
    point = classes(html, "#a .timeline-item-point")
    assert ["rounded-full", "ring-2"] -- point == []
    refute Enum.any?(point, &String.starts_with?(&1, "bg-"))
    assert "size-full" in classes(html, "#a .timeline-item-point .avatar")
  end
end
