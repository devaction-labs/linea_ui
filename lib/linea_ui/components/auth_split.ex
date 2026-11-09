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
    assigns = assign(assigns, :has_aside, assigns.src != nil or assigns.art != [] or assigns.aside != [])

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
            <LineaUI.Components.Divider.divider :if={@providers != []}>{@divider_label}</LineaUI.Components.Divider.divider>
            {render_slot(@inner_block)}
            <p :if={@footer != []} class="linea-auth-foot">{render_slot(@footer)}</p>
          </div>
        </section>

        <aside :if={@has_aside} class="linea-auth-aside">
          {render_slot(@aside)}
          <img :if={@aside == [] and @src && @art == []} src={@src} alt={@alt} />
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
                <svg :for={n <- 1..5} viewBox="0 0 24 24" class={n > quote.rating && "off"} aria-hidden="true">
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
      <.icon :if={@icon_name && @icon == []} name={@icon_name} />{render_slot(@icon)}{render_slot(@inner_block)}
    </a>
    <button :if={!@href} type="button" class={merge(["linea-oauth", @class])} {@rest}>
      <.icon :if={@icon_name && @icon == []} name={@icon_name} />{render_slot(@icon)}{render_slot(@inner_block)}
    </button>
    """
  end
end
