defmodule LineaUI.Components.ErrorPage do
  @moduledoc """
  The canvas's error screens: the whole page an `ErrorHTML` renders (404, 500, 403, 401/419, 429, 503 and offline)
  and the error inside the app, under the shell.

      <.error_page code={404} request_id={@request_id}>
        <:brand><img src={~p"/images/logo.svg"} class="size-8.5" /> <b>Acme</b></:brand>
        <:status href="https://status.acme.com">All systems operational</:status>
        <:actions>
          <.button navigate={~p"/"} color="primary" size="lg">Back home</.button>
        </:actions>
        <.error_links title="Maybe you were looking for">
          <:link navigate={~p"/orders"} icon="huge-invoice-01" description="Every order">Orders</:link>
        </.error_links>
        <:card>Orders with a similar number…</:card>
        <:footer><a href="/help">Help center</a></:footer>
      </.error_page>

      <.error_state code={404} title="Order #2499 not found">
        It may have been deleted or belong to another branch.
        <:actions><.button navigate={~p"/orders"} color="primary">See every order</.button></:actions>
      </.error_state>

  `code` is the HTTP status (an integer or text, `"OFF"` for offline). It picks the color of the big code
  (`tone`: `neutral` for 404, `error` for 5xx, `warning` for 403, 429 and offline, `accent` for 401, 419 and 503)
  and the English defaults of `label` (`error_page`), `title` and `description` (and of the `error_state` icon), all of which
  you pass translated.

  ## The page

  On the left, the code and its label, the title, the description, the `actions` and the inner block (the
  canvas puts `error_links/1` or an `alert` there). On the right, the dotted panel with rings, the code in
  230px mono fading down and the `card` slot floating over it (a search with similar records, the log line of
  a 500, the permissions of a 403...). On top, the `brand` and the `status` link (a dot in the color of
  `status`: `ok`, `warning` or `down`); at the bottom the `request_id` with a copy button, the `timestamp`
  and the `footer` (help links). Under 1100px the panel goes below the text; on a phone it is hidden.

  It is a whole page: render it as the `ErrorHTML` template, with the root layout that loads the CSS
  (`render_errors: [formats: [html: MyAppWeb.ErrorHTML], root_layout: {MyAppWeb.Layouts, :root}]`).
  The styles are `canvas-error-page.css` (`sg-err`).
  """

  use LineaUI.Component

  import LineaUI.Components.Icon, only: [icon: 1]

  @defaults %{
    "400" =>
      {"neutral", "Bad request", "That request didn't make sense.",
       "Something in the address or the form was not what we expected. Go back and try again.",
       "huge-alert-02"},
    "401" =>
      {"accent", "Session expired", "Your session expired.",
       "For security, you were signed out after a while without use. Sign in again to carry on where you left off.",
       "huge-square-lock-02"},
    "403" =>
      {"warning", "Access denied", "You don't have access to this area.",
       "Ask whoever manages the account to give you access; you will be told when it is granted.",
       "huge-square-lock-02"},
    "404" =>
      {"neutral", "Page not found", "We couldn't find this page.",
       "The address may have been mistyped, or the record was deleted or moved.",
       "huge-search-01"},
    "419" =>
      {"accent", "Session expired", "Your session expired.",
       "For security, you were signed out after a while without use. Sign in again to carry on where you left off.",
       "huge-square-lock-02"},
    "422" =>
      {"warning", "Unprocessable", "We couldn't process this.",
       "The data sent could not be used. Check it and try again.", "huge-alert-02"},
    "429" =>
      {"warning", "Too many requests", "Easy, that was too fast.",
       "We got many actions in a row from this account. Access comes back by itself in a few seconds.",
       "huge-clock-01"},
    "500" =>
      {"error", "Internal error", "Something went wrong on our side.",
       "Nothing you did caused this. The team got the error report and your data is safe; try again in a moment.",
       "huge-alert-02"},
    "502" =>
      {"error", "Bad gateway", "Something went wrong on our side.",
       "A service we depend on did not answer properly. Try again in a moment.", "huge-alert-02"},
    "503" =>
      {"accent", "Under maintenance", "We'll be right back.",
       "We are updating the system. Try again in a few minutes.", "huge-clock-01"},
    "504" =>
      {"error", "Timeout", "That took too long.",
       "A service we depend on took too long to answer. Try again in a moment.", "huge-clock-01"},
    "OFF" =>
      {"warning", "No connection", "You are offline.",
       "The internet connection was lost. Try again when the network is back.",
       "huge-wifi-off-01"}
  }

  @doc "The defaults of the code: `{tone, label, title, description, icon}`."
  def defaults(code) do
    key = code |> to_string() |> String.upcase()
    Map.get(@defaults, key) || fallback(key)
  end

  defp fallback("5" <> _), do: @defaults["500"]
  defp fallback(_key), do: @defaults["400"]

  defp put_defaults(assigns) do
    {tone, _label, title, description, _icon} = defaults(assigns.code)

    assigns
    |> assign(:tone, assigns.tone || tone)
    |> assign(:title, assigns.title || title)
    |> assign(:description, assigns.description || description)
  end

  @doc """
  Renders the whole error page.
  """
  attr :code, :any, required: true, doc: "The HTTP status (`404`) or a short text (`\"OFF\"`)."

  attr :tone, :string,
    default: nil,
    values: [nil, "neutral", "error", "warning", "accent"],
    doc: "The color of the code; by `code` when `nil`."

  attr :label, :string, default: nil, doc: "The words after the code chip (`Page not found`)."
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :request_id, :string, default: nil, doc: "Shown in the footer with a copy button."
  attr :request_id_label, :string, default: "Request ID"
  attr :copy_label, :string, default: "Copy request ID"

  attr :copy, :boolean,
    default: true,
    doc:
      "A copy button by the request id. It is a `LineaUI.Clipboard` hook, so it copies inside a LiveView; on a plain `ErrorHTML` page a click on the id selects it whole."

  attr :timestamp, :string, default: nil, doc: "When it happened, as text, after the request id."
  attr :id, :string, default: "error-page"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :brand, doc: "The logo and the name, top left."

  slot :status, doc: "The link to the status page, top right." do
    attr :href, :string
    attr :status, :string, doc: "`ok` (default, green), `warning` or `down`."
  end

  slot :actions, doc: "The buttons under the description."
  slot :inner_block, doc: "Under the actions: `error_links/1`, an alert, a note."
  slot :card, doc: "The card floating over the big code."
  slot :footer, doc: "The links at the right end of the footer."

  def error_page(assigns) do
    {_tone, label, _title, _description, _icon} = defaults(assigns.code)

    assigns =
      assigns
      |> put_defaults()
      |> assign(:label, assigns.label || label)

    ~H"""
    <div id={@id} class={merge(["sg-err", @class])} data-tone={@tone} {@rest}>
      <header class="sg-err-top">
        {render_slot(@brand)}
        <a
          :for={status <- @status}
          href={status[:href]}
          class="sg-err-status"
          data-status={status[:status] || "ok"}
        >
          <i aria-hidden="true"></i>{render_slot(status)}
          <.icon :if={status[:href]} name="huge-arrow-right-01" />
        </a>
      </header>

      <main class="sg-err-main">
        <div class="sg-err-text">
          <span class="sg-err-label"><span class="sg-err-code">{@code}</span>{@label}</span>
          <h1 class="sg-err-title">{@title}</h1>
          <p :if={@description} class="sg-err-desc">{@description}</p>
          <div :if={@actions != []} class="sg-err-actions">{render_slot(@actions)}</div>
          {render_slot(@inner_block)}
        </div>
        <div class="sg-err-art" aria-hidden={@card == [] && "true"}>
          <svg class="sg-err-rings" viewBox="0 0 600 600" aria-hidden="true">
            <circle :for={r <- [90, 150, 210, 270]} cx="300" cy="300" r={r} />
          </svg>
          <div class="sg-err-digits" aria-hidden="true">{@code}</div>
          <div :if={@card != []} class="sg-err-card">{render_slot(@card)}</div>
        </div>
      </main>

      <footer :if={@request_id || @timestamp || @footer != []} class="sg-err-foot">
        <span :if={@request_id} class="rid">
          {@request_id_label} <code id={"#{@id}-rid"}>{@request_id}</code>
          <LineaUI.Components.Clipboard.clipboard
            :if={@copy}
            id={"#{@id}-copy"}
            from={"##{@id}-rid"}
            icon_only
            variant="flat"
            size="xs"
            toast={nil}
            aria-label={@copy_label}
          />
        </span>
        <span :if={@timestamp}>{@timestamp}</span>
        <span :if={@footer != []} class="end">{render_slot(@footer)}</span>
      </footer>
    </div>
    """
  end

  @doc """
  Renders the error inside the app: the code (150px) with the icon tile on it, the title, the description,
  the actions and the inner block under them (a table of recent records, an alert), centered.
  """
  attr :code, :any, required: true
  attr :tone, :string, default: nil, values: [nil, "neutral", "error", "warning", "accent"]
  attr :icon, :string, default: nil, doc: "A `huge-*` icon for the tile; by `code` when `nil`."
  attr :title, :string, default: nil
  attr :description, :string, default: nil

  attr :id, :string,
    default: nil,
    doc: "Derives the id of the title (`\"\#{id}-title\"`); `err-<code>-title` when `nil`."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, doc: "The description, instead of `description`."
  slot :actions
  slot :more, doc: "Under the actions, full width."

  def error_state(assigns) do
    {_tone, _label, _title, _description, icon} = defaults(assigns.code)

    assigns =
      assigns
      |> put_defaults()
      |> assign(:icon, assigns.icon || icon)
      |> assign(
        :title_id,
        if(assigns.id, do: "#{assigns.id}-title", else: "err-#{assigns.code}-title")
      )

    ~H"""
    <section
      id={@id}
      class={merge(["sg-err-state", @class])}
      data-tone={@tone}
      aria-labelledby={@title_id}
      {@rest}
    >
      <div class="in">
        <div class="mark">
          <div class="sg-err-digits" aria-hidden="true">{@code}</div>
          <span class="tile" aria-hidden="true"><.icon name={@icon} /></span>
        </div>
        <h1 id={@title_id}>{@title}</h1>
        <p :if={@inner_block != []}>{render_slot(@inner_block)}</p>
        <p :if={@inner_block == [] and @description}>{@description}</p>
        <div :if={@actions != []} class="sg-err-actions">{render_slot(@actions)}</div>
        <div :if={@more != []} class="more">{render_slot(@more)}</div>
      </div>
    </section>
    """
  end

  @doc """
  The list of links under the actions of an error page: a faint title and rows with an icon tile, a label,
  a line of description and a chevron.

      <.error_links title="Who can grant it">
        <:link href="mailto:alex@acme.com" icon="huge-user" description="Account admin">Alex Nogueira</:link>
      </.error_links>
  """
  attr :title, :string, default: nil
  attr :class, :any, default: nil

  slot :link, required: true do
    attr :href, :string
    attr :navigate, :string
    attr :icon, :string
    attr :description, :string
  end

  def error_links(assigns) do
    ~H"""
    <nav class={merge(["sg-err-links", @class])} aria-label={@title}>
      <span :if={@title} class="h">{@title}</span>
      <.link :for={link <- @link} href={link[:href]} navigate={link[:navigate]}>
        <span :if={link[:icon]} class="ic"><.icon name={link.icon} /></span>
        <span class="t">
          <b>{render_slot(link)}</b>
          <span :if={link[:description]}>{link.description}</span>
        </span>
        <.icon name="huge-arrow-right-01" class="chev" />
      </.link>
    </nav>
    """
  end
end
