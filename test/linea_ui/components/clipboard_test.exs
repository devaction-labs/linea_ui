defmodule LineaUI.Components.ClipboardTest do
  use LineaUI.ComponentCase, async: true

  defp attr(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "a primary copy button with LineOne's toasts" do
    html = render(~H|<.clipboard id="c" value="secret" />|)

    assert attr(html, "#c", "phx-hook") == ["LineaUI.Clipboard"]
    assert attr(html, "#c", "data-value") == ["secret"]
    assert attr(html, "#c", "data-toast") == ["Text Copied"]
    assert attr(html, "#c", "data-error-toast") == ["Error"]
    assert "bg-primary" in classes(html, "#c")
    assert String.trim(find(html, "#c") |> LazyHTML.text()) == "Copy"
  end

  test "from, a label of its own, button styling and on_copy" do
    html =
      render(~H"""
      <.clipboard id="c" from="#text" size="xs" color="neutral" toast={nil} on_copy="copied">
        Grab
      </.clipboard>
      """)

    assert attr(html, "#c", "data-from") == ["#text"]
    assert attr(html, "#c", "data-toast") == []
    assert "h-6" in classes(html, "#c")
    assert String.trim(find(html, "#c") |> LazyHTML.text()) == "Grab"
    assert attr(html, "#c", "data-on-copy") |> hd() =~ "copied"
  end

  test "clipboard_input joins a field and a button that copies it" do
    html = render(~H|<.clipboard_input id="share" name="url" value="https://x" />|)

    assert attr(html, "input#share", "name") == ["url"]
    assert attr(html, "input#share", "value") == ["https://x"]
    assert attr(html, "#share-copy", "data-from") == ["#share"]
    assert "rounded-l-none" in classes(html, "#share-copy")
  end
end
