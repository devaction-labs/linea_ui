defmodule LineaUI.Components.BoxTest do
  use LineaUI.ComponentCase, async: true

  test "a box is a bordered 12px box with its header, body and footer" do
    html =
      render(~H"""
      <.box id="p">
        <.box_header>
          <.box_title>Teams</.box_title>
          <.box_toolbar><button>Add</button></.box_toolbar>
        </.box_header>
        <.box_body>Body</.box_body>
        <.box_footer>Foot</.box_footer>
      </.box>
      """)

    assert "rounded-xl" in classes(html, "#p")
    assert "border" in classes(html, "#p")
    assert "min-h-14" in classes(html, ".box-header")
    assert [_] = find(html, ".box-header h3") |> Enum.to_list()
    assert "p-5" in classes(html, "#p > div:nth-child(2)")
    assert "border-t" in classes(html, ".box-footer")
  end

  test "accent is the muted tray, and class and attributes reach the parts" do
    html =
      render(~H"""
      <.box id="a" accent class="w-96" data-x="1">
        <.box_table class="t">Rows</.box_table>
      </.box>
      """)

    assert "bg-slate-100" in classes(html, "#a")
    assert "w-96" in classes(html, "#a")
    assert [_] = find(html, "#a[data-x='1']") |> Enum.to_list()
    assert "grid" in classes(html, ".box-table")
    assert "t" in classes(html, ".box-table")
  end

  test "grid takes the padding off the body and the border off its table" do
    html = render(~H|<.box id="g" grid>
  <.box_body>Rows</.box_body>
</.box>|)

    assert "[&_.box-body]:p-0" in classes(html, "#g")
    assert "box-body" in classes(html, "#g > div")
  end
end
