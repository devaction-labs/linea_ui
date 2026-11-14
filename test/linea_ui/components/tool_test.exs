defmodule LineaUI.Components.ToolTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp texts(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

  test "a running call is a plain line with the running status and its verb" do
    html = render(~H|<.tool id="t" state="running" subject="pnpm install" />|)

    assert attr_of(html, "div.linea-trace-line", "data-status") == ["running"]
    assert texts(html, ".linea-trace-title") == ["Running pnpm install"]
    assert find(html, "details") |> Enum.count() == 0
  end

  test "a call with output opens on a small code block; an error tints it" do
    html = render(~H|<.tool id="t" state="error" subject="pnpm lint" output="1 error" open />|)

    assert attr_of(html, "details.linea-trace-step", "open") == [""]
    assert texts(html, "summary .linea-trace-title") == ["Failed to run pnpm lint"]
    assert attr_of(html, "#t-output", "data-size") == ["sm"]
    assert attr_of(html, "#t-output", "data-variant") == ["destructive"]
  end

  test "verbs, locale and title" do
    html =
      render(~H"""
      <.tool id="a" state="done" subject="docs.ex" verbs={%{done: "Read"}} />
      <.tool id="b" state="waiting" subject="ls" locale="pt_BR" />
      <.tool id="c" state="denied" title="Denied the deploy" />
      """)

    assert texts(html, ".linea-trace-title") == ["Read docs.ex", "Aguardando para rodar ls", "Denied the deploy"]
    assert attr_of(html, ".linea-trace-line", "data-status") == [nil, "pending", nil]
  end

  test "the approval card asks and sends both events with the value" do
    html =
      render(~H"""
      <.tool_approval id="ap" subject="rm -rf tmp" input="rm -rf tmp" on_approve="approve" on_deny="deny" value="call-1" />
      """)

    assert texts(html, "#ap-q") == ["Run rm -rf tmp?"]
    assert attr_of(html, "#ap button", "phx-click") == ["deny", "approve"]
    assert attr_of(html, "#ap button", "phx-value-value") == ["call-1", "call-1"]
    assert find(html, "#ap-input") |> Enum.count() == 1
  end
end
