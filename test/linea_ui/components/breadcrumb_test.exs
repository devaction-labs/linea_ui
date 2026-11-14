defmodule LineaUI.Components.BreadcrumbTest do
  use LineaUI.ComponentCase, async: true

  test "links for the trail, plain text and aria-current for the last step" do
    html =
      render(~H"""
      <.breadcrumb variant="plain">
        <:item href="/">Home</:item>
        <:item navigate="/elements">Elements</:item>
        <:item>Breadcrumb</:item>
      </.breadcrumb>
      """)

    assert [_] = find(html, "nav[aria-label=Breadcrumb] > ul") |> Enum.to_list()
    assert [_, _] = find(html, "li > a") |> Enum.to_list()
    assert [current] = find(html, "[aria-current=page]") |> Enum.to_list()
    assert String.trim(LazyHTML.text(current)) == "Breadcrumb"
    assert [_, _] = find(html, "li > svg") |> Enum.to_list()
    assert "text-primary" in classes(html, "a")
    assert "rounded-md" in classes(html, "a")
    assert "hover:underline-offset-3" in classes(html, "a")
    assert "text-slate-400" in classes(html, "li > svg")
  end

  test "a custom separator and the bordered variant" do
    html =
      render(~H"""
      <.breadcrumb variant="bordered">
        <:separator><span class="sep">/</span></:separator>
        <:item href="/">Home</:item>
        <:item>Now</:item>
      </.breadcrumb>
      """)

    assert [_] = find(html, "span.sep") |> Enum.to_list()
    assert [] = find(html, "li > svg") |> Enum.to_list()
    assert "shadow-[inset_0_0_0_1px_var(--color-slate-200)]" in classes(html, "a")
    refute "border" in classes(html, "a")
    assert "px-2" in classes(html, "a")
    assert "py-[5px]" in classes(html, "a")
  end

  test "the current page is soft and cut with an ellipsis, with its title" do
    html =
      render(~H"""
      <.breadcrumb variant="plain">
        <:item href="/">Home</:item>
        <:item title="A very long page name">A very long page name</:item>
      </.breadcrumb>
      """)

    assert "text-slate-600" in classes(html, "[aria-current=page]")
    assert "min-w-0" in classes(html, "[aria-current=page]")
    assert "truncate" in classes(html, "[aria-current=page] > span")

    assert [_] =
             find(html, "[aria-current=page][title='A very long page name']") |> Enum.to_list()
  end

  test "items with phx-click are buttons and pass their attributes on" do
    assigns = %{path: [%{id: "1", name: "Docs"}, %{id: "2", name: "Pics"}]}

    html =
      rendered_to_string(~H"""
      <.breadcrumb variant="plain">
        <:item :for={f <- @path} phx-click="open" phx-value-id={f.id} phx-target="#fm">{f.name}</:item>
        <:item id="now" data-kind="current">Now</:item>
      </.breadcrumb>
      """)

    assert [_, _] =
             find(html, "button[type=button][phx-click=open][phx-target='#fm']") |> Enum.to_list()

    assert ["1", "2"] = find(html, "button") |> LazyHTML.attribute("phx-value-id")
    assert "text-primary" in classes(html, "button")
    assert [_] = find(html, "div#now[data-kind=current][aria-current=page]") |> Enum.to_list()
  end

  test "the canvas variant is the sg-crumb pill with / separators and the current page in the ink" do
    html =
      render(~H"""
      <.breadcrumb variant="canvas">
        <:item href="/c">Clientes</:item>
        <:item>Casa</:item>
      </.breadcrumb>
      """)

    assert "sg-crumb" in classes(html, "ul")
    assert html |> find("ul .sep") |> LazyHTML.text() == "/"
    assert "font-medium" in classes(html, "[aria-current=page]")
  end

  defp collapsed(max) do
    assigns = %{max: max}

    rendered_to_string(~H"""
    <.breadcrumb id="trail" max_items={@max}>
      <:item href="/a">A</:item>
      <:item href="/b">B</:item>
      <:item phx-click="open" phx-value-id="c">C</:item>
      <:item href="/d">D</:item>
      <:item>E</:item>
    </.breadcrumb>
    """)
  end

  test "max_items keeps the first step and the last ones; the middle goes into a dropdown" do
    html = collapsed(4)

    assert [_] = find(html, "#trail-more[phx-hook='LineaUI.Dropdown']") |> Enum.to_list()

    assert texts(html, "#trail > ul > li > a, #trail > ul > li > div[aria-current]") == [
             "A",
             "D",
             "E"
           ]

    assert html |> find("[aria-current=page]") |> LazyHTML.text() =~ "E"

    assert [_, _] = find(html, "#trail-more-menu [role=menuitem]") |> Enum.to_list()
    assert [_] = find(html, "#trail-more-menu a[role=menuitem][href='/b']") |> Enum.to_list()

    assert [_] =
             find(html, "#trail-more-menu button[role=menuitem][phx-click=open][phx-value-id=c]")
             |> Enum.to_list()

    assert LazyHTML.attribute(find(html, "#trail-more [data-trigger] button"), "aria-label") == [
             "Show hidden steps"
           ]

    assert [_] = find(html, "#trail-more [data-trigger] button svg") |> Enum.to_list()
  end

  test "max_items counts the dots as a step and never hides less than it has" do
    three = collapsed(3)
    assert [_, _, _] = find(three, "#trail-more-menu [role=menuitem]") |> Enum.to_list()

    two = collapsed(1)
    assert [_, _, _] = find(two, "#trail-more-menu [role=menuitem]") |> Enum.to_list()

    fits = collapsed(5)
    assert [] = find(fits, "#trail-more") |> Enum.to_list()
    assert [_, _, _, _] = find(fits, "#trail li") |> Enum.to_list() |> Enum.take(4)

    none = render(~H"<.breadcrumb>
  <:item>Only</:item>
</.breadcrumb>")
    assert [] = find(none, "[data-trigger]") |> Enum.to_list()
  end

  test "navigate, patch and href that are nil or false make the step plain text" do
    html =
      render(~H"""
      <.breadcrumb>
        <:item navigate="/">Home</:item>
        <:item navigate={nil}>Admin</:item>
        <:item patch={false}>Group</:item>
        <:item href={nil} navigate={false} patch={nil}>Area</:item>
        <:item navigate={nil}>Now</:item>
      </.breadcrumb>
      """)

    assert [_] = find(html, "li a") |> Enum.to_list()
    assert texts(html, "li > div > span") == ["Admin", "Group", "Area"]
    assert texts(html, "nav.sg-crumb b, ul.sg-crumb b") == ["Now"]
  end

  test "steps built with :for and a nil navigate" do
    assigns = %{
      steps: [%{name: "Home", to: "/"}, %{name: "Mgmt", to: nil}, %{name: "Now", to: nil}]
    }

    html =
      rendered_to_string(~H"""
      <.breadcrumb>
        <:item :for={step <- @steps} navigate={step.to}>{step.name}</:item>
      </.breadcrumb>
      """)

    assert [_] = find(html, "li a[href='/']") |> Enum.to_list()
    assert texts(html, "li > div > span") == ["Mgmt"]
    assert texts(html, "b[class]") == ["Now"]
  end

  test "nil routes also work inside the collapsed dropdown" do
    html =
      render(~H"""
      <.breadcrumb id="p" max_items={3}>
        <:item navigate="/">A</:item>
        <:item navigate={nil}>B</:item>
        <:item navigate={nil}>C</:item>
        <:item>D</:item>
      </.breadcrumb>
      """)

    assert [_] = find(html, "#p-more") |> Enum.to_list()
  end

  test "the canvas current step is a <b> inside aria-current=page; plain keeps the span" do
    canvas =
      render(~H"""
      <.breadcrumb>
        <:item navigate="/">Home</:item>
        <:item>Now</:item>
      </.breadcrumb>
      """)

    assert texts(canvas, "[aria-current=page] > b") == ["Now"]
    assert [] = find(canvas, "li > a b") |> Enum.to_list()

    plain =
      render(~H"""
      <.breadcrumb variant="plain">
        <:item>Now</:item>
      </.breadcrumb>
      """)

    assert [] = find(plain, "b") |> Enum.to_list()
    assert texts(plain, "[aria-current=page] > span") == ["Now"]
  end

  defp texts(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))
end
