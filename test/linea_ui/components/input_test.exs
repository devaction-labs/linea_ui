defmodule LineaUI.Components.InputTest do
  use LineaUI.ComponentCase, async: true

  defp form_field(params, errors) do
    form = Phoenix.Component.to_form(params, as: :user, errors: errors)
    form[:email]
  end

  test "a bare outlined input without caption" do
    html = render(~H'<.input name="u" placeholder="Username" />')
    assert [_] = find(html, "input[type=text][name=u][placeholder=Username]") |> Enum.to_list()
    assert find(html, "label") |> Enum.to_list() == []
    classes = classes(html, "input")
    assert "form-input" in classes
    assert "border-slate-300" in classes
    assert "dark:focus:border-accent" in classes
  end

  test "variant, size and shape pick LineOne's classes and class overrides them" do
    html =
      render(~H"""
      <.input name="u" variant="filled" size="lg" shape="pill" class="px-6" />
      """)

    classes = classes(html, "input")
    assert "bg-slate-150" in classes
    assert "focus:ring-3" in classes
    assert "h-12" in classes
    assert "rounded-full" in classes
    assert "px-6" in classes
    refute "px-4" in classes
    refute "rounded-lg" in classes
  end

  test "a caption wraps the input in a block label, help goes under it" do
    html =
      render(~H'<.input name="u" label="Choose Username:" help="This is a help text" />')

    assert [label] = find(html, "label.block") |> Enum.to_list()
    assert LazyHTML.text(label) =~ "Choose Username:"
    assert "mt-1.5" in classes(html, "label > span + span")
    assert "text-tiny-plus" in classes(html, "label + span")
    assert LazyHTML.text(find(html, "label + span")) =~ "This is a help text"
  end

  test "state paints the border and the help line" do
    html = render(~H'<.input name="u" state="success" help="Username is valid" />')
    assert "border-success" in classes(html, "input")
    refute "border-slate-300" in classes(html, "input")
    assert "text-success" in classes(html, "label + span")
  end

  test "field fills id, name, value and shows errors once used" do
    field = form_field(%{"email" => "a@b"}, email: {"is invalid", []})
    assigns = %{field: field}
    html = rendered_to_string(~H'<.input field={@field} type="email" />')
    assert [_] = find(html, "input#user_email[name='user[email]'][value='a@b']") |> Enum.to_list()
    assert "border-error" in classes(html, "input")
    assert LazyHTML.text(find(html, "span.text-error")) =~ "is invalid"
    assert [_] = find(html, "input[aria-invalid=true]") |> Enum.to_list()

    field = form_field(%{}, email: {"can't be blank", []})
    assigns = %{field: field}
    html = rendered_to_string(~H'<.input field={@field} />')
    assert find(html, ".text-error") |> Enum.to_list() == []
  end

  test "prefix and suffix icons sit inside a positioned wrapper" do
    html =
      render(~H"""
      <.input name="q" placeholder="Search">
        <:prefix><svg class="icon-a"></svg></:prefix>
        <:suffix><svg class="icon-b"></svg></:suffix>
      </.input>
      """)

    assert [_] = find(html, "span.relative.flex > input.peer") |> Enum.to_list()
    assert "px-9" in classes(html, "input")
    assert [_] = find(html, "span.absolute.right-0 svg.icon-b") |> Enum.to_list()
    assert [_] = find(html, "span.absolute:not(.right-0) svg.icon-a") |> Enum.to_list()
  end

  test "options render a datalist" do
    html = render(~H'<.input id="b" name="b" options={["Edge", "Safari"]} />')
    assert [_] = find(html, "input[list=b-options]") |> Enum.to_list()

    assert ["Edge", "Safari"] =
             find(html, "datalist#b-options option") |> LazyHTML.attribute("value")
  end

  test "disabled and hidden types" do
    html = render(~H'<.input name="u" disabled />')
    assert [_] = find(html, "input[disabled]") |> Enum.to_list()
    assert "disabled:bg-zinc-100" in classes(html, "input")

    html = render(~H'<.input type="hidden" name="t" value="x" />')
    assert [_] = find(html, "input[type=hidden][name=t][value=x]") |> Enum.to_list()
  end

  test "a mask wires the hook with its options" do
    html =
      render(~H"""
      <.input
        id="card"
        name="card"
        mask="date"
        mask_options={%{pattern: ["m", "d", "Y"], delimiter: "-"}}
      />
      """)

    assert [input] =
             find(html, "input#card[phx-hook='LineaUI.InputMask'][data-mask=date]")
             |> Enum.to_list()

    assert JSON.decode!(hd(LazyHTML.attribute(input, "data-mask-options"))) == %{
             "pattern" => ["m", "d", "Y"],
             "delimiter" => "-"
           }

    assert [_] = find(html, "input[name=card]") |> Enum.to_list()
  end

  test "a masked input gets an id and passes phx-debounce" do
    html = render(~H'<.input name="c" mask="credit_card" phx-debounce="300" />')
    assert [id] = find(html, "input[phx-hook]") |> LazyHTML.attribute("id")
    assert id =~ "input-"
    assert [_] = find(html, "input[phx-debounce='300']") |> Enum.to_list()
  end

  test "mask_submit raw moves the name to a hidden input" do
    html =
      render(~H"""
      <.input
        id="amount"
        name="amount"
        value="1234"
        mask="numeral"
        mask_submit="raw"
        phx-debounce="200"
      />
      """)

    assert [_] = find(html, "input#amount[data-mask-submit=raw]:not([name])") |> Enum.to_list()

    assert [_] =
             find(
               html,
               "input#amount-raw[type=hidden][name=amount][value='1234'][phx-debounce='200']"
             )
             |> Enum.to_list()
  end

  test "align right" do
    html =
      render(~H"""
      <.input id="a" name="a" align="right" />
      <.input id="b" name="b" />
      """)

    assert "text-right" in classes(html, "#a")
    refute "text-right" in classes(html, "#b")
  end

  test "clear_on_submit wires the sync hook and the server value" do
    html =
      render(~H"""
      <.input id="todo" name="title" value="" clear_on_submit />
      <.input id="m" name="m" value="12" mask="numeral" clear_on_submit />
      <.input id="plain" name="p" />
      """)

    assert [_] =
             find(
               html,
               "#todo[phx-hook='LineaUI.InputSync'][data-clear-on-submit][data-value='']"
             )
             |> Enum.to_list()

    assert [_] =
             find(html, "#m[phx-hook='LineaUI.InputMask'][data-clear-on-submit][data-value='12']")
             |> Enum.to_list()

    assert [] = find(html, "#plain[phx-hook]") |> Enum.to_list()
  end
end
