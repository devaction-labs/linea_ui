defmodule LineaUI.Components.ContainerTest do
  use LineaUI.ComponentCase, async: true

  test "the fixed container is centered and the fluid one is not" do
    html =
      render(~H"""
      <.container_fixed id="a" class="py-4">
        <p>x</p>
      </.container_fixed>
      <.container_fluid id="b">
        <p>y</p>
      </.container_fluid>
      """)

    assert "xl:mx-auto" in classes(html, "#a")
    assert "py-4" in classes(html, "#a")
    refute "xl:mx-auto" in classes(html, "#b")
    assert "px-6" in classes(html, "#b")
  end
end
