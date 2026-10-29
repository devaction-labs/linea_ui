defmodule LineaUI.Components.PaginationTest do
  use LineaUI.ComponentCase, async: true

  alias LineaUI.Components.Pagination

  defp count(html, selector), do: html |> find(selector) |> Enum.count()

  test "window keeps the ends and the pages around the current one" do
    assert Pagination.window(2, 5, 1, 1) == [1, 2, 3, 4, 5]
    assert Pagination.window(5, 10, 1, 1) == [1, :gap, 4, 5, 6, :gap, 10]
    assert Pagination.window(1, 10, 1, 1) == [1, 2, :gap, 10]
    assert Pagination.window(4, 10, 1, 1) == [1, 2, 3, 4, 5, :gap, 10]
    assert Pagination.window(1, 1, 1, 1) == [1]
  end

  test "patch links with the current page marked" do
    html =
      render(~H"""
      <.pagination page={2} total_pages={5} patch={&"/p?page=#{&1}"} />
      """)

    assert count(html, "nav[aria-label=Pagination] ol.pagination > li") == 7
    assert count(html, "a[data-phx-link=patch][href='/p?page=3']") == 2
    assert count(html, "a[aria-current=page][href='/p?page=2']") == 1
    assert "bg-primary" in classes(html, "a[aria-current=page]")
    assert count(html, "a[aria-label='Previous page'][href='/p?page=1']") == 1
    assert count(html, "a[aria-label='Next page'][href='/p?page=3']") == 1
    assert "rounded-l-lg" in classes(html, "li:first-child")
    assert "bg-slate-150" in classes(html, "li:first-child")
  end

  test "navigate and href links" do
    html = render(~H|<.pagination page={1} total_pages={3} navigate={&"/n/#{&1}"} />|)
    assert count(html, "a[data-phx-link=redirect][href='/n/2']") == 2

    html = render(~H|<.pagination page={1} total_pages={3} href={&"/h/#{&1}"} />|)
    assert count(html, "a[href='/h/3']") == 1
  end

  test "the first page disables the previous arrow" do
    html = render(~H|<.pagination page={1} total_pages={3} on_change="go" />|)
    assert count(html, "span[aria-label='Previous page'][aria-disabled=true]") == 1
    assert "opacity-60" in classes(html, "span[aria-label='Previous page']")
  end

  test "on_change buttons with a target, or JS" do
    html = render(~H|<.pagination page={1} total_pages={3} on_change="go" target="#x" />|)
    assert count(html, "button[phx-click=go][phx-value-page='2'][phx-target='#x']") == 2

    html =
      render(
        ~H|<.pagination page={1} total_pages={3} on_change={Phoenix.LiveView.JS.push("go")} />|
      )

    assert [click | _] =
             html |> find("button[phx-value-page='3']") |> LazyHTML.attribute("phx-click")

    assert click =~ "go"
  end

  test "pages are named for screen readers and the ellipsis is hidden" do
    html = render(~H|<.pagination page={5} total_pages={10} on_change="go" />|)

    assert count(html, "button[aria-label='Page 5'][aria-current=page]") == 1
    assert count(html, "span[aria-hidden=true]") == 2

    html =
      render(
        ~H|<.pagination page={2} total_pages={3} on_change="go" page_label="Página %{page}" />|
      )

    assert count(html, "button[aria-label='Página 3']") == 1
  end

  test "gaps, divided, pill and sizes" do
    html =
      render(
        ~H|<.pagination page={5} total_pages={10} on_change="go" divided shape="pill" size="lg" />|
      )

    assert html =~ "..."
    assert "space-x-1.5" in classes(html, "ol")
    assert classes(html, "li") == []
    assert "rounded-full" in classes(html, "button[phx-value-page='10']")
    assert "bg-slate-150" in classes(html, "button[phx-value-page='10']")
    assert "h-10" in classes(html, "button[phx-value-page='10']")
    assert "size-4.5" in classes(html, "svg")

    html =
      render(~H|<.pagination page={1} total_pages={2} on_change="go" size="sm" arrows={false} />|)

    assert "h-7" in classes(html, "button")
    assert count(html, "li") == 2
  end

  test "total_entries and page_size add the summary and work out the pages" do
    html =
      render(~H"""
      <.pagination
        id="p"
        page={2}
        page_size={15}
        total_entries={128}
        on_change="go"
        summary="Mostrando %{first}–%{last} de %{total}"
      />
      """)

    assert "Mostrando 16–30 de 128" =
             html |> find("[role=status]") |> LazyHTML.text() |> String.trim()

    assert [_] = html |> find("button[phx-value-page='9']") |> Enum.to_list()
    assert [] = html |> find("button[phx-value-page='10']") |> Enum.to_list()
    assert [] = html |> find("form") |> Enum.to_list()
    assert ["p"] = html |> find("nav") |> LazyHTML.attribute("id")

    html = render(~H|<.pagination page={9} page_size={15} total_entries={128} on_change="go" />|)

    assert "Showing 121–128 of 128" =
             html |> find("[role=status]") |> LazyHTML.text() |> String.trim()

    html = render(~H|<.pagination page={1} page_size={15} total_entries={0} on_change="go" />|)
    assert "Showing 0–0 of 0" = html |> find("[role=status]") |> LazyHTML.text() |> String.trim()

    html = render(~H|<.pagination page={1} total_pages={1} total_entries={4} on_change="go" />|)
    assert "Showing 1–4 of 4" = html |> find("[role=status]") |> LazyHTML.text() |> String.trim()
  end

  test "the numbers of the summary are bold and the words around them are escaped" do
    html =
      render(~H"""
      <.pagination
        page={1}
        page_size={15}
        total_entries={128}
        on_change="go"
        summary="<i>Mostrando</i> %{first}–%{last} de %{total}"
      />
      """)

    assert ["1", "15", "128"] =
             html
             |> find("[role=status] b")
             |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

    assert "[&_b]:font-semibold" in classes(html, "[role=status]")
    assert [] = html |> find("[role=status] i") |> Enum.to_list()
    assert html =~ "&lt;i&gt;Mostrando&lt;/i&gt;"
  end

  test "the labels are 12.5, 13.5 and 14.5px, the large one with 14px of padding" do
    html =
      render(~H"""
      <.pagination page={1} total_pages={3} on_change="go" size="sm" />
      <.pagination page={1} total_pages={3} on_change="go" />
      <.pagination page={1} total_pages={3} on_change="go" size="lg" />
      """)

    assert "text-[12.5px]" in classes(html, "button[phx-value-page='2'].h-7")
    assert "text-[13.5px]" in classes(html, "button[phx-value-page='2'].h-8")
    assert "text-[14.5px]" in classes(html, "button[phx-value-page='2'].h-10")
    assert "px-3.5" in classes(html, "button[phx-value-page='2'].h-10")
  end

  test "page_sizes add a rows-per-page select in its own form" do
    html =
      render(~H"""
      <.pagination
        id="p"
        page={1}
        page_size={30}
        total_entries={100}
        page_sizes={[15, 30, 50]}
        on_change="go"
        on_page_size="per_page"
        target="#c"
        page_size_label="%{size} / página"
        page_size_aria="Linhas por página"
        class="px-4"
      />
      """)

    assert ["p-page-size"] = html |> find("form") |> LazyHTML.attribute("id")
    assert ["per_page"] = html |> find("form") |> LazyHTML.attribute("phx-change")
    assert ["#c"] = html |> find("form") |> LazyHTML.attribute("phx-target")
    assert ["page_size"] = html |> find("select") |> LazyHTML.attribute("name")
    assert ["Linhas por página"] = html |> find("select") |> LazyHTML.attribute("aria-label")

    assert ["15 / página", "30 / página", "50 / página"] =
             html |> find("option") |> Enum.map(&String.trim(LazyHTML.text(&1)))

    assert ["30"] = html |> find("option[selected]") |> LazyHTML.attribute("value")
    assert "px-4" in classes(html, "div")

    html = render(~H|<.pagination page={1} total_pages={3} page_sizes={[10]} on_change="go" />|)
    assert [] = html |> find("[role=status]") |> Enum.to_list()
    assert [] = html |> find("form[id]") |> Enum.to_list()
  end

  test "without total_pages or entries there is a single page" do
    html = render(~H|<.pagination page={1} on_change="go" />|)
    assert [_] = html |> find("[aria-current=page]") |> Enum.to_list()
  end
end
