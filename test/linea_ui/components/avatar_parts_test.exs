defmodule LineaUI.Components.AvatarPartsTest do
  use LineaUI.ComponentCase, async: true

  test "frame, picture, indicator and status compose" do
    html =
      render(~H"""
      <.avatar_frame id="f" class="size-9">
        <.avatar_picture id="p"><img alt="x" src="/x.png" /></.avatar_picture>
        <.avatar_indicator class="-end-2 -bottom-2">
          <.avatar_status id="s" status="busy" class="size-2.5" />
        </.avatar_indicator>
      </.avatar_frame>
      """)

    assert "size-9" in classes(html, "#f")
    refute "size-10" in classes(html, "#f")
    assert "rounded-full" in classes(html, "#p")
    assert "bg-yellow-600" in classes(html, "#s")
    assert [_] = find(html, "#f #p img") |> Enum.to_list()
  end
end
