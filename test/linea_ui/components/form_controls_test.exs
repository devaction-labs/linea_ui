defmodule LineaUI.Components.FormControlsTest do
  use LineaUI.ComponentCase, async: true

  describe "form" do
    test "label, error and help_text" do
      assert [_] =
               find(render(~H'<.label for="x">X</.label>'), "label.block[for=x]")
               |> Enum.to_list()

      assert "text-error" in classes(render(~H'<.error>bad</.error>'), "span")
      assert "text-base-content/55" in classes(render(~H'<.help_text>hi</.help_text>'), "span")

      assert "text-success" in classes(
               render(~H'<.help_text state="success">ok</.help_text>'),
               "span"
             )
    end

    test "error is announced and a success help line has a check-circle icon" do
      assert [_] = find(render(~H'<.error>bad</.error>'), "span[role=alert]") |> Enum.to_list()

      ok = render(~H'<.help_text state="success">ok</.help_text>')
      assert [svg] = find(ok, "span > svg") |> Enum.to_list()
      assert "size-3.5" in (svg |> LazyHTML.attribute("class") |> List.first() |> String.split())
      assert find(render(~H'<.help_text>hi</.help_text>'), "svg") |> Enum.to_list() == []

      assert find(render(~H'<.help_text state="error">no</.help_text>'), "svg") |> Enum.to_list() ==
               []
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
      assert LazyHTML.text(find(html, ".mt-1\\.5.block")) =~ "Where"
    end
  end

  describe "textarea" do
    test "outlined, not resizable, with its rows" do
      html = render(~H'<.textarea name="t" value="hello" placeholder="Enter Text" />')
      assert [textarea] = find(html, "textarea[name=t][rows='4']") |> Enum.to_list()
      assert LazyHTML.text(textarea) =~ "hello"
      classes = classes(html, "textarea")
      assert "textarea" in classes
      assert "resize-none" in classes
    end

    test "filled and resizable" do
      classes =
        classes(render(~H'<.textarea name="t" variant="filled" resizable />'), "textarea")

      assert "bg-base-200" in classes
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

      assert [_] = find(html, "div.rounded-field.border > div.flex .h") |> Enum.to_list()
      assert [_] = find(html, "div.rounded-field.border > div.py-2 .f") |> Enum.to_list()
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

      assert "aria-invalid:textarea-error" in classes(html, "textarea")
    end
  end

  describe "range" do
    test "color and size" do
      html = render(~H'<.range name="v" value={50} color="primary" size="lg" />')
      assert [_] = find(html, "input[type=range][name=v][value='50']") |> Enum.to_list()
      classes = classes(html, "input")
      assert ["range", "range-primary", "range-lg"] -- classes == []
    end

    test "min, max, step and phx-debounce pass through" do
      html = render(~H'<.range name="v" min={0} max={10} step={2} phx-debounce="100" />')

      assert [_] =
               find(html, "input[min='0'][max='10'][step='2'][phx-debounce='100']")
               |> Enum.to_list()
    end
  end

  describe "input_group" do
    test "is a group named by its caption" do
      html = render(~H'<.input_group id="g" label="Price"><.input name="p" /></.input_group>')
      assert [_] = find(html, "span#g-label") |> Enum.to_list()
      assert [_] = find(html, "div#g[role=group][aria-labelledby=g-label]") |> Enum.to_list()
      assert find(html, "[aria-invalid]") |> Enum.to_list() == []

      html = render(~H'<.input_group label="Price"><.input name="p" /></.input_group>')
      assert [id] = find(html, "span[id^=input-group-]") |> LazyHTML.attribute("id")
      assert [_] = find(html, "div[role=group][aria-labelledby='#{id}']") |> Enum.to_list()

      assert [_] =
               find(
                 render(~H'<.input_group><.input name="p" /></.input_group>'),
                 "div[role=group]"
               )
               |> Enum.to_list()
    end

    test "errors turn the shared border red and show under the row" do
      html =
        render(~H"""
        <.input_group id="g" label="Price" errors={["must be positive"]}>
          <.input_group_addon>$</.input_group_addon>
          <.input name="p" />
        </.input_group>
        """)

      assert "[&_.input]:input-error" in classes(html, "div[role=group]")

      assert [_] =
               find(html, "div[role=group][aria-invalid=true][aria-describedby=g-messages]")
               |> Enum.to_list()

      assert LazyHTML.text(find(html, "#g-messages span.text-error")) =~ "must be positive"
    end

    test "help shows under the row without turning it red" do
      html = render(~H'<.input_group help="In dollars"><.input name="p" /></.input_group>')
      refute "[&_.input]:input-error" in classes(html, "div[role=group]")
      assert find(html, "div[role=group][aria-invalid]") |> Enum.to_list() == []
      assert LazyHTML.text(find(html, "div > span")) =~ "In dollars"
    end

    test "size sizes the parts together" do
      sm = classes(render(~H'<.input_group size="sm"><.input name="p" /></.input_group>'), "div")
      assert "[&_.input]:input-sm" in sm
      assert "[&_.btn]:btn-sm" in sm
      lg = classes(render(~H'<.input_group size="lg"><.input name="p" /></.input_group>'), "div")
      assert "[&_.input]:input-lg" in lg

      refute "[&_.input]:input-sm" in classes(
               render(~H'<.input_group><.input name="p" /></.input_group>'),
               "div"
             )
    end

    test "the outline addon is a field with soft text" do
      html = render(~H'<.input_group>
  <.input_group_addon>@</.input_group_addon>
</.input_group>')
      assert ["input", "join-item", "text-base-content/60"] -- classes(html, "div > span") == []
    end

    test "is daisyUI's join of its children" do
      html =
        render(~H"""
        <.input_group label="Price">
          <.input_group_addon variant="filled">$</.input_group_addon>
          <.input name="p" />
        </.input_group>
        """)

      classes = classes(html, "div.join")
      assert "mt-1.5" in classes
      assert "bg-base-200" in classes(html, "div.join > span")
      assert [_] = find(html, "div.join > input[name=p]") |> Enum.to_list()
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

      [sm, lg, md] = find(html, "div.join > span") |> LazyHTML.attribute("class")
      assert sm =~ "input-sm"
      assert lg =~ "input-lg"
      refute md =~ "input-sm"
      refute md =~ "input-lg"
    end

    test "pill shape" do
      assert "[--join-r:9999px]" in classes(
               render(~H'<.input_group shape="pill"><.input name="p" /></.input_group>'),
               "div"
             )
    end
  end

  test "field as div draws label_hint and label_aside beside the caption" do
    html =
      render(~H"""
      <.field as="div" label="Anexos" label_hint="opcional">
        <:label_aside><a href="/x" id="aside">Esqueci</a></:label_aside>
        <p>controls</p>
      </.field>
      """)

    assert "justify-between" in classes(html, "span.font-medium")
    assert LazyHTML.text(find(html, "span.font-medium > span")) =~ "opcional"
    assert [_] = find(html, "span.font-medium a#aside") |> Enum.to_list()
  end

  test "field as div without a hint keeps the plain caption" do
    html = render(~H'<.field as="div" label="Anexos">
  <p>x</p>
</.field>')
    refute "justify-between" in classes(html, "span.font-medium")
  end

  test "field below sits between the control and the help line" do
    html =
      render(~H"""
      <.field label="Senha" help="Mínimo 8">
        <:below><i id="bars"></i></:below>
        <input />
      </.field>
      """)

    assert [_] = find(html, "#bars") |> Enum.to_list()
    assert elem(:binary.match(html, "bars"), 0) < elem(:binary.match(html, "Mínimo 8"), 0)
  end
end
