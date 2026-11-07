defmodule LineaUI.Components.StableIdTest do
  use LineaUI.ComponentCase, async: true

  defp ids(html, selector), do: html |> find(selector) |> LazyHTML.attribute("id")

  test "stable_id derives from the name, sanitized, and from a hash of label/placeholder otherwise" do
    import LineaUI.Component.Helpers, only: [stable_id: 2, stable_id: 3]

    assert stable_id("textarea", %{name: "post[body]"}) == "textarea-post_body_"

    assert stable_id("x", %{name: nil, label: "A", value: 1}) ==
             stable_id("x", %{label: "A", value: 2})

    refute stable_id("x", %{label: "A"}) == stable_id("x", %{label: "B"})

    assert stable_id("x", %{label: "A", other: 1}, [:label]) ==
             stable_id("x", %{label: "A"}, [:label])
  end

  test "a textarea with counter and a name keeps its id across renders" do
    a = render(~H|<.textarea name="post[body]" counter maxlength={80} value="a" />|)
    b = render(~H|<.textarea name="post[body]" counter maxlength={80} value="abc" />|)

    assert [id] = ids(a, "textarea")
    assert id =~ ~r/^[A-Za-z0-9_\-:.]+$/
    assert ids(b, "textarea") == [id]
  end

  test "a nameless textarea with counter keeps its id when only the value changes" do
    a = render(~H|<.textarea counter label="Bio" value="a" />|)
    b = render(~H|<.textarea counter label="Bio" value="abc" />|)

    assert [id] = ids(a, "textarea")
    assert id =~ "textarea-"
    assert ids(b, "textarea") == [id]
  end

  test "otp and number inputs without id keep theirs across renders" do
    a = render(~H|<.otp_input name="code" value="1" />|)
    b = render(~H|<.otp_input name="code" value="12" />|)
    assert ids(a, "[phx-hook='LineaUI.Otp']") == ids(b, "[phx-hook='LineaUI.Otp']")
    assert ids(a, "[phx-hook='LineaUI.Otp']") != []

    c = render(~H|<.otp_input label="Code" value="1" />|)
    d = render(~H|<.otp_input label="Code" value="12" />|)
    assert ids(c, "[phx-hook='LineaUI.Otp']") == ids(d, "[phx-hook='LineaUI.Otp']")

    e = render(~H|<.number_input name="qty" value={1} />|)
    f = render(~H|<.number_input name="qty" value={2} />|)
    assert ids(e, "input") == ids(f, "input")
    assert ids(e, "input") != []
  end
end
