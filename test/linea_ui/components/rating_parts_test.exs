defmodule LineaUI.Components.RatingPartsTest do
  use LineaUI.ComponentCase, async: true

  test "a cell is on only when asked" do
    html =
      render(~H"""
      <.rating_row id="r">
        <.rating_cell id="a" on><span>x</span></.rating_cell>
        <.rating_cell id="b"><span>y</span></.rating_cell>
      </.rating_row>
      """)

    assert [_] = find(html, "#r #a[data-on]") |> Enum.to_list()
    assert [] = find(html, "#b[data-on]") |> Enum.to_list()
  end
end
