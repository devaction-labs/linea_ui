defmodule LineaUI.Components.ProgressPartsTest do
  use LineaUI.ComponentCase, async: true

  test "a track holds a fill whose width stays in the style" do
    html =
      render(~H"""
      <.progress_track id="t" color="success" class="w-36">
        <.progress_fill id="f" style="width: 80%" />
      </.progress_track>
      """)

    assert "w-36" in classes(html, "#t")
    assert "[&>.progress-fill]:bg-green-500" in classes(html, "#t")
    assert "progress-fill" in classes(html, "#f")
    assert [_] = find(html, "#f[style='width: 80%']") |> Enum.to_list()
  end
end
