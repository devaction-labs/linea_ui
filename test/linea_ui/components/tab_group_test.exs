defmodule LineaUI.Components.TabGroupTest do
  use LineaUI.ComponentCase, async: true

  test "carries the attribute Metronic's script reads and the layout classes" do
    html =
      render(~H"""
      <.tab_group id="g" class="kt-toggle-group flex gap-2"><span>x</span></.tab_group>
      """)

    assert [_] = find(html, "#g[data-kt-tabs=true]") |> Enum.to_list()
    assert "kt-toggle-group" in classes(html, "#g")
    assert [_] = find(html, "#g span") |> Enum.to_list()
  end
end
