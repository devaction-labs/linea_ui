defmodule LineaUI.Components.ClipboardTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "a primary copy button with LineOne's toasts" do
    html = render(~H|<.clipboard id="c" value="secret" />|)

    assert attr_of(html, "#c", "phx-hook") == ["LineaUI.Clipboard"]
    assert attr_of(html, "#c", "data-value") == ["secret"]
    assert attr_of(html, "#c", "data-toast") == ["Text Copied"]
    assert attr_of(html, "#c", "data-error-toast") == ["Error"]
    assert "accent" in classes(html, "#c")
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
    assert "sm" in classes(html, "#c")
    assert String.trim(find(html, "#c") |> LazyHTML.text()) == "Grab"
    assert attr_of(html, "#c", "data-on-copy") |> hd() =~ "copied"
  end

  test "copied_label swaps the text while data-copied is set" do
    html = render(~H|<.clipboard id="c" value="x" copied_label="Copied">Copy</.clipboard>|)

    assert "group/clip" in classes(html, "#c")
    assert find(html, "#c span[aria-live=polite]") |> LazyHTML.text() |> String.trim() == "Copied"

    assert find(html, "#c span.group-data-copied\\/clip\\:hidden")
           |> LazyHTML.text()
           |> String.trim() == "Copy"

    plain = render(~H|<.clipboard id="c" value="x" />|)
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

  test "icon_only is the round canvas icon button" do
    html = render(~H|<.clipboard id="c" from="#cmd" icon_only aria-label="Copy command" />|)

    assert attr_of(html, "#c", "aria-label") == ["Copy command"]
    assert "sg-ib" in classes(html, "#c")
    refute "sg-btn" in classes(html, "#c")
    refute LazyHTML.text(find(html, "#c")) =~ "Copy"

    small = render(~H|<.clipboard id="c" value="x" icon_only size="sm" variant="flat" />|)
    assert "sm" in classes(small, "#c")
    assert "plain" in classes(small, "#c")
  end

  test "copied starts the button in its copied state" do
    html =
      render(~H|<.clipboard id="c" value="x" copied copied_label="Copiado">Copiar</.clipboard>|)

    assert attr_of(html, "#c", "data-copied") == [""]
    assert attr_of(render(~H|<.clipboard id="c" value="x" />|), "#c", "data-copied") == []
  end

  test "locale pt_BR translates the default toasts and label; an explicit toast wins" do
    html = render(~H|<.clipboard id="c" value="x" locale="pt_BR" />|)
    assert attr_of(html, "#c", "data-toast") == ["Texto copiado"]
    assert attr_of(html, "#c", "data-error-toast") == ["Erro ao copiar"]
    assert String.trim(find(html, "#c") |> LazyHTML.text()) == "Copiar"

    own = render(~H|<.clipboard id="c" value="x" locale="pt_BR" toast="Chave copiada" />|)
    assert attr_of(own, "#c", "data-toast") == ["Chave copiada"]

    input = render(~H|<.clipboard_input id="share" value="x" locale="pt_BR" />|)
    assert attr_of(input, "#share-copy", "data-toast") == ["Texto copiado"]
    assert find(input, "#share-copy") |> LazyHTML.text() |> String.trim() == "Copiar"
  end

  test "clipboard_input takes the copied label" do
    html = render(~H|<.clipboard_input id="share" value="x" copied_label="Copied" icon />|)

    assert find(html, "#share-copy span[aria-live=polite]") |> LazyHTML.text() =~ "Copied"
  end
end
