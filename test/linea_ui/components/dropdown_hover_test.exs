defmodule LineaUI.Components.DropdownHoverTest do
  use LineaUI.ComponentCase, async: true

  test "hover is off unless asked and then the hook finds it on the wrapper" do
    off = render(~H|<.dropdown id="a" label="A">
  <.dropdown_item>x</.dropdown_item>
</.dropdown>|)
    on = render(~H|<.dropdown id="b" label="B" hover>
  <.dropdown_item>x</.dropdown_item>
</.dropdown>|)

    assert [_] = find(off, "#a[data-hover=false]") |> Enum.to_list()
    assert [_] = find(on, "#b[data-hover=true]") |> Enum.to_list()
  end
end
