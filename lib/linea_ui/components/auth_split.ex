defmodule LineaUI.Components.AuthSplit do
  @moduledoc """
  The canvas sign in and sign up screen in two halves: the form on the left (brand in the corner, a soft glow
  at the top, the title, the subtitle, the form and a line under it) and, on the right, a picture filling its
  half with a testimonial over its lower part.

      <.auth_split title="Criar conta" subtitle="Preencha seus dados para criar a conta." src={~p"/images/auth.jpg"}>
        <:brand><img src={~p"/images/logo.svg"} class="size-7" /> Acme</:brand>
        <:providers>
          <.oauth_button provider="google" href={~p"/auth/google"}>Google</.oauth_button>
          <.oauth_button provider="apple" href={~p"/auth/apple"}>Apple</.oauth_button>
        </:providers>
        <.form for={@form} phx-submit="save">…</.form>
        <:quote author="Marina Costa" role="Gerente, Loja Bom Fim" rating={5}>
          Em uma semana a equipe inteira estava usando.
        </:quote>
        <:footer>Já tem conta? <.link navigate={~p"/users/log-in"}>Entrar</.link></:footer>
      </.auth_split>

  The picture is `src` or the `:art` slot (`<.summit />`); without either and without `:aside`, the form takes
  the whole card. `:quote` lays the testimonial over the picture (`author`, `role`, `rating` from 0 to 5);
  `:aside` replaces the whole right half. `:providers` puts the sign in buttons (`oauth_button/1`) in a row
  above the inner block, with `divider_label` between them and the form. `variant`: `card` (default, floating
  on the dotted canvas) or `full` (the whole screen). `glow={false}` takes the glow away. Under 1024px the
  right half goes away. Styles: `canvas-auth-split.css` (`linea-auth`).

  The three other states of the screen, as in the canvas:

      <%!-- Link sent: the step after "sign in with a link" --%>
      <.auth_split title="Confira o seu e-mail" subtitle="Mandamos um link para marina@acme.com.">
        <.auth_sent>Abra o e-mail no mesmo aparelho e toque em <b>Entrar</b>.</.auth_sent>
        <.button disabled class="w-full" size="lg">Reenviar em 0:42</.button>
      </.auth_split>

      <%!-- With errors: the notice on top of the form; each field shows its own errors --%>
      <.auth_alert>Não deu para criar a conta. Corrija os campos marcados.</.auth_alert>
      <.input field={@form[:email]} label="E-mail" />

      <%!-- Sending: the submit button disables itself and shows the spinner --%>
      <.auth_submit loading={@saving} loading_label="Criando a conta…">Cadastrar</.auth_submit>
  """

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [icon: 1]

  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :src, :string, default: nil, doc: "The picture of the right half."
  attr :alt, :string, default: ""
  attr :variant, :string, default: "card", values: ~w(card full)
  attr :glow, :boolean, default: true
  attr :divider_label, :string, default: "Or", doc: "Between the providers and the form."
  attr :brand_href, :string, default: "/"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :brand, doc: "The logo and the name, top left."
  slot :providers, doc: "The `oauth_button/1`s, in a row above the form."
  slot :inner_block, required: true, doc: "The form."
  slot :footer, doc: "The line under the form (\"Already have an account? Sign in\")."
  slot :art, doc: "The picture as markup, instead of `src`."

  slot :quote, doc: "A testimonial over the picture." do
    attr :author, :string
    attr :role, :string
    attr :rating, :integer
  end

  slot :aside, doc: "Replaces the right half."

  def auth_split(assigns) do
    assigns =
      assign(assigns, :has_aside, assigns.src != nil or assigns.art != [] or assigns.aside != [])

    ~H"""
    <div
      class={merge(["linea-auth", @class])}
      data-variant={@variant}
      data-glow={to_string(@glow)}
      data-aside={if @has_aside, do: "picture", else: "none"}
      {@rest}
    >
      <div class="linea-auth-card">
        <section class="linea-auth-form">
          <a :if={@brand != []} href={@brand_href} class="linea-auth-brand">{render_slot(@brand)}</a>
          <div class="linea-auth-body">
            <header class="linea-auth-head">
              <h1 class="linea-auth-title">{@title}</h1>
              <p :if={@subtitle} class="linea-auth-sub">{@subtitle}</p>
            </header>
            <div :if={@providers != []} class="linea-auth-providers">{render_slot(@providers)}</div>
            <div :if={@providers != []} class="sg-divider" role="separator">{@divider_label}</div>
            {render_slot(@inner_block)}
            <p :if={@footer != []} class="linea-auth-foot">{render_slot(@footer)}</p>
          </div>
        </section>

        <aside :if={@has_aside} class="linea-auth-aside">
          {render_slot(@aside)}
          <img :if={(@aside == [] and @src) && @art == []} src={@src} alt={@alt} />
          <div :if={@aside == [] and @art != []} class="art">{render_slot(@art)}</div>
          <figure :for={quote <- @quote} :if={@aside == []} class="linea-auth-quote">
            <blockquote>{render_slot(quote)}</blockquote>
            <figcaption>
              <span
                :if={quote[:rating]}
                class="linea-auth-stars"
                role="img"
                aria-label={"#{quote.rating} / 5"}
              >
                <svg
                  :for={n <- 1..5}
                  viewBox="0 0 24 24"
                  class={n > quote.rating && "off"}
                  aria-hidden="true"
                >
                  <path d="M12 2.5l2.9 6.1 6.6.8-4.9 4.6 1.3 6.6L12 17.3l-5.9 3.3 1.3-6.6-4.9-4.6 6.6-.8z" />
                </svg>
              </span>
              <span :if={quote[:author]} class="linea-auth-who">
                <b>{quote.author}</b>
                <span :if={quote[:role]}>{quote.role}</span>
              </span>
            </figcaption>
          </figure>
        </aside>
      </div>
    </div>
    """
  end

  @providers %{"google" => "huge-google", "apple" => "huge-apple", "github" => "huge-github"}

  @doc """
  A sign in button for an identity provider: the provider's icon and the label, as a link (`href`) or a button.

      <.oauth_button provider="google" href={~p"/auth/google"}>Google</.oauth_button>

  `provider` is `google`, `apple` or `github` (their Hugeicons line icons); for another one leave it out and
  pass the icon in `:icon`.
  """
  attr :provider, :string, default: nil, values: [nil, "google", "apple", "github"]
  attr :href, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(type disabled form name value)

  slot :icon
  slot :inner_block, required: true

  def oauth_button(assigns) do
    assigns = assign(assigns, :icon_name, @providers[assigns.provider])

    ~H"""
    <a :if={@href} href={@href} class={merge(["linea-oauth", @class])} {@rest}>
      <.icon :if={@icon_name && @icon == []} name={@icon_name} />{render_slot(@icon)}{render_slot(
        @inner_block
      )}
    </a>
    <button :if={!@href} type="button" class={merge(["linea-oauth", @class])} {@rest}>
      <.icon :if={@icon_name && @icon == []} name={@icon_name} />{render_slot(@icon)}{render_slot(
        @inner_block
      )}
    </button>
    """
  end

  @doc """
  The "link sent" block: a tile with a mail icon and the message beside it. Announced politely
  (`role="status"`).

      <.auth_sent>Abra o e-mail no mesmo aparelho e toque em <b>Entrar</b>.</.auth_sent>
  """
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon, doc: "Replaces the mail icon."
  slot :inner_block, required: true

  def auth_sent(assigns) do
    ~H"""
    <div class={merge(["linea-auth-sent", @class])} role="status" {@rest}>
      <span class="tile">
        {render_slot(@icon)}
        <svg :if={@icon == []} viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path
            d="M2 6L8.91302 9.91697C11.4616 11.361 12.5384 11.361 15.087 9.91697L22 6"
            stroke="currentColor"
            stroke-linejoin="round"
            stroke-width="1.5"
          />
          <path
            d="M2.01577 13.4756C2.08114 16.5412 2.11383 18.0739 3.24496 19.2094C4.37608 20.3448 5.95033 20.3843 9.09883 20.4634C11.0393 20.5122 12.9607 20.5122 14.9012 20.4634C18.0497 20.3843 19.6239 20.3448 20.7551 19.2094C21.8862 18.0739 21.9189 16.5412 21.9842 13.4756C22.0053 12.4899 22.0053 11.5101 21.9842 10.5244C21.9189 7.45886 21.8862 5.92609 20.7551 4.79066C19.6239 3.65523 18.0497 3.61568 14.9012 3.53657C12.9607 3.48781 11.0393 3.48781 9.09882 3.53656C5.95033 3.61566 4.37608 3.65521 3.24495 4.79065C2.11382 5.92608 2.08114 7.45885 2.01576 10.5244C1.99474 11.5101 1.99475 12.4899 2.01577 13.4756Z"
            stroke="currentColor"
            stroke-linejoin="round"
            stroke-width="1.5"
          />
        </svg>
      </span>
      <span>{render_slot(@inner_block)}</span>
    </div>
    """
  end

  @doc """
  The notice on top of a form with errors: a cross icon and the message (`role="alert"`).

      <.auth_alert>Não deu para criar a conta. Corrija os campos marcados.</.auth_alert>
  """
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def auth_alert(assigns) do
    ~H"""
    <div class={merge(["linea-auth-alert", @class])} role="alert" {@rest}>
      <svg class="i sm" viewBox="0 0 24 24" aria-hidden="true">
        <path d="M18.9991 19L5 5.00098" />
        <path d="M19 5L5.00092 18.999" />
      </svg>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The form's submit button, full width and accent. With `loading` it disables itself (no double submit),
  sets `aria-busy` and shows the spinner before the label; change the label to say what is going on.

      <.auth_submit loading={@saving} loading_label="Criando a conta…">Cadastrar</.auth_submit>

  `loading_label` is the label while loading (the inner block when left out).
  """
  attr :loading, :boolean, default: false
  attr :loading_label, :string, default: nil, doc: "The label while `loading`."
  attr :type, :string, default: "submit"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def auth_submit(assigns) do
    ~H"""
    <button
      type={@type}
      class={merge(["sg-btn accent lg block", @loading && "is-loading", @class])}
      disabled={@loading || nil}
      aria-busy={@loading && "true"}
      {@rest}
    >
      <span :if={@loading} class="linea-auth-spin" aria-hidden="true"></span>
      {if @loading && @loading_label, do: @loading_label, else: render_slot(@inner_block)}
    </button>
    """
  end
end
