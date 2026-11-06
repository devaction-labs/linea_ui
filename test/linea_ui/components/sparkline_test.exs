defmodule LineaUI.Components.SparklineTest do
  use LineaUI.ComponentCase, async: true

  test "draws the line and its fill from the numbers, the highest at the top" do
    html = render(~H|<.sparkline id="s" values={[1, 3, 2]} />|)

    assert [_] = find(html, "svg.sg-spark") |> Enum.to_list()
    assert [_] = find(html, "linearGradient#s-fill") |> Enum.to_list()
    [line] = find(html, "path[stroke=currentColor]") |> Enum.to_list()
    assert LazyHTML.attribute(line, "d") == ["M0.0 30.0 L52.0 4.0 L104.0 17.0"]
  end

  test "primary paints it in the accent, the default in the ink" do
    assert [style] =
             render(~H|<.sparkline id="a" values={[1, 2]} color="primary" />|)
             |> find("svg")
             |> LazyHTML.attribute("style")

    assert style =~ "var(--accent)"

    assert [style] =
             render(~H|<.sparkline id="b" values={[1, 2]} />|)
             |> find("svg")
             |> LazyHTML.attribute("style")

    assert style =~ "var(--ink)"
  end

  test "fewer than two numbers draw nothing" do
    assert [] = render(~H|<.sparkline id="c" values={[1]} />|) |> find("svg") |> Enum.to_list()
  end
end
