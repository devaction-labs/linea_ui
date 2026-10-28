defmodule LineaUI.Components.ClipboardTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "a primary copy button with LineOne's toasts" do
    html = render(~H|<.clipboard id="c" value="secret" />|)

    assert attr_of(html, "#c", "phx-hook") == ["LineaUI.Clipboard"]
    assert attr_of(html, "#c", "data-value") == ["secret"]
    assert attr_of(html, "#c", "data-toast") == ["Text Copied"]
    assert attr_of(html, "#c", "data-error-toast") == ["Error"]
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

    assert attr_of(html, "#c", "data-from") == ["#text"]
    assert attr_of(html, "#c", "data-toast") == []
    assert "h-6" in classes(html, "#c")
    assert String.trim(find(html, "#c") |> LazyHTML.text()) == "Grab"
    assert attr_of(html, "#c", "data-on-copy") |> hd() =~ "copied"
  end

  test "copied_label swaps the text and turns the button success green while data-copied is set" do
    html = render(~H|<.clipboard id="c" value="x" copied_label="Copied">Copy</.clipboard>|)

    assert "data-copied:bg-success" in classes(html, "#c")
    assert "group/clip" in classes(html, "#c")
    assert find(html, "#c span[aria-live=polite]") |> LazyHTML.text() |> String.trim() == "Copied"

    assert find(html, "#c span.group-data-copied\\/clip\\:hidden")
           |> LazyHTML.text()
           |> String.trim() == "Copy"

    plain = render(~H|<.clipboard id="c" value="x" />|)
    refute "data-copied:bg-success" in classes(plain, "#c")
    assert find(plain, "#c span") |> Enum.empty?()
  end

  test "clipboard_input joins a field and a button that copies it" do
    html = render(~H|<.clipboard_input id="share" name="url" value="https://x" />|)

    assert attr_of(html, "input#share", "name") == ["url"]
    assert attr_of(html, "input#share", "value") == ["https://x"]
    assert attr_of(html, "#share-copy", "data-from") == ["#share"]
    assert "rounded-l-none" in classes(html, "#share-copy")
  end

  test "icon adds the copy icon and the check that replaces it while copied" do
    html = render(~H|<.clipboard id="c" value="x" icon copied_label="Copied">Copy</.clipboard>|)

    assert find(html, "#c svg") |> Enum.count() == 2
    assert find(html, "#c span.group-data-copied\\/clip\\:inline") |> Enum.count() >= 1
  end

  test "icon_only is a square icon button that still turns green" do
    html = render(~H|<.clipboard id="c" from="#cmd" icon_only aria-label="Copy command" />|)

    assert attr_of(html, "#c", "aria-label") == ["Copy command"]
    assert "size-[2.375rem]" in classes(html, "#c")
    assert "data-copied:bg-success" in classes(html, "#c")
    refute LazyHTML.text(find(html, "#c")) =~ "Copy"
  end

  test "clipboard_input takes the copied label" do
    html = render(~H|<.clipboard_input id="share" value="x" copied_label="Copied" icon />|)

    assert find(html, "#share-copy span[aria-live=polite]") |> LazyHTML.text() =~ "Copied"
  end
end
