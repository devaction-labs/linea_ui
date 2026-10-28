defmodule LineaUI.Components.FormControlsTest do
  use LineaUI.ComponentCase, async: true

  describe "form" do
    test "label, error and help_text" do
      assert [_] =
               find(render(~H'<.label for="x">X</.label>'), "label.block[for=x]")
               |> Enum.to_list()

      assert "text-error" in classes(render(~H'<.error>bad</.error>'), "span")
      assert "text-slate-400" in classes(render(~H'<.help_text>hi</.help_text>'), "span")

      assert "text-success" in classes(
               render(~H'<.help_text state="success">ok</.help_text>'),
               "span"
             )
    end

    test "field wraps any control with caption, help and errors" do
      form =
        Phoenix.Component.to_form(%{"country" => "br"},
          as: :a,
          errors: [country: {"is invalid", []}]
        )

      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <.field field={@form[:country]} label="Country" help="Where">
          <select id="a_country"></select>
        </.field>
        """)

      assert [_] = find(html, "label.block[for=a_country] span.mt-1\\.5 select") |> Enum.to_list()
      assert LazyHTML.text(find(html, ".text-error")) =~ "is invalid"
      assert LazyHTML.text(find(html, ".text-tiny-plus")) =~ "Where"
    end
  end

  describe "textarea" do
    test "outlined, not resizable, with its rows" do
      html = render(~H'<.textarea name="t" value="hello" placeholder="Enter Text" />')
      assert [textarea] = find(html, "textarea[name=t][rows='4']") |> Enum.to_list()
      assert LazyHTML.text(textarea) =~ "hello"
      classes = classes(html, "textarea")
      assert "form-textarea" in classes
      assert "resize-none" in classes
      assert "p-2.5" in classes
    end

    test "filled and resizable" do
      classes =
        classes(render(~H'<.textarea name="t" variant="filled" resizable />'), "textarea")

      assert "bg-slate-150" in classes
      refute "resize-none" in classes
    end

    test "counter shows the length, the limit and a tone, wired to the hook" do
      html =
        render(~H'<.textarea name="t" value="hello" maxlength={10} counter />')

      assert [ta] =
               find(html, "textarea[phx-hook='LineaUI.Textarea'][data-max='10']")
               |> Enum.to_list()

      assert [id] = LazyHTML.attribute(ta, "id")
      assert [_] = find(html, "textarea[aria-describedby='#{id}-counter']") |> Enum.to_list()

      assert [counter] =
               find(html, "##{id}-counter[aria-live=polite][data-tone=ok]") |> Enum.to_list()

      assert LazyHTML.text(counter) =~ "5 / 10"

      html = render(~H'<.textarea name="t" value="123456789" maxlength={10} counter />')
      assert [_] = find(html, "[aria-live=polite][data-tone=warn]") |> Enum.to_list()

      html = render(~H'<.textarea name="t" value="ab" counter min_length={20} />')
      assert [c] = find(html, "[aria-live=polite][data-tone=bad]") |> Enum.to_list()
      assert LazyHTML.text(c) =~ "2 / 20 mín."

      html = render(~H'<.textarea name="t" />')
      assert [] = find(html, "[aria-live]") |> Enum.to_list()
      assert [] = find(html, "[phx-hook]") |> Enum.to_list()
    end

    test "autogrow hooks the textarea, drops the handle and caps the rows" do
      html = render(~H'<.textarea name="t" autogrow resizable max_rows={6} />')

      assert [_] =
               find(html, "textarea[phx-hook][data-autogrow][data-max-rows='6']")
               |> Enum.to_list()

      classes = classes(html, "textarea")
      assert "resize-none" in classes
      assert "overflow-hidden" in classes
    end

    test "header and footer frame the textarea" do
      html =
        render(~H"""
        <.textarea name="t" rows={5}>
          <:header><span class="h">Title</span></:header>
          <:footer><span class="f">Save</span></:footer>
        </.textarea>
        """)

      assert [_] = find(html, "div.rounded-lg.border > div.flex .h") |> Enum.to_list()
      assert [_] = find(html, "div.rounded-lg.border > div.p-2\\.5 .f") |> Enum.to_list()
      classes = classes(html, "textarea")
      assert "py-0" in classes
      refute "border" in classes
    end

    test "field wiring" do
      form = Phoenix.Component.to_form(%{"bio" => "x"}, as: :u, errors: [bio: {"too short", []}])
      assigns = %{form: form}
      html = rendered_to_string(~H'<.textarea field={@form[:bio]} label="Bio" />')

      assert [_] =
               find(html, "textarea#u_bio[name='u[bio]'][aria-invalid=true]") |> Enum.to_list()

      assert "border-error" in classes(html, "textarea")
    end
  end

  describe "range" do
    test "color and size" do
      html = render(~H'<.range name="v" value={50} color="primary" size="lg" />')
      assert [_] = find(html, "input[type=range][name=v][value='50']") |> Enum.to_list()
      classes = classes(html, "input")
      assert "form-range" in classes
      assert "text-primary" in classes
      assert "[--range-thumb-size:24px]" in classes
    end

    test "min, max, step and phx-debounce pass through" do
      html = render(~H'<.range name="v" min={0} max={10} step={2} phx-debounce="100" />')

      assert [_] =
               find(html, "input[min='0'][max='10'][step='2'][phx-debounce='100']")
               |> Enum.to_list()
    end
  end

  describe "input_group" do
    test "joins its children and rounds only the ends" do
      html =
        render(~H"""
        <.input_group label="Price">
          <.input_group_addon variant="filled">$</.input_group_addon>
          <.input name="p" />
        </.input_group>
        """)

      classes = classes(html, "div.flex")
      assert "-space-x-px" in classes
      assert "[&>:first-child]:rounded-l-lg" in classes
      assert "mt-1.5" in classes
      assert "bg-slate-150" in classes(html, "div.flex > span")
      assert [_] = find(html, "div.flex > input[name=p]") |> Enum.to_list()
    end

    test "addon size follows the inputs" do
      html =
        render(~H"""
        <.input_group>
          <.input_group_addon size="sm">@</.input_group_addon>
          <.input_group_addon size="lg">@</.input_group_addon>
          <.input_group_addon>@</.input_group_addon>
        </.input_group>
        """)

      [sm, lg, md] = find(html, "div.flex > span") |> LazyHTML.attribute("class")
      assert sm =~ "text-xs-plus"
      assert lg =~ "text-base"
      refute md =~ "text-xs-plus"
      refute md =~ "text-base"
    end

    test "pill shape" do
      assert "[&>:last-child]:rounded-r-full" in classes(
               render(~H'<.input_group shape="pill"><.input name="p" /></.input_group>'),
               "div"
             )
    end
  end
end
