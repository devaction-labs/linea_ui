defmodule LineaUI.Components.TooltipTest do
  use LineaUI.ComponentCase, async: true

  test "wires the hook with the options, the hint and its arrow" do
    html =
      render(~H"""
      <.tooltip
        id="t"
        text="Hint"
        color="success"
        placement="left-end"
        trigger="click"
        delay={500}
        duration={200}
        follow_cursor="horizontal"
      >
        <button>?</button>
      </.tooltip>
      """)

    assert [root] = find(html, "div#t[phx-hook='LineaUI.Tooltip']") |> Enum.to_list()
    assert LazyHTML.attribute(root, "data-placement") == ["left-end"]
    assert LazyHTML.attribute(root, "data-trigger") == ["click"]
    assert LazyHTML.attribute(root, "data-delay") == ["500"]
    assert LazyHTML.attribute(root, "data-duration") == ["200"]
    assert LazyHTML.attribute(root, "data-follow-cursor") == ["horizontal"]
    assert LazyHTML.attribute(root, "data-interactive") == ["false"]
    assert [_] = find(html, "#t-tip[role=tooltip][hidden]") |> Enum.to_list()
    assert [_] = find(html, ".tippy-box[data-theme=success][data-state=hidden]") |> Enum.to_list()
    assert [_] = find(html, ".tippy-svg-arrow > svg") |> Enum.to_list()
    assert html |> find(".tippy-content") |> LazyHTML.text() == "Hint"
  end

  test "HTML content uses the content theme and is interactive" do
    html =
      render(~H"""
      <.tooltip id="t" arrow={false}>
        <button>?</button>
        <:content>
          <div id="card">Card</div>
        </:content>
      </.tooltip>
      """)

    assert [_] = find(html, ".tippy-box[data-theme=content] #card") |> Enum.to_list()
    assert [] = find(html, ".tippy-svg-arrow") |> Enum.to_list()
    assert find(html, "#t") |> LazyHTML.attribute("data-interactive") == ["true"]
  end

  test "neutral has no theme, open and callbacks reach the data attributes" do
    html =
      render(~H"""
      <.tooltip id="t" text="x" open on_open={Phoenix.LiveView.JS.push("opened")}>
        <button>?</button>
      </.tooltip>
      """)

    assert [] = find(html, ".tippy-box[data-theme]") |> Enum.to_list()
    assert find(html, "#t") |> LazyHTML.attribute("data-open") == ["true"]
    assert find(html, "#t") |> LazyHTML.attribute("data-on-open") |> hd() =~ "opened"
  end
end
