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
end
