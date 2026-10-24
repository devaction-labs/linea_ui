defmodule LineaUI.Components.FabTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp fab_html(attrs),
    do: Phoenix.LiveViewTest.render_component(&fab/1, Enum.into(attrs, %{id: "f", label: "Go"}))

  test "a named slot with no text around it keeps the label visible" do
    html =
      render(~H"""
      <.fab id="ask" label="Ask the assistant">
        <:icon><span id="own-icon">i</span></:icon>
      </.fab>
      """)

    assert find(html, "#ask #own-icon") |> Enum.count() == 1

    assert String.trim(find(html, "#ask .linea-fab-label") |> LazyHTML.text()) ==
             "Ask the assistant"
  end

  test "text inside replaces the visible label and keeps the aria-label" do
    html = render(~H|<.fab id="ask" label="Ask the assistant">Perguntar</.fab>|)

    assert String.trim(find(html, "#ask .linea-fab-label") |> LazyHTML.text()) == "Perguntar"
    assert attr_of(html, "#ask", "aria-label") == ["Ask the assistant"]
  end

  test "a button labelled for assistive tech, bubble at rest, with the sparkle" do
    html = render(~H|<.fab id="ask" label="Ask the assistant" phx-click="open" />|)

    assert attr_of(html, "button#ask", "aria-label") == ["Ask the assistant"]
    assert attr_of(html, "#ask", "type") == ["button"]
    assert attr_of(html, "#ask", "phx-click") == ["open"]
    assert attr_of(html, "#ask", "data-retract") == ["hover"]
    assert attr_of(html, "#ask", "data-state") == ["collapsed"]
    assert attr_of(html, "#ask", "phx-hook") == []
    assert attr_of(html, "#ask", "title") == []
    assert find(html, "#ask svg path") |> Enum.count() == 1

    assert String.trim(find(html, "#ask .linea-fab-label") |> LazyHTML.text()) ==
             "Ask the assistant"

    assert "bg-navy-900" in classes(html, "#ask")
    assert "bottom-right" not in classes(html, "#ask")
    assert "bottom-6" in classes(html, "#ask")
    assert "right-6" in classes(html, "#ask")
    assert "z-(--linea-z-fab)" in classes(html, "#ask")
  end

  test "retract modes set the data attributes and the starting shape" do
    for {mode, state} <- [
          {"hover", "collapsed"},
          {"auto", "expanded"},
          {"never", "expanded"},
          {"always", "collapsed"}
        ] do
      html = fab_html(retract: mode)
      assert attr_of(html, "#f", "data-retract") == [mode]
      assert attr_of(html, "#f", "data-state") == [state]
    end
  end

  test "auto takes the hook, the delay and keeps data-state client-owned" do
    html = render(~H|<.fab id="f" label="Go" retract="auto" retract_after={6000} />|)

    assert attr_of(html, "#f", "phx-hook") == ["LineaUI.Fab"]
    assert attr_of(html, "#f", "data-retract-after") == ["6000"]
    assert attr_of(html, "#f", "phx-mounted") |> hd() =~ "data-state"
  end

  test "the delay defaults to 4000 ms" do
    html = render(~H|<.fab id="f" label="Go" retract="auto" />|)
    assert attr_of(html, "#f", "data-retract-after") == ["4000"]
  end

  test "the other modes need no hook" do
    for mode <- ~w(hover never always) do
      html = fab_html(retract: mode)
      assert attr_of(html, "#f", "phx-hook") == []
    end
  end

  test "always shows the label as the native tooltip" do
    html = render(~H|<.fab id="f" label="Chat with us" retract="always" />|)
    assert attr_of(html, "#f", "title") == ["Chat with us"]
    assert attr_of(html, "#f", "aria-label") == ["Chat with us"]
  end

  test "expanded forces the pill open and drops the hook" do
    html = render(~H|<.fab id="f" label="Go" expanded />|)
    assert attr_of(html, "#f", "data-state") == ["expanded"]

    html = render(~H|<.fab id="f" label="Go" retract="auto" expanded />|)
    assert attr_of(html, "#f", "data-state") == ["expanded"]
    assert attr_of(html, "#f", "phx-hook") == []
  end

  test "positions" do
    for {position, expected} <- [
          {"bottom-left", ["bottom-6", "left-6"]},
          {"top-right", ["top-6", "right-6"]},
          {"top-left", ["top-6", "left-6"]}
        ] do
      html = fab_html(position: position)
      assert Enum.all?(expected, &(&1 in classes(html, "#f")))
    end
  end

  test "class overrides the offset" do
    html = render(~H|<.fab id="f" label="Go" class="bottom-24" />|)
    assert "bottom-24" in classes(html, "#f")
    assert "bottom-6" not in classes(html, "#f")
  end

  test "colors and sizes" do
    assert "bg-primary" in classes(render(~H|<.fab id="f" label="Go" color="primary" />|), "#f")
    assert "bg-white" in classes(render(~H|<.fab id="f" label="Go" color="light" />|), "#f")

    html = render(~H|<.fab id="f" label="Go" />|)
    assert "from-primary" in classes(html, "#f > span")
    assert "size-10" in classes(html, "#f > span")

    html = render(~H|<.fab id="f" label="Go" size="lg" />|)
    assert "size-12" in classes(html, "#f > span")
  end

  test "a link with navigate, href or patch" do
    html = render(~H|<.fab id="f" label="Help" navigate="/help" />|)
    assert attr_of(html, "a#f", "href") == ["/help"]
    assert attr_of(html, "a#f", "aria-label") == ["Help"]
    assert find(html, "button") |> Enum.count() == 0

    assert attr_of(render(~H|<.fab id="f" label="Help" href="/x" />|), "a#f", "href") == ["/x"]

    assert attr_of(render(~H|<.fab id="f" label="Help" patch="/y" />|), "a#f", "data-phx-link") ==
             ["patch"]
  end

  test "disabled" do
    html = render(~H|<.fab id="f" label="Go" disabled />|)
    assert attr_of(html, "button#f", "disabled") == [""]

    html = render(~H|<.fab id="f" label="Go" disabled navigate="/x" />|)
    assert attr_of(html, "a#f", "aria-disabled") == ["true"]
    assert attr_of(html, "a#f", "tabindex") == ["-1"]
  end

  test "badge, icon slot and label override" do
    html =
      render(~H"""
      <.fab id="f" label="Messages" badge={3}>
        <:icon><i class="glyph"></i></:icon>
        Chat
      </.fab>
      """)

    assert find(html, "#f .glyph") |> Enum.count() == 1
    assert find(html, "#f svg") |> Enum.count() == 0
    assert String.trim(find(html, "#f .bg-error") |> LazyHTML.text()) == "3"
    assert String.trim(find(html, "#f .linea-fab-label") |> LazyHTML.text()) == "Chat"
    assert attr_of(html, "#f", "aria-label") == ["Messages"]
  end

  test "no badge by default" do
    html = render(~H|<.fab id="f" label="Go" />|)
    assert find(html, "#f .bg-error") |> Enum.count() == 0
  end
end
