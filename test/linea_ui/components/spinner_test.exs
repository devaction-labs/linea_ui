defmodule LineaUI.Components.SpinnerTest do
  use LineaUI.ComponentCase, async: true

  test "the default spinner is LineOne's border ring" do
    html = render(~H"<.spinner />")
    assert "spinner" in classes(html, "[role=status]")
    refute "sg-spin" in classes(html, "[role=status]")
  end

  test "the canvas variant renders sg-spin with its size and tone" do
    html = render(~H|<.spinner variant="canvas" size="xl" color="success" label="Carregando" />|)
    classes = classes(html, "[role=status]")
    assert "sg-spin" in classes
    assert "xl" in classes
    assert "pos" in classes
    assert html |> find("[role=status]") |> LazyHTML.attribute("aria-label") == ["Carregando"]
  end
end
