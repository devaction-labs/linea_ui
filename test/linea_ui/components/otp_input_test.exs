defmodule LineaUI.Components.OtpInputTest do
  use LineaUI.ComponentCase, async: true

  alias Phoenix.LiveView.JS

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp boxes(html), do: html |> find("input[data-otp-box]") |> Enum.to_list()

  test "six numeric boxes in a labelled group, and the hidden code" do
    html = render(~H|<.otp_input name="code" value="482" label="Code" />|)

    assert attr_of(html, "#code", "role") == ["group"]
    assert attr_of(html, "#code", "phx-hook") == ["LineaUI.Otp"]
    assert attr_of(html, "#code", "aria-labelledby") == ["code-label"]
    assert attr_of(html, "#code", "aria-label") == []
    assert attr_of(html, "#code-label", "id") == ["code-label"]
    assert attr_of(html, "#code", "data-length") == ["6"]
    assert attr_of(html, "#code", "data-mode") == ["numeric"]
    assert attr_of(html, "#code", "data-value") == ["482"]
    assert attr_of(html, "#code", "data-autofocus") == []

    assert length(boxes(html)) == 6

    assert html |> find("input[data-otp-box]") |> LazyHTML.attribute("value") == [
             "4",
             "8",
             "2",
             "",
             "",
             ""
           ]

    assert attr_of(html, "input[data-otp-box]", "name") == []
    assert attr_of(html, "#code-1", "aria-label") == ["Digit 1"]
    assert attr_of(html, "#code-6", "aria-label") == ["Digit 6"]
    assert attr_of(html, "#code-1", "autocomplete") == ["one-time-code"]
    assert attr_of(html, "#code-1", "inputmode") == ["numeric"]
    assert attr_of(html, "#code-1", "pattern") == ["[0-9]*"]
    assert attr_of(html, "#code-1", "type") == ["text"]
    assert attr_of(html, "#code-1", "data-filled") == [""]
    assert attr_of(html, "#code-4", "data-filled") == []

    assert attr_of(html, "input[type=hidden][name=code]", "value") == ["482"]
    assert attr_of(html, "input[type=hidden][name=code]", "phx-update") == ["ignore"]
    assert attr_of(html, "input[type=hidden][name=code]", "id") == ["code-value"]
  end

  test "without a label the group is named by aria_label" do
    html =
      render(~H|<.otp_input name="code" aria_label="Verification code" digit_label="Dígito" />|)

    assert attr_of(html, "#code", "aria-label") == ["Verification code"]
    assert attr_of(html, "#code", "aria-labelledby") == []
    assert attr_of(html, "#code-2", "aria-label") == ["Dígito 2"]
  end

  test "the look of the Signetum canvas on the boxes" do
    html = render(~H|<.otp_input name="code" />|)
    classes = classes(html, "#code-1")

    assert [
             "h-[54px]",
             "rounded-xl",
             "text-[22px]",
             "font-mono",
             "font-semibold",
             "text-center",
             "px-0"
           ] --
             classes == []

    assert "data-filled:border-primary" in classes
    assert "dark:data-filled:border-accent" in classes
  end

  test "sizes" do
    html =
      render(~H"""
      <.otp_input name="a" size="sm" />
      <.otp_input name="b" size="lg" />
      """)

    assert "h-10" in classes(html, "#a-1")
    assert "h-16" in classes(html, "#b-1")
    assert "text-2xl" in classes(html, "#b-1")
  end

  test "length cuts the value and pads the boxes" do
    html = render(~H|<.otp_input name="pin" length={4} value="123456" />|)

    assert length(boxes(html)) == 4
    assert attr_of(html, "#pin", "data-value") == ["1234"]
    assert attr_of(html, "input[type=hidden]", "value") == ["1234"]

    html = render(~H|<.otp_input name="pin" length={4} value="12" />|)
    assert attr_of(html, "#pin", "data-value") == ["12"]
  end

  test "an integer value and characters the mode refuses" do
    html = render(~H|<.otp_input name="n" value={4821} />|)
    assert attr_of(html, "#n", "data-value") == ["4821"]

    html = render(~H|<.otp_input name="n" value="48-2a1" />|)
    assert attr_of(html, "#n", "data-value") == ["4821"]

    html = render(~H|<.otp_input name="n" value="a8-2" mode="alphanumeric" length={4} />|)
    assert attr_of(html, "#n", "data-value") == ["a82"]
    assert attr_of(html, "#n", "data-mode") == ["alphanumeric"]
    assert attr_of(html, "#n-1", "inputmode") == ["text"]
    assert attr_of(html, "#n-1", "pattern") == ["[A-Za-z0-9]*"]
  end

  test "mask draws the boxes as a password" do
    html = render(~H|<.otp_input name="pin" mask />|)
    assert attr_of(html, "#pin-1", "type") == ["password"]
  end

  test "disabled and autofocus" do
    html = render(~H|<.otp_input name="code" disabled autofocus />|)

    assert attr_of(html, "#code-1", "disabled") == [""]
    assert attr_of(html, "input[type=hidden]", "disabled") == [""]
    assert attr_of(html, "#code", "data-autofocus") == [""]
  end

  test "a separator after a position, or after several" do
    html = render(~H|<.otp_input name="code" separator={3} />|)
    assert [separator] = find(html, "[aria-hidden=true]") |> Enum.to_list()
    assert LazyHTML.text(separator) =~ "–"

    html = render(~H|<.otp_input name="code" length={8} separator={[2, 4, 8, 0]} />|)
    assert length(find(html, "[aria-hidden=true]") |> Enum.to_list()) == 2

    html = render(~H|<.otp_input name="code" />|)
    assert find(html, "[aria-hidden=true]") |> Enum.to_list() == []
  end

  test "on_complete as an event name or a JS command, with the target" do
    html = render(~H|<.otp_input name="code" on_complete="verify" target="#form" />|)
    assert [js] = attr_of(html, "#code", "data-on-complete")
    assert js =~ "verify"
    assert js =~ "#form"
    assert js =~ "code"

    html = render(~H|<.otp_input name="code" on_complete={JS.push("done")} />|)
    assert [js] = attr_of(html, "#code", "data-on-complete")
    assert js =~ "done"

    html = render(~H|<.otp_input name="code" />|)
    assert attr_of(html, "#code", "data-on-complete") == ["[]"]
  end

  test "help, errors and the error state" do
    html =
      render(~H|<.otp_input name="code" value="12" help="Sent by SMS" errors={["is invalid"]} />|)

    assert html =~ "Sent by SMS"
    assert html =~ "is invalid"
    assert attr_of(html, "#code-1", "aria-invalid") == ["true"]
    assert "border-error" in classes(html, "#code-1")
    refute "data-filled:border-primary" in classes(html, "#code-1")
  end

  test "a form field supplies the id, name, value and wrapper" do
    form = to_form(%{"code" => "9081"}, as: :otp)
    assigns = %{__changed__: nil, form: form}

    html = rendered_to_string(~H|<.otp_input field={@form[:code]} wrapper_class="mt-4" />|)

    assert attr_of(html, "#otp_code", "data-value") == ["9081"]
    assert attr_of(html, "input[type=hidden][name='otp[code]']", "value") == ["9081"]
    assert attr_of(html, "#otp_code-1", "value") == ["9"]
    assert "mt-4" in classes(html, "div:has(#otp_code)")
  end

  test "class goes to every box and rest to the group" do
    html = render(~H|<.otp_input name="code" class="bg-red-500" data-x="1" />|)

    assert "bg-red-500" in classes(html, "#code-1")
    assert "bg-red-500" in classes(html, "#code-6")
    assert attr_of(html, "#code", "data-x") == ["1"]
  end
end
