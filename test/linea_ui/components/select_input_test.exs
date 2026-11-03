defmodule LineaUI.Components.SelectInputTest do
  use LineaUI.ComponentCase, async: true

  test "a native select that keeps the attribute Metronic's script reads" do
    html =
      render(~H"""
      <.select_input id="s" name="period" class="w-36" data-kt-select-placeholder="Pick">
        <option value="1">1 month</option>
      </.select_input>
      """)

    assert [_] = find(html, "select#s[data-kt-select=true][name=period]") |> Enum.to_list()
    assert "w-36" in classes(html, "#s")
    assert [_] = find(html, "#s option[value='1']") |> Enum.to_list()
  end
end
