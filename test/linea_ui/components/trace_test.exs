defmodule LineaUI.Components.TraceTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp texts(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

  test "a line: icon, title, description and status" do
    html =
      render(~H"""
      <.trace id="t">
        <.trace_line icon="huge-command-line" title="Ran pnpm --version" description="0.4s" />
        <.trace_line icon="huge-command-line" status="running">Running <code>pnpm build</code></.trace_line>
      </.trace>
      """)

    assert attr_of(html, "#t", "class") == ["linea-trace"]
    assert texts(html, "#t .linea-trace-title") == ["Ran pnpm --version", "Running pnpm build"]
    assert texts(html, "#t .linea-trace-desc") == ["0.4s"]
    assert attr_of(html, "#t .linea-trace-line", "data-status") == ["running"]
    assert find(html, "#t .linea-trace-icon") |> Enum.count() == 2
  end

  test "an error line shows the alert icon" do
    html = render(~H|<.trace_line icon="huge-command-line" status="error" title="Failed to run pnpm install" />|)

    assert attr_of(html, ".linea-trace-line", "data-status") == ["error"]
    assert html =~ "huge-alert-02"
    refute html =~ "huge-command-line"
  end

  test "a line with navigate is a link with its end icon" do
    html = render(~H|<.trace_line icon="huge-file-02" navigate="/docs" end_icon="huge-arrow-right-01" title="Read docs.ex" />|)

    assert attr_of(html, "a.linea-trace-line", "href") == ["/docs"]
    assert find(html, ".linea-trace-end") |> Enum.count() == 1
  end

  test "a step is a details element with the line as summary and the block under it" do
    html =
      render(~H"""
      <.trace_step id="s" icon="huge-command-line" title="Ran node --version" open>
        <pre class="linea-trace-code">v24.18.0</pre>
      </.trace_step>
      """)

    assert attr_of(html, "details#s", "open") == [""]
    assert texts(html, "#s summary .linea-trace-title") == ["Ran node --version"]
    assert find(html, "#s summary .linea-trace-chev") |> Enum.count() == 1
    assert texts(html, "#s .linea-trace-body") == ["v24.18.0"]
  end
end
