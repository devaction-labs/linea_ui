defmodule LineaUI.Components.ActionMenuTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp menu(assigns) do
    ~H"""
    <.action_menu id="am" label="Actions of Teste MCP" class="w-64">
      <:title>Teste MCP</:title>
      <.action_menu_item href="/c/1" icon="huge-view" kbd="↵">Open</.action_menu_item>
      <.action_menu_item phx-click="members" icon="huge-user-multiple">Members</.action_menu_item>
      <.action_menu_separator />
      <.action_menu_item phx-click="invite" icon="huge-mail-01" disabled hint="Invite accepted">
        Resend
      </.action_menu_item>
      <.action_menu_item phx-click="delete" icon="huge-delete-02" danger>Delete</.action_menu_item>
    </.action_menu>
    """
  end

  test "the button, the popper panel and the Dropdown machinery" do
    html = render(~H"<.menu />")

    assert attr_of(html, "#am", "phx-hook") == ["LineaUI.ActionMenu"]
    assert attr_of(html, "#am", "data-placement") == ["bottom-end"]
    assert attr_of(html, "#am", "data-popup") == ["menu"]
    assert attr_of(html, "#am-button", "aria-label") == ["Actions of Teste MCP"]
    assert attr_of(html, "#am-button", "type") == ["button"]
    assert [_] = find(html, "#am-button .huge-more-horizontal") |> Enum.to_list()
    assert [_] = find(html, "#am [data-trigger]") |> Enum.to_list()
    assert attr_of(html, "#am-menu", "popover") == ["manual"]
    assert "popper-root" in classes(html, "#am-menu")
    assert attr_of(html, "#am-menu [role=menu]", "aria-labelledby") == ["am-button"]
    assert "linea-am" in classes(html, "#am-menu [role=menu]")
    assert "w-64" in classes(html, "#am-menu [role=menu]")
  end

  test "title, links, buttons, separator, shortcut and hint" do
    html = render(~H"<.menu />")

    assert find(html, ".linea-am-h") |> LazyHTML.text() =~ "Teste MCP"
    assert [_] = find(html, "a[role=menuitem][href='/c/1']") |> Enum.to_list()
    assert [_, _, _] = find(html, "button[role=menuitem][phx-click]") |> Enum.to_list()
    assert [_] = find(html, "[role=separator]") |> Enum.to_list()
    assert find(html, "a .linea-am-kbd") |> LazyHTML.text() == "↵"
    assert find(html, "[disabled] .linea-am-hint") |> LazyHTML.text() == "Invite accepted"
    assert [_] = find(html, "[data-danger]") |> Enum.to_list()
  end

  test "a disabled item is disabled and aria-disabled, and the others are not" do
    html = render(~H"<.menu />")

    assert [_] =
             find(html, "button[role=menuitem][disabled][aria-disabled=true]") |> Enum.to_list()

    assert [_] = find(html, "[aria-disabled=true]") |> Enum.to_list()
    assert [_, _, _, _] = find(html, "[role=menuitem][tabindex='-1']") |> Enum.to_list()
  end

  test "without a title there is no header" do
    html =
      render(~H"""
      <.action_menu id="am" label="Actions">
        <.action_menu_item phx-click="x">One</.action_menu_item>
      </.action_menu>
      """)

    assert [] = find(html, ".linea-am-h") |> Enum.to_list()
  end
end
