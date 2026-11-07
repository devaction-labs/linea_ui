defmodule LineaUI.Components.EmailTest do
  use LineaUI.ComponentCase, async: true

  defp html(assigns \\ %{}) do
    assigns = Map.merge(%{theme: :auto}, assigns)

    Phoenix.LiveViewTest.rendered_to_string(~H"""
    <.email_layout
      subject="Your code"
      preheader="Valid for 10 minutes"
      brand="Acme"
      logo_url="https://acme.com/logo.png"
      eyebrow="Confirm"
      title="Your verification code"
      theme={@theme}
    >
      <:badge><img id="icon" src="https://acme.com/e.png" width="24" height="24" alt="" /></:badge>
      <:body>
        <.email_p>Hello <b>Ana</b>.</.email_p>
        <.email_code value="482913" hint="Or tap:" />
        <.email_facts rows={[
          {"Estimate", "Thu"},
          {"Tracking", "BR482", :mono},
          {"Total", "R$ 10", :total}
        ]} />
        <.email_steps steps={[{"Paid", true}, {"Shipped", true}, {"Delivered", false}]} />
      </:body>
      <:action href="https://app.acme.com/confirm?t=1">Sign in</:action>
      <:note>Not you? Ignore it.</:note>
      <:footer>Acme Ltda</:footer>
    </.email_layout>
    """)
  end

  test "a whole document for mail clients: doctype, title, preheader and the color scheme" do
    out = html()

    assert out =~ "<!DOCTYPE html>"
    assert out =~ "<title>Your code</title>"
    assert out =~ "Valid for 10 minutes"
    assert out =~ ~s(name="color-scheme" content="light dark")
    assert out =~ "max-width:520px"
  end

  test "the title, eyebrow, badge, note and footer are in the card" do
    doc = out_doc()

    assert text(doc, "h2") =~ "Your verification code"
    assert text(doc, ".em-soft") =~ "Confirm"
    assert find(doc, "#icon") |> Enum.count() == 1
    assert text(doc, "table") =~ "Not you? Ignore it."
    assert text(doc, "table") =~ "Acme Ltda"
  end

  test "the main button links to a safe url and spells the address out" do
    doc = out_doc()

    assert find(doc, "a[href='https://app.acme.com/confirm?t=1']") |> Enum.count() == 2
    assert text(doc, "table") =~ "copy and paste this address"
  end

  test "a secondary button sits beside the main one and takes a safe address" do
    assigns = %{}

    out =
      Phoenix.LiveViewTest.rendered_to_string(~H"""
      <.email_layout subject="s" title="t">
        <:body>x</:body>
        <:action href="https://a.com/1">Track</:action>
        <:secondary href="javascript:alert(1)">View order</:secondary>
      </.email_layout>
      """)

    assert out =~ "View order"
    assert out =~ ~s(class="em-edge")
    refute out =~ "javascript:"
    refute html() =~ ~s(class="em-edge")
  end

  test "the gap above the footer is outside its panel" do
    doc = out_doc()

    assert find(doc, "td.em-panel div") |> Enum.count() == 0
    assert find(doc, "td[style*='height:16px']") |> Enum.count() == 1
  end

  test "a note takes an optional 16px icon image" do
    assigns = %{}

    out =
      Phoenix.LiveViewTest.rendered_to_string(~H"""
      <.email_layout subject="s" title="t">
        <:body>x</:body>
        <:note icon="https://acme.com/i.png">With icon</:note>
        <:note icon="javascript:alert(1)">Unsafe</:note>
        <:note>Plain</:note>
      </.email_layout>
      """)

    assert find(out, "img[src='https://acme.com/i.png'][width='16'][height='16']") |> Enum.count() ==
             1

    refute out =~ "javascript:"
    assert find(out, "img[width='16']") |> Enum.count() == 1
  end

  test "an unsafe address becomes a hash" do
    assigns = %{}

    out =
      Phoenix.LiveViewTest.rendered_to_string(~H"""
      <.email_layout subject="s" title="t">
        <:body>x</:body>
        <:action href="javascript:alert(1)">Go</:action>
      </.email_layout>
      """)

    refute out =~ "javascript:"
    assert out =~ ~s(href="#")
  end

  test "the code has one box per character and an accessible value" do
    doc = out_doc()

    assert text(doc, "[aria-label='482913']") |> String.replace(~r/\s/, "") == "482913"
    assert find(doc, "[aria-label='482913'] td") |> Enum.count() == 6
  end

  test "facts mark mono and total rows; steps check the done ones" do
    out = html()

    assert out =~ "BR482"
    assert out =~ "font-weight:600"
    assert out =~ "✓"
    assert (out |> String.split("✓") |> length()) - 1 == 2
  end

  test "auto adds the dark block, a fixed theme does not and dark paints the dark palette" do
    assert html() =~ "prefers-color-scheme:dark"
    refute html(%{theme: :light}) =~ "prefers-color-scheme:dark"
    assert html(%{theme: :dark}) =~ "background-color:#111113"
    assert html(%{theme: :dark}) =~ ~s(content="dark")
  end

  test "the canvas options: ink button, no fallback, plain footer, title size, table facts" do
    assigns = %{}

    out =
      Phoenix.LiveViewTest.rendered_to_string(~H"""
      <.email_layout
        subject="S"
        title="Pedido aprovado"
        theme={:light}
        alt_text={nil}
        button="ink"
        footer_style="plain"
        title_size={16}
        compact
      >
        <:body>
          <.email_p theme={:light} muted>Olá</.email_p>
          <.email_facts
            theme={:light}
            variant="table"
            header={{"Indicador", "Valor"}}
            rows={[{"Vendas", "1", :mono}]}
          />
        </:body>
        <:action href="https://app.example.com/p/1">Ver pedido</:action>
        <:footer>Signetum</:footer>
      </.email_layout>
      """)

    assert out =~ "border-radius:999px;background-color:#17171a"
    refute out =~ "&rarr;"
    refute out =~ "copy and paste"
    assert out =~ "font-size:16px"
    refute out =~ ~s(class="em-ink em-title")
    assert out =~ "padding:20px;"
    assert out =~ "font-size:11.5px"
    refute out =~ "padding:20px 24px;border-radius:12px"
    assert out =~ "Indicador"
    assert out =~ "color:#9d9ba1"
    assert out =~ "font-size:13.5px"
  end

  test "the defaults keep the accent button with its arrow and the footer panel" do
    out = html()
    assert out =~ "&rarr;"
    assert out =~ "copy and paste"
    assert out =~ "padding:20px 24px;border-radius:12px"
  end

  defp out_doc, do: html()

  defp text(doc, selector), do: doc |> find(selector) |> LazyHTML.text()
end
