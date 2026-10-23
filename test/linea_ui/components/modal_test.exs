defmodule LineaUI.Components.ModalTest do
  use LineaUI.ComponentCase, async: true

  defp attr(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "a closed, fading modal wired to the dialog hook" do
    html = render(~H|<.modal id="m">
  <p>Hi</p>
</.modal>|)

    assert attr(html, "#m", "phx-hook") == ["LineaUI.Dialog"]
    assert attr(html, "#m", "data-open") == ["false"]
    assert attr(html, "#m", "data-kind") == ["modal"]
    assert attr(html, "#m", "role") == ["dialog"]
    assert "modal" in classes(html, "#m")
    assert "max-w-lg" in classes(html, "#m-panel")
    assert [_] = find(html, "#m [data-backdrop]") |> Enum.to_list()
    assert [_] = find(html, "#m-panel button[aria-label=Close]") |> Enum.to_list()
  end

  test "animation, size, placement, origin, blur and class" do
    html =
      render(~H"""
      <.modal
        id="m"
        animation="scale"
        size="xl"
        placement="top"
        origin="bottom"
        blur
        class="pb-4"
        open
      >
        x
      </.modal>
      """)

    assert "modal-scale" in classes(html, "#m")
    assert "justify-start" in classes(html, "#m")
    assert ["max-w-2xl", "origin-bottom", "pb-4"] -- classes(html, "#m-panel") == []
    assert "backdrop-blur-sm" in classes(html, "#m [data-backdrop]")
    assert attr(html, "#m", "data-open") == ["true"]
  end

  test "the bar header carries the title and the close button; the footer and body follow" do
    html =
      render(~H"""
      <.modal id="m" body_class="p-0">
        <:header>Edit Pin</:header>
        Body
        <:footer class="text-center">Footer</:footer>
      </.modal>
      """)

    assert find(html, "#m-title") |> LazyHTML.text() =~ "Edit Pin"
    assert "bg-slate-200" in classes(html, "#m-panel > div:first-child")
    assert attr(html, "#m", "aria-labelledby") == ["m-title"]
    assert "p-0" in classes(html, "#m-panel > div:nth-child(2)")
    assert "text-center" in classes(html, "#m-panel > div:last-child")
    assert [close] = find(html, "#m-panel button") |> Enum.to_list()
    assert LazyHTML.attribute(close, "phx-click") |> hd() =~ "linea:close"
  end

  test "the plain header and no close button" do
    html =
      render(~H"""
      <.modal id="m" close_button={false}><:header variant="plain">Settings</:header>x</.modal>
      """)

    assert "h-8" in classes(html, "#m-panel > div:first-child")
    assert find(html, "#m button") |> Enum.to_list() == []
  end

  test "prevent_close and the callbacks: an event name pushes the id, a %JS{} runs as is" do
    html =
      render(~H"""
      <.modal id="m" prevent_close on_close="closed" on_open={JS.add_class("x", to: "body")}>x</.modal>
      """)

    assert attr(html, "#m", "data-prevent-close") == ["true"]
    assert [close] = attr(html, "#m", "data-on-close")
    assert close =~ ~s("event":"closed")
    assert close =~ ~s("id":"m")
    assert attr(html, "#m", "data-on-open") |> hd() =~ "add_class"
  end
end
