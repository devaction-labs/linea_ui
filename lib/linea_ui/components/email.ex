defmodule LineaUI.Components.Email do
  @moduledoc """
  LineOne's transactional e-mail: one layout for the e-mails a system sends (a sign-in code, a reset link, an
  order update): the logo, a card with an icon badge, an eyebrow, a title, text, a block of code, facts or steps,
  a main button with its address spelled out, a note (with an optional 16px `icon` image) and a footer, set
  16px under the card. 520px wide.

      <.email_layout subject="Your code" preheader="Valid for 10 minutes" brand="Acme" logo_url="https://acme.com/logo.png"
                     eyebrow="Confirm your access" title="Your verification code">
        <:badge><img src="https://acme.com/mail/envelope.png" width="24" height="24" alt="" /></:badge>
        <:body>
          <p>Hi <b>Ana</b>. Type this code on the sign-in screen. It is valid for 10 minutes.</p>
          <.email_code value="482913" />
        </:body>
        <:action href="https://app.acme.com/confirm?token=7f3a9c">Sign in</:action>
        <:note>Not you? Ignore this e-mail: nobody signs in without the code.</:note>
        <:footer>Acme Ltda · Main Street, 100</:footer>
      </.email_layout>

  It renders a whole HTML document built for mail clients: tables for the structure, every style inline,
  web-safe font stacks, no script and no stylesheet that matters. The only `<style>` carries the resets, the
  mobile padding and the dark mode: with `theme={:auto}` (the default) the e-mail follows the reader's
  `prefers-color-scheme`, `:light` and `:dark` fix it. Every color is also on a hook class (`em-*`) that the
  dark block overrides with `!important`.

  Icons and logos are images (`<img>` with an absolute URL): mail clients do not draw SVG or icon fonts.

  ## Helpers

    * `email_code/1`: a verification code, one box per character.
    * `email_facts/1`: label and value rows in a panel; a row can be `:mono` (a tracking number) or `:total`.
    * `email_steps/1`: a row of steps, done or to come (paid, shipped, delivered).

  Use them inside the `:body` slot, with `email_p/1` for the paragraphs. They draw the light palette and the
  dark block restyles them; when the layout has a fixed `theme={:dark}`, pass `theme={:dark}` to them too.

  Deliver it as the `html_body` of your mailer (`Phoenix.HTML.Safe.to_iodata/1` of the rendered component, or
  `Phoenix.Template.render_to_string/4` with a template that calls it).
  """

  use Phoenix.Component

  @sans "Poppins,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif"
  @inter "Inter,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif"
  @mono "JetBrains Mono,SF Mono,Menlo,Consolas,Courier New,monospace"

  @light %{
    canvas: "#f1f5f9",
    card: "#ffffff",
    card_clear: "rgba(255,255,255,0)",
    hair: "#e9eef5",
    ink: "#1e293b",
    body: "#475569",
    muted: "#64748b",
    primary: "#4f46e5",
    primary_text: "#4f46e5",
    soft: "#eef2ff",
    panel: "#f8fafc",
    grid: "rgba(79,70,229,.07)"
  }

  @dark %{
    canvas: "#192132",
    card: "#26334d",
    card_clear: "rgba(38,51,77,0)",
    hair: "#384766",
    ink: "#e7e9ef",
    body: "#c2c9d6",
    muted: "#a3adc2",
    primary: "#5f5af6",
    primary_text: "#a5b4fc",
    soft: "#303a6b",
    panel: "#222e45",
    grid: "rgba(129,140,248,.08)"
  }

  @resets "body{margin:0;padding:0;width:100% !important;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%}" <>
            "table,td{mso-table-lspace:0pt;mso-table-rspace:0pt}" <>
            "img{border:0;outline:none;text-decoration:none;-ms-interpolation-mode:bicubic}" <>
            "a{text-decoration:none}.em-logo-dark{display:none;max-height:0;overflow:hidden}" <>
            "@media only screen and (max-width:560px){.em-outer{padding:24px 12px 32px !important}" <>
            ".em-pad{padding-left:22px !important;padding-right:22px !important}" <>
            ".em-title{font-size:21px !important}}"

  @doc "The themes of the e-mail."
  @spec email_themes() :: [atom()]
  def email_themes, do: [:auto, :light, :dark]

  @doc """
  The e-mail: a whole HTML document.

  `eyebrow` is the short tag above the title. The `:action` slot is the main button (`href` required) and the
  address is spelled out under it, for the clients that block buttons. `alt_text` introduces that address.
  """
  attr :subject, :string, required: true, doc: "The `<title>`, and what the inbox shows."
  attr :preheader, :string, default: nil, doc: "The line next to the subject in the inbox."
  attr :brand, :string, default: nil, doc: "The name beside the logo."
  attr :logo_url, :string, default: nil, doc: "Absolute URL of the logo."

  attr :logo_dark_url, :string,
    default: nil,
    doc: "Absolute URL of the logo for dark backgrounds."

  attr :eyebrow, :string, default: nil
  attr :title, :string, required: true
  attr :theme, :atom, default: :auto, values: [:auto, :light, :dark]
  attr :lang, :string, default: "en"

  attr :alt_text, :string,
    default: "If the button does not work, copy and paste this address into your browser:"

  slot :badge, doc: "The inside of the icon tile: an `<img>` of 24px."
  slot :body, required: true, doc: "The text and the helpers."

  slot :action, doc: "The main button; the label is the content." do
    attr :href, :string, required: true
  end

  slot :note,
    doc: "A line of small print in a panel: the validity, or what to do if it was not you." do
    attr :icon, :string,
      doc:
        "Absolute http(s) URL of a 16px image shown before the text (an image, as every icon in a mail)."
  end

  slot :footer, doc: "Under the card: who sends this and why."

  def email_layout(assigns) do
    p = palette(assigns.theme)

    assigns =
      assign(assigns,
        p: p,
        css: {:safe, @resets <> dark_css(assigns.theme)},
        scheme: scheme(assigns.theme),
        sans: @sans,
        inter: @inter
      )

    ~H"""
    <!DOCTYPE html>
    <html lang={@lang} xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="color-scheme" content={@scheme} />
        <meta name="supported-color-schemes" content={@scheme} />
        <meta name="x-apple-disable-message-reformatting" />
        <meta name="format-detection" content="telephone=no,address=no,email=no,date=no,url=no" />
        <title>{@subject}</title>
        <style>
          <%= @css %>
        </style>
      </head>
      <body style={"margin:0;padding:0;background-color:#{@p.canvas};"} class="em-canvas">
        <div
          :if={@preheader}
          style="display:none;font-size:1px;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;mso-hide:all;"
        >
          {@preheader}
        </div>
        <table
          role="presentation"
          width="100%"
          border="0"
          cellpadding="0"
          cellspacing="0"
          class="em-canvas"
          bgcolor={@p.canvas}
          style={"background-color:#{@p.canvas};"}
        >
          <tr>
            <td align="center" class="em-outer" style="padding:36px 16px 44px;">
              <table
                role="presentation"
                width="520"
                border="0"
                cellpadding="0"
                cellspacing="0"
                style="width:100%;max-width:520px;"
              >
                <tr :if={@logo_url || @brand}>
                  <td style="padding:0 6px 18px;">
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0">
                      <tr>
                        <td :if={@logo_url} valign="middle" style="padding-right:10px;">
                          <img
                            src={@logo_url}
                            height="28"
                            alt={@brand || ""}
                            class="em-logo-light"
                            style="display:block;height:28px;width:auto;"
                          />
                          <img
                            :if={@logo_dark_url}
                            src={@logo_dark_url}
                            height="28"
                            alt={@brand || ""}
                            class="em-logo-dark"
                            style="display:none;max-height:0;overflow:hidden;height:28px;width:auto;"
                          />
                        </td>
                        <td
                          :if={@brand}
                          valign="middle"
                          class="em-ink"
                          style={"color:#{@p.ink};font-family:#{@sans};font-size:17px;line-height:28px;font-weight:600;"}
                        >
                          {@brand}
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td
                    class="em-card"
                    bgcolor={@p.card}
                    style={"background-color:#{@p.card};border:1px solid #{@p.hair};border-radius:14px;overflow:hidden;"}
                  >
                    <table role="presentation" width="100%" border="0" cellpadding="0" cellspacing="0">
                      <tr :if={@badge != []}>
                        <td
                          class="em-hero em-pad"
                          bgcolor={@p.card}
                          style={"padding:30px 32px 0;background-color:#{@p.card};background-image:#{hero_image(@p)};background-size:100% 100%,22px 22px,22px 22px;background-position:0 0,-1px -1px,-1px -1px;"}
                        >
                          <table role="presentation" border="0" cellpadding="0" cellspacing="0">
                            <tr>
                              <td
                                class="em-primary"
                                width="48"
                                height="48"
                                align="center"
                                valign="middle"
                                bgcolor={@p.primary}
                                style={"width:48px;height:48px;border-radius:14px;background-color:#{@p.primary};"}
                              >
                                {render_slot(@badge)}
                              </td>
                            </tr>
                          </table>
                        </td>
                      </tr>
                      <tr>
                        <td class="em-pad" style="padding:20px 32px 32px;">
                          <p :if={@eyebrow} style="margin:0 0 12px;">
                            <span
                              class="em-soft"
                              style={"display:inline-block;padding:3px 9px;border-radius:5px;background-color:#{@p.soft};color:#{@p.primary_text};font-family:#{@inter};font-size:11px;line-height:16px;font-weight:600;letter-spacing:.07em;text-transform:uppercase;"}
                            >
                              {@eyebrow}
                            </span>
                          </p>
                          <h2
                            class="em-ink em-title"
                            style={"margin:0 0 14px;color:#{@p.ink};font-family:#{@sans};font-size:22px;line-height:1.3;font-weight:600;letter-spacing:-.01em;"}
                          >
                            {@title}
                          </h2>
                          {render_slot(@body)}
                          <.button_row
                            :for={action <- @action}
                            action={action}
                            p={@p}
                            sans={@sans}
                            alt_text={@alt_text}
                          />
                          <.note :for={note <- @note} note={note} p={@p} sans={@sans} />
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr :if={@footer != []}>
                  <td style="height:16px;line-height:16px;font-size:1px;">&nbsp;</td>
                </tr>
                <tr :if={@footer != []}>
                  <td
                    class="em-panel"
                    bgcolor={@p.panel}
                    style={"padding:20px 24px;border-radius:12px;background-color:#{@p.panel};border:1px solid #{@p.hair};color:#{@p.muted};font-family:#{@sans};font-size:12.5px;line-height:1.6;"}
                  >
                    {render_slot(@footer)}
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end

  attr :action, :any, required: true
  attr :p, :map, required: true
  attr :sans, :string, required: true
  attr :alt_text, :string, required: true

  defp button_row(assigns) do
    assigns = assign(assigns, href: safe_url(assigns.action.href))

    ~H"""
    <table role="presentation" border="0" cellpadding="0" cellspacing="0" style="margin:22px 0 4px;">
      <tr>
        <td
          class="em-primary"
          align="center"
          bgcolor={@p.primary}
          style={"border-radius:9px;background-color:#{@p.primary};"}
        >
          <a
            href={@href}
            target="_blank"
            style={"display:inline-block;padding:12px 22px;border-radius:9px;color:#ffffff;font-family:#{@sans};font-size:14.5px;line-height:22px;font-weight:500;letter-spacing:.01em;text-decoration:none;"}
          >
            {render_slot(@action)}&nbsp;&nbsp;&rarr;
          </a>
        </td>
      </tr>
    </table>
    <p
      class="em-muted"
      style={"margin:16px 0 0;color:#{@p.muted};font-family:#{@sans};font-size:12px;line-height:1.6;"}
    >
      {@alt_text}<br />
      <a
        href={@href}
        class="em-accent"
        style={"color:#{@p.primary_text};text-decoration:underline;word-break:break-all;"}
      >{@href}</a>
    </p>
    """
  end

  attr :note, :any, required: true
  attr :p, :map, required: true
  attr :sans, :string, required: true

  defp note(assigns) do
    assigns = assign(assigns, icon: icon_url(assigns.note))

    ~H"""
    <table
      role="presentation"
      width="100%"
      border="0"
      cellpadding="0"
      cellspacing="0"
      class="em-panel"
      bgcolor={@p.panel}
      style={"margin:22px 0 0;border-collapse:separate;border-radius:10px;background-color:#{@p.panel};border:1px solid #{@p.hair};"}
    >
      <tr>
        <td
          :if={@icon}
          valign="top"
          width="16"
          style="width:16px;padding:14px 0 0 14px;line-height:0;font-size:0;"
        >
          <img
            src={@icon}
            width="16"
            height="16"
            alt=""
            style="display:block;width:16px;height:16px;"
          />
        </td>
        <td
          class="em-muted"
          style={"padding:12px 14px;color:#{@p.muted};font-family:#{@sans};font-size:12.5px;line-height:1.6;"}
        >
          {render_slot(@note)}
        </td>
      </tr>
    </table>
    """
  end

  @doc "A paragraph of the body, styled for the e-mail. Give the same `theme` as the layout when it is fixed."
  attr :theme, :atom, default: :auto, values: [:auto, :light, :dark]
  attr :rest, :global
  slot :inner_block, required: true

  def email_p(assigns) do
    assigns = assign(assigns, p: palette(assigns.theme), sans: @sans)

    ~H"""
    <p
      class="em-body"
      style={"margin:0 0 12px;color:#{@p.body};font-family:#{@sans};font-size:14.5px;line-height:1.65;"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  A verification code, one box per character.

      <.email_code value="482913" hint="Or sign in with one tap:" />
  """
  attr :value, :string, required: true
  attr :hint, :string, default: nil
  attr :theme, :atom, default: :auto, values: [:auto, :light, :dark]

  def email_code(assigns) do
    assigns =
      assign(assigns,
        p: palette(assigns.theme),
        chars: String.graphemes(assigns.value),
        mono: @mono,
        sans: @sans
      )

    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      aria-label={@value}
      style="margin:20px 0 6px -4px;border-collapse:separate;border-spacing:4px 0;"
    >
      <tr>
        <td
          :for={char <- @chars}
          class="em-panel em-ink"
          align="center"
          valign="middle"
          width="44"
          height="54"
          bgcolor={@p.panel}
          style={"width:44px;height:54px;border:1px solid #{@p.hair};border-radius:10px;background-color:#{@p.panel};color:#{@p.ink};font-family:#{@mono};font-size:24px;line-height:54px;font-weight:600;text-align:center;"}
        >
          {char}
        </td>
      </tr>
    </table>
    <p
      :if={@hint}
      class="em-muted"
      style={"margin:0 0 4px;color:#{@p.muted};font-family:#{@sans};font-size:12.5px;"}
    >
      {@hint}
    </p>
    """
  end

  @doc """
  Rows of label and value in a panel. A row is `{label, value}`, or `{label, value, :mono}` for a code or a
  tracking number, or `{label, value, :total}` for the highlighted last line.

      <.email_facts rows={[{"Estimate", "Thu, Oct 29"}, {"Tracking", "BR482913077XY", :mono}, {"Total", "R$ 1.284,90", :total}]} />
  """
  attr :rows, :list, required: true
  attr :theme, :atom, default: :auto, values: [:auto, :light, :dark]

  def email_facts(assigns) do
    assigns =
      assign(assigns,
        p: palette(assigns.theme),
        sans: @sans,
        mono: @mono,
        rows: Enum.map(assigns.rows, &fact/1)
      )

    ~H"""
    <table
      role="presentation"
      width="100%"
      border="0"
      cellpadding="0"
      cellspacing="0"
      class="em-panel"
      bgcolor={@p.panel}
      style={"margin:18px 0 4px;border-collapse:separate;border:1px solid #{@p.hair};border-radius:10px;background-color:#{@p.panel};"}
    >
      <tr :for={{row, index} <- Enum.with_index(@rows)}>
        <td
          class={["em-line", row.kind == :total && "em-soft"]}
          valign="top"
          style={"padding:10px 14px;#{rule(index, @p)}#{total(row.kind, @p)}color:#{(row.kind == :total && @p.primary_text) || @p.muted};font-family:#{@sans};font-size:13px;line-height:1.5;#{(row.kind == :total && "font-weight:600;") || ""}"}
        >
          {row.label}
        </td>
        <td
          class={["em-line", row.kind == :total && "em-soft"]}
          align="right"
          valign="top"
          style={"padding:10px 14px;#{rule(index, @p)}#{total(row.kind, @p)}color:#{(row.kind == :total && @p.primary_text) || @p.ink};font-family:#{(row.kind == :mono && @mono) || @sans};font-size:#{(row.kind == :mono && "12px") || "13px"};line-height:1.5;font-weight:#{(row.kind == :total && "600") || "500"};text-align:right;word-break:break-all;"}
        >
          {row.value}
        </td>
      </tr>
    </table>
    """
  end

  defp fact({label, value}), do: %{label: label, value: value, kind: :plain}
  defp fact({label, value, kind}), do: %{label: label, value: value, kind: kind}

  defp rule(0, _p), do: ""
  defp rule(_index, p), do: "border-top:1px solid #{p.hair};"

  defp total(:total, p), do: "background-color:#{p.soft};"
  defp total(_kind, _p), do: ""

  @doc """
  A row of steps: `{label, done?}` pairs, in order. Done ones are filled with a check.

      <.email_steps steps={[{"Paid", true}, {"Shipped", true}, {"Delivered", false}]} />
  """
  attr :steps, :list, required: true
  attr :theme, :atom, default: :auto, values: [:auto, :light, :dark]

  def email_steps(assigns) do
    assigns =
      assign(assigns, p: palette(assigns.theme), sans: @sans, last: length(assigns.steps) - 1)

    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      width="100%"
      style="margin:18px 0 6px;"
    >
      <tr>
        <%= for {{label, done}, index} <- Enum.with_index(@steps) do %>
          <td align="center" valign="top" width="1" style="width:1%;white-space:nowrap;padding:0 4px;">
            <table role="presentation" border="0" cellpadding="0" cellspacing="0" align="center">
              <tr>
                <td
                  class={[done && "em-primary", !done && "em-panel"]}
                  align="center"
                  valign="middle"
                  width="22"
                  height="22"
                  bgcolor={(done && @p.primary) || @p.panel}
                  style={"width:22px;height:22px;border-radius:11px;background-color:#{(done && @p.primary) || @p.panel};border:1px solid #{(done && @p.primary) || @p.hair};color:#ffffff;font-family:#{@sans};font-size:12px;line-height:20px;text-align:center;"}
                >
                  {(done && "✓") || " "}
                </td>
              </tr>
            </table>
            <p
              class={["em-muted", done && "em-ink"]}
              style={"margin:6px 0 0;color:#{(done && @p.ink) || @p.muted};font-family:#{@sans};font-size:11.5px;line-height:1.3;font-weight:500;"}
            >
              {label}
            </p>
          </td>
          <td :if={index < @last} valign="top" style="padding-top:11px;">
            <div
              class={[
                Enum.at(@steps, index + 1) |> elem(1) && "em-primary",
                !(Enum.at(@steps, index + 1) |> elem(1)) && "em-line"
              ]}
              style={"height:2px;line-height:2px;font-size:1px;background-color:#{(Enum.at(@steps, index + 1) |> elem(1)) && @p.primary || @p.hair};"}
            >
              &nbsp;
            </div>
          </td>
        <% end %>
      </tr>
    </table>
    """
  end

  defp palette(:dark), do: @dark
  defp palette(_theme), do: @light

  defp scheme(:auto), do: "light dark"
  defp scheme(:dark), do: "dark"
  defp scheme(_theme), do: "light"

  defp hero_image(p) do
    "linear-gradient(180deg,#{p.card_clear} 0%,#{p.card} 100%)," <>
      "linear-gradient(#{p.grid} 1px,transparent 1px),linear-gradient(90deg,#{p.grid} 1px,transparent 1px)"
  end

  defp dark_css(:auto) do
    p = @dark

    rules = [
      {"body,.em-canvas", "background-color:#{p.canvas} !important"},
      {".em-card", "background-color:#{p.card} !important;border-color:#{p.hair} !important"},
      {".em-hero",
       "background-color:#{p.card} !important;background-image:#{hero_image(p)} !important"},
      {".em-ink", "color:#{p.ink} !important"},
      {".em-body", "color:#{p.body} !important"},
      {".em-muted", "color:#{p.muted} !important"},
      {".em-accent", "color:#{p.primary_text} !important"},
      {".em-soft", "background-color:#{p.soft} !important;color:#{p.primary_text} !important"},
      {".em-panel", "background-color:#{p.panel} !important;border-color:#{p.hair} !important"},
      {".em-line", "border-color:#{p.hair} !important"},
      {".em-primary",
       "background-color:#{p.primary} !important;border-color:#{p.primary} !important"},
      {".em-logo-light", "display:none !important"},
      {".em-logo-dark", "display:block !important;max-height:none !important"}
    ]

    "@media (prefers-color-scheme:dark){" <>
      Enum.map_join(rules, "", fn {selector, css} -> "#{selector}{#{css}}" end) <> "}"
  end

  defp dark_css(_theme), do: ""

  defp safe_url("https://" <> _ = url), do: url
  defp safe_url("http://" <> _ = url), do: url
  defp safe_url(_url), do: "#"

  defp icon_url(%{icon: "https://" <> _ = url}), do: url
  defp icon_url(%{icon: "http://" <> _ = url}), do: url
  defp icon_url(_note), do: nil
end
