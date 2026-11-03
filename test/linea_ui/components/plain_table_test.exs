defmodule LineaUI.Components.PlainTableTest do
  use LineaUI.ComponentCase, async: true

  test "renders a table with the plain class and its options" do
    html =
      render(~H"""
      <.table_plain id="t" border highlight class="mt-2">
        <tbody>
          <tr>
            <td>x</td>
          </tr>
        </tbody>
      </.table_plain>
      """)

    for c <- ~w(table-plain table-plain-border table-plain-highlight mt-2),
        do: assert(c in classes(html, "#t"))

    assert [_] = find(html, "#t td") |> Enum.to_list()
  end
end
