defmodule LineaUI.Components.ProgressTest do
  use LineaUI.ComponentCase, async: true

  test "the bar width follows value and max" do
    html =
      render(~H"""
      <.progress value={50} max={200} color="success" />
      """)

    assert [style] = html |> find("[role=progressbar] > div") |> LazyHTML.attribute("style")
    assert style =~ "width: 25.0%"
    assert "bg-success" in classes(html, "[role=progressbar] > div")
  end

  test "soft tints the track with every color" do
    html =
      render(~H"""
      <.progress id="primary" variant="soft" color="primary" />
      <.progress id="secondary" variant="soft" color="secondary" />
      <.progress id="info" variant="soft" color="info" />
      <.progress id="success" variant="soft" color="success" />
      <.progress id="warning" variant="soft" color="warning" />
      <.progress id="error" variant="soft" color="error" />
      <.progress id="solid" color="info" />
      """)

    for color <- ~w(primary secondary info success warning error) do
      assert "bg-#{color}/15" in classes(html, "##{color}")
    end

    assert "dark:bg-accent/25" in classes(html, "#primary")
    assert "dark:bg-secondary-light/25" in classes(html, "#secondary")
    assert "bg-slate-150" in classes(html, "#solid")
  end

  test "white is a white bar on a translucent track" do
    html =
      render(~H"""
      <.progress id="w" color="white" value={40} />
      """)

    assert "bg-white/30" in classes(html, "#w")
    assert "bg-white" in classes(html, "#w > div")
  end

  test "height wins over size, and the default is unchanged" do
    html =
      render(~H"""
      <.progress id="a" height="1.5" />
      <.progress id="b" size="lg" height="1" />
      <.progress id="c" />
      """)

    assert "h-1.5" in classes(html, "#a")
    refute "h-2" in classes(html, "#a")
    assert "h-1" in classes(html, "#b")
    refute "h-3" in classes(html, "#b")
    assert "h-2" in classes(html, "#c")
  end
end
