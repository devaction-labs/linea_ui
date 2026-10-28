defmodule LineaUI.Components.TextareaTest do
  use LineaUI.ComponentCase, async: true

  test "a bare outlined textarea has the primary focus ring and a disabled look that keeps the border" do
    html = render(~H'<.textarea name="bio" placeholder="Enter Text" />')
    assert [_] = find(html, "textarea[name=bio][rows='4'][placeholder='Enter Text']") |> Enum.to_list()
    assert find(html, "label") |> Enum.to_list() == []

    classes = classes(html, "textarea")
    assert "focus:border-primary" in classes
    assert "focus:ring-3" in classes
    assert "disabled:opacity-60" in classes
    assert "disabled:bg-slate-150" in classes
    refute "disabled:border-none" in classes
    assert "resize-none" in classes
  end

  test "resizable drops resize-none and disabled sets the attribute" do
    html = render(~H'<.textarea name="bio" resizable disabled />')
    refute "resize-none" in classes(html, "textarea")
    assert [_] = find(html, "textarea[disabled]") |> Enum.to_list()
  end

  test "filled variant" do
    assert "bg-slate-150" in classes(render(~H'<.textarea name="b" variant="filled" />'), "textarea")
  end

  test "error and success paint the border and ring; error sets aria-invalid" do
    html = render(~H'<.textarea name="b" errors={["too short"]} />')
    assert "border-error" in classes(html, "textarea")
    assert "ring-error/25" in classes(html, "textarea")
    assert [_] = find(html, "textarea[aria-invalid=true]") |> Enum.to_list()
    assert LazyHTML.text(find(html, "span.text-error")) =~ "too short"

    html = render(~H'<.textarea name="b" state="success" help="Valid" />')
    assert "border-success" in classes(html, "textarea")
    assert find(html, "textarea[aria-invalid]") |> Enum.to_list() == []
    assert "text-success" in classes(html, "label + span")
  end

  test "a caption wraps it in a label and help goes under it" do
    html = render(~H'<.textarea name="b" label="Bio" help="Short" />')
    assert LazyHTML.text(find(html, "label")) =~ "Bio"
    assert LazyHTML.text(find(html, "label + span")) =~ "Short"
  end

  test "header and footer sit in a frame that glows on focus, with an 8px 10px footer" do
    html =
      render(~H"""
      <.textarea name="post" label="Comment">
        <:header>head</:header>
        <:footer>foot</:footer>
      </.textarea>
      """)

    frame = classes(html, "div.rounded-lg")
    assert "focus-within:!border-primary" in frame
    assert "focus-within:ring-3" in frame
    assert "mt-1.5" in frame
    assert "pt-0" not in classes(html, "textarea")
    assert "py-0" in classes(html, "textarea")
    assert "py-2" in classes(html, "div.justify-between:last-child")
    assert "px-2.5" in classes(html, "div.justify-between:last-child")
  end
end
