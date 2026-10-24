defmodule LineaUI.Components.DrawerTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "a closed left drawer with its backdrop, wired to the dialog hook" do
    html = render(~H|<.drawer id="d">Menu</.drawer>|)

    assert attr_of(html, "#d", "phx-hook") == ["LineaUI.Dialog"]
    assert attr_of(html, "#d", "data-kind") == ["drawer"]
    assert attr_of(html, "#d", "data-lock") == ["false"]
    assert ["drawer-overlay", "hidden"] -- classes(html, "#d > [data-backdrop]") == []

    assert ["drawer-content", "hidden", "left-0", "w-72"] -- classes(html, "#d > div:last-child") ==
             []

    refute "drawer-right" in classes(html, "#d")
  end

  test "right side, no overlay, open, a frame class and a panel class" do
    html =
      render(
        ~H|<.drawer id="d" side="right" overlay={false} open class="w-80" panel_class="p-4">x</.drawer>|
      )

    assert "drawer-right" in classes(html, "#d")
    assert "right-0" in classes(html, "#d > div")
    assert find(html, "#d [data-backdrop]") |> Enum.to_list() == []
    assert attr_of(html, "#d", "data-open") == ["true"]
    frame = classes(html, ".drawer-content")
    assert "w-80" in frame
    refute "w-72" in frame
    assert "p-4" in classes(html, "#d-panel")
  end

  test "on_close with a target pushes to it" do
    html = render(~H|<.drawer id="d" on_close="closed" target="#comp">x</.drawer>|)
    assert attr_of(html, "#d", "data-on-close") |> hd() =~ ~s("target":"#comp")
  end

  test "a bare drawer has no header, body or footer of its own" do
    html = render(~H|<.drawer id="d">
  <nav id="nav">x</nav>
</.drawer>|)
    assert find(html, "#d [data-drawer-header], #d [data-drawer-body]") |> Enum.to_list() == []
    assert [_] = find(html, "#d-panel > #nav") |> Enum.to_list()
    refute attr_of(html, "#d", "aria-labelledby") |> List.first()
  end

  test "a sheet: title, description, close button, scrolling body and footer" do
    html =
      render(~H"""
      <.drawer id="s" placement="right" size="md" title="New customer" description="Who buys">
        <p id="body">Form</p>
        <:footer class="gap-3"><button id="save">Save</button></:footer>
      </.drawer>
      """)

    assert "drawer-right" in classes(html, "#s")

    assert ["right-3", "w-full", "max-w-[min(560px,calc(100%-1.5rem))]"] --
             classes(html, ".drawer-content") == []

    refute "w-72" in classes(html, ".drawer-content")
    assert attr_of(html, "#s", "aria-labelledby") == ["s-title"]
    assert find(html, "#s-title") |> LazyHTML.text() =~ "New customer"
    assert find(html, "[data-drawer-header] p") |> LazyHTML.text() =~ "Who buys"
    assert [close] = find(html, "[data-drawer-close]") |> Enum.to_list()
    assert LazyHTML.attribute(close, "aria-label") == ["Close"]
    assert LazyHTML.attribute(close, "phx-click") |> hd() =~ "linea:close"

    assert ["overflow-y-auto", "flex-1", "scrollbar-sm"] -- classes(html, "[data-drawer-body]") ==
             []

    assert [_] = find(html, "[data-drawer-body] > #body") |> Enum.to_list()

    assert ["justify-end", "border-t", "bg-slate-50", "gap-3"] --
             classes(html, "[data-drawer-footer]") == []

    assert [_] = find(html, "[data-drawer-footer] > #save") |> Enum.to_list()
  end

  test "a sheet floats by default: margins, rounded panel and the whole height" do
    html = render(~H|<.drawer id="s" title="T" size="lg">x</.drawer>|)

    assert attr_of(html, "#s", "data-variant") == ["float"]
    assert "drawer-float" in classes(html, "#s")

    assert ["top-3", "left-3", "h-[calc(100%-1.5rem)]", "max-w-[min(760px,calc(100%-1.5rem))]"] --
             classes(html, ".drawer-content") == []

    assert ["rounded-2xl", "overflow-hidden"] -- classes(html, "#s-panel") == []
  end

  test "flush keeps the panel against the edge" do
    html =
      render(
        ~H|<.drawer id="s" title="T" variant="flush" placement="right" size="md">x</.drawer>|
      )

    assert attr_of(html, "#s", "data-variant") == ["flush"]
    refute "drawer-float" in classes(html, "#s")

    assert ["top-0", "right-0", "h-full", "max-w-[560px]"] -- classes(html, ".drawer-content") ==
             []

    refute "rounded-2xl" in classes(html, "#s-panel")
  end

  test "bottom is a mobile sheet with a grab handle and 78% of the height" do
    html = render(~H|<.drawer id="s" title="T" placement="bottom">x</.drawer>|)

    assert "drawer-bottom" in classes(html, "#s")
    assert ["inset-x-3", "bottom-3", "h-[78dvh]"] -- classes(html, ".drawer-content") == []
    assert [_] = find(html, "#s-panel > [data-drawer-grab]") |> Enum.to_list()

    flush = render(~H|<.drawer id="f" title="T" placement="bottom" variant="flush">x</.drawer>|)
    assert ["inset-x-0", "bottom-0"] -- classes(flush, ".drawer-content") == []
    assert "rounded-t-2xl" in classes(flush, "#f-panel")
  end

  test "a bare drawer is a plain frame, but at the bottom it is flush, and a variant makes it a sheet" do
    plain = render(~H|<.drawer id="p">x</.drawer>|)
    assert attr_of(plain, "#p", "data-variant") == []
    assert find(plain, "[data-drawer-grab]") |> Enum.to_list() == []

    bare = render(~H|<.drawer id="b" placement="bottom">x</.drawer>|)
    assert attr_of(bare, "#b", "data-variant") == ["flush"]
    assert [_] = find(bare, "[data-drawer-grab]") |> Enum.to_list()

    html =
      render(~H"""
      <.drawer id="c" variant="float">
        <.sheet_header title="Edit" description="Since 2025" />
        <.sheet_body class="gap-2">
          <p id="x">Form</p>
        </.sheet_body>
        <.sheet_footer class="gap-3"><button id="ok">Save</button></.sheet_footer>
      </.drawer>
      """)

    assert "drawer-float" in classes(html, "#c")
    assert find(html, "[data-drawer-header] h2") |> LazyHTML.text() =~ "Edit"
    assert find(html, "[data-drawer-header] p") |> LazyHTML.text() =~ "Since 2025"
    assert "gap-2" in classes(html, "[data-drawer-body]")
    assert [_] = find(html, "[data-drawer-footer] > #ok") |> Enum.to_list()
    assert [_] = find(html, "#c-panel > [data-drawer-body] > #x") |> Enum.to_list()
  end

  test "the header's close closes the closest drawer, or the one it names" do
    html = render(~H|<.sheet_header title="T" />|)
    [click] = find(html, "[data-drawer-close]") |> LazyHTML.attribute("phx-click")
    assert click =~ "linea:close"
    assert click =~ "closest"

    named = render(~H|<.sheet_header title="T" drawer="edit" close_label="Fechar" />|)
    [click] = find(named, "[data-drawer-close]") |> LazyHTML.attribute("phx-click")
    assert click =~ "#edit"
    assert find(named, "[data-drawer-close]") |> LazyHTML.attribute("aria-label") == ["Fechar"]
  end

  test "each size sets the sheet's width" do
    for {size, width} <- [
          {"sm", "max-w-[400px]"},
          {"md", "max-w-[560px]"},
          {"lg", "max-w-[760px]"},
          {"xl", "max-w-[1080px]"}
        ] do
      assigns = %{size: size}

      html =
        Phoenix.LiveViewTest.rendered_to_string(~H|<.drawer id="d" size={@size}>x</.drawer>|)

      assert width in classes(html, ".drawer-content")
    end
  end

  test "placement wins over side" do
    html = render(~H|<.drawer id="d" side="right" placement="left">x</.drawer>|)
    refute "drawer-right" in classes(html, "#d")
    assert "left-0" in classes(html, ".drawer-content")
  end

  test "back, actions and a custom header; the close button can go" do
    html =
      render(~H"""
      <.drawer id="c" title="ignored" close_button={false}>
        <:back><button id="back">Back</button></:back>
        <:header class="pb-2"><span id="custom">Combine line</span></:header>
        <:actions><button id="approve">Approve</button></:actions>
        x
      </.drawer>
      """)

    assert [_] = find(html, "[data-drawer-header] > div > #back") |> Enum.to_list()
    assert [_] = find(html, "#c-title > #custom") |> Enum.to_list()
    refute LazyHTML.text(find(html, "[data-drawer-header]")) =~ "ignored"
    assert [_] = find(html, "[data-drawer-header] #approve") |> Enum.to_list()
    assert find(html, "[data-drawer-close]") |> Enum.to_list() == []
    assert "pb-2" in classes(html, "[data-drawer-header]")
  end

  test "lock_scroll locks the page, and the root keeps its layer through patches" do
    html = render(~H|<.drawer id="d" lock_scroll title="T">x</.drawer>|)
    assert attr_of(html, "#d", "data-lock") == ["true"]
    assert attr_of(html, "#d", "phx-mounted") |> hd() =~ "style"
  end

  test "the layers come from CSS, not from z utilities" do
    html = render(~H|<.drawer id="d">x</.drawer>|)
    refute Enum.any?(classes(html, ".drawer-overlay"), &String.starts_with?(&1, "z-"))
    refute Enum.any?(classes(html, ".drawer-content"), &String.starts_with?(&1, "z-"))
  end

  test "the open panel carries no transform, so a modal inside it covers the viewport" do
    html =
      render(~H"""
      <.drawer id="sheet" title="Order" open>
        <p>Body</p>
        <.modal id="confirm-delete">Sure?</.modal>
      </.drawer>
      """)

    panel = classes(html, "#sheet-panel")

    refute Enum.any?(
             panel,
             &(&1 =~ ~r/^(transform|translate|scale|rotate|filter|backdrop|will-change|contain)/)
           )

    assert [_] = find(html, "#sheet #confirm-delete[phx-hook='LineaUI.Dialog']") |> Enum.to_list()
  end
end
