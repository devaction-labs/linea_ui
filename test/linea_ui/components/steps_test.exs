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

  test "a step's state colors its point and marks the current step" do
    html =
      render(~H"""
      <.steps>
        <:step label="A" state="done" />
        <:step label="B" state="current" />
        <:step label="C" state="error" />
        <:step label="D" state="todo" />
      </.steps>
      """)

    assert "bg-primary" in classes(html, "li:nth-child(1) .step-header")
    assert "bg-slate-200" in classes(html, "li:nth-child(2) .step-header")
    assert "bg-error" in classes(html, "li:nth-child(3) .step-header")
    assert "bg-slate-200" in classes(html, "li:nth-child(4) .step-header")
    assert html |> find("li[aria-current=step]") |> Enum.count() == 1
    assert [_] = find(html, "li:nth-child(2)[aria-current=step]") |> Enum.to_list()
  end

  defp stepper_texts(html, selector),
    do:
      html
      |> find(selector)
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

  defp states(html), do: html |> find("li") |> LazyHTML.attribute("data-state")

  test "the stepper derives each state from current" do
    html =
      render(~H"""
      <.stepper current={1}>
        <:step label="Company" sub="Tax id" />
        <:step label="Certificate" sub="File" />
        <:step label="Profile" />
        <:step label="Test" />
      </.stepper>
      """)

    assert states(html) == ["done", "current", "todo", "todo"]
    assert find(html, "ol") |> Enum.count() == 1

    assert html |> find("li[aria-current=step]") |> LazyHTML.attribute("data-state") == [
             "current"
           ]

    assert stepper_texts(html, "li:nth-child(1) .block") |> List.first() =~ "Company"
    assert stepper_texts(html, "li:nth-child(1) .text-xs") == ["Tax id"]
    assert find(html, "li:nth-child(3) .text-xs") |> Enum.count() == 0
  end

  test "an error flags the current step and keeps aria-current on it" do
    html =
      render(~H"""
      <.stepper current={1} error>
        <:step label="A" />
        <:step label="B" />
        <:step label="C" />
      </.stepper>
      """)

    assert states(html) == ["done", "error", "todo"]
    assert html |> find("li[aria-current=step]") |> LazyHTML.attribute("data-state") == ["error"]
    assert "bg-error" in classes(html, "li:nth-child(2) > span:first-child")
    assert stepper_texts(html, "li:nth-child(2) .rounded-full") == ["!"]
  end

  test "the dot shows the number, a check for done steps and a marker when given" do
    html =
      render(~H"""
      <.stepper current={2}>
        <:step label="A" />
        <:step label="B" marker="B" />
        <:step label="C" />
        <:step label="D" />
      </.stepper>
      """)

    dots = stepper_texts(html, "li .rounded-full")
    assert Enum.at(dots, 1) == "B"
    assert Enum.at(dots, 2) == "3"
    assert Enum.at(dots, 3) == "4"
    assert [_] = find(html, "li:nth-child(1) .rounded-full svg") |> Enum.to_list()
    assert find(html, "li:nth-child(3) .rounded-full svg") |> Enum.count() == 0
  end

  test "a step's own state wins over current" do
    html =
      render(~H"""
      <.stepper current={0}>
        <:step label="A" />
        <:step label="B" state="done" />
      </.stepper>
      """)

    assert states(html) == ["current", "done"]
  end

  test "without current every step is to do" do
    html = render(~H|<.stepper><:step label="A" /><:step label="B" /></.stepper>|)
    assert states(html) == ["todo", "todo"]
    assert find(html, "li[aria-current]") |> Enum.count() == 0
  end

  test "the state is read out for screen readers, in the language given" do
    html =
      render(~H"""
      <.stepper
        current={1}
        state_names={
          %{"done" => "Concluído", "current" => "Atual", "error" => "Erro", "todo" => "Pendente"}
        }
      >
        <:step label="A" />
        <:step label="B" />
        <:step label="C" />
      </.stepper>
      """)

    assert stepper_texts(html, ".sr-only") == ["Concluído:", "Atual:", "Pendente:"]
  end

  test "horizontal draws a bar per step over a grid of the steps" do
    html =
      render(~H"""
      <.stepper current={1}>
        <:step label="A" />
        <:step label="B" />
        <:step label="C" />
      </.stepper>
      """)

    assert html |> find("ol") |> LazyHTML.attribute("style") == [
             "grid-template-columns: repeat(3, minmax(0, 1fr))"
           ]

    assert "grid" in classes(html, "ol")
    assert find(html, "li > span.h-1") |> Enum.count() == 3
    assert "bg-primary" in classes(html, "li:nth-child(1) > span.h-1")
    assert "bg-slate-150" in classes(html, "li:nth-child(3) > span.h-1")
  end

  test "horizontal shows a step's content under its text" do
    html =
      render(~H"""
      <.stepper current={0}>
        <:step label="A"><a href="#more">More</a></:step>
        <:step label="B" />
      </.stepper>
      """)

    assert stepper_texts(html, "li:nth-child(1) > span:last-child a") == ["More"]
    assert find(html, "li:nth-child(2) a") |> Enum.count() == 0
  end

  test "vertical joins the dots with a line and puts the content at the right end" do
    html =
      render(~H"""
      <.stepper orientation="vertical" current={1}>
        <:step label="A" />
        <:step label="B"><button type="button">Import</button></:step>
        <:step label="C" />
      </.stepper>
      """)

    assert "flex-col" in classes(html, "ol")
    refute html |> find("ol") |> LazyHTML.attribute("style") |> Enum.join() =~ "grid-template"
    assert "before:bg-primary" in classes(html, "li:nth-child(1)")
    assert "before:bg-slate-200" in classes(html, "li:nth-child(2)")
    assert "last:before:hidden" in classes(html, "li:nth-child(3)")
    assert find(html, "li > span.h-1") |> Enum.count() == 0
    assert stepper_texts(html, "li:nth-child(2) button") == ["Import"]
    assert "size-7" in classes(html, "li:nth-child(1) .rounded-full")
  end

  test "class and rest land on the list" do
    html = render(~H|<.stepper id="s" class="mt-4" data-x="1"><:step label="A" /></.stepper>|)
    assert "mt-4" in classes(html, "#s")
    assert html |> find("#s") |> LazyHTML.attribute("data-x") == ["1"]
  end
end
