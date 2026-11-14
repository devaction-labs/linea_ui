defmodule LineaUI.Components.CodeBlockTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)
  defp texts(html, selector), do: html |> find(selector) |> Enum.map(&LazyHTML.text/1)

  test "a code string becomes one line per row, with a header and a copy button" do
    html =
      render(~H"""
      <.code_block id="cb" title="Terminal" icon="huge-command-line" code={"$ node --version\nv24.18.0"} copy line_numbers wrap />
      """)

    assert texts(html, "#cb .linea-code-line") == ["$ node --version", "v24.18.0"]
    assert texts(html, "#cb .linea-code-name") == ["Terminal"]
    assert attr_of(html, "#cb-code", "data-numbers") == [""]
    assert attr_of(html, "#cb-code", "data-wrap") == [""]
    assert attr_of(html, "#cb-copy", "data-value") == ["$ node --version\nv24.18.0"]
    assert find(html, "#cb .linea-code-float") |> Enum.count() == 0
  end

  test "lines carry their variant and highlight marks lines by number" do
    html =
      render(~H"""
      <.code_block id="d" lines={["a", %{text: "b", variant: "removed"}, %{text: "c", variant: "added"}, "d"]} highlight={[4]} />
      """)

    assert attr_of(html, "#d .linea-code-line", "data-variant") == [nil, "removed", "added", "highlighted"]
    assert find(html, "#d .linea-code-h") |> Enum.count() == 0
  end

  test "copy without a header floats; start_line sets the counter and the gutter width" do
    html = render(~H|<.code_block id="f" code={"x\ny"} copy line_numbers start_line={99} />|)

    assert find(html, "#f .linea-code-float #f-copy") |> Enum.count() == 1
    [style] = attr_of(html, "#f-code", "style")
    assert style =~ "counter-reset:linea-line 98"
    assert style =~ "--linea-code-gutter:3ch"
  end

  test "size and variant are data attributes; a safe block is drawn as is" do
    html =
      render(~H"""
      <.code_block id="s" size="sm" variant="destructive">{Phoenix.HTML.raw("<span class=\"k\">def</span>")}</.code_block>
      """)

    assert attr_of(html, "#s", "data-size") == ["sm"]
    assert attr_of(html, "#s", "data-variant") == ["destructive"]
    assert find(html, "#s-code span.k") |> Enum.count() == 1
    assert find(html, "#s .linea-code-line") |> Enum.count() == 0
  end
end
