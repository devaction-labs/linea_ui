defmodule LineaUI.Components.CommandPaletteTest do
  use LineaUI.ComponentCase, async: true

  alias Phoenix.LiveView.JS

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp texts(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

  defp items do
    [
      %{
        group: "Go to",
        scope: "pages",
        label: "Orders",
        sub: "Sales",
        icon: "huge-search-01",
        keys: ["G", "O"]
      },
      %{
        group: "Go to",
        scope: "pages",
        label: "Customers",
        navigate: "/customers",
        keywords: "clients"
      },
      %{
        group: "Actions",
        scope: "actions",
        label: "New order",
        value: "new-order",
        href: "https://example.com"
      },
      %{label: "Help"}
    ]
  end

  test "a modal dialog labelled for assistive tech, with the hook inside it" do
    html = render(~H|<.command_palette id="palette" label="Search" items={items()} />|)

    assert attr_of(html, "#palette", "phx-hook") == ["LineaUI.Dialog"]
    assert attr_of(html, "#palette", "data-open") == ["false"]
    assert attr_of(html, "#palette", "aria-label") == ["Search"]
    assert attr_of(html, "#palette-palette", "phx-hook") == ["LineaUI.CommandPalette"]
    assert attr_of(html, "#palette-palette", "data-shortcut") == ["Mod+k"]
    assert "max-w-160" in classes(html, "#palette-panel")
  end

  test "the input is a combobox controlling the listbox" do
    html = render(~H|<.command_palette id="palette" items={items()} placeholder="Find" />|)

    assert attr_of(html, "input[role=combobox]", "aria-controls") == ["palette-list"]
    assert attr_of(html, "input[role=combobox]", "aria-expanded") == ["false"]
    assert attr_of(html, "input[role=combobox]", "aria-autocomplete") == ["list"]
    assert attr_of(html, "input[role=combobox]", "placeholder") == ["Find"]
    assert attr_of(html, "input[role=combobox]", "autofocus") == [""]
    assert [_] = find(html, "#palette-list[role=listbox]") |> Enum.to_list()
  end

  test "the scope chips are toggle buttons carrying their scope" do
    html =
      render(~H"""
      <.command_palette id="palette" scopes={[{"All", "all"}, {"Pages", "pages"}]} scopes_label="Where" />
      """)

    assert attr_of(html, "[role=group][aria-label=Where]", "aria-label") == ["Where"]
    assert attr_of(html, "button[data-scope-chip]", "data-scope") == ["all", "pages"]
    assert attr_of(html, "button[data-scope-chip]", "aria-pressed") == ["false", "false"]

    assert texts(html, "button[data-scope-chip]") == ["All", "Pages"]
  end

  test "without scopes there are no chips" do
    html = render(~H|<.command_palette id="palette" />|)
    assert find(html, "[data-scope-chip]") |> Enum.count() == 0
  end

  test "items are options grouped under headings, with their scope and searchable text" do
    html = render(~H|<.command_palette id="palette" items={items()} />|)

    assert find(html, "[role=option][data-item]") |> Enum.count() == 4
    assert attr_of(html, "[data-item]", "data-scope") == ["pages", "pages", "actions", ""]

    assert attr_of(html, "[data-item]", "data-text") ==
             ["Orders Sales", "Customers clients", "New order", "Help"]

    assert attr_of(html, "[data-item]", "data-value") == [
             "Orders",
             "Customers",
             "new-order",
             "Help"
           ]

    assert attr_of(html, "[data-item]", "id") ==
             ~w(palette-item-0 palette-item-1 palette-item-2 palette-item-3)

    assert attr_of(html, "[data-item]", "aria-selected") == ["false", "false", "false", "false"]

    assert html
           |> find("[data-group] > div[id]")
           |> Enum.map(&LazyHTML.text/1)
           |> Enum.map(&String.trim/1) == ["Go to", "Actions"]

    assert attr_of(html, "[data-group]", "aria-labelledby") == [
             "palette-group-0",
             "palette-group-1"
           ]

    assert attr_of(html, "[data-group] > div[id]", "id") == ["palette-group-0", "palette-group-1"]
  end

  test "an item without a group is listed without a heading" do
    html = render(~H|<.command_palette id="palette" items={[%{label: "Help"}]} />|)
    assert find(html, "[data-group]") |> Enum.count() == 1
    assert find(html, "[data-group] > div[id]") |> Enum.count() == 0
    assert attr_of(html, "[data-group]", "role") == []
  end

  test "an item with an address is a link, any other item a button" do
    html = render(~H|<.command_palette id="palette" items={items()} />|)

    assert attr_of(html, "a[data-item]", "href") == ["/customers", "https://example.com"]
    assert attr_of(html, "a[data-item]", "role") == ["option", "option"]
    assert attr_of(html, "button[data-item]", "type") == ["button", "button"]
  end

  test "icons, subs and key hints are drawn" do
    html = render(~H|<.command_palette id="palette" items={items()} />|)

    assert [_] = find(html, "#palette-item-0 span.huge-search-01") |> Enum.to_list()

    assert html |> find("#palette-item-0 span.block") |> Enum.map(&LazyHTML.text/1) == [
             "Orders",
             "Sales"
           ]

    assert texts(html, "#palette-item-0 kbd") == ["G", "O"]
    assert find(html, "#palette-item-1 kbd") |> Enum.count() == 0
  end

  test "the assistant row is hidden until the hook shows it, and carries its template" do
    html =
      render(~H"""
      <.command_palette
        id="palette"
        assistant={%{label: "Ask: %{query}", sub: "Uses your data"}}
        assistant_mode="always"
      />
      """)

    assert attr_of(html, "[data-assistant]", "role") == ["option"]
    assert attr_of(html, "[data-assistant]", "data-template") == ["Ask: %{query}"]
    assert attr_of(html, "[data-assistant]", "hidden") == [""]
    assert attr_of(html, "#palette-palette", "data-assistant-mode") == ["always"]
    assert [_] = find(html, "[data-assistant] span.huge-ai-magic") |> Enum.to_list()
    assert html |> find("[data-assistant]") |> LazyHTML.text() =~ "Uses your data"
  end

  test "without an assistant there is no assistant row, and the empty message is hidden" do
    html = render(~H|<.command_palette id="palette" empty="Nada" />|)

    assert find(html, "[data-assistant]") |> Enum.count() == 0
    assert attr_of(html, "[data-empty]", "hidden") == [""]
    assert html |> find("[data-empty]") |> LazyHTML.text() |> String.trim() == "Nada"
  end

  test "events and the shortcut reach the hook as data attributes" do
    html =
      render(~H"""
      <.command_palette
        id="palette"
        on_select="picked"
        on_assistant={JS.push("ask")}
        on_search="search"
        debounce={50}
        shortcut={nil}
        target="#form"
      />
      """)

    assert attr_of(html, "#palette-palette", "data-on-search") == ["search"]
    assert attr_of(html, "#palette-palette", "data-debounce") == ["50"]
    assert attr_of(html, "#palette-palette", "phx-target") == ["#form"]
    assert attr_of(html, "#palette-palette", "data-shortcut") == []
    assert [select] = attr_of(html, "#palette-palette", "data-on-select")
    assert select =~ ~s("event":"picked") or select =~ "picked"
    assert select =~ "#form"
    assert [assistant] = attr_of(html, "#palette-palette", "data-on-assistant")
    assert assistant =~ "ask"
  end

  test "hints and the footer slot" do
    html =
      render(~H"""
      <.command_palette id="palette" hint_navigate="Mover" hint_open="Abrir" hint_new_tab="Nova aba">
        <:footer>Abrindo Pedidos</:footer>
      </.command_palette>
      """)

    text = html |> find("#palette-palette") |> LazyHTML.text()
    assert text =~ "Mover"
    assert text =~ "Abrir"
    assert text =~ "Nova aba"
    assert text =~ "Abrindo Pedidos"
    assert [_] = find(html, "[aria-live=polite]") |> Enum.to_list()
  end

  test "open and class go to the modal" do
    html = render(~H|<.command_palette id="palette" open class="shadow-2xl" />|)

    assert attr_of(html, "#palette", "data-open") == ["true"]
    assert "shadow-2xl" in classes(html, "#palette-panel")
  end
end
