defmodule LineaUI.Components.SignaturePadTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)
  defp count(html, selector), do: html |> find(selector) |> Enum.count()

  @svg ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 170"><path d="M1 2L3 4"/></svg>)

  test "a hidden input carries the field name and the saved SVG" do
    assigns = %{svg: @svg}
    html = rendered_to_string(~H|<.signature_pad id="s" name="sign[svg]" value={@svg} />|)

    assert attr_of(html, "input[type=hidden]", "name") == ["sign[svg]"]
    assert attr_of(html, "input[type=hidden]", "value") == [@svg]
    assert attr_of(html, "input[type=hidden]", "phx-update") == ["ignore"]
    assert attr_of(html, "#s-signature", "data-value") == [@svg]
  end

  test "an empty pad submits an empty value" do
    html = render(~H|<.signature_pad name="sign" />|)

    assert attr_of(html, "input[type=hidden]", "value") == [""]
  end

  test "the hook, its mode and its ink go on the root" do
    html = render(~H|<.signature_pad id="s" name="sign" mode="type" text="Ana" ink="#112233" />|)

    assert attr_of(html, "#s-signature", "phx-hook") == ["LineaUI.SignaturePad"]
    assert attr_of(html, "#s-signature", "data-mode") == ["type"]
    assert attr_of(html, "#s-signature", "data-modes") == ["draw,type"]
    assert attr_of(html, "#s-signature", "data-text") == ["Ana"]
    assert attr_of(html, "#s-signature", "data-ink") == ["#112233"]
    assert attr_of(html, "[data-type-input]", "value") == ["Ana"]
  end

  test "the drawing surface is client-owned and described for assistive technology" do
    html = render(~H|<.signature_pad id="s" name="sign" height={220} />|)

    assert attr_of(html, "#s-pad", "phx-update") == ["ignore"]
    assert attr_of(html, "#s-pad", "role") == ["img"]
    assert attr_of(html, "#s-pad", "aria-label") == ["Signature area"]
    assert attr_of(html, "#s-pad", "style") == ["height: 220px"]
    assert attr_of(html, "[data-path]", "stroke") == ["#0F172A"]
  end

  test "the mode switch has a button per mode and shows the active one pressed" do
    html = render(~H|<.signature_pad name="sign" mode="type" />|)

    assert attr_of(html, "[data-mode-button=draw]", "aria-pressed") == ["false"]
    assert attr_of(html, "[data-mode-button=type]", "aria-pressed") == ["true"]
  end

  test "a single mode hides the switch and sets the mode" do
    html = render(~H|<.signature_pad name="sign" modes={["type"]} />|)

    assert count(html, "[data-mode-button]") == 0
    assert attr_of(html, "div[data-modes]", "data-mode") == ["type"]
  end

  test "unknown modes fall back to both" do
    html = render(~H|<.signature_pad name="sign" modes={["scribble"]} />|)

    assert attr_of(html, "div[data-modes]", "data-modes") == ["draw,type"]
  end

  test "there is a clear button and both statuses, the empty one showing" do
    html = render(~H|<.signature_pad name="sign" />|)

    assert count(html, "[data-clear]") == 1
    assert attr_of(html, "[data-status-ready]", "hidden") == [""]
    assert attr_of(html, "[data-status-empty]", "hidden") == []
  end

  test "pt_BR names the texts in Portuguese and labels override single ones" do
    html =
      render(
        ~H|<.signature_pad name="sign" locale="pt_BR" labels={%{signature_clear: "Apagar"}} />|
      )

    assert LazyHTML.text(find(html, "[data-clear]")) |> String.trim() == "Apagar"
    assert LazyHTML.text(find(html, "[data-status-empty]")) |> String.trim() == "Sem assinatura"

    assert LazyHTML.text(find(html, "[data-hint]")) |> String.trim() ==
             "Assine aqui com o dedo ou o mouse"

    assert attr_of(html, "[data-mode-button=draw]", "data-mode-button") == ["draw"]
  end

  test "disabled stops the pad and its buttons" do
    html = render(~H|<.signature_pad name="sign" disabled />|)

    assert attr_of(html, "div[data-modes]", "data-disabled") == ["true"]
    assert attr_of(html, "[data-clear]", "disabled") == [""]
    assert attr_of(html, "input[type=hidden]", "disabled") == [""]
    assert "pointer-events-none" in classes(html, "[data-pad]")
  end

  test "on_change, target and debounce reach the hook and the hidden input" do
    html =
      render(
        ~H|<.signature_pad id="s" name="sign" on_change="signed" target="#form" phx-debounce="300" />|
      )

    assert attr_of(html, "#s-signature", "data-on-change") == ["signed"]
    assert attr_of(html, "#s-signature", "phx-target") == ["#form"]
    assert attr_of(html, "input[type=hidden]", "phx-debounce") == ["300"]
  end

  test "a field fills id, name and value and shows its errors" do
    form =
      Phoenix.Component.to_form(%{"signature" => @svg},
        as: :receipt,
        errors: [signature: {"can't be blank", []}]
      )

    assigns = %{form: form}
    html = rendered_to_string(~H|<.signature_pad field={@form[:signature]} label="Signature" />|)

    assert attr_of(html, "input[type=hidden]", "name") == ["receipt[signature]"]
    assert attr_of(html, "input[type=hidden]", "id") == ["receipt_signature"]
    assert attr_of(html, "input[type=hidden]", "value") == [@svg]
    assert html =~ "can&#39;t be blank"
    assert html =~ "Signature"
  end
end
