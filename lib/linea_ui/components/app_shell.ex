defmodule LineaUI.Components.AppShell do
  @moduledoc """
  LineOne's application shell: the page frame, the main sidebar (the icon rail), the sidebar panel with its
  collapsible groups, the minimized panel, the sideblock and the horizontal navigation, the header, the right
  sidebar, the page header and the dark mode and monochrome toggles.

      <.app_shell id="shell" sidebar_open={@sidebar_open} on_toggle="sidebar">
        <:sidebar>
          <.main_sidebar current={@current_path}>
            <:logo navigate={~p"/"} src={~p"/images/logo.svg"} />
            <:item navigate={~p"/dashboards"} label="Dashboards"><.icon name="home" /></:item>
            <:bottom>
              <.sidebar_profile id="profile" src={@user.avatar} name={@user.name} subtitle="Designer">
                <:item navigate={~p"/profile"} color="warning" title="Profile" description="Your profile setting">
                  <.icon name="user" />
                </:item>
              </.sidebar_profile>
            </:bottom>
          </.main_sidebar>
          <.sidebar_panel title="Layouts">
            <.sidebar_nav>
              <.sidebar_nav_group label="Starter" current={@current_path}>
                <:item navigate={~p"/starter/blurred"}>Blurred Header</:item>
              </.sidebar_nav_group>
            </.sidebar_nav>
          </.sidebar_panel>
        </:sidebar>
        <:header>
          <.header right_sidebar="right-sidebar">
            <:notifications>…</:notifications>
          </.header>
        </:header>
        <:aside>
          <.right_sidebar id="right-sidebar">…</.right_sidebar>
        </:aside>
        <.page_header title="Avatar">
          <:crumb navigate={~p"/elements"}>Elements</:crumb>
          <:crumb>Avatar</:crumb>
        </.page_header>
        …
      </.app_shell>

  The state LineOne keeps in `<body>` classes lives on the shell's root element: `is-sidebar-open`,
  `has-min-sidebar` (`layout="minimal"`), `navigation:sideblock` and `navigation:horizontal`,
  `is-header-blur` and `is-header-not-sticky`.

  ## LiveView

  `sidebar_open` is the server's state; the browser toggles without a round trip and tells the server through
  `on_toggle`. A choice made in the browser survives patches and live navigation (`navigate` between LiveViews
  rendering the same shell id) unless the server changes `sidebar_open`; at `xl` and up it is also kept in
  `localStorage["linea-sidebar"]` (`persist`). Below `xl` the sidebar closes, as in LineOne.
  `LineaUI.open/close/toggle(socket_or_js, "shell")` drive it from the server or a JS pipeline.

  Active items come from `active` on each item or from `current` (the current path, compared with the item's
  `navigate`, `patch` or `href`), so they follow live navigation.

  Dark mode (`<html class="dark">`, `localStorage["dark-mode"]`) and monochrome mode (`<body class="is-monochrome">`,
  `localStorage["monochrome-mode"]`) are client state; put `<.theme_script />` in the root layout's `<head>`
  so the first paint already has them.

  ## Setup

  The hooks (`LineaUI.AppShell`, `LineaUI.SidebarGroup`, `LineaUI.ShellPopper`, `LineaUI.ShellTooltips`,
  `LineaUI.RightSidebar`, `LineaUI.ThemeToggle`, `LineaUI.MonochromeToggle`) come with LineaUI's `Hooks`.
  Render the shell in the app layout of a `live_session` and give it the current path from an `on_mount`
  hook, so the active items follow `navigate`:

      def on_mount(:current_path, _params, _session, socket) do
        {:cont,
         Phoenix.LiveView.attach_hook(socket, :current_path, :handle_params, fn _params, url, socket ->
           {:cont, assign(socket, :current_path, URI.parse(url).path)}
         end)}
      end

  ## Layouts

  `layout="sidebar"` (the default) takes a `main_sidebar/1` and a `sidebar_panel/1`; `"minimal"` adds a
  `sidebar_panel_min/1`; `"sideblock"` takes a `sideblock/1`; `"horizontal"` keeps the main sidebar and panel
  for phones and puts `horizontal_nav_menu/1`s in the `:nav` slot of `header/1`; `"framed"` is the app
  frame described below.

  ## The framed shell

  `layout="framed"` is an app in a frame: the menu sits on the grey frame, 10px from the edges, and the page
  is a rounded white panel beside it. The menu is `framed_sidebar/1` with `rail_link/1`s and `rail_module/1`s
  (a module opens the pages under it; the module of the current page starts open). It collapses to a 60px rail
  of icons (tooltips on hover, badges turned into dots; a click on a module opens it again) and the choice is
  kept per person. Below 768px the menu becomes a top bar with a hamburger. The page's title block is
  `page_header/1` with `variant="page"`.

      <.app_shell id="shell" layout="framed">
        <:sidebar>
          <.framed_sidebar id="menu" on_collapse="collapse" collapsed={@collapsed}>
            <:brand><img src={~p"/images/mark.svg"} class="size-5" alt="" /></:brand>
            <:wordmark>Signetum</:wordmark>
            <.rail_link navigate={~p"/today"} label="Today" current={@current_path}><.icon name="huge-home-01" /></.rail_link>
            <.rail_module id="sales" label="Sales" badge="3" current={@current_path}>
              <:icon><.icon name="huge-shopping-cart-01" /></:icon>
              <:item navigate={~p"/orders"}>Orders</:item>
              <:item navigate={~p"/products"}>Products</:item>
            </.rail_module>
            <:bottom>
              <.rail_user name="Ana Souza" subtitle="Admin"><.avatar name="Ana Souza" color="auto" size="32" /></.rail_user>
            </:bottom>
          </.framed_sidebar>
        </:sidebar>
        <.page_header variant="page" title="Order PV-1283" description="Clinica Santa Monica" clock>
          <:crumb navigate={~p"/orders"}>Orders</:crumb>
          <:crumb>PV-1283</:crumb>
          <:badge><.badge color="info">Approved</.badge></:badge>
          <:actions><.button color="primary">Issue NF-e</.button></:actions>
        </.page_header>
        …
      </.app_shell>
  """

  use LineaUI.Component
  import LineaUI.Components.Icon, only: [glyph: 1]

  @link_attrs ~w(href navigate patch method replace)

  @layouts %{
    "framed" => "linea-frame",
    "sidebar" => "",
    "minimal" => "has-min-sidebar",
    "sideblock" => "navigation:sideblock",
    "horizontal" => "navigation:horizontal"
  }

  @default_open %{
    "framed" => false,
    "sidebar" => true,
    "minimal" => false,
    "sideblock" => true,
    "horizontal" => false
  }

  @icon_button "btn size-8 rounded-full p-0 hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25"

  @doc """
  The page frame: the sidebar, the header, the drawers and the `<main>` content, with LineOne's body classes.

  `on_toggle` runs when the browser opens or closes the sidebar (a toggle button, a close button, a breakpoint
  change, or a remembered choice applied on mount). An event name is pushed with
  `%{"id" => id, "open" => boolean}`; a `%JS{}` is executed.

      <.app_shell id="shell" layout="minimal" sidebar_open={@sidebar_open} on_toggle="sidebar">
        <:sidebar>…</:sidebar>
        <:header><.header /></:header>
        <.page_header title="Orders" />
      </.app_shell>

      def handle_event("sidebar", %{"open" => open}, socket),
        do: {:noreply, assign(socket, :sidebar_open, open)}
  """
  attr :id, :string, default: "app-shell"

  attr :layout, :string,
    default: "sidebar",
    values: ~w(sidebar minimal sideblock horizontal framed),
    doc:
      "`sidebar` is the main sidebar with its panel, `minimal` shows the minimized panel while the panel is closed, `sideblock` is one wide sidebar, `horizontal` puts the navigation in the header, `framed` is the grey frame with a `framed_sidebar/1` and a rounded main panel."

  attr :sidebar_open, :boolean,
    default: nil,
    doc: "Whether the sidebar is open; defaults to open for `sidebar` and `sideblock`."

  attr :header_blur, :boolean, default: true, doc: "LineOne's `is-header-blur`."

  attr :header_sticky, :boolean,
    default: true,
    doc: "`false` is LineOne's `is-header-not-sticky`."

  attr :persist, :boolean, default: true, doc: "Keep the sidebar choice in `localStorage`."
  attr :preloader, :boolean, default: false, doc: "LineOne's app preloader, faded out on mount."
  attr :on_toggle, :any, default: nil, doc: "An event name or a `%JS{}`."
  attr :target, :any, default: nil, doc: "The `phx-target` of `on_toggle`."

  attr :main_class, :any,
    default: nil,
    doc: "Merged into the classes of `<main class=\"main-content\">`."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :sidebar, doc: "The main sidebar and its panel, or the sideblock."
  slot :header, doc: "The `header/1`."
  slot :aside, doc: "Fixed parts: the right sidebar, drawers."
  slot :inner_block

  def app_shell(%{layout: "framed"} = assigns) do
    ~H"""
    <div
      id={@id}
      class={
        merge([
          "linea-frame flex h-dvh flex-col gap-2.5 bg-slate-150 max-md:pt-14 md:flex-row md:p-2.5 dark:bg-navy-900",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@sidebar)}
      {render_slot(@header)}
      {render_slot(@aside)}
      <main class={
        merge([
          "flex min-w-0 flex-1 flex-col gap-[18px] overflow-y-auto bg-white px-4 py-5 shadow-[0_3px_10px_rgb(48_46_56/.06)] md:rounded-xl md:px-7 md:py-[22px] dark:bg-navy-700 dark:shadow-none dark:md:ring-1 dark:md:ring-navy-500",
          @main_class
        ])
      }>
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end

  def app_shell(assigns) do
    assigns = assign_new(assigns, :open, fn -> open?(assigns) end)

    ~H"""
    <div
      id={@id}
      phx-hook="LineaUI.AppShell"
      phx-mounted={JS.ignore_attributes(["class", "data-settling"])}
      data-open={bool(@open)}
      data-persist={bool(@persist)}
      data-toggle-event={event_name(@on_toggle)}
      data-on-toggle={js_command(@on_toggle)}
      data-target={@target}
      class={
        merge([
          "min-h-100vh flex grow bg-slate-50 dark:bg-navy-900",
          layout_class(@layout),
          @open && "is-sidebar-open",
          @header_blur && "is-header-blur",
          !@header_blur && "is-header-solid",
          !@header_sticky && "is-header-not-sticky",
          @class
        ])
      }
      {@rest}
    >
      <div
        :if={@preloader}
        data-app-preloader
        id={@id <> "-preloader"}
        phx-mounted={JS.ignore_attributes(["class"])}
        class="app-preloader fixed z-50 grid h-full w-full place-content-center bg-slate-50 dark:bg-navy-900"
      >
        <div class="app-preloader-inner relative inline-block size-48"></div>
      </div>
      <div
        :if={@sidebar != []}
        class={["sidebar print:hidden", @layout == "horizontal" && "sm:hidden"]}
      >
        {render_slot(@sidebar)}
      </div>
      {render_slot(@header)}
      {render_slot(@aside)}
      <main class={merge(["main-content w-full px-[var(--margin-x)] pb-8", @main_class])}>
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end

  defp open?(%{sidebar_open: nil, layout: layout}), do: Map.fetch!(@default_open, layout)
  defp open?(%{sidebar_open: open}), do: open

  defp layout_class(layout), do: Map.fetch!(@layouts, layout)

  @doc """
  The main sidebar: LineOne's icon rail with the logo, the section links (with a tooltip on the right and an
  active state) and the bottom links.

      <.main_sidebar current={@current_path}>
        <:logo navigate={~p"/"} src={~p"/images/app-logo.svg"} />
        <:item navigate={~p"/forms"} label="Forms"><svg>…</svg></:item>
        <:bottom><.main_sidebar_link navigate={~p"/settings"}><svg>…</svg></.main_sidebar_link></:bottom>
      </.main_sidebar>
  """
  attr :id, :string, default: "main-sidebar"

  attr :current, :string,
    default: nil,
    doc: "The current path; an item whose link matches it is active."

  attr :centered, :boolean,
    default: false,
    doc: "Centers the links between the logo and the bottom."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :logo do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :src, :string
    attr :alt, :string
  end

  slot :item do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :label, :string, doc: "The tooltip and the accessible name."
    attr :active, :boolean
  end

  slot :bottom

  def main_sidebar(assigns) do
    ~H"""
    <div id={@id} phx-hook="LineaUI.ShellTooltips" class={merge(["main-sidebar", @class])} {@rest}>
      <div class={[
        "flex h-full w-full flex-col items-center border-r border-slate-150 bg-white dark:border-navy-700 dark:bg-navy-800",
        @centered && "justify-between"
      ]}>
        <div :for={logo <- @logo} class="flex pt-4">
          <.link {link_attrs(logo)}>
            <img
              :if={logo[:src]}
              class="size-11 transition-transform duration-500 ease-in-out hover:rotate-[360deg]"
              src={logo.src}
              alt={logo[:alt] || "logo"}
            />
            {logo.inner_block && render_slot(logo)}
          </.link>
        </div>
        <div class={[
          "is-scrollbar-hidden flex flex-col space-y-4 overflow-y-auto pt-6",
          !@centered && "grow"
        ]}>
          <.main_sidebar_link
            :for={item <- @item}
            label={item[:label]}
            active={active?(item, @current)}
            {link_attrs(item)}
          >
            {render_slot(item)}
          </.main_sidebar_link>
        </div>
        <div :if={@bottom != []} class="flex flex-col items-center space-y-3 py-3">
          {render_slot(@bottom)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  One icon link of the main sidebar. With `label` it gets LineOne's tooltip on its right (inside a
  `main_sidebar/1`, which positions it) and that accessible name.

      <.main_sidebar_link navigate={~p"/settings"} label="Settings" current={@current_path}>
        <svg class="size-7">…</svg>
      </.main_sidebar_link>
  """
  attr :label, :string, default: nil, doc: "The tooltip and the accessible name."
  attr :active, :boolean, default: false

  attr :current, :string,
    default: nil,
    doc: "The current path; the link is active when it matches."

  attr :class, :any, default: nil
  attr :rest, :global, include: @link_attrs
  slot :inner_block, required: true, doc: "The icon."

  def main_sidebar_link(assigns) do
    assigns = assign(assigns, :active, assigns.active or active?(assigns.rest, assigns.current))

    ~H"""
    <.link
      class={
        merge([
          "tooltip-main-sidebar flex size-11 items-center justify-center rounded-lg outline-hidden transition-colors duration-200",
          rail_state(@active),
          @class
        ])
      }
      data-tooltip-ref={@label && "true"}
      aria-label={@label}
      aria-current={@active && "page"}
      {@rest}
    >
      {render_slot(@inner_block)}
      <span :if={@label} role="tooltip" class="shell-tooltip">
        <span class="shell-tooltip-box">
          {@label}
          <svg class="shell-tooltip-arrow" viewBox="0 0 16 6" aria-hidden="true">
            <path d="M0 6s1.796-.013 4.67-3.615C5.851.9 6.93.006 8 0c1.07-.006 2.148.887 3.343 2.385C14.233 6.005 16 6 16 6H0z" />
          </svg>
        </span>
      </span>
    </.link>
    """
  end

  defp rail_state(true),
    do:
      "bg-primary/10 text-primary hover:bg-primary/20 focus:bg-primary/20 active:bg-primary/25 dark:bg-navy-600 dark:text-accent-light dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90"

  defp rail_state(false),
    do:
      "hover:bg-primary/20 focus:bg-primary/20 active:bg-primary/25 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25"

  @profile_colors %{
    "primary" => "bg-primary dark:bg-accent",
    "secondary" => "bg-secondary",
    "info" => "bg-info",
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error"
  }

  @status_colors %{
    "success" => "bg-success",
    "warning" => "bg-warning",
    "error" => "bg-error",
    "info" => "bg-info",
    "neutral" => "bg-slate-300 dark:bg-navy-400"
  }

  @doc """
  The avatar at the bottom of the main sidebar and the profile box it opens on its right: the person, a list
  of links with a colored icon, and a footer (LineOne's logout button).

      <.sidebar_profile id="profile" src={@user.avatar} name="Travis Fuller" subtitle="Product Designer">
        <:item navigate={~p"/profile"} color="warning" title="Profile" description="Your profile setting">
          <svg>…</svg>
        </:item>
        <:footer><.button color="primary" class="h-9 w-full">Logout</.button></:footer>
      </.sidebar_profile>

  A link of the box closes it.
  """
  attr :id, :string, required: true
  attr :src, :string, required: true
  attr :alt, :string, default: "avatar"
  attr :name, :string, required: true
  attr :subtitle, :string, default: nil

  attr :status, :string,
    default: "success",
    values: [nil | ~w(success warning error info neutral)]

  attr :href, :string, default: nil
  attr :navigate, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :method, :string
    attr :color, :string, values: ~w(primary secondary info success warning error)
    attr :title, :string, required: true
    attr :description, :string
  end

  slot :footer

  def sidebar_profile(assigns) do
    assigns =
      assign(assigns,
        profile_colors: @profile_colors,
        status_class: @status_colors[assigns.status]
      )

    ~H"""
    <div
      id={@id}
      phx-hook="LineaUI.ShellPopper"
      data-placement="right-end"
      data-gap="12"
      class={merge(["flex", @class])}
      {@rest}
    >
      <button
        type="button"
        id={@id <> "-ref"}
        data-popper-ref
        phx-mounted={JS.ignore_attributes(["class", "aria-expanded"])}
        aria-haspopup="true"
        aria-expanded="false"
        aria-controls={@id <> "-box"}
        aria-label={@name}
        class="avatar cursor-pointer size-12"
      >
        <img class="rounded-full" src={@src} alt={@alt} />
        <span
          :if={@status_class}
          class={[
            "absolute right-0 size-3.5 rounded-full border-2 border-white dark:border-navy-700",
            @status_class
          ]}
        ></span>
      </button>
      <div
        id={@id <> "-box"}
        data-popper-box
        data-popper-placement="right"
        phx-mounted={JS.ignore_attributes(["class", "style"])}
        class="popper-root fixed top-0 left-0"
      >
        <div class="popper-box w-64 rounded-lg border border-slate-150 bg-white shadow-soft dark:border-navy-600 dark:bg-navy-700">
          <div class="flex items-center space-x-4 rounded-t-lg bg-slate-100 py-5 px-4 dark:bg-navy-800">
            <div class="avatar size-14">
              <img class="rounded-full" src={@src} alt={@alt} />
            </div>
            <div>
              <.link
                href={@href}
                navigate={@navigate}
                data-popper-close
                class="text-base font-medium text-slate-700 hover:text-primary focus:text-primary dark:text-navy-100 dark:hover:text-accent-light dark:focus:text-accent-light"
              >
                {@name}
              </.link>
              <p :if={@subtitle} class="text-xs text-slate-400 dark:text-navy-300">{@subtitle}</p>
            </div>
          </div>
          <div class="flex flex-col pt-2 pb-5">
            <.link
              :for={item <- @item}
              data-popper-close
              class="group flex items-center space-x-3 py-2 px-4 tracking-wide outline-hidden transition-all hover:bg-slate-100 focus:bg-slate-100 dark:hover:bg-navy-600 dark:focus:bg-navy-600"
              {link_attrs(item)}
            >
              <div class={[
                "flex size-8 items-center justify-center rounded-lg text-white",
                @profile_colors[item[:color] || "primary"]
              ]}>
                {item.inner_block && render_slot(item)}
              </div>
              <div>
                <h2 class="font-medium text-slate-700 transition-colors group-hover:text-primary group-focus:text-primary dark:text-navy-100 dark:group-hover:text-accent-light dark:group-focus:text-accent-light">
                  {item.title}
                </h2>
                <div
                  :if={item[:description]}
                  class="text-xs text-slate-400 line-clamp-1 dark:text-navy-300"
                >
                  {item.description}
                </div>
              </div>
            </.link>
            <div :if={@footer != []} class="mt-3 px-4">{render_slot(@footer)}</div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  The sidebar panel next to the main sidebar: its title, the close button LineOne shows below `xl`, and the
  scrolling body (`sidebar_nav/1`, `sidebar_nav_divider/1`).

      <.sidebar_panel title="Elements">
        <.sidebar_nav>
          <.sidebar_nav_link navigate={~p"/avatar"} current={@current_path}>Avatar</.sidebar_nav_link>
        </.sidebar_nav>
        <.sidebar_nav_divider />
        <.sidebar_nav>…</.sidebar_nav>
      </.sidebar_panel>
  """
  attr :title, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def sidebar_panel(assigns) do
    ~H"""
    <div class={merge(["sidebar-panel", @class])} {@rest}>
      <div class="flex h-full grow flex-col bg-white pl-[var(--main-sidebar-width)] dark:bg-navy-750">
        <div class="flex h-18 w-full items-center justify-between pl-4 pr-1">
          <p class="text-base tracking-wider text-slate-800 dark:text-navy-100">{@title}</p>
          <.sidebar_close />
        </div>
        <div class="nav-wrapper scrollbar-sm h-[calc(100%-4.5rem)] overflow-x-hidden overflow-y-auto pb-6">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :class, :any, default: nil

  defp sidebar_close(assigns) do
    ~H"""
    <button
      type="button"
      data-sidebar-close
      aria-label="Close sidebar"
      class={
        merge([
          "sidebar-close btn size-7 rounded-full p-0 text-primary hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:text-accent-light/80 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25 xl:hidden",
          @class
        ])
      }
    >
      <.glyph name={:chevron_left} class="size-6" />
    </button>
    """
  end

  @doc """
  A list of the sidebar panel (or the sideblock): `sidebar_nav_link/1` and `sidebar_nav_group/1`.

      <.sidebar_nav>
        <.sidebar_nav_link navigate={~p"/orders"} current={@current_path}>Orders</.sidebar_nav_link>
      </.sidebar_nav>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def sidebar_nav(assigns) do
    ~H"""
    <ul class={merge(["flex flex-1 flex-col px-4 font-inter", @class])} {@rest}>
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc """
  A plain link of the sidebar panel, active with `active` or when its path is `current`.

      <.sidebar_nav_link navigate={~p"/orders"} current={@current_path}>Orders</.sidebar_nav_link>
  """
  attr :active, :boolean, default: false

  attr :current, :string,
    default: nil,
    doc: "The current path; the link is active when it matches."

  attr :class, :any, default: nil
  attr :rest, :global, include: @link_attrs
  slot :inner_block, required: true

  def sidebar_nav_link(assigns) do
    assigns = assign(assigns, :active, assigns.active or active?(assigns.rest, assigns.current))

    ~H"""
    <li>
      <.link
        class={
          merge([
            "nav-link flex py-2 text-xs-plus tracking-wide outline-hidden transition-colors duration-300 ease-in-out",
            nav_state(@active),
            @class
          ])
        }
        aria-current={@active && "page"}
        {@rest}
      >
        {render_slot(@inner_block)}
      </.link>
    </li>
    """
  end

  defp nav_state(true), do: "font-medium text-primary dark:text-accent-light"

  defp nav_state(false),
    do: "text-slate-600 hover:text-slate-800 dark:text-navy-200 dark:hover:text-navy-50"

  @doc """
  A collapsible group of the sidebar panel. It opens when one of its items is active (or with `open`); the
  groups that share `name` open one at a time, like LineOne's accordion. A group opened or closed in the browser
  stays so across patches unless the server changes `open`.

      <.sidebar_nav_group label="Starter" current={@current_path}>
        <:item navigate={~p"/starter/1"}>Blurred Header</:item>
        <:item navigate={~p"/starter/2"}>Unblurred Header</:item>
      </.sidebar_nav_group>
  """
  attr :id, :string, default: nil, doc: "Defaults to `sidebar-group-<label>`."
  attr :label, :string, required: true
  attr :open, :boolean, default: nil, doc: "Defaults to whether an item is active."

  attr :name, :string,
    default: "sidebar-nav",
    doc: "Groups with the same name open one at a time."

  attr :current, :string, default: nil, doc: "The current path; the matching item is active."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item, required: true do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :active, :boolean
  end

  def sidebar_nav_group(assigns) do
    items = Enum.map(assigns.item, &Map.put(&1, :active, active?(&1, assigns.current)))

    assigns =
      assigns
      |> assign(:item, items)
      |> assign(:id, assigns.id || "sidebar-group-" <> slug(assigns.label))
      |> then(&assign(&1, :open, group_open?(&1.open, items)))

    ~H"""
    <li class={@class} {@rest}>
      <details
        id={@id}
        name={@name}
        open={@open}
        data-open={bool(@open)}
        phx-hook="LineaUI.SidebarGroup"
        phx-mounted={JS.ignore_attributes(["open"])}
        class="sidebar-group nav-parent [&[open]>summary]:font-semibold [&[open]>summary]:text-slate-800 dark:[&[open]>summary]:text-navy-50 [&[open]>summary_svg]:rotate-90"
      >
        <summary class="ac-trigger flex w-full cursor-pointer list-none items-center justify-between py-2 text-xs-plus tracking-wide text-slate-600 outline-hidden transition-[color,padding-left] duration-300 ease-in-out hover:text-slate-800 dark:text-navy-200 dark:hover:text-navy-50">
          <span>{@label}</span>
          <.glyph
            name={:chevron_right}
            class="size-4 text-slate-400 transition-transform ease-in-out"
          />
        </summary>
        <ul class="ac-panel">
          <li :for={item <- @item}>
            <.link
              class={[
                "nav-link flex items-center justify-between p-2 text-xs-plus tracking-wide outline-hidden transition-[color,padding-left] duration-300 ease-in-out hover:pl-4",
                nav_state(item.active)
              ]}
              aria-current={item.active && "page"}
              {link_attrs(item)}
            >
              <div class="flex items-center space-x-2">
                <div class="size-1.5 rounded-full border border-current opacity-40"></div>
                <span>{render_slot(item)}</span>
              </div>
            </.link>
          </li>
        </ul>
      </details>
    </li>
    """
  end

  defp group_open?(nil, items), do: Enum.any?(items, & &1.active)
  defp group_open?(open, _items), do: open

  @doc """
  The line between the lists of the sidebar panel.

      <.sidebar_nav_divider />
  """
  attr :class, :any, default: nil

  def sidebar_nav_divider(assigns) do
    ~H"""
    <div class={merge(["my-3 mx-4 h-px bg-slate-200 dark:bg-navy-500", @class])}></div>
    """
  end

  @doc """
  LineOne's minimized sidebar panel (`layout="minimal"`): shown next to the main sidebar while the panel is
  closed. A header (an avatar), the icon links (`sidebar_min_group/1`, `sidebar_min_link/1`,
  `sidebar_min_divider/1`) and a footer.

      <.sidebar_panel_min>
        <:header><div class="avatar size-10">…</div></:header>
        <.sidebar_min_group>
          <.sidebar_min_link navigate={~p"/inbox"} label="Inbox" current={@current_path}><svg>…</svg></.sidebar_min_link>
          <.sidebar_min_link navigate={~p"/trash"} label="Trash" color="error"><svg>…</svg></.sidebar_min_link>
        </.sidebar_min_group>
        <.sidebar_min_divider />
        <.sidebar_min_group>…</.sidebar_min_group>
        <:footer><.button variant="outline" shape="pill" icon aria-label="More">…</.button></:footer>
      </.sidebar_panel_min>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :header
  slot :inner_block, required: true
  slot :footer

  def sidebar_panel_min(assigns) do
    ~H"""
    <div class={merge(["sidebar-panel-min", @class])} {@rest}>
      <div class="flex h-full flex-col items-center bg-white dark:bg-navy-750">
        <div class="flex h-18 shrink-0 items-center justify-center">{render_slot(@header)}</div>
        <div class="flex h-[calc(100%-4.5rem)] grow flex-col">
          <div class="is-scrollbar-hidden flex grow flex-col overflow-y-auto">
            {render_slot(@inner_block)}
          </div>
          <div :if={@footer != []} class="py-3">{render_slot(@footer)}</div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  A list of icon links of the minimized panel; the first one keeps LineOne's top margin.

      <.sidebar_min_group>
        <.sidebar_min_link href="#" label="Home"><svg>…</svg></.sidebar_min_link>
      </.sidebar_min_group>
  """
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def sidebar_min_group(assigns) do
    ~H"""
    <ul class={merge(["space-y-1 first:mt-4", @class])}>{render_slot(@inner_block)}</ul>
    """
  end

  @min_colors %{
    "neutral" =>
      "hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25",
    "primary" =>
      "text-primary hover:bg-primary/20 focus:bg-primary/20 active:bg-primary/25 dark:text-accent-light dark:hover:bg-accent-light/20 dark:focus:bg-accent-light/20 dark:active:bg-accent-light/25",
    "secondary" =>
      "text-secondary hover:bg-secondary/20 focus:bg-secondary/20 active:bg-secondary/25 dark:text-secondary-light dark:hover:bg-secondary-light/20 dark:focus:bg-secondary-light/20 dark:active:bg-secondary-light/25",
    "info" => "text-info hover:bg-info/20 focus:bg-info/20 active:bg-info/25",
    "success" => "text-success hover:bg-success/20 focus:bg-success/20 active:bg-success/25",
    "warning" => "text-warning hover:bg-warning/20 focus:bg-warning/20 active:bg-warning/25",
    "error" => "text-error hover:bg-error/20 focus:bg-error/20 active:bg-error/25"
  }

  @min_active "bg-primary/10 font-medium text-primary hover:bg-primary/20 focus:bg-primary/20 active:bg-primary/25 dark:bg-accent-light/10 dark:text-accent-light dark:hover:bg-accent-light/20 dark:focus:bg-accent-light/20 dark:active:bg-accent-light/25"

  @doc """
  An icon link of the minimized panel. Active links are primary soft, the others take `color`.

      <.sidebar_min_link navigate={~p"/starred"} label="Starred" color="warning"><svg>…</svg></.sidebar_min_link>
  """
  attr :label, :string, default: nil, doc: "The accessible name."

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error)

  attr :active, :boolean, default: false

  attr :current, :string,
    default: nil,
    doc: "The current path; the link is active when it matches."

  attr :class, :any, default: nil
  attr :rest, :global, include: @link_attrs
  slot :inner_block, required: true

  def sidebar_min_link(assigns) do
    active = assigns.active or active?(assigns.rest, assigns.current)
    assigns = assign(assigns, active: active, state: min_state(active, assigns.color))

    ~H"""
    <li>
      <.link
        class={merge(["btn size-10 p-0", @state, @class])}
        aria-label={@label}
        aria-current={@active && "page"}
        {@rest}
      >
        {render_slot(@inner_block)}
      </.link>
    </li>
    """
  end

  defp min_state(true, _color), do: @min_active
  defp min_state(false, color), do: Map.fetch!(@min_colors, color)

  @doc """
  The line between the lists of the minimized panel.

      <.sidebar_min_divider />
  """
  attr :class, :any, default: nil

  def sidebar_min_divider(assigns) do
    ~H"""
    <div class={merge(["my-4 h-px bg-slate-200 dark:bg-navy-500", @class])}></div>
    """
  end

  @doc """
  LineOne's sideblock (`layout="sideblock"`): one wide sidebar with the logo, the close button and the
  navigation (`sidebar_nav/1`). It goes in the `:sidebar` slot of `<.app_shell layout="sideblock">`.

      <.sideblock>
        <:logo navigate={~p"/"} src={~p"/images/app-logo.svg"} />
        <.sidebar_nav>
          <.sidebar_nav_group label="Orders" current={@current_path}>
            <:item navigate={~p"/orders"}>All orders</:item>
          </.sidebar_nav_group>
        </.sidebar_nav>
      </.sideblock>
  """
  attr :class, :any, default: nil
  attr :rest, :global

  slot :logo do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :src, :string
    attr :alt, :string
  end

  slot :inner_block, required: true

  def sideblock(assigns) do
    ~H"""
    <div class={merge(["sidebar-panel", @class])} {@rest}>
      <div class="flex h-full grow flex-col border-r border-slate-150 bg-white dark:border-navy-700 dark:bg-navy-750">
        <div class="flex items-center justify-between px-3 pt-4">
          <div :for={logo <- @logo} class="flex">
            <.link {link_attrs(logo)}>
              <img
                :if={logo[:src]}
                class="size-11 transition-transform duration-500 ease-in-out hover:rotate-[360deg]"
                src={logo.src}
                alt={logo[:alt] || "logo"}
              />
              {logo.inner_block && render_slot(logo)}
            </.link>
          </div>
          <.sidebar_close />
        </div>
        <div class="nav-wrapper scrollbar-sm mt-5 h-[calc(100%-4.5rem)] overflow-x-hidden overflow-y-auto pb-6">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  The header: LineOne's animated sidebar toggle, the search bar (and the full screen search of phones), the
  dark mode and monochrome toggles, the notifications, the right sidebar toggle and a profile slot.

  With a `:nav` slot it is LineOne's horizontal navigation header: the toggle only on phones, the `:brand`
  on larger screens and the navigation row (`horizontal_nav_menu/1`) below.

      <.header right_sidebar="right-sidebar">
        <:start><.page_header title="Orders" class="py-0 lg:py-0" /></:start>
        <:search_results>…</:search_results>
        <:notifications>…</:notifications>
      </.header>

  The search input takes `search_input` (a map of attributes: `name`, `value`, `phx-change`, `phx-debounce`…).
  """
  attr :id, :string, default: "app-header"
  attr :toggle, :boolean, default: true, doc: "The sidebar toggle."
  attr :search, :boolean, default: true
  attr :search_placeholder, :string, default: "Search here..."
  attr :search_input, :map, default: %{}
  attr :theme_toggle, :boolean, default: true
  attr :monochrome_toggle, :boolean, default: true

  attr :right_sidebar, :string,
    default: nil,
    doc: "The id of the `right_sidebar/1` its button toggles."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :brand, doc: "The logo and name of a horizontal header." do
    attr :href, :string
    attr :navigate, :string
    attr :src, :string
    attr :label, :string
  end

  slot :start, doc: "Content after the toggle: a title, a breadcrumb."
  slot :search_results, doc: "The box under the search bar, shown while it has the focus."
  slot :mobile_search, doc: "What the full screen search of phones shows under its input."
  slot :actions, doc: "Buttons before the theme toggle."

  slot :notifications, doc: "The notification box; the bell opens it." do
    attr :dot, :boolean, doc: "LineOne's pinging dot; true by default."
    attr :label, :string
  end

  slot :profile, doc: "Content at the end, such as an avatar menu."
  slot :nav, doc: "The navigation row of a horizontal header."

  def header(assigns) do
    assigns = assign(assigns, horizontal: assigns.nav != [], icon_button: @icon_button)

    ~H"""
    <nav id={@id} class={merge(["header print:hidden", @class])} {@rest}>
      <div class={[
        "header-container relative flex w-full bg-white dark:bg-navy-700 print:hidden",
        @horizontal && "sm:flex-col"
      ]}>
        <div class={["flex w-full items-center justify-between", @horizontal && "sm:h-16"]}>
          <div class="flex min-w-0 items-center space-x-4">
            <div :if={@toggle} class={["size-7", @horizontal && "sm:hidden"]}>
              <.sidebar_toggle />
            </div>
            <div :for={brand <- @brand} class="hidden items-center space-x-2 sm:flex">
              <.link href={brand[:href]} navigate={brand[:navigate]}>
                <img
                  :if={brand[:src]}
                  class="size-10 transition-transform duration-500 ease-in-out hover:rotate-[360deg]"
                  src={brand.src}
                  alt={brand[:label] || "logo"}
                />
              </.link>
              <span
                :if={brand[:label]}
                class="text-xl font-semibold uppercase text-slate-700 dark:text-navy-100"
              >
                {brand.label}
              </span>
              {brand.inner_block && render_slot(brand)}
            </div>
            {render_slot(@start)}
          </div>
          <div class="-mr-1.5 flex items-center space-x-2">
            <button
              :if={@search}
              type="button"
              aria-label="Search"
              phx-click={show_mobile_search(@id)}
              class={["mobile-searchbar-show sm:hidden", @icon_button]}
            >
              <.glyph
                name={:search}
                class="size-5.5 text-slate-500 dark:text-navy-100"
                stroke_width="1.5"
              />
            </button>
            <div
              :if={@search}
              id={@id <> "-search"}
              phx-hook={@search_results != [] && "LineaUI.ShellPopper"}
              data-placement="bottom-end"
              data-gap="12"
              data-trigger="focus"
              class="hidden sm:flex"
            >
              <div class="relative mr-4 flex h-8">
                <input
                  id={@id <> "-search-input"}
                  type="text"
                  data-popper-ref
                  data-open-class="w-80"
                  data-closed-class="w-60"
                  phx-mounted={JS.ignore_attributes(["class", "aria-expanded"])}
                  placeholder={@search_placeholder}
                  aria-label={@search_placeholder}
                  class="form-input peer h-full w-60 rounded-full bg-slate-150 px-4 pl-9 text-xs-plus text-slate-800 ring-primary/50 hover:bg-slate-200 focus:ring-3 dark:bg-navy-900/90 dark:text-navy-100 dark:placeholder-navy-300 dark:ring-accent/50 dark:hover:bg-navy-900 dark:focus:bg-navy-900"
                  {@search_input}
                />
                <div class="pointer-events-none absolute flex h-full w-10 items-center justify-center text-slate-400 peer-focus:text-primary dark:text-navy-300 dark:peer-focus:text-accent">
                  <.search_glyph />
                </div>
              </div>
              <div
                :if={@search_results != []}
                id={@id <> "-search-box"}
                data-popper-box
                data-popper-placement="bottom"
                phx-mounted={JS.ignore_attributes(["class", "style"])}
                class="popper-root fixed top-0 left-0"
              >
                <div class="popper-box flex max-h-[calc(100vh-6rem)] w-80 flex-col rounded-lg border border-slate-150 bg-white shadow-soft dark:border-navy-800 dark:bg-navy-700 dark:shadow-soft-dark">
                  {render_slot(@search_results)}
                </div>
              </div>
            </div>
            {render_slot(@actions)}
            <.theme_toggle :if={@theme_toggle} id={@id <> "-theme"} />
            <.monochrome_toggle :if={@monochrome_toggle} id={@id <> "-monochrome"} />
            <div
              :for={notifications <- @notifications}
              id={@id <> "-notifications"}
              phx-hook="LineaUI.ShellPopper"
              data-placement="bottom-end"
              data-gap="12"
              class="flex"
            >
              <button
                type="button"
                id={@id <> "-notifications-ref"}
                data-popper-ref
                phx-mounted={JS.ignore_attributes(["class", "aria-expanded"])}
                aria-haspopup="true"
                aria-expanded="false"
                aria-label={notifications[:label] || "Notifications"}
                class={["relative", @icon_button]}
              >
                <.glyph
                  name={:bell}
                  class="size-5 text-slate-500 dark:text-navy-100"
                  stroke_width="1.5"
                />
                <span
                  :if={Map.get(notifications, :dot, true)}
                  class="absolute -top-px -right-px flex size-3 items-center justify-center"
                >
                  <span class="absolute inline-flex h-full w-full animate-ping rounded-full bg-secondary opacity-80"></span>
                  <span class="inline-flex size-2 rounded-full bg-secondary"></span>
                </span>
              </button>
              <div
                id={@id <> "-notifications-box"}
                data-popper-box
                data-popper-placement="bottom"
                phx-mounted={JS.ignore_attributes(["class", "style"])}
                class="popper-root fixed top-0 left-0"
              >
                <div class="popper-box mx-4 mt-1 flex max-h-[calc(100vh-6rem)] w-[calc(100vw-2rem)] flex-col rounded-lg border border-slate-150 bg-white shadow-soft dark:border-navy-800 dark:bg-navy-700 dark:shadow-soft-dark sm:m-0 sm:w-80">
                  {render_slot(notifications)}
                </div>
              </div>
            </div>
            <.right_sidebar_toggle :if={@right_sidebar} target={@right_sidebar} />
            {render_slot(@profile)}
          </div>
        </div>
        <div
          :if={@horizontal}
          class="is-scrollbar-hidden -mx-2 hidden h-12 items-center space-x-2 overflow-y-auto font-inter sm:flex"
        >
          {render_slot(@nav)}
        </div>
      </div>
    </nav>
    <div
      :if={@search}
      id={@id <> "-mobile-search"}
      data-mobile-searchbar
      data-hide={hide_mobile_search(@id)}
      class="mobile-searchbar fixed inset-0 z-[100] hidden flex-col bg-white dark:bg-navy-700"
    >
      <div class="flex items-center space-x-2 bg-slate-100 px-3 pt-2 dark:bg-navy-800">
        <button
          type="button"
          aria-label="Close search"
          phx-click={hide_mobile_search(@id)}
          class="mobile-searchbar-hide btn -ml-1.5 size-7 shrink-0 rounded-full p-0 text-slate-600 hover:bg-slate-300/20 active:bg-slate-300/25 dark:text-navy-100 dark:hover:bg-navy-300/20 dark:active:bg-navy-300/25"
        >
          <.glyph name={:chevron_left} class="size-5" stroke_width="1.5" />
        </button>
        <input
          id={@id <> "-mobile-search-input"}
          type="text"
          placeholder={@search_placeholder}
          aria-label={@search_placeholder}
          class="mobile-searchbar-input form-input h-8 w-full bg-transparent placeholder-slate-400 dark:placeholder-navy-300"
          {@search_input}
        />
      </div>
      {render_slot(@mobile_search)}
    </div>
    """
  end

  defp show_mobile_search(id) do
    JS.show(to: "##{id}-mobile-search", display: "flex")
    |> JS.focus(to: "##{id}-mobile-search-input")
  end

  defp hide_mobile_search(id) do
    JS.hide(to: "##{id}-mobile-search", transition: {"animate:leave", "", ""}, time: 150)
  end

  defp search_glyph(assigns) do
    ~H"""
    <.glyph name={:search_solid} class="size-4.5 transition-colors duration-200" />
    """
  end

  @doc """
  LineOne's animated hamburger: three bars that turn into an arrow while the sidebar is open. Inside an
  `app_shell/1` it toggles the sidebar; `header/1` already renders one.

      <.sidebar_toggle />
  """
  attr :class, :any, default: nil
  attr :rest, :global

  def sidebar_toggle(assigns) do
    ~H"""
    <button
      type="button"
      data-sidebar-toggle
      aria-label="Toggle sidebar"
      class={
        merge([
          "sidebar-toggle cursor-pointer ml-0.5 flex size-7 flex-col justify-center space-y-1.5 text-primary outline-hidden focus:outline-hidden dark:text-accent-light/80",
          @class
        ])
      }
      {@rest}
    >
      <span></span>
      <span></span>
      <span></span>
    </button>
    """
  end

  @doc """
  A dropdown of the horizontal navigation (the `:nav` slot of `header/1`): an icon and a label, and a box of
  links (`:item` slots, or `horizontal_nav_link/1` and `horizontal_nav_divider/1` as content). It is active
  with `active`, or when one of its items is active or matches `current`.

      <.horizontal_nav_menu id="nav-pages" label="Pages" current={@current_path}>
        <:icon><svg>…</svg></:icon>
        <:item navigate={~p"/pages/blank"}>Blank</:item>
      </.horizontal_nav_menu>
  """
  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false
  attr :current, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon

  slot :item do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :active, :boolean
  end

  slot :inner_block

  def horizontal_nav_menu(assigns) do
    items = Enum.map(assigns.item, &Map.put(&1, :active, active?(&1, assigns.current)))

    assigns =
      assign(assigns,
        item: items,
        active: assigns.active or Enum.any?(items, & &1.active)
      )

    ~H"""
    <div
      id={@id}
      phx-hook="LineaUI.ShellPopper"
      data-placement="bottom-start"
      data-gap="4"
      class={merge(["inline-flex", @class])}
      {@rest}
    >
      <button
        type="button"
        id={@id <> "-ref"}
        data-popper-ref
        aria-haspopup="true"
        aria-expanded="false"
        class={[
          "btn popper-ref space-x-2 px-2 py-1.5 text-xs-plus font-medium leading-none",
          menu_state(@active)
        ]}
      >
        {render_slot(@icon)}
        <span>{@label}</span>
      </button>
      <div
        id={@id <> "-box"}
        data-popper-box
        data-popper-placement="bottom"
        phx-mounted={JS.ignore_attributes(["class", "style"])}
        class="popper-root fixed top-0 left-0"
      >
        <div class="popper-box max-h-[calc(100vh-120px)] overflow-y-auto rounded-md border border-slate-150 bg-white py-1.5 font-inter dark:border-navy-500 dark:bg-navy-700">
          <ul :if={@item != []}>
            <li :for={item <- @item}>
              <.horizontal_nav_link active={item.active} {link_attrs(item)}>
                {render_slot(item)}
              </.horizontal_nav_link>
            </li>
          </ul>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  defp menu_state(true),
    do: "bg-primary/10 text-primary dark:bg-accent-light/10 dark:text-accent-light"

  defp menu_state(false),
    do:
      "text-slate-600 hover:bg-slate-300/20 hover:text-slate-800 active:bg-slate-300/25 dark:text-navy-200 dark:hover:bg-navy-300/20 dark:hover:text-navy-100 dark:active:bg-navy-300/25"

  @doc """
  A link of a horizontal navigation box (inside `horizontal_nav_menu/1`). A click closes the box.

      <.horizontal_nav_link navigate={~p"/reports"} current={@current_path}>Reports</.horizontal_nav_link>
  """
  attr :active, :boolean, default: false

  attr :current, :string,
    default: nil,
    doc: "The current path; the link is active when it matches."

  attr :class, :any, default: nil
  attr :rest, :global, include: @link_attrs
  slot :inner_block, required: true

  def horizontal_nav_link(assigns) do
    assigns = assign(assigns, :active, assigns.active or active?(assigns.rest, assigns.current))

    ~H"""
    <.link
      data-popper-close
      aria-current={@active && "page"}
      class={
        merge([
          "flex h-8 items-center px-3 pr-8 font-medium tracking-wide outline-hidden transition-all hover:bg-slate-100 hover:text-slate-800 focus:bg-slate-100 focus:text-slate-800 dark:hover:bg-navy-600 dark:hover:text-navy-100 dark:focus:bg-navy-600 dark:focus:text-navy-100",
          @active && "text-primary dark:text-accent-light",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  The line between the links of a horizontal navigation box.

      <.horizontal_nav_divider />
  """
  attr :class, :any, default: nil

  def horizontal_nav_divider(assigns) do
    ~H"""
    <div role="separator" class={merge(["my-1 h-px bg-slate-150 dark:bg-navy-500", @class])}></div>
    """
  end

  @doc """
  LineOne's right sidebar: a drawer from the right with an overlay, a top row (`:title` and the close button),
  the content and a `:footer` (LineOne's floating tab bar).

  Opened with `open`, `right_sidebar_toggle/1`, or `LineaUI.open/close/toggle(id)` (also from the server with
  a socket). Esc, the overlay and the close button close it. `on_open` and `on_close` take an event name,
  pushed with `%{"id" => id}`, or a `%JS{}`.

      <.right_sidebar id="right-sidebar" open={@panel_open} on_close="panel-closed">
        <:title><span class="text-xs">25 May, 2022</span></:title>
        <div class="px-3">…</div>
      </.right_sidebar>
  """
  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :label, :string, default: "Sidebar"
  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :title
  slot :inner_block
  slot :footer

  def right_sidebar(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="LineaUI.RightSidebar"
      data-open={bool(@open)}
      data-open-event={event_name(@on_open)}
      data-on-open={js_command(@on_open)}
      data-close-event={event_name(@on_close)}
      data-on-close={js_command(@on_close)}
      data-target={@target}
      class={merge(["right-sidebar drawer drawer-right", @class])}
      {@rest}
    >
      <div
        id={@id <> "-overlay"}
        data-drawer-overlay
        phx-mounted={JS.ignore_attributes(["class"])}
        class="drawer-overlay right-sidebar-overlay fixed inset-0 z-[150] hidden bg-slate-900/60"
      >
      </div>
      <div
        id={@id <> "-content"}
        data-drawer-content
        role="dialog"
        aria-modal="true"
        aria-label={@label}
        aria-hidden="true"
        phx-mounted={JS.ignore_attributes(["class", "aria-hidden"])}
        class="drawer-content right-sidebar-content fixed right-0 top-0 z-[151] hidden h-full w-full sm:w-80"
      >
        <div class="relative flex h-full w-full flex-col bg-white dark:bg-navy-750">
          <div class="flex items-center justify-between py-2 px-4">
            <div class="flex min-w-0 items-center">{render_slot(@title)}</div>
            <button
              type="button"
              data-drawer-close
              aria-label="Close"
              class="btn -mr-1 size-6 rounded-full p-0 hover:bg-slate-300/20 focus:bg-slate-300/20 active:bg-slate-300/25 dark:hover:bg-navy-300/20 dark:focus:bg-navy-300/20 dark:active:bg-navy-300/25"
            >
              <.glyph name={:close} class="size-4" />
            </button>
          </div>
          {render_slot(@inner_block)}
          {render_slot(@footer)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  The header button (LineOne's grid icon) that toggles a `right_sidebar/1`; `header/1` renders one with
  `right_sidebar="id"`.

      <.right_sidebar_toggle target="right-sidebar" />
  """
  attr :target, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def right_sidebar_toggle(assigns) do
    assigns = assign(assigns, :icon_button, @icon_button)

    ~H"""
    <button
      type="button"
      aria-label="Toggle right sidebar"
      aria-controls={@target}
      phx-click={LineaUI.toggle(@target)}
      class={merge([@icon_button, @class])}
      {@rest}
    >
      <.glyph name={:apps} class="size-5.5 text-slate-500 dark:text-navy-100" stroke_width="1.5" />
    </button>
    """
  end

  @doc """
  The menu of the framed shell (`<.app_shell layout="framed">`): the brand, an optional workspace and search,
  the navigation (`rail_link/1`, `rail_module/1`) and the bottom items. It collapses to a 60px rail of
  icons: the labels (any element with the class `rail-label`) go away, badges become dots and a tooltip shows
  the label on hover. The choice is kept in `localStorage` (`persist`); a `collapsed` the server changes wins
  over it. Below 768px it is a top bar with a hamburger that opens the menu under it.

      <.framed_sidebar id="menu" collapsed={@collapsed} on_collapse="collapse">
        <:brand><img src={~p"/images/mark.svg"} alt="" class="size-5" /></:brand>
        <:wordmark>Signetum</:wordmark>
        <.rail_link navigate={~p"/today"} label="Today"><svg>…</svg></.rail_link>
      </.framed_sidebar>

      def handle_event("collapse", %{"collapsed" => collapsed}, socket),
        do: {:noreply, assign(socket, :collapsed, collapsed)}

  Put `<.rail_toggle for="menu" />` anywhere (the header, the bottom of the menu) for the button that collapses it.
  """
  attr :id, :string, required: true
  attr :collapsed, :boolean, default: false, doc: "Whether the menu starts as a rail."

  attr :persist, :boolean,
    default: true,
    doc: "Keep the choice in `localStorage[\"linea-rail\"]`."

  attr :on_collapse, :string,
    default: nil,
    doc:
      "An event pushed with `%{\"id\" => id, \"collapsed\" => boolean}` when the choice changes."

  attr :target, :any, default: nil, doc: "The `phx-target` of `on_collapse`."
  attr :label, :string, default: "Main menu", doc: "The accessible name of the menu."
  attr :mobile_label, :string, default: "Menu", doc: "The accessible name of the hamburger."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :brand, doc: "The mark in its rounded box (a logo image)."
  slot :wordmark, doc: "The name next to the mark; hidden in the rail."
  slot :workspace, doc: "The workspace switcher under the brand; hidden in the rail."
  slot :search, doc: "The search box; mark what the rail hides with `rail-label`."
  slot :bottom, doc: "Items under the navigation: settings, the person."
  slot :inner_block, required: true, doc: "The navigation: `rail_link/1` and `rail_module/1`."

  def framed_sidebar(assigns) do
    ~H"""
    <aside
      id={@id}
      class={merge(["linea-rail", @class])}
      aria-label={@label}
      phx-hook="LineaUI.ShellRail"
      phx-mounted={JS.ignore_attributes(["data-collapsed", "data-mobile-open"])}
      data-collapsed={bool(@collapsed)}
      data-server-collapsed={bool(@collapsed)}
      data-mobile-open="false"
      data-persist={bool(@persist)}
      data-on-collapse={@on_collapse}
      data-target={@target}
      {@rest}
    >
      <div class="rail-bar">
        <div class="rail-brand">
          <span :if={@brand != []} class="rail-mark">{render_slot(@brand)}</span>
          <span :if={@wordmark != []} class="rail-label rail-wordmark">{render_slot(@wordmark)}</span>
        </div>
        <button
          type="button"
          class="rail-burger"
          aria-expanded="false"
          aria-controls={@id <> "-body"}
          aria-label={@mobile_label}
          data-mobile-toggle
        >
          <svg
            class="size-5"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            aria-hidden="true"
          >
            <path d="M4 7h16M4 12h16M4 17h16" />
          </svg>
        </button>
      </div>
      <div id={@id <> "-body"} class="rail-body">
        <div :if={@workspace != []} class="rail-label">{render_slot(@workspace)}</div>
        <div :if={@search != []} class="rail-search">{render_slot(@search)}</div>
        <nav class="rail-nav" aria-label={@label}>{render_slot(@inner_block)}</nav>
        {render_slot(@bottom)}
      </div>
    </aside>
    """
  end

  @doc """
  A button that collapses and expands the `framed_sidebar/1` with that id, from anywhere on the page. It is
  pressed (`aria-pressed`) while the menu is a rail.

      <.rail_toggle for="menu" label="Collapse menu" />
  """
  attr :for, :string, required: true, doc: "The id of the `framed_sidebar/1`."
  attr :label, :string, default: "Collapse menu"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "The icon; the default is a panel with its sidebar."

  def rail_toggle(assigns) do
    ~H"""
    <button
      type="button"
      class={merge([icon_button(), @class])}
      aria-label={@label}
      aria-pressed="false"
      data-rail-toggle={@for}
      {@rest}
    >
      {render_slot(@inner_block) || rail_toggle_icon(assigns)}
    </button>
    """
  end

  defp rail_toggle_icon(assigns) do
    ~H"""
    <svg
      class="size-4.5"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <rect x="3" y="4" width="18" height="16" rx="3" />
      <path d="M9 4v16" />
    </svg>
    """
  end

  @doc """
  A page of the framed menu: the icon, the label, an optional badge and a tooltip with the label for the rail.

      <.rail_link navigate={~p"/today"} label="Today" current={@current_path}><svg>…</svg></.rail_link>
      <.rail_link navigate={~p"/chat"} label="Chat" badge="2">…</.rail_link>
  """
  attr :label, :string, required: true
  attr :badge, :string, default: nil, doc: "A count; a red dot in the rail."
  attr :active, :boolean, default: false

  attr :current, :string,
    default: nil,
    doc: "The current path; the link is active when it matches."

  attr :class, :any, default: nil
  attr :rest, :global, include: @link_attrs
  slot :inner_block, required: true, doc: "The icon."

  def rail_link(assigns) do
    assigns = assign(assigns, :active, assigns.active or active?(assigns.rest, assigns.current))

    ~H"""
    <.link
      class={merge(["rail-item", @active && "is-active", @class])}
      aria-label={@label}
      aria-current={@active && "page"}
      {@rest}
    >
      <span class="rail-icon" aria-hidden="true">{render_slot(@inner_block)}</span>
      <span class="rail-label rail-text">{@label}</span>
      <span :if={@badge} class="rail-badge">{@badge}</span>
      <span class="rail-tip" role="tooltip">{@label}</span>
    </.link>
    """
  end

  @doc """
  A module of the framed menu: a button that opens the pages under it. The module of the current page
  starts open; opening and closing it needs no round trip, and a patch keeps what the person chose. In the
  rail a click on it expands the menu and opens the module.

      <.rail_module id="sales" label="Sales" badge="3" current={@current_path}>
        <:icon><svg>…</svg></:icon>
        <:item navigate={~p"/orders"}>Orders</:item>
        <:item navigate={~p"/products"}>Products</:item>
      </.rail_module>
  """
  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :badge, :string, default: nil, doc: "A count; a red dot in the rail."
  attr :open, :boolean, default: nil, doc: "Defaults to whether one of the pages is active."
  attr :current, :string, default: nil, doc: "The current path; the matching page is active."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon, required: true

  slot :item, required: true, doc: "A page: `navigate`, `patch` or `href`, and `active`." do
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
    attr :active, :boolean
  end

  def rail_module(assigns) do
    items = Enum.map(assigns.item, &Map.put(&1, :active, active?(&1, assigns.current)))
    open = group_open?(assigns.open, items)

    assigns =
      assigns
      |> assign(:items, items)
      |> assign(:module_open, open)
      |> assign(:module_active, Enum.any?(items, & &1.active))

    ~H"""
    <div
      id={@id}
      class={merge(["rail-module", @class])}
      data-open={bool(@module_open)}
      phx-mounted={JS.ignore_attributes(["data-open"])}
      {@rest}
    >
      <button
        type="button"
        class={["rail-item", @module_active && "is-active"]}
        aria-label={@label}
        aria-expanded={bool(@module_open)}
        aria-controls={@id <> "-pages"}
        aria-current={@module_active && "true"}
        phx-mounted={JS.ignore_attributes(["aria-expanded"])}
        phx-click={
          JS.toggle_attribute({"data-open", "true", "false"}, to: "##{@id}")
          |> JS.toggle_attribute({"aria-expanded", "true", "false"})
        }
        data-module
      >
        <span class="rail-icon" aria-hidden="true">{render_slot(@icon)}</span>
        <span class="rail-label rail-text">{@label}</span>
        <span :if={@badge} class="rail-badge">{@badge}</span>
        <svg
          class="rail-label rail-chev"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          aria-hidden="true"
        >
          <path d="m9 6 6 6-6 6" />
        </svg>
        <span class="rail-tip" role="tooltip">{@label}</span>
      </button>
      <div id={@id <> "-pages"} class="rail-sub">
        <.link
          :for={item <- @items}
          aria-current={item.active && "page"}
          {link_attrs(item)}
        >
          {render_slot(item)}
        </.link>
      </div>
    </div>
    """
  end

  @doc """
  The person at the bottom of the framed menu: their picture and, outside the rail, their name and subtitle.

      <.rail_user name="Ana Souza" subtitle="Admin"><.avatar name="Ana Souza" color="auto" size="32" /></.rail_user>
  """
  attr :name, :string, required: true
  attr :subtitle, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true, doc: "The picture."

  def rail_user(assigns) do
    ~H"""
    <div class={merge(["rail-user", @class])} {@rest}>
      {render_slot(@inner_block)}
      <span class="rail-label min-w-0">
        <span class="block truncate text-sm font-medium text-slate-800 dark:text-navy-50">{@name}</span>
        <span :if={@subtitle} class="block truncate text-xs text-slate-400 dark:text-navy-300">
          {@subtitle}
        </span>
      </span>
    </div>
    """
  end

  @doc """
  The title of a page with LineOne's breadcrumb next to it: the crumbs with a link are followed by a
  chevron, the last one is plain text.

      <.page_header title="Avatar">
        <:crumb navigate={~p"/elements"}>Elements</:crumb>
        <:crumb>Avatar</:crumb>
        <:actions><.button color="primary">New</.button></:actions>
      </.page_header>
  """
  attr :title, :string, required: true

  attr :variant, :string,
    default: "inline",
    values: ~w(inline page),
    doc:
      "`inline` is LineOne's row, the title with its crumbs beside it. `page` is the framed shell's title block: the crumbs with the clock and the bell on top, then the badge, the 28px title with a context line and the actions, and the tabs."

  attr :description, :string,
    default: nil,
    doc: "The context line under the title (`variant=\"page\"`)."

  attr :clock, :boolean,
    default: false,
    doc: "The date and time at the end of the top row, kept current (`variant=\"page\"`)."

  attr :locale, :string,
    default: nil,
    doc: "The language of the clock (`pt-BR`); the browser's when not given."

  attr :bell, :boolean,
    default: false,
    doc: "A bell button at the end of the top row (`variant=\"page\"`)."

  attr :bell_label, :string, default: "Notifications"
  attr :on_bell, :any, default: nil, doc: "An event name or a `%JS{}` for the bell's click."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :crumb do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
  end

  slot :actions, doc: "Buttons or filters at the right end of the row."
  slot :inner_block, doc: "Content after the breadcrumb."
  slot :badge, doc: "The status badge above the title (`variant=\"page\"`)."
  slot :notifications, doc: "Replaces the bell with your own button or menu (`variant=\"page\"`)."
  slot :tabs, doc: "The page's tabs under the title, over a rule (`variant=\"page\"`)."

  def page_header(%{variant: "page"} = assigns) do
    assigns = assign(assigns, :crumbs, mark_last(assigns.crumb))

    ~H"""
    <header class={merge(["flex flex-col gap-[18px]", @class])} {@rest}>
      <div class="flex items-center gap-2.5">
        <nav
          :if={@crumb != []}
          aria-label="Breadcrumb"
          class="flex min-w-0 flex-wrap items-center gap-2.5 text-sm text-slate-500 dark:text-navy-200"
        >
          <%= for {crumb, last} <- @crumbs do %>
            <.link
              :if={link?(crumb)}
              class="text-primary transition-colors hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
              {link_attrs(crumb)}
            >
              {render_slot(crumb)}
            </.link>
            <span
              :if={!link?(crumb)}
              aria-current={last && "page"}
              class={last && "text-slate-800 dark:text-navy-50"}
            >
              {render_slot(crumb)}
            </span>
            <span :if={!last} aria-hidden="true">/</span>
          <% end %>
        </nav>
        {render_slot(@inner_block)}
        <div class="ml-auto flex items-center gap-2.5">
          <span
            :if={@clock}
            id={"#{@rest[:id] || "page-header-#{:erlang.phash2(@title)}"}-clock"}
            class="hidden text-sm text-slate-400 sm:inline dark:text-navy-300"
            phx-hook="LineaUI.ShellClock"
            data-locale={@locale}
          ></span>
          {render_slot(@notifications)}
          <button
            :if={@bell and @notifications == []}
            type="button"
            class={icon_button()}
            aria-label={@bell_label}
            phx-click={@on_bell}
          >
            <.glyph name={:bell} class="size-5" />
          </button>
        </div>
      </div>
      <div class="flex flex-wrap items-end justify-between gap-5">
        <div class="min-w-0">
          <div :if={@badge != []} class="flex items-center gap-2.5">{render_slot(@badge)}</div>
          <h1 class="mt-1.5 mb-1 text-[28px] leading-9 font-semibold tracking-[-0.02em] text-slate-800 dark:text-navy-50">
            {@title}
          </h1>
          <p :if={@description} class="text-sm text-slate-500 dark:text-navy-200">{@description}</p>
        </div>
        <div :if={@actions != []} class="flex items-center gap-2.5">{render_slot(@actions)}</div>
      </div>
      <div
        :if={@tabs != []}
        class="-mb-px flex items-end gap-2.5 border-b border-slate-150 dark:border-navy-600"
      >
        {render_slot(@tabs)}
      </div>
    </header>
    """
  end

  def page_header(assigns) do
    assigns = assign(assigns, :crumbs, mark_last(assigns.crumb))

    ~H"""
    <div class={merge(["flex items-center space-x-4 py-5 lg:py-6", @class])} {@rest}>
      <h2 class="text-xl font-medium text-slate-800 dark:text-navy-50 lg:text-2xl">{@title}</h2>
      <div :if={@crumb != []} class="hidden h-full py-1 sm:flex">
        <div class="h-full w-px bg-slate-300 dark:bg-navy-600"></div>
      </div>
      <ul :if={@crumb != []} class="hidden flex-wrap items-center space-x-2 sm:flex">
        <li :for={{crumb, last} <- @crumbs} class={!last && "flex items-center space-x-2"}>
          <.link
            :if={link?(crumb)}
            class="text-primary transition-colors hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
            {link_attrs(crumb)}
          >
            {render_slot(crumb)}
          </.link>
          <span :if={!link?(crumb)} aria-current={last && "page"}>{render_slot(crumb)}</span>
          <.glyph :if={!last} name={:chevron_right} class="size-4" />
        </li>
      </ul>
      {render_slot(@inner_block)}
      <div :if={@actions != []} class="ml-auto flex items-center space-x-2">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  defp mark_last(entries) do
    count = length(entries)
    Enum.with_index(entries, fn entry, index -> {entry, index == count - 1} end)
  end

  @doc """
  LineOne's dark mode button: a moon in dark mode, a sun in light mode. It toggles the `dark` class of `<html>`
  and keeps it in `localStorage["dark-mode"]`. `on_change` gets `%{"dark" => boolean}` (an event name) or runs
  (a `%JS{}`).

      <.theme_toggle id="theme" on_change="theme-changed" />
  """
  attr :id, :string, default: "theme-toggle"
  attr :on_change, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def theme_toggle(assigns) do
    assigns = assign(assigns, :icon_button, @icon_button)

    ~H"""
    <button
      type="button"
      id={@id}
      phx-hook="LineaUI.ThemeToggle"
      phx-mounted={JS.ignore_attributes(["aria-pressed"])}
      aria-label="Toggle dark mode"
      data-change-event={event_name(@on_change)}
      data-on-change={js_command(@on_change)}
      data-target={@target}
      class={merge(["darkmode-toggle", @icon_button, @class])}
      {@rest}
    >
      <.glyph name={:moon} class="darkmode-moon size-6 text-amber-400" />
      <.glyph name={:sun} class="darkmode-sun size-6 text-amber-400" />
    </button>
    """
  end

  @doc """
  LineOne's monochrome mode: the palette button of the header (`variant="button"`) or the switch of its
  monochrome page (`variant="switch"`, the label as content). It toggles the `is-monochrome` class of `<body>`
  and keeps it in `localStorage["monochrome-mode"]`; every toggle on the page follows. `on_change` gets
  `%{"monochrome" => boolean}` or runs.

      <.monochrome_toggle id="mono" />
      <.monochrome_toggle id="mono-switch" variant="switch">Toggle Monochrome Mode</.monochrome_toggle>
  """
  attr :id, :string, default: "monochrome-toggle"
  attr :variant, :string, default: "button", values: ~w(button switch)
  attr :on_change, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def monochrome_toggle(%{variant: "switch"} = assigns) do
    ~H"""
    <label class={merge(["flex items-center space-x-2", @class])}>
      <input
        id={@id}
        type="checkbox"
        phx-hook="LineaUI.MonochromeToggle"
        data-change-event={event_name(@on_change)}
        data-on-change={js_command(@on_change)}
        data-target={@target}
        class="form-switch h-5 w-10 rounded-lg bg-slate-300 before:rounded-md before:bg-slate-50 checked:bg-slate-500 checked:before:bg-white dark:bg-navy-900 dark:before:bg-navy-300 dark:checked:bg-navy-400 dark:checked:before:bg-white"
        {@rest}
      />
      <span :if={@inner_block != []}>{render_slot(@inner_block)}</span>
    </label>
    """
  end

  def monochrome_toggle(assigns) do
    assigns = assign(assigns, :icon_button, @icon_button)

    ~H"""
    <button
      type="button"
      id={@id}
      phx-hook="LineaUI.MonochromeToggle"
      phx-mounted={JS.ignore_attributes(["aria-pressed"])}
      aria-label="Toggle monochrome mode"
      data-change-event={event_name(@on_change)}
      data-on-change={js_command(@on_change)}
      data-target={@target}
      class={merge(["monochrome-toggle", @icon_button, @class])}
      {@rest}
    >
      <svg class="size-4.5" viewBox="0 0 512 512" aria-hidden="true">
        <defs>
          <linearGradient id={@id <> "-gradient"} x1="0" y1="0" x2="1" y2="0">
            <stop offset="0" stop-color="var(--color-sky-400)" />
            <stop offset="1" stop-color="var(--color-blue-600)" />
          </linearGradient>
        </defs>
        <path
          fill={"url(##{@id}-gradient)"}
          d="M512 256c0 .9 0 1.8 0 2.7c-.4 36.5-33.6 61.3-70.1 61.3H344c-26.5 0-48 21.5-48 48c0 3.4 .4 6.7 1 9.9c2.1 10.2 6.5 20 10.8 29.9c6.1 13.8 12.1 27.5 12.1 42c0 31.8-21.6 60.7-53.4 62c-3.5 .1-7 .2-10.6 .2C114.6 512 0 397.4 0 256S114.6 0 256 0S512 114.6 512 256zM128 288a32 32 0 1 0 -64 0 32 32 0 1 0 64 0zm0-96a32 32 0 1 0 0-64 32 32 0 1 0 0 64zM288 96a32 32 0 1 0 -64 0 32 32 0 1 0 64 0zm96 96a32 32 0 1 0 0-64 32 32 0 1 0 0 64z"
        />
      </svg>
    </button>
    """
  end

  @doc """
  The script for the root layout's `<head>` that applies the stored dark mode before the first paint (LineOne's
  "prevent flickering" script) and the stored monochrome mode as soon as `<body>` exists.

      <head>
        <.theme_script />
      </head>
  """
  attr :rest, :global

  def theme_script(assigns) do
    ~H"""
    <script phx-no-curly-interpolation {@rest}>
      (() => {
        try {
          localStorage.getItem("dark-mode") === "dark" && document.documentElement.classList.add("dark");
          localStorage.getItem("monochrome-mode") === "monochrome" &&
            document.addEventListener("DOMContentLoaded", () => document.body.classList.add("is-monochrome"));
        } catch (_e) {}
      })();
    </script>
    """
  end

  defp icon_button, do: @icon_button

  defp link_attrs(entry), do: Map.take(entry, [:href, :navigate, :patch, :method, :replace])

  defp link?(entry), do: Enum.any?([:href, :navigate, :patch], &Map.has_key?(entry, &1))

  defp active?(%{active: true}, _current), do: true
  defp active?(_entry, nil), do: false

  defp active?(entry, current),
    do: path_of(entry[:navigate] || entry[:patch] || entry[:href]) == path_of(current)

  defp path_of(nil), do: :none
  defp path_of(url) when is_binary(url), do: url |> URI.parse() |> Map.fetch!(:path)

  defp slug(label) do
    label
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp event_name(event) when is_binary(event), do: event
  defp event_name(_other), do: nil

  defp js_command(%JS{} = js), do: js
  defp js_command(_other), do: nil
end
