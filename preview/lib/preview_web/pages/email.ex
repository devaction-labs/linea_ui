defmodule PreviewWeb.Pages.Email do
  use PreviewWeb.Page, title: "Transactional e-mail", category: :components

  import LineaUI.Components.Email

  def render(assigns) do
    assigns = assign(assigns, code: code_html(:auto), order: order_html(:auto), dark: order_html(:dark))

    ~H"""
    <.example title="Verification code" text="A code in boxes, the main button and its address spelled out, and a note." class="mt-5">
      <iframe title="Code e-mail" srcdoc={@code} class="h-[640px] w-full rounded-lg border-0 bg-slate-100"></iframe>
    </.example>
    <.example title="Order update" text="Steps, facts with a mono and a total row, and two buttons' worth of links." class="mt-5">
      <iframe title="Order e-mail" srcdoc={@order} class="h-[720px] w-full rounded-lg border-0 bg-slate-100"></iframe>
    </.example>
    <.example title="Fixed dark" text="theme={:dark} paints the dark palette whatever the reader's system says." class="mt-5">
      <iframe title="Dark e-mail" srcdoc={@dark} class="h-[720px] w-full rounded-lg border-0"></iframe>
    </.example>
    """
  end

  defp to_html(rendered), do: rendered |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

  defp code_html(theme) do
    assigns = %{theme: theme}

    to_html(~H"""
    <.email_layout subject="Your code" preheader="Valid for 10 minutes" brand="LineaUI" eyebrow="Confirm your access" title="Your verification code" theme={@theme}>
      <:badge><span style="color:#fff;font-size:22px;line-height:48px;">✉</span></:badge>
      <:body>
        <.email_p theme={@theme}>Hi <b>Ana</b>. Type the code below on the sign-in screen. It is valid for 10 minutes.</.email_p>
        <.email_code value="482913" hint="Or sign in with one tap:" theme={@theme} />
      </:body>
      <:action href="https://app.example.com/confirm?token=7f3a9c">Sign in</:action>
      <:note>Not you? Ignore this e-mail: nobody signs in without the code.</:note>
      <:footer><b>Acme Ltda</b><br />Main Street, 100 · Feira de Santana, BA</:footer>
    </.email_layout>
    """)
  end

  defp order_html(theme) do
    assigns = %{theme: theme}

    to_html(~H"""
    <.email_layout subject="Order shipped" brand="LineaUI" eyebrow="Order #1283" title="Your order is on its way" theme={@theme}>
      <:badge><span style="color:#fff;font-size:22px;line-height:48px;">▣</span></:badge>
      <:body>
        <.email_p theme={@theme}>The carrier picked up your <b>3 items</b> today at 09:40.</.email_p>
        <.email_steps steps={[{"Paid", true}, {"Shipped", true}, {"Delivered", false}]} theme={@theme} />
        <.email_facts rows={[{"Estimate", "Thu, Oct 29"}, {"Carrier", "Rapido Sul"}, {"Tracking", "BR482913077XY", :mono}, {"Total", "R$ 1.284,90", :total}]} theme={@theme} />
      </:body>
      <:action href="https://app.example.com/orders/1283">Track delivery</:action>
      <:secondary href="https://app.example.com/orders/1283/details">View order</:secondary>
      <:footer><b>Acme Ltda</b><br />You got this e-mail because you placed an order.</:footer>
    </.email_layout>
    """)
  end
end
