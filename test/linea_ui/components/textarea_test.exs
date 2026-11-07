defmodule LineaUI.Components.TextareaTest do
  use LineaUI.ComponentCase, async: true

  test "a bare outlined textarea is the canvas field: white, 11px corners, 14px text, primary focus ring" do
    html = render(~H'<.textarea name="bio" placeholder="Enter Text" />')

    assert [_] =
             find(html, "textarea[name=bio][rows='4'][placeholder='Enter Text']")
             |> Enum.to_list()

    assert find(html, "label") |> Enum.to_list() == []

    classes = classes(html, "textarea")
    assert "bg-white" in classes
    assert "rounded-[11px]" in classes
    assert "text-[14px]" in classes

    assert "focus:shadow-[inset_0_0_0_1px_var(--color-primary),0_0_0_4px_color-mix(in_oklab,var(--color-primary)_14%,transparent)]" in classes

    assert "disabled:bg-zinc-100" in classes
    assert "resize-none" in classes
  end

  test "resizable drops resize-none and disabled sets the attribute" do
    html = render(~H'<.textarea name="bio" resizable disabled />')
    refute "resize-none" in classes(html, "textarea")
    assert [_] = find(html, "textarea[disabled]") |> Enum.to_list()
  end

  test "filled variant" do
    assert "bg-slate-150" in classes(
             render(~H'<.textarea name="b" variant="filled" />'),
             "textarea"
           )
  end

  test "error and success paint the line and ring; error sets aria-invalid" do
    html = render(~H'<.textarea name="b" errors={["too short"]} />')
    assert Enum.any?(classes(html, "textarea"), &(&1 =~ "var(--color-error)"))
    assert [_] = find(html, "textarea[aria-invalid=true]") |> Enum.to_list()
    assert LazyHTML.text(find(html, "span.text-error")) =~ "too short"

    html = render(~H'<.textarea name="b" state="success" help="Valid" />')
    assert Enum.any?(classes(html, "textarea"), &(&1 =~ "var(--color-success)"))
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

    frame = classes(html, "div.rounded-md")
    assert "focus-within:!border-primary" in frame
    assert "focus-within:ring-3" in frame
    assert "mt-1.5" in frame
    assert "pt-0" not in classes(html, "textarea")
    assert "py-0" in classes(html, "textarea")
    assert "py-2" in classes(html, "div.justify-between:last-child")
    assert "px-2.5" in classes(html, "div.justify-between:last-child")
  end

  test "the counter shares the row of the help, at the right; alone it sits under the control" do
    framed =
      render(~H'<.textarea name="n" label="Note" help="Keep it short" maxlength={200} counter />')

    assert [_] =
             find(framed, "div.flex.justify-between > div.ml-auto > span[aria-live=polite]")
             |> Enum.to_list()

    assert ["Keep it short"] =
             framed
             |> find("div.flex.justify-between > div.min-w-0")
             |> Enum.map(&LazyHTML.text/1)
             |> Enum.map(&String.trim/1)

    alone = render(~H'<.textarea name="n" maxlength={200} counter />')

    assert [_] =
             find(alone, "div.w-full > div.justify-end > span[aria-live=polite]")
             |> Enum.to_list()
  end

  test "the help line stays muted under state=error" do
    html = render(~H'<.textarea name="b" state="error" help="Conte o que aconteceu" />')
    refute "text-error" in classes(html, "label + span")
  end

  test "counter_format and counter_align=start" do
    html =
      render(~H"""
      <.textarea
        id="d"
        name="d"
        label="Descrição"
        value="abc"
        maxlength="300"
        counter
        counter_format="%{count} de %{max}"
        counter_align="start"
      />
      """)

    assert LazyHTML.text(find(html, "#d-counter")) == "3 de 300"
    assert html |> find("textarea") |> LazyHTML.attribute("data-format") == ["%{count} de %{max}"]
    assert "justify-start" in classes(html, "div:has(> #d-counter)")
  end
end
