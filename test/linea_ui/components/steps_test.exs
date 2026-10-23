defmodule LineaUI.Components.StepsTest do
  use LineaUI.ComponentCase, async: true

  test "renders the steps with labels and points" do
    html =
      render(~H"""
      <.steps>
        <:step label="Step 1">1</:step>
        <:step label="Step 2" current>2</:step>
      </.steps>
      """)

    assert "steps" in classes(html, "ol")
    assert html |> find("li.step") |> Enum.count() == 2
    assert "before:bg-slate-200" in classes(html, "li")
    assert "bg-slate-200" in classes(html, ".step-header")
    assert html |> find("li[aria-current=step]") |> Enum.count() == 1
    assert html |> find("h3") |> Enum.map(&LazyHTML.text/1) == ["Step 1", "Step 2"]
  end

  test "color paints points and line, a step's color only its point" do
    html =
      render(~H"""
      <.steps color="primary">
        <:step label="A" />
        <:step label="B" color="secondary" ping />
      </.steps>
      """)

    assert "before:bg-primary" in classes(html, "li")
    assert "bg-primary" in classes(html, ".step-header")
    assert "bg-secondary" in classes(html, "li:last-child .step-header")
    assert "animate-ping" in classes(html, "li:last-child .step-header span")
  end

  test "vertical, line space and sizes" do
    html =
      render(~H"""
      <.steps orientation="vertical" line_space size="sm">
        <:step label="A" />
      </.steps>
      """)

    ol = classes(html, "ol")
    assert "is-vertical" in ol
    assert "line-space" in ol
    assert "[--size:1rem]" in ol
    assert "not-last:pb-12" in classes(html, "li")
    assert "text-xs-plus" in classes(html, "h3")

    html = render(~H|<.steps size="lg"><:step label="A" /></.steps>|)
    assert "[--size:2.75rem]" in classes(html, "ol")
  end
end
