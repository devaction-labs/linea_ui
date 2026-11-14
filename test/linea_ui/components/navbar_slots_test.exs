defmodule LineaUI.Components.NavbarSlotsTest do
  use LineaUI.ComponentCase, async: true

  import LineaUI.Components.Navbar

  defp own_search(assigns) do
    ~H"""
    <button id="palette" type="button">⌘K</button>
    """
  end

  defp own_bell(assigns) do
    ~H"""
    <div id="bell">bell</div>
    """
  end

  test "own components fill the center and end slots in place of the pieces, in the same wrapper" do
    html =
      render(~H"""
      <.navbar>
        <:center><.own_search /></:center>
        <:end><.own_bell /></:end>
      </.navbar>
      """)

    assert ["sg-nb"] == classes(html, "header")
    assert [_] = Enum.to_list(find(html, "header > #palette"))
    assert [_] = Enum.to_list(find(html, "header > .sg-nb-end > #bell"))
  end
end
