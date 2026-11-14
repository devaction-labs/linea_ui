defmodule LineaUI.Components.Navbar do
  @moduledoc """
  The app top bar of the canvas "Navbar" board: one container, `navbar/1`, and small pieces to put in it. The right
  side is always the same vocabulary (search, notifications, theme, language and the user); the variants change what
  goes on the left and the visual weight.

      <.navbar>
        <.navbar_crumbs items={[%{label: "Início", navigate: ~p"/"}, %{label: "Projetos", navigate: ~p"/projetos"}, %{label: "Site novo"}]} />
        <:end>
          <.navbar_search placeholder="Buscar ou ir para…" phx-click={JS.exec("data-show", to: "#palette")} />
          <.navbar_bell dot />
          <.theme_switch id="theme" variant="icons" size="sm" />
          <.navbar_lang locales={["PT", "EN"]} current="PT" />
          <.navbar_sep />
          <.navbar_user id="me" user={@user}>
            <:menu>
              <.navbar_menu_head user={@user}><:badge><.badge color="primary">Admin</.badge></:badge></.navbar_menu_head>
              <.navbar_menu_item icon="huge-user" navigate={~p"/perfil"}>Perfil</.navbar_menu_item>
              <hr />
              <.navbar_menu_item icon="huge-logout-01" danger href={~p"/sair"} method="delete">Sair</.navbar_menu_item>
            </:menu>
          </.navbar_user>
        </:end>
      </.navbar>

  `variant` is `"default"` (60px, a line under it), `"float"` (a frosted pill detached from the top, for apps with no
  side menu), `"clear"` (transparent, over a hero or a cover; the icon buttons get a glass background), `"dense"` (44px)
  or `"mobile"` (56px: menu, title, bell and user). The slots are `inner_block` (the left side), `:center` (between the
  two, such as `navbar_links/1` or a wide `navbar_search/1`), `:end` (the right side) and `:tabs`, which makes the bar two
  rows: the content on top and the tabs (`navbar_tabs/1`) under it.

  ## Your own components in the bar

  The pieces are optional: `:center` and `:end` take any markup, in the same `.sg-nb-end` wrapper, so an app can
  put a `live_component` (the ⌘K palette, the notifications bell, the account menu) in place of `navbar_search/1`,
  `navbar_bell/1` and `navbar_user/1` and the bar keeps the same markup around it:

      <.navbar>
        <.navbar_crumbs items={@crumbs} />
        <:center><.live_component module={MyAppWeb.PaletteTrigger} id="palette" /></:center>
        <:end>
          <.live_component module={MyAppWeb.BellLive} id="bell" user={@user} />
          <.live_component module={MyAppWeb.AccountMenu} id="me" user={@user} />
        </:end>
      </.navbar>

  Inside the `:topbar` slot of `shell/1` it is the top of the page:

      <.shell nav={...} user={@user} footer="version">
        <:topbar><.navbar>...</.navbar></:topbar>
      </.shell>

  ## The pieces

    * `navbar_brand/1`, `navbar_workspace/1`, `navbar_chip/1`, `navbar_slash/1` and `navbar_crumbs/1` are the left side.
    * `navbar_links/1`, `navbar_tabs/1` and `navbar_title/1` are the middle (and the tabs row).
    * `navbar_search/1`, `navbar_bell/1`, `navbar_icon/1`, `navbar_lang/1`, `navbar_sep/1`, `navbar_env/1`, `navbar_sync/1`
      and `navbar_avatars/1` are the right side. The theme choice is `theme_switch/1` (`variant="icons" size="sm"`), a
      button is `button/1`.
    * `navbar_user/1` is the avatar and, with the `:menu` slot, the account menu; `navbar_menu_head/1`,
      `navbar_menu_status/1`, `navbar_menu_row/1` and `navbar_menu_item/1` are what goes in it.

  Icons are Hugeicons: write each name in full (`huge-search-01`) so Tailwind sees it. Styles: `canvas-navbar.css`
  (`sg-nb`), inside a `.sg` root.
  """

  use LineaUI.Component

  alias LineaUI.Components.Sidebar.Nav

  import LineaUI.Components.Button, only: [button: 1]
  import LineaUI.Components.Icon, only: [icon: 1]

  @variants ~w(default float clear dense mobile)

  # --- the bar ----------------------------------------------------------------------------------------------

  attr :variant, :string, default: "default", values: @variants

  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, doc: "The left side."
  slot :center, doc: "Between the left and the right: `navbar_links/1`, a wide `navbar_search/1`."
  slot :end, doc: "The right side (inside `.sg-nb-end`)."
  slot :tabs, doc: "`navbar_tabs/1`: makes the bar two rows (`tall`)."

  def navbar(%{variant: "float"} = assigns) do
    assigns = assign_derived(assigns, :end_, [:end], fn -> assigns.end end)

    ~H"""
    <div class="sg-nb-floatwrap">
      <.bar
        variant={@variant}
        class={@class}
        id={@id}
        rest={@rest}
        inner={@inner_block}
        center={@center}
        end_slot={@end_}
        tabs={@tabs}
      />
    </div>
    """
  end

  def navbar(assigns) do
    assigns = assign_derived(assigns, :end_, [:end], fn -> assigns.end end)

    ~H"""
    <.bar
      variant={@variant}
      class={@class}
      id={@id}
      rest={@rest}
      inner={@inner_block}
      center={@center}
      end_slot={@end_}
      tabs={@tabs}
    />
    """
  end

  attr :variant, :string, required: true
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :map, default: %{}
  attr :inner, :list, default: []
  attr :center, :list, default: []
  attr :end_slot, :list, default: []
  attr :tabs, :list, default: []

  defp bar(assigns) do
    assigns =
      assign_derived(assigns, :classes, [:variant, :tabs, :class], fn ->
        merge([
          "sg-nb",
          variant_class(assigns.variant),
          assigns.tabs != [] && "tall",
          assigns.class
        ])
      end)

    ~H"""
    <header id={@id} class={@classes} {@rest}>
      <div :if={@tabs != []} class="sg-nb-row">
        {render_slot(@inner)}{render_slot(@center)}
        <div :if={@end_slot != []} class="sg-nb-end">{render_slot(@end_slot)}</div>
      </div>
      <%= if @tabs == [] do %>
        {render_slot(@inner)}{render_slot(@center)}
        <div :if={@end_slot != []} class="sg-nb-end">{render_slot(@end_slot)}</div>
      <% end %>
      {render_slot(@tabs)}
    </header>
    """
  end

  defp variant_class("float"), do: "float"
  defp variant_class("clear"), do: "clear"
  defp variant_class("dense"), do: "dense"
  defp variant_class("mobile"), do: "mob"
  defp variant_class(_variant), do: nil

  # --- the left side ----------------------------------------------------------------------------------------

  @doc """
  The logo and the name of the app.

      <.navbar_brand name="Linea" />
      <.navbar_brand name="Linea" logo="L" />
      <.navbar_brand name="Linea" src={~p"/images/logo.svg"} />
  """
  attr :name, :string, default: nil
  attr :logo, :string, default: nil, doc: "The letter in the logo (default: the first of `name`)."
  attr :src, :string, default: nil, doc: "A picture for the logo instead of the letter."
  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_brand(assigns) do
    assigns =
      assign_derived(assigns, :letter, [:logo, :name], fn ->
        assigns.logo || (assigns.name && assigns.name |> String.first() |> String.upcase())
      end)

    ~H"""
    <span class={merge(["row sg-nb-brandrow", @class])} {@rest}>
      <span class="sg-nb-logo" aria-hidden={@name && "true"}>
        <img :if={@src} src={@src} alt="" />
        <%= if !@src do %>
          {@letter}
        <% end %>
      </span>
      <b :if={@name} class="sg-nb-brand">{@name}</b>
    </span>
    """
  end

  @doc """
  The path to the page. Each item is `%{label: "...", navigate: path}` (or `href` / `patch`); the last one, the page
  itself, is bold, and an item with no link is plain text.

      <.navbar_crumbs items={[%{label: "Início", navigate: ~p"/"}, %{label: "Site novo"}]} />
  """
  attr :items, :list, required: true
  attr :label, :string, default: "Breadcrumb", doc: "The `aria-label` of the `nav`."
  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_crumbs(assigns) do
    assigns =
      assign_derived(assigns, :entries, [:items], fn -> crumb_entries(assigns.items) end)

    ~H"""
    <nav class={merge(["sg-nb-crumb", @class])} aria-label={@label} {@rest}>
      <%= for entry <- @entries do %>
        <span :if={!entry.first} class="sep" aria-hidden="true">/</span>
        <b :if={entry.last} aria-current="page">{entry.label}</b>
        <.link :if={!entry.last && entry.link} {entry.link}>{entry.label}</.link>
        <span :if={!entry.last && !entry.link}>{entry.label}</span>
      <% end %>
    </nav>
    """
  end

  defp crumb_entries(items) do
    last = length(items) - 1

    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      %{label: item.label, link: explicit_link(item), first: index == 0, last: index == last}
    end)
  end

  @doc """
  The workspace (company) switcher at the left of the bar: the logo, the name, a line under it and a chevron. It is a
  button: `phx-click` opens your menu. It brings its own `.sg-nb-start` column, which keeps a wide search centered.

      <.navbar_workspace name="Loja Bom Fim" sub="Plano Pro" phx-click={...} />
  """
  attr :name, :string, required: true
  attr :sub, :string, default: nil
  attr :logo, :string, default: nil, doc: "The letter (default: the first of `name`)."
  attr :src, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_workspace(assigns) do
    assigns =
      assign_derived(assigns, :letter, [:logo, :name], fn ->
        assigns.logo || assigns.name |> String.first() |> String.upcase()
      end)

    ~H"""
    <div class="sg-nb-start">
      <button type="button" class={merge(["sg-nb-ws", @class])} {@rest}>
        <span class="sg-nb-logo" aria-hidden="true">
          <img :if={@src} src={@src} alt="" />
          <%= if !@src do %>
            {@letter}
          <% end %>
        </span>
        <span class="col">
          <b>{@name}</b>
          <span :if={@sub}>{@sub}</span>
        </span>
        <.icon name="huge-arrow-down-01" class="i sm" />
      </button>
    </div>
    """
  end

  @doc """
  A selector in a path of selectors (organization, project): a colored square with a short text, the name, a tag and a
  chevron. A button: `phx-click` opens the list.

      <.navbar_slash /><.navbar_chip label="Loja Bom Fim" square="LB" color="#1a7f4b" tag="Pro" phx-click={...} />
  """
  attr :label, :string, required: true
  attr :square, :string, default: nil, doc: "The text in the square (2 or 3 letters)."
  attr :color, :string, default: nil, doc: "The CSS color of the square."
  attr :tag, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_chip(assigns) do
    ~H"""
    <button type="button" class={merge(["sg-nb-chip", @class])} {@rest}>
      <span :if={@square} class="sg-nb-sq" style={@color && "background:#{@color}"}>{@square}</span>
      <b>{@label}</b>
      <span :if={@tag} class="sg-nb-tag tag">{@tag}</span>
      <.icon name="huge-arrow-down-01" class="i sm" />
    </button>
    """
  end

  @doc "The `/` between two selectors."
  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_slash(assigns) do
    ~H"""
    <span class={merge(["sg-nb-slash", @class])} aria-hidden="true" {@rest}>/</span>
    """
  end

  # --- the middle -------------------------------------------------------------------------------------------

  @doc """
  The main links, centered. Each item is `%{label: "...", navigate: path, active: boolean}` (`href` / `patch` work
  too). The active one is the item with `active: true` or the one whose link equals `current`; it gets `on` and
  `aria-current="page"`.

      <.navbar_links current={@current_path} items={[%{label: "Início", navigate: ~p"/"}, %{label: "Projetos", navigate: ~p"/projetos"}]} />
  """
  attr :items, :list, required: true

  attr :current, :string,
    default: nil,
    doc: "The current path: the item with this link is the active one."

  attr :label, :string, default: nil, doc: "An `aria-label` for the `nav`."
  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_links(assigns) do
    assigns =
      assign_derived(assigns, :entries, [:items, :current], fn ->
        nav_entries(assigns.items, assigns.current)
      end)

    ~H"""
    <nav class={merge(["sg-nb-links", @class])} aria-label={@label} {@rest}>
      <.link
        :for={entry <- @entries}
        class={entry.on && "on"}
        aria-current={entry.on && "page"}
        {entry.link}
      >
        {entry.label}
      </.link>
    </nav>
    """
  end

  @doc """
  The tabs of the page, in the second row of a `tabs` bar. The items are those of `navbar_links/1` plus an optional
  `count`, a small mono number after the label.

      <:tabs><.navbar_tabs current={@current_path} items={[%{label: "Quadro", patch: ~p"/p/1"}, %{label: "Arquivos", patch: ~p"/p/1/files", count: 12}]} /></:tabs>
  """
  attr :items, :list, required: true
  attr :current, :string, default: nil
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_tabs(assigns) do
    assigns =
      assign_derived(assigns, :entries, [:items, :current], fn ->
        nav_entries(assigns.items, assigns.current)
      end)

    ~H"""
    <nav class={merge(["sg-nb-tabs", @class])} aria-label={@label} {@rest}>
      <.link
        :for={entry <- @entries}
        class={entry.on && "on"}
        aria-current={entry.on && "page"}
        {entry.link}
      >
        {entry.label}<span :if={entry.count} class="n">{entry.count}</span>
      </.link>
    </nav>
    """
  end

  @doc "The centered title of the mobile bar."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def navbar_title(assigns) do
    ~H"""
    <b class={merge(["sg-nb-mtitle", @class])} {@rest}>{render_slot(@inner_block)}</b>
    """
  end

  # --- the right side ---------------------------------------------------------------------------------------

  @doc """
  The search field of the bar. It is a trigger, not an input: a button that looks like one, whose `phx-click` opens the
  command palette. `wide` is the bigger one for the center of the bar; `width` is a CSS width.

      <.navbar_search placeholder="Buscar ou ir para…" phx-click={...} />
      <:center><.navbar_search wide placeholder="Buscar pedidos, clientes…" phx-click={...} /></:center>
  """
  attr :placeholder, :string, default: "Search"
  attr :kbd, :string, default: "⌘K", doc: "The shortcut shown at the end; `nil` hides it."
  attr :wide, :boolean, default: false
  attr :width, :string, default: nil, doc: "A CSS width (`\"240px\"`, `\"100%\"`)."
  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_search(assigns) do
    ~H"""
    <button
      type="button"
      class={merge(["sg-nb-search", @wide && "wide", @class])}
      style={@width && "width:#{@width}"}
      {@rest}
    >
      <.icon name="huge-search-01" class="i" />
      <span>{@placeholder}</span>
      <kbd :if={@kbd}>{@kbd}</kbd>
    </button>
    """
  end

  @doc """
  The notifications button; `dot` shows the orange dot of something unread. `phx-click` (or `navigate`/`href`) is yours.

      <.navbar_bell dot phx-click={...} />
  """
  attr :dot, :boolean, default: false, doc: "There is something unread."
  attr :label, :string, default: "Notifications"
  attr :size, :string, default: "md", values: ~w(md sm)
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch)

  def navbar_bell(assigns) do
    ~H"""
    <span class={merge(["sg-nb-bell", @class])}>
      <.button icon size={@size} aria-label={@label} {@rest}>
        <.icon name="huge-notification-03" class="i" />
      </.button>
      <i :if={@dot} aria-hidden="true"></i>
    </span>
    """
  end

  @doc """
  An icon button of the bar (search on a small screen, help, the menu of the mobile bar): the kit's round icon button
  with the icon you name. The label is its accessible name.

      <.navbar_icon name="huge-search-01" label="Buscar" phx-click={...} />
  """
  attr :name, :string, required: true, doc: "A Hugeicons name, written in full (`huge-menu-01`)."
  attr :label, :string, required: true
  attr :size, :string, default: "md", values: ~w(md sm)
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch)

  def navbar_icon(assigns) do
    ~H"""
    <.button icon size={@size} aria-label={@label} class={@class} {@rest}>
      <.icon name={@name} class="i" />
    </.button>
    """
  end

  @doc """
  The language switcher: a small segmented group. `locales` is a list of codes (`["PT", "EN"]`, with `current`) or of
  maps `%{code: "PT", navigate: path, active: true}` (`href` / `patch`, or `click`, the `phx-click` value, work too,
  and `label` is the title).

      <.navbar_lang locales={[%{code: "PT", href: "?locale=pt"}, %{code: "EN", href: "?locale=en"}]} current="PT" />
  """
  attr :locales, :list, required: true
  attr :current, :string, default: nil
  attr :label, :string, default: "Language"
  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_lang(assigns) do
    assigns =
      assign_derived(assigns, :entries, [:locales, :current], fn ->
        Enum.map(assigns.locales, &locale(&1, assigns.current))
      end)

    ~H"""
    <span class={merge(["sg-nb-lang", @class])} role="group" aria-label={@label} {@rest}>
      <.link
        :for={entry <- @entries}
        class={entry.on && "on"}
        aria-current={entry.on && "true"}
        title={entry.title}
        {entry.link}
      >
        {entry.code}
      </.link>
    </span>
    """
  end

  defp locale(code, current) when is_binary(code),
    do: %{code: code, title: nil, on: code == current, link: %{href: "#"}}

  defp locale(%{code: code} = locale, current) do
    link = Map.merge(link_of(locale), click_of(locale))

    %{
      code: code,
      title: locale[:label],
      on: locale[:active] == true or (current != nil and code == current),
      link: link
    }
  end

  defp click_of(%{click: click}) when not is_nil(click), do: %{"phx-click": click}
  defp click_of(_locale), do: %{}

  @doc "The thin vertical line between the icons and the user."
  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_sep(assigns) do
    ~H"""
    <span class={merge(["sg-nb-sep", @class])} aria-hidden="true" {@rest}></span>
    """
  end

  @doc "The environment pill (`Produção`, `Homologação`); `tone` is `ok` (green) or `warn` (amber)."
  attr :label, :string, required: true
  attr :tone, :string, default: "ok", values: ~w(ok warn)
  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_env(assigns) do
    ~H"""
    <span class={merge(["sg-nb-env", @tone == "warn" && "warn", @class])} {@rest}>
      <i aria-hidden="true"></i>{@label}
    </span>
    """
  end

  @doc "The save state: a green check and a muted text (`Salvo há 2 min`)."
  attr :text, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_sync(assigns) do
    ~H"""
    <span class={merge(["sg-nb-sync", @class])} role="status" {@rest}>
      <.icon name="huge-tick-02" />{@text}
    </span>
    """
  end

  @doc """
  The people on the page, as overlapping avatars. `users` are maps with `name`, `initials`, `avatar` and `color`; `max`
  of them are shown and the rest is a `+N` bubble (`total` when the list you pass is already cut).

      <.navbar_avatars users={@members} max={3} />
  """
  attr :users, :list, required: true
  attr :max, :integer, default: 3

  attr :total, :integer,
    default: nil,
    doc: "How many people there are (default: the length of `users`)."

  attr :class, :any, default: nil
  attr :rest, :global

  def navbar_avatars(assigns) do
    assigns =
      assign_derived(assigns, :shown, [:users, :max], fn ->
        Enum.take(assigns.users, assigns.max)
      end)

    assigns =
      assign_derived(assigns, :extra, [:users, :max, :total], fn ->
        max(0, (assigns.total || length(assigns.users)) - assigns.max)
      end)

    ~H"""
    <span class={merge(["sg-nb-avs", @class])} {@rest}>
      <.user_avatar :for={user <- @shown} user={user} class="sm" />
      <span :if={@extra > 0} class="more">+{@extra}</span>
    </span>
    """
  end

  # --- the user ---------------------------------------------------------------------------------------------

  @doc """
  The user of the bar: the avatar (`variant="avatar"`), with a status ring (`"ring"`) or with the name and the role
  (`"named"`). `user` is `%{name, email, role, initials, avatar, color}`, the shape the sidebar uses.

  Without the `:menu` slot it is a button for your own `phx-click`. With it, the button opens a raised panel (`role="menu"`,
  hidden at first; `id` is then required) toggled by `Phoenix.LiveView.JS`, so no round trip: a click on the button toggles
  it and a click outside or Escape closes it.

      <.navbar_user id="me" user={@user} variant="named">
        <:menu>
          <.navbar_menu_head user={@user} />
          <.navbar_menu_item icon="huge-user" navigate={~p"/perfil"}>Perfil</.navbar_menu_item>
        </:menu>
      </.navbar_user>
  """
  attr :user, :map, required: true
  attr :variant, :string, default: "avatar", values: ~w(avatar ring named)
  attr :id, :string, default: nil, doc: "Required with a `:menu`."
  attr :label, :string, default: "Account menu", doc: "The accessible name of the button."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :menu,
    doc:
      "The content of the panel: `navbar_menu_*` pieces, links with `role=\"menuitem\"`, `<hr />`."

  def navbar_user(%{menu: [_ | _]} = assigns) do
    assigns =
      assigns
      |> assign_derived(:ids, [:id], fn ->
        %{trigger: assigns.id <> "-trigger", menu: assigns.id <> "-menu"}
      end)
      |> assign_derived(:toggle, [:id], fn -> toggle_menu(assigns.id) end)
      |> assign_derived(:close, [:id], fn -> close_menu(assigns.id) end)

    ~H"""
    <div
      id={@id}
      class="sg-nb-mewrap"
      phx-click-away={@close}
      phx-window-keydown={@close}
      phx-key="Escape"
    >
      <.me
        user={@user}
        variant={@variant}
        id={@ids.trigger}
        label={@label}
        class={@class}
        menu_id={@ids.menu}
        toggle={@toggle}
        rest={@rest}
      />
      <div id={@ids.menu} class="sg-am sg-nb-menu" role="menu" aria-label={@label} hidden>
        {render_slot(@menu)}
      </div>
    </div>
    """
  end

  def navbar_user(assigns) do
    ~H"""
    <.me user={@user} variant={@variant} id={@id} label={@label} class={@class} rest={@rest} />
    """
  end

  defp toggle_menu(id) do
    JS.toggle_attribute({"hidden", "hidden"}, to: "#" <> id <> "-menu")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "#" <> id <> "-trigger")
    |> JS.toggle_class("open", to: "#" <> id <> "-trigger")
  end

  defp close_menu(id) do
    JS.set_attribute({"hidden", "hidden"}, to: "#" <> id <> "-menu")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "#" <> id <> "-trigger")
    |> JS.remove_class("open", to: "#" <> id <> "-trigger")
  end

  attr :user, :map, required: true
  attr :variant, :string, required: true
  attr :id, :string, default: nil
  attr :label, :string, required: true
  attr :class, :any, default: nil
  attr :menu_id, :string, default: nil
  attr :toggle, :any, default: nil
  attr :rest, :map, default: %{}

  defp me(assigns) do
    assigns =
      assign_derived(assigns, :classes, [:variant, :class], fn ->
        merge([
          "sg-nb-me",
          assigns.variant == "ring" && "ring",
          assigns.variant == "named" && "named",
          assigns.class
        ])
      end)

    ~H"""
    <button
      type="button"
      id={@id}
      class={@classes}
      aria-label={@label}
      aria-haspopup={@menu_id && "menu"}
      aria-controls={@menu_id}
      aria-expanded={@menu_id && "false"}
      phx-click={@toggle}
      {@rest}
    >
      <.user_avatar user={@user} />
      <span :if={@variant == "named"} class="col sg-nb-who">
        <b>{@user[:name]}</b>
        <span :if={@user[:role]}>{@user[:role]}</span>
      </span>
      <.icon :if={@variant == "named"} name="huge-arrow-down-01" class="i sm" />
    </button>
    """
  end

  attr :user, :map, required: true
  attr :class, :string, default: nil

  defp user_avatar(assigns) do
    assigns = assign_derived(assigns, :initials, [:user], fn -> Nav.initials(assigns.user) end)

    ~H"""
    <span
      class={merge(["sg-av", @class])}
      style={@user[:color] && "background:#{@user[:color]}"}
      title={@user[:name]}
      role="img"
      aria-label={@user[:name]}
    >
      <img :if={@user[:avatar]} src={@user[:avatar]} alt="" />
      <%= if !@user[:avatar] do %>
        {@initials}
      <% end %>
    </span>
    """
  end

  @doc """
  The head of the user menu: the avatar, the name and the email, and a `:badge` (the role) at the end.

      <.navbar_menu_head user={@user}><:badge><.badge color="primary">Admin</.badge></:badge></.navbar_menu_head>
  """
  attr :user, :map, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :badge

  def navbar_menu_head(assigns) do
    ~H"""
    <div class={merge(["sg-nb-mhead", @class])} {@rest}>
      <.user_avatar user={@user} />
      <div class="col">
        <b>{@user[:name]}</b>
        <span :if={@user[:email]}>{@user[:email]}</span>
      </div>
      {render_slot(@badge)}
    </div>
    """
  end

  @doc """
  The status line of the menu: a green dot, the label and an `:action` at the end (a text or a button).

      <.navbar_menu_status label="Disponível"><:action>Mudar</:action></.navbar_menu_status>
  """
  attr :label, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :action

  def navbar_menu_status(assigns) do
    ~H"""
    <div class={merge(["sg-nb-mstatus", @class])} {@rest}>
      <i aria-hidden="true"></i>{@label}
      <span :if={@action != []} class="faint">{render_slot(@action)}</span>
    </div>
    """
  end

  @doc """
  A row of the menu with a label and a control at the end: `theme_switch/1`, `navbar_lang/1`.

      <.navbar_menu_row label="Tema"><.theme_switch id="theme-menu" variant="icons" size="sm" /></.navbar_menu_row>
  """
  attr :label, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def navbar_menu_row(assigns) do
    ~H"""
    <div class={merge(["sg-nb-mrow", @class])} {@rest}>
      <span>{@label}</span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  An item of the menu: a link (`navigate`, `href`, `patch`, with `method="delete"` for a sign-out) or, with only
  `phx-click`, an action. `icon` is a Hugeicons name, `kbd` a shortcut at the end, `danger` the red one.

      <.navbar_menu_item icon="huge-settings-02" navigate={~p"/config"} kbd="⌘,">Configurações</.navbar_menu_item>
  """
  attr :icon, :string, default: nil
  attr :kbd, :string, default: nil
  attr :danger, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method download target rel)
  slot :inner_block, required: true

  def navbar_menu_item(assigns) do
    ~H"""
    <.link role="menuitem" class={merge([@danger && "neg", @class])} {@rest}>
      <.icon :if={@icon} name={@icon} class="i" />
      <span class="t">{render_slot(@inner_block)}</span>
      <span :if={@kbd} class="sg-kbd">{@kbd}</span>
    </.link>
    """
  end

  # --- shared -----------------------------------------------------------------------------------------------

  @link_keys [:navigate, :href, :patch]

  defp link_of(item) do
    case Map.take(item, @link_keys) do
      link when map_size(link) == 0 -> %{href: "#"}
      link -> link
    end
  end

  defp explicit_link(item) do
    case Map.take(item, @link_keys) do
      link when map_size(link) == 0 -> nil
      link -> link
    end
  end

  defp nav_entries(items, current) do
    Enum.map(items, fn item ->
      link = link_of(item)

      %{
        label: item.label,
        count: item[:count],
        link: link,
        on: item[:active] == true or (current != nil and current in Map.values(link))
      }
    end)
  end
end
