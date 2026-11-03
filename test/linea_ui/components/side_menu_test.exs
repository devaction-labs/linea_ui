defmodule LineaUI.Components.SideMenuTest do
  use LineaUI.ComponentCase, async: true

  defp texts(html, selector),
    do:
      html
      |> find(selector)
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

  test "the demo1 shell holds the sidebar, the header, the page and the footer, and starts expanded" do
    html =
      render(~H"""
      <.app_shell id="shell" layout="demo1">
        <:sidebar>
          <aside id="side">menu</aside>
        </:sidebar>
        <:header>
          <header id="top">top</header>
        </:header>
        <p id="page">page</p>
        <:footer>
          <footer id="foot">foot</footer>
        </:footer>
      </.app_shell>
      """)

    assert [_] = find(html, "#shell[data-collapsed=false][data-mobile=false]") |> Enum.to_list()
    assert "group/shell" in classes(html, "#shell")
    assert texts(html, "main #page") == ["page"]
    assert [_] = find(html, "#shell > div > #top") |> Enum.to_list()
    assert [_] = find(html, "#shell > div > #foot") |> Enum.to_list()
  end

  test "the sidebar button flips the collapsed attribute of the shell it names" do
    html =
      render(~H"""
      <.shell_sidebar shell="shell" label="Main menu" toggle_label="Collapse the menu">
        <:brand>Acme</:brand>
        <.side_menu_link href="/" active>Home</.side_menu_link>
      </.shell_sidebar>
      """)

    assert [_] =
             find(html, ~s(aside[aria-label="Main menu"][phx-hook="LineaUI.ShellSidebar"]))
             |> Enum.to_list()

    assert [_] = find(html, "button[data-shell-toggle]") |> Enum.to_list()
    assert [_] = find(html, "nav[data-shell-scroll]") |> Enum.to_list()

    assert [button] = find(html, ~s(button[aria-label="Collapse the menu"])) |> Enum.to_list()
    [click] = LazyHTML.attribute(button, "phx-click")
    assert click =~ "data-collapsed"
    assert click =~ "#shell"
    assert [_] = find(html, ~s(nav a[aria-current=page])) |> Enum.to_list()
  end

  test "a heading keeps its text for the menu and an ellipsis for the rail" do
    html =
      render(~H"""
      <.side_menu_heading>Account</.side_menu_heading>
      """)

    assert texts(html, "div > span:first-child") == ["Account"]
    assert texts(html, ~s(span[aria-hidden=true])) == ["···"]
  end

  test "a link is marked as the current page only when active, and shows its tag" do
    html =
      render(~H"""
      <.side_menu_link href="/a" active><:icon>i</:icon>Orders</.side_menu_link>
      <.side_menu_link href="/b" tag="Soon">Mail</.side_menu_link>
      """)

    assert [_] = find(html, "a[aria-current=page]") |> Enum.to_list()
    assert texts(html, "a[href='/a'] span:nth-child(2)") == ["Orders"]
    assert texts(html, "a[href='/b'] span:last-child") == ["Soon"]
  end

  test "a group is a details that opens on the current branch, with its sub-items" do
    html =
      render(~H"""
      <.side_menu_group label="Account" open>
        <:icon>i</:icon>
        <.side_menu_sublink href="/profile" active>Profile</.side_menu_sublink>
        <.side_menu_sublink href="/team">Team</.side_menu_sublink>
      </.side_menu_group>
      <.side_menu_group label="Closed">
        <.side_menu_sublink href="/x">X</.side_menu_sublink>
      </.side_menu_group>
      """)

    assert [_] = find(html, "details[open]") |> Enum.to_list()
    assert [_, _] = find(html, "details") |> Enum.to_list()
    assert texts(html, "details[open] summary") == ["i Account"]
    assert [_] = find(html, "details[open] a[aria-current=page]") |> Enum.to_list()
    assert "text-primary" in classes(html, "a[aria-current=page] span:last-child")
  end

  test "the header carries the navigation, the actions and the hamburger that opens the shell" do
    html =
      render(~H"""
      <.shell_header shell="shell" menu_label="Open the menu">
        <:nav><.shell_header_link href="/" active>Home</.shell_header_link></:nav>
        <:actions><button id="bell">b</button></:actions>
      </.shell_header>
      """)

    assert [_] = find(html, "header nav a[aria-current=page]") |> Enum.to_list()
    assert [_] = find(html, "header #bell") |> Enum.to_list()
    assert [button] = find(html, ~s(button[aria-label="Open the menu"])) |> Enum.to_list()
    [click] = LazyHTML.attribute(button, "phx-click")
    assert click =~ "data-mobile"
  end
end
