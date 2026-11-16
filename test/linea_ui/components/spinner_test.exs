defmodule LineaUI.Components.SpinnerTest do
  use LineaUI.ComponentCase, async: true

  test "the default spinner is daisyUI's loading-spinner" do
    html = render(~H"<.spinner />")
    assert ["loading", "loading-spinner", "loading-sm"] -- classes(html, "[role=status]") == []
  end

  test "size and color are daisyUI's size and the text color" do
    html = render(~H|<.spinner variant="canvas" size="xl" color="success" label="Carregando" />|)
    classes = classes(html, "[role=status]")
    assert "loading-xl" in classes
    assert "text-success" in classes
    assert html |> find("[role=status]") |> LazyHTML.attribute("aria-label") == ["Carregando"]
  end
end
