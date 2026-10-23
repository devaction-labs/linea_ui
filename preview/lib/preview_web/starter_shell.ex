defmodule PreviewWeb.StarterShell do
  @moduledoc """
  LineOne's starter pages rebuilt with the AppShell components, shared by the six `PagesStarter*` pages.

  The shell is drawn inside a frame with a transform, so its `fixed` parts stay inside the preview; the
  "Full screen" button (or `#starter-fullscreen`) puts the frame over the whole window, Esc brings it back.
  """

  use PreviewWeb, :html

  @logo "/lineone/images/app-logo.svg"
  @avatar "/lineone/images/avatar/avatar-12.jpg"

  @groups [
    {"Onboarding", ["Onboarding v1", "Onboarding v2"]},
    {"User Card", Enum.map(1..7, &"User Card #{&1}")},
    {"Blog Card", Enum.map(1..8, &"Blog Card #{&1}") ++ ["Blog Details"]},
    {"Help", ["Help 1", "Help 2", "Help 3"]},
    {"Price List", Enum.map(1..4, &"Price List #{&1}")},
    {"Invoice", ["Invoice 1", "Invoice 2"]}
  ]

  @auth [{"Sign In", ["Sign In 1", "Sign In 2"]}, {"Sign Up", ["Sign Up 1", "Sign Up 2"]}]

  @errors [
    "Error 404 v1",
    "Error 404 v2",
    "Error 404 v3",
    "Error 404 v4",
    "Error 401",
    "Error 429",
    "Error 500"
  ]

  @starters [
    {"Blurred Header", "/pages-starter1"},
    {"Unblurred Header", "/pages-starter2"},
    {"Centered Links", "/pages-starter3"},
    {"Minimal Sidebar", "/pages-starter4"},
    {"Horizontal Navigation", "/pages-starter5"},
    {"Sideblock", "/pages-starter6"}
  ]

  @rail [
    {"dashboards", "Dashboards"},
    {"apps", "Applications"},
    {"pages", "Pages & Layouts"},
    {"forms", "Forms"},
    {"components", "Components"},
    {"elements", "Elements"}
  ]

  @min_colors ~w(neutral neutral neutral neutral error success warning error info)

  @menus [
    {"dashboards", "Dashboards"},
    {"apps", "Apps"},
    {"pages", "Pages"},
    {"forms", "Forms"},
    {"components", "Components"}
  ]

  @doc "The assigns a starter page starts with."
  def mount(socket, current),
    do: Phoenix.Component.assign(socket, sidebar_open: nil, current: current)

  @doc "Keeps the server's sidebar state in sync with the browser."
  def handle_event("sidebar", %{"open" => open}, socket),
    do: {:noreply, Phoenix.Component.assign(socket, :sidebar_open, open)}

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  attr :layout, :string, default: "sidebar"
  attr :header_blur, :boolean, default: true
  attr :centered, :boolean, default: false
  attr :sidebar_open, :boolean, default: nil
  attr :current, :string, required: true

  def starter(assigns) do
    assigns =
      assign(assigns,
        logo: @logo,
        avatar: @avatar,
        groups: @groups,
        auth: @auth,
        errors: @errors,
        starters: @starters,
        rail: @rail,
        min_colors: Enum.with_index(@min_colors, 1),
        menus: @menus
      )

    ~H"""
    <div class="flex justify-end">
      <button
        id="starter-fullscreen"
        type="button"
        class="text-xs text-primary hover:text-primary-focus dark:text-accent-light"
        phx-click={JS.toggle_class(fullscreen_classes(), to: "#starter-frame")}
      >
        Full screen
      </button>
    </div>
    <div
      id="starter-frame"
      phx-window-keydown={
        JS.remove_class(fullscreen_on(), to: "#starter-frame")
        |> JS.add_class(fullscreen_off(), to: "#starter-frame")
      }
      phx-key="Escape"
      class="relative h-[calc(100vh-9rem)] min-h-[560px] overflow-hidden rounded-lg border border-slate-150 [transform:translateZ(0)] dark:border-navy-700"
    >
      <.app_shell
        id="starter-shell"
        layout={@layout}
        header_blur={@header_blur}
        sidebar_open={@sidebar_open}
        on_toggle="sidebar"
        class="h-full min-h-full"
      >
        <:sidebar>
          <.main_sidebar :if={@layout != "sideblock"} current={@current} centered={@centered}>
            <:logo navigate="/" src={@logo} />
            <:item :for={{name, label} <- @rail} href="#" label={label} active={name == "pages"}>
              <.icon name={name} class="size-7" />
            </:item>
            <:bottom>
              <.main_sidebar_link href="#" label="Settings">
                <.icon name="settings" class="size-7" />
              </.main_sidebar_link>
              <.profile avatar={@avatar} />
            </:bottom>
          </.main_sidebar>
          <.sidebar_panel :if={@layout != "sideblock"} title="Layouts">
            <.layout_nav {assigns} />
          </.sidebar_panel>
          <.sidebar_panel_min :if={@layout == "minimal"}>
            <:header>
              <div class="avatar flex size-10 rounded-full bg-info/10 text-info">
                <div class="is-initial"><.icon name="min-0" class="size-5" /></div>
              </div>
            </:header>
            <.sidebar_min_group>
              <.sidebar_min_link
                :for={{color, index} <- Enum.take(@min_colors, 5)}
                href="#"
                color={color}
                active={index == 1}
                label={"Link #{index}"}
              >
                <.icon name={"min-#{index}"} class="size-5.5" />
              </.sidebar_min_link>
            </.sidebar_min_group>
            <.sidebar_min_divider />
            <.sidebar_min_group>
              <.sidebar_min_link
                :for={{color, index} <- Enum.drop(@min_colors, 5)}
                href="#"
                color={color}
                label={"List #{index}"}
              >
                <.icon name={"min-#{index}"} class="size-5.5" />
              </.sidebar_min_link>
            </.sidebar_min_group>
            <:footer>
              <.button
                variant="outline"
                shape="pill"
                icon
                class="size-10 font-medium"
                aria-label="More"
              >
                <.icon name="min-10" class="size-6" />
              </.button>
            </:footer>
          </.sidebar_panel_min>
          <.sideblock :if={@layout == "sideblock"}>
            <:logo navigate="/" src={@logo} />
            <.layout_nav {assigns} />
          </.sideblock>
        </:sidebar>
        <:header>
          <.header right_sidebar="starter-right-sidebar">
            <:brand :if={@layout == "horizontal"} navigate="/" src={@logo} label="lineone" />
            <:search_results><.search_results /></:search_results>
            <:mobile_search><.search_results mobile /></:mobile_search>
            <:notifications><.notifications /></:notifications>
            <:nav :if={@layout == "horizontal"}>
              <.horizontal_nav_menu
                :for={{name, label} <- @menus}
                id={"starter-nav-" <> name}
                label={label}
                active={name == "pages"}
              >
                <:icon><.icon name={name} class="size-6" /></:icon>
                <:item href="#">Link</:item>
                <:item href="#">Another Link</:item>
                <:item href="#">Something else</:item>
                <.horizontal_nav_divider />
                <.horizontal_nav_link href="#">Separated Link</.horizontal_nav_link>
              </.horizontal_nav_menu>
            </:nav>
          </.header>
        </:header>
        <:aside>
          <.right_sidebar id="starter-right-sidebar" label="Right sidebar">
            <:title>
              <p class="flex shrink-0 items-center space-x-1.5">
                <svg class="size-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
                <span class="text-xs">25 May, 2022</span>
              </p>
            </:title>
            <.right_sidebar_home />
          </.right_sidebar>
        </:aside>
        <.page_header title="Blank Template" />
      </.app_shell>
    </div>
    """
  end

  defp fullscreen_on, do: "fixed inset-0 z-[200] h-screen rounded-none border-0"
  defp fullscreen_off, do: "relative h-[calc(100vh-9rem)] rounded-lg border"
  defp fullscreen_classes, do: fullscreen_on() <> " " <> fullscreen_off()

  defp layout_nav(assigns) do
    ~H"""
    <.sidebar_nav>
      <.sidebar_nav_group :for={{label, items} <- @groups} label={label}>
        <:item :for={item <- items} href="#">{item}</:item>
      </.sidebar_nav_group>
    </.sidebar_nav>
    <.sidebar_nav_divider />
    <.sidebar_nav>
      <.sidebar_nav_group :for={{label, items} <- @auth} label={label}>
        <:item :for={item <- items} href="#">{item}</:item>
      </.sidebar_nav_group>
    </.sidebar_nav>
    <.sidebar_nav_divider />
    <.sidebar_nav>
      <.sidebar_nav_group label="Error">
        <:item :for={item <- @errors} href="#">{item}</:item>
      </.sidebar_nav_group>
      <.sidebar_nav_group label="Starter" current={@current}>
        <:item :for={{label, path} <- @starters} navigate={path}>{label}</:item>
      </.sidebar_nav_group>
    </.sidebar_nav>
    """
  end

  attr :avatar, :string, required: true

  defp profile(assigns) do
    ~H"""
    <.sidebar_profile
      id="starter-profile"
      src={@avatar}
      name="Travis Fuller"
      subtitle="Product Designer"
      href="#"
    >
      <:item href="#" color="warning" title="Profile" description="Your profile setting">
        <.icon name="profile" class="size-4.5" />
      </:item>
      <:item href="#" color="info" title="Messages" description="Your messages and tasks">
        <.icon name="messages" class="size-4.5" />
      </:item>
      <:item href="#" color="secondary" title="Team" description="Your team activity">
        <.icon name="team" class="size-4.5" />
      </:item>
      <:item href="#" color="error" title="Activity" description="Your activity and events">
        <.icon name="activity" class="size-4.5" />
      </:item>
      <:item href="#" color="success" title="Settings" description="Webapp settings">
        <.icon name="app-settings" class="size-4.5" />
      </:item>
      <:footer>
        <.button color="primary" class="h-9 w-full space-x-2">
          <.icon name="logout" class="size-5" />
          <span>Logout</span>
        </.button>
      </:footer>
    </.sidebar_profile>
    """
  end

  attr :mobile, :boolean, default: false

  defp search_results(assigns) do
    ~H"""
    <div class={[
      "is-scrollbar-hidden flex shrink-0 overflow-x-auto px-2 text-slate-600 dark:text-navy-200",
      @mobile && "bg-slate-100 dark:bg-navy-800",
      !@mobile && "rounded-t-lg bg-slate-100 dark:bg-navy-800"
    ]}>
      <button
        :for={{tab, index} <- Enum.with_index(~w(All Files Chats Emails Projects Tasks))}
        type="button"
        class={[
          "btn shrink-0 rounded-none border-b-2 px-3.5 py-2.5",
          index == 0 && "border-primary text-primary dark:border-accent dark:text-accent-light",
          index != 0 &&
            "border-transparent hover:text-slate-800 focus:text-slate-800 dark:hover:text-navy-100 dark:focus:text-navy-100"
        ]}
      >
        {tab}
      </button>
    </div>
    <div class="is-scrollbar-hidden overflow-y-auto overscroll-contain pb-2">
      <div class="is-scrollbar-hidden mt-3 flex space-x-4 overflow-x-auto px-3">
        <a
          :for={
            {label, color} <- [
              {"Kanban", "bg-success"},
              {"Analytics", "bg-secondary"},
              {"Chat", "bg-info"},
              {"Files", "bg-error"},
              {"Banking", "bg-secondary"},
              {"Mail", "bg-primary dark:bg-accent"}
            ]
          }
          href="#"
          class="w-14 text-center"
        >
          <div class="avatar size-12">
            <div class={["is-initial rounded-full text-white", color]}>{String.first(label)}</div>
          </div>
          <p class="mt-1.5 overflow-hidden text-ellipsis whitespace-nowrap text-xs text-slate-700 dark:text-navy-100">
            {label}
          </p>
        </a>
      </div>
      <div class="mt-3 flex items-center justify-between bg-slate-100 py-1.5 px-3 dark:bg-navy-800">
        <p class="text-xs uppercase text-slate-400 dark:text-navy-300">Recent</p>
        <a
          href="#"
          class="text-tiny-plus font-medium uppercase text-primary outline-hidden transition-colors duration-300 hover:text-primary/70 focus:text-primary/70 dark:text-accent-light dark:hover:text-accent-light/70 dark:focus:text-accent-light/70"
        >
          View All
        </a>
      </div>
      <div class="mt-1 font-inter font-medium">
        <a
          :for={label <- ["Chat App", "File Manager App", "Email App", "Kanban Board", "Todo App"]}
          href="#"
          class="group flex items-center space-x-2 px-2.5 py-2 tracking-wide outline-hidden transition-all hover:bg-slate-100 hover:text-slate-800 focus:bg-slate-100 focus:text-slate-800 dark:hover:bg-navy-600 dark:hover:text-navy-100 dark:focus:bg-navy-600 dark:focus:text-navy-100"
        >
          <.icon
            name="apps"
            class="size-4.5 text-slate-400 transition-colors group-hover:text-slate-500 group-focus:text-slate-500 dark:text-navy-300 dark:group-hover:text-navy-200 dark:group-focus:text-navy-200"
          />
          <span>{label}</span>
        </a>
      </div>
    </div>
    """
  end

  defp notifications(assigns) do
    ~H"""
    <div class="rounded-t-lg bg-slate-100 text-slate-600 dark:bg-navy-800 dark:text-navy-200">
      <div class="flex items-center justify-between px-4 pt-2">
        <div class="flex items-center space-x-2">
          <h3 class="font-medium text-slate-700 dark:text-navy-100">Notifications</h3>
          <div class="badge h-5 rounded-full bg-primary/10 px-1.5 text-primary dark:bg-accent-light/15 dark:text-accent-light">
            26
          </div>
        </div>
        <.button variant="flat" shape="pill" icon size="sm" class="-mr-1.5" aria-label="Settings">
          <.icon name="app-settings" class="size-4.5" />
        </.button>
      </div>
      <div class="is-scrollbar-hidden flex shrink-0 overflow-x-auto px-3">
        <button
          :for={{tab, index} <- Enum.with_index(~w(All Alerts Events Logs))}
          type="button"
          class={[
            "btn shrink-0 rounded-none border-b-2 px-3.5 py-2.5",
            index == 0 && "border-primary text-primary dark:border-accent dark:text-accent-light",
            index != 0 &&
              "border-transparent hover:text-slate-800 focus:text-slate-800 dark:hover:text-navy-100 dark:focus:text-navy-100"
          ]}
        >
          <span>{tab}</span>
        </button>
      </div>
    </div>
    <div class="is-scrollbar-hidden space-y-4 overflow-y-auto px-4 py-4">
      <div
        :for={
          {title, text, tone} <- [
            {"User Photo Changed", "John Doe changed his avatar photo",
             "bg-secondary/10 text-secondary dark:bg-secondary-light/15 dark:text-secondary-light"},
            {"Mon, June 14, 2021", "08:00 - 09:00 · Frontend Conf",
             "bg-info/10 text-info dark:bg-info/15"},
            {"Images Added", "Mores Clarke added new image gallery",
             "bg-primary/10 text-primary dark:bg-accent-light/15 dark:text-accent-light"},
            {"Design Completed", "Robert Nolan completed the design of the CRM application",
             "bg-success/10 text-success dark:bg-success/15"}
          ]
        }
        class="flex items-center space-x-3"
      >
        <div class={["flex size-10 shrink-0 items-center justify-center rounded-lg", tone]}>
          <.icon name="activity" class="size-5" />
        </div>
        <div>
          <p class="font-medium text-slate-600 dark:text-navy-100">{title}</p>
          <div class="mt-1 text-xs text-slate-400 line-clamp-1 dark:text-navy-300">{text}</div>
        </div>
      </div>
    </div>
    """
  end

  defp right_sidebar_home(assigns) do
    ~H"""
    <div class="is-scrollbar-hidden overflow-y-auto overscroll-contain pt-1">
      <label class="relative flex px-3">
        <input
          class="form-input peer h-8 w-full rounded-lg bg-slate-150 px-3 py-2 pl-9 text-xs-plus ring-primary/50 placeholder:text-slate-400 hover:bg-slate-200 focus:ring-3 dark:bg-navy-900/90 dark:ring-accent/50 dark:placeholder:text-navy-300 dark:hover:bg-navy-900 dark:focus:bg-navy-900"
          placeholder="Search here..."
          type="text"
        />
        <span class="pointer-events-none absolute flex h-full w-10 items-center justify-center text-slate-400 peer-focus:text-primary dark:text-navy-300 dark:peer-focus:text-accent">
          <.icon name="dashboards" class="size-4.5" />
        </span>
      </label>
      <div class="mt-3">
        <h2 class="px-3 text-xs-plus font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100">
          Banking cards
        </h2>
        <div class="mt-3 flex space-x-4 overflow-x-auto px-3 is-scrollbar-hidden">
          <div class="relative flex h-38 w-64 shrink-0 flex-col overflow-hidden rounded-xl bg-linear-to-br from-purple-500 to-indigo-600 p-3.5">
            <p class="text-xs text-white/80">Balance</p>
            <p class="text-xl font-semibold text-white">$2,139.22</p>
            <p class="mt-auto tracking-widest text-white">**** **** **** 8945</p>
          </div>
          <div class="relative flex h-38 w-64 shrink-0 flex-col overflow-hidden rounded-xl bg-linear-to-br from-pink-500 to-rose-500 p-3.5">
            <p class="text-xs text-white/80">Balance</p>
            <p class="text-xl font-semibold text-white">$2,139.22</p>
            <p class="mt-auto tracking-widest text-white">**** **** **** 8945</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :class, :string, default: nil

  defp icon(%{name: "dashboards"} = assigns) do
    ~H"""
    <svg aria-hidden="true" class={@class} fill="none" viewBox="0 0 24 24"><path
      fill="currentColor"
      fill-opacity=".3"
      d="M5 14.059c0-1.01 0-1.514.222-1.945.221-.43.632-.724 1.453-1.31l4.163-2.974c.56-.4.842-.601 1.162-.601.32 0 .601.2 1.162.601l4.163 2.974c.821.586 1.232.88 1.453 1.31.222.43.222.935.222 1.945V19c0 .943 0 1.414-.293 1.707C18.414 21 17.943 21 17 21H7c-.943 0-1.414 0-1.707-.293C5 20.414 5 19.943 5 19v-4.94Z"
    /><path
      fill="currentColor"
      d="M3 12.387c0 .267 0 .4.084.441.084.041.19-.04.4-.204l7.288-5.669c.59-.459.885-.688 1.228-.688.343 0 .638.23 1.228.688l7.288 5.669c.21.163.316.245.4.204.084-.04.084-.174.084-.441v-.409c0-.48 0-.72-.102-.928-.101-.208-.291-.355-.67-.65l-7-5.445c-.59-.459-.885-.688-1.228-.688-.343 0-.638.23-1.228.688l-7 5.445c-.379.295-.569.442-.67.65-.102.208-.102.448-.102.928v.409Z"
    /><path fill="currentColor" d="M11.5 15.5h1A1.5 1.5 0 0 1 14 17v3.5h-4V17a1.5 1.5 0 0 1 1.5-1.5Z" /><path
      fill="currentColor"
      d="M17.5 5h-1a.5.5 0 0 0-.5.5v3a.5.5 0 0 0 .5.5h1a.5.5 0 0 0 .5-.5v-3a.5.5 0 0 0-.5-.5Z"
    /></svg>
    """
  end

  defp icon(%{name: "apps"} = assigns) do
    ~H"""
    <svg aria-hidden="true" class={@class} viewBox="0 0 24 24" fill="none"><path
      d="M5 8H19V16C19 17.8856 19 18.8284 18.4142 19.4142C17.8284 20 16.8856 20 15 20H9C7.11438 20 6.17157 20 5.58579 19.4142C5 18.8284 5 17.8856 5 16V8Z"
      fill="currentColor"
      fill-opacity="0.3"
    /><path
      d="M12 8L11.7608 5.84709C11.6123 4.51089 10.4672 3.5 9.12282 3.5V3.5C7.68381 3.5 6.5 4.66655 6.5 6.10555V6.10555C6.5 6.97673 6.93539 7.79026 7.66025 8.2735L9.5 9.5"
      stroke="currentColor"
      stroke-linecap="round"
    /><path
      d="M12 8L12.2392 5.84709C12.3877 4.51089 13.5328 3.5 14.8772 3.5V3.5C16.3162 3.5 17.5 4.66655 17.5 6.10555V6.10555C17.5 6.97673 17.0646 7.79026 16.3397 8.2735L14.5 9.5"
      stroke="currentColor"
      stroke-linecap="round"
    /><rect x="4" y="8" width="16" height="3" rx="1" fill="currentColor" /><path
      d="M12 11V15"
      stroke="currentColor"
      stroke-linecap="round"
    /></svg>
    """
  end

  defp icon(%{name: "pages"} = assigns) do
    ~H"""
    <svg aria-hidden="true" class={@class} viewBox="0 0 24 24" fill="none"><path
      d="M9.85714 3H4.14286C3.51167 3 3 3.51167 3 4.14286V9.85714C3 10.4883 3.51167 11 4.14286 11H9.85714C10.4883 11 11 10.4883 11 9.85714V4.14286C11 3.51167 10.4883 3 9.85714 3Z"
      fill="currentColor"
    /><path
      d="M9.85714 12.8999H4.14286C3.51167 12.8999 3 13.4116 3 14.0428V19.757C3 20.3882 3.51167 20.8999 4.14286 20.8999H9.85714C10.4883 20.8999 11 20.3882 11 19.757V14.0428C11 13.4116 10.4883 12.8999 9.85714 12.8999Z"
      fill="currentColor"
      fill-opacity="0.3"
    /><path
      d="M19.757 3H14.0428C13.4116 3 12.8999 3.51167 12.8999 4.14286V9.85714C12.8999 10.4883 13.4116 11 14.0428 11H19.757C20.3882 11 20.8999 10.4883 20.8999 9.85714V4.14286C20.8999 3.51167 20.3882 3 19.757 3Z"
      fill="currentColor"
      fill-opacity="0.3"
    /><path
      d="M19.757 12.8999H14.0428C13.4116 12.8999 12.8999 13.4116 12.8999 14.0428V19.757C12.8999 20.3882 13.4116 20.8999 14.0428 20.8999H19.757C20.3882 20.8999 20.8999 20.3882 20.8999 19.757V14.0428C20.8999 13.4116 20.3882 12.8999 19.757 12.8999Z"
      fill="currentColor"
      fill-opacity="0.3"
    /></svg>
    """
  end

  defp icon(%{name: "forms"} = assigns) do
    ~H"""
    <svg aria-hidden="true" class={@class} viewBox="0 0 24 24" fill="none"><path
      fill-opacity="0.25"
      d="M21.0001 16.05V18.75C21.0001 20.1 20.1001 21 18.7501 21H6.6001C6.9691 21 7.3471 20.946 7.6981 20.829C7.7971 20.793 7.89609 20.757 7.99509 20.712C8.31009 20.586 8.61611 20.406 8.88611 20.172C8.96711 20.109 9.05711 20.028 9.13811 19.947L9.17409 19.911L15.2941 13.8H18.7501C20.1001 13.8 21.0001 14.7 21.0001 16.05Z"
      fill="currentColor"
    /><path
      fill-opacity="0.5"
      d="M17.7324 11.361L15.2934 13.8L9.17334 19.9111C9.80333 19.2631 10.1993 18.372 10.1993 17.4V8.70601L12.6384 6.26701C13.5924 5.31301 14.8704 5.31301 15.8244 6.26701L17.7324 8.17501C18.6864 9.12901 18.6864 10.407 17.7324 11.361Z"
      fill="currentColor"
    /><path
      d="M7.95 3H5.25C3.9 3 3 3.9 3 5.25V17.4C3 17.643 3.02699 17.886 3.07199 18.12C3.09899 18.237 3.12599 18.354 3.16199 18.471C3.20699 18.606 3.252 18.741 3.306 18.867C3.315 18.876 3.31501 18.885 3.31501 18.885C3.32401 18.885 3.32401 18.885 3.31501 18.894C3.44101 19.146 3.585 19.389 3.756 19.614C3.855 19.731 3.95401 19.839 4.05301 19.947C4.15201 20.055 4.26 20.145 4.377 20.235L4.38601 20.244C4.61101 20.415 4.854 20.559 5.106 20.685C5.115 20.676 5.11501 20.676 5.11501 20.685C5.25001 20.748 5.385 20.793 5.529 20.838C5.646 20.874 5.76301 20.901 5.88001 20.928C6.11401 20.973 6.357 21 6.6 21C6.969 21 7.347 20.946 7.698 20.829C7.797 20.793 7.89599 20.757 7.99499 20.712C8.30999 20.586 8.61601 20.406 8.88601 20.172C8.96701 20.109 9.05701 20.028 9.13801 19.947L9.17399 19.911C9.80399 19.263 10.2 18.372 10.2 17.4V5.25C10.2 3.9 9.3 3 7.95 3ZM6.6 18.75C5.853 18.75 5.25 18.147 5.25 17.4C5.25 16.653 5.853 16.05 6.6 16.05C7.347 16.05 7.95 16.653 7.95 17.4C7.95 18.147 7.347 18.75 6.6 18.75Z"
      fill="currentColor"
    /></svg>
    """
  end

  defp icon(%{name: "components"} = assigns) do
    ~H"""
    <svg aria-hidden="true" class={@class} viewBox="0 0 24 24" fill="none"><path
      fill-opacity="0.5"
      d="M14.2498 16C14.2498 17.5487 13.576 18.9487 12.4998 19.9025C11.5723 20.7425 10.3473 21.25 8.99976 21.25C6.10351 21.25 3.74976 18.8962 3.74976 16C3.74976 13.585 5.39476 11.5375 7.61726 10.9337C8.22101 12.4562 9.51601 13.6287 11.1173 14.0662C11.5548 14.1887 12.0185 14.25 12.4998 14.25C12.981 14.25 13.4448 14.1887 13.8823 14.0662C14.1185 14.6612 14.2498 15.3175 14.2498 16Z"
      fill="currentColor"
    /><path
      d="M17.75 9.00012C17.75 9.68262 17.6187 10.3389 17.3825 10.9339C16.7787 12.4564 15.4837 13.6289 13.8825 14.0664C13.445 14.1889 12.9813 14.2501 12.5 14.2501C12.0187 14.2501 11.555 14.1889 11.1175 14.0664C9.51625 13.6289 8.22125 12.4564 7.6175 10.9339C7.38125 10.3389 7.25 9.68262 7.25 9.00012C7.25 6.10387 9.60375 3.75012 12.5 3.75012C15.3962 3.75012 17.75 6.10387 17.75 9.00012Z"
      fill="currentColor"
    /><path
      fill-opacity="0.3"
      d="M21.25 16C21.25 18.8962 18.8962 21.25 16 21.25C14.6525 21.25 13.4275 20.7425 12.5 19.9025C13.5763 18.9487 14.25 17.5487 14.25 16C14.25 15.3175 14.1187 14.6612 13.8825 14.0662C15.4837 13.6287 16.7787 12.4562 17.3825 10.9337C19.605 11.5375 21.25 13.585 21.25 16Z"
      fill="currentColor"
    /></svg>
    """
  end

  defp icon(%{name: "elements"} = assigns) do
    ~H"""
    <svg aria-hidden="true" class={@class} viewBox="0 0 24 24" fill="none"><path
      d="M13.3111 14.75H5.03356C3.36523 14.75 2.30189 12.9625 3.10856 11.4958L5.24439 7.60911L7.24273 3.96995C8.07689 2.45745 10.2586 2.45745 11.0927 3.96995L13.1002 7.60911L14.0627 9.35995L15.2361 11.4958C16.0427 12.9625 14.9794 14.75 13.3111 14.75Z"
      fill="currentColor"
    /><path
      fill-opacity="0.3"
      d="M21.1667 15.2083C21.1667 18.4992 18.4992 21.1667 15.2083 21.1667C11.9175 21.1667 9.25 18.4992 9.25 15.2083C9.25 15.0525 9.25917 14.9058 9.26833 14.75H13.3108C14.9792 14.75 16.0425 12.9625 15.2358 11.4958L14.0625 9.36C14.4292 9.28666 14.8142 9.25 15.2083 9.25C18.4992 9.25 21.1667 11.9175 21.1667 15.2083Z"
      fill="currentColor"
    /></svg>
    """
  end

  defp icon(%{name: "settings"} = assigns) do
    ~H"""
    <svg aria-hidden="true" class={@class} viewBox="0 0 24 24" fill="none"><path
      fill-opacity="0.3"
      fill="currentColor"
      d="M2 12.947v-1.771c0-1.047.85-1.913 1.899-1.913 1.81 0 2.549-1.288 1.64-2.868a1.919 1.919 0 0 1 .699-2.607l1.729-.996c.79-.474 1.81-.192 2.279.603l.11.192c.9 1.58 2.379 1.58 3.288 0l.11-.192c.47-.795 1.49-1.077 2.279-.603l1.73.996a1.92 1.92 0 0 1 .699 2.607c-.91 1.58-.17 2.868 1.639 2.868 1.04 0 1.899.856 1.899 1.912v1.772c0 1.047-.85 1.912-1.9 1.912-1.808 0-2.548 1.288-1.638 2.869.52.915.21 2.083-.7 2.606l-1.729.997c-.79.473-1.81.191-2.279-.604l-.11-.191c-.9-1.58-2.379-1.58-3.288 0l-.11.19c-.47.796-1.49 1.078-2.279.605l-1.73-.997a1.919 1.919 0 0 1-.699-2.606c.91-1.58.17-2.869-1.639-2.869A1.911 1.911 0 0 1 2 12.947Z"
    /><path
      fill="currentColor"
      d="M11.995 15.332c1.794 0 3.248-1.464 3.248-3.27 0-1.807-1.454-3.272-3.248-3.272-1.794 0-3.248 1.465-3.248 3.271 0 1.807 1.454 3.271 3.248 3.271Z"
    /></svg>
    """
  end

  defp icon(%{name: "profile"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="2"
    ><path
      stroke-linecap="round"
      stroke-linejoin="round"
      d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
    /></svg>
    """
  end

  defp icon(%{name: "messages"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="2"
    ><path
      stroke-linecap="round"
      stroke-linejoin="round"
      d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
    /></svg>
    """
  end

  defp icon(%{name: "team"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="2"
    ><path
      stroke-linecap="round"
      stroke-linejoin="round"
      d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
    /></svg>
    """
  end

  defp icon(%{name: "activity"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="2"
    ><path
      stroke-linecap="round"
      stroke-linejoin="round"
      d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
    /></svg>
    """
  end

  defp icon(%{name: "app-settings"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="2"
    ><path
      stroke-linecap="round"
      stroke-linejoin="round"
      d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
    /><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
    """
  end

  defp icon(%{name: "logout"} = assigns) do
    ~H"""
    <svg aria-hidden="true" class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor"><path
      stroke-linecap="round"
      stroke-linejoin="round"
      stroke-width="1.5"
      d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
    /></svg>
    """
  end

  defp icon(%{name: "min-0"} = assigns) do
    ~H"""
    <svg aria-hidden="true" class={@class} viewBox="0 0 24 24" fill="none" stroke="currentColor"><path
      d="M12.5293 18L20.9999 8.40002"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
    /><path
      d="M3 13.2L7.23529 18L17.8235 6"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
    /></svg>
    """
  end

  defp icon(%{name: "min-1"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="1.5"
    ><path
      stroke-linecap="round"
      stroke-linejoin="round"
      d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
    /></svg>
    """
  end

  defp icon(%{name: "min-2"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="1.5"
    ><path
      stroke-linecap="round"
      stroke-linejoin="round"
      d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"
    /></svg>
    """
  end

  defp icon(%{name: "min-3"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="1.5"
    ><path
      stroke-linecap="round"
      stroke-linejoin="round"
      d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
    /></svg>
    """
  end

  defp icon(%{name: "min-4"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="1.5"
    ><path
      stroke-linecap="round"
      stroke-linejoin="round"
      d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
    /></svg>
    """
  end

  defp icon(%{name: "min-5"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="1.5"
    ><path
      stroke-linecap="round"
      stroke-linejoin="round"
      d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
    /></svg>
    """
  end

  defp icon(%{name: "min-6"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      stroke="currentColor"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      fill="none"
    ><path d="M7 6H21M7 12H21M7 18H21" stroke-linecap="round" stroke-linejoin="round" /><path
      d="M3 6H4M3 12H4M3 18H4"
      stroke-linecap="round"
      stroke-linejoin="round"
    /></svg>
    """
  end

  defp icon(%{name: "min-7"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      stroke="currentColor"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      fill="none"
    ><path d="M7 6H21M7 12H21M7 18H21" stroke-linecap="round" stroke-linejoin="round" /><path
      d="M3 6H4M3 12H4M3 18H4"
      stroke-linecap="round"
      stroke-linejoin="round"
    /></svg>
    """
  end

  defp icon(%{name: "min-8"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      stroke="currentColor"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      fill="none"
    ><path d="M7 6H21M7 12H21M7 18H21" stroke-linecap="round" stroke-linejoin="round" /><path
      d="M3 6H4M3 12H4M3 18H4"
      stroke-linecap="round"
      stroke-linejoin="round"
    /></svg>
    """
  end

  defp icon(%{name: "min-9"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      stroke="currentColor"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      fill="none"
    ><path d="M7 6H21M7 12H21M7 18H21" stroke-linecap="round" stroke-linejoin="round" /><path
      d="M3 6H4M3 12H4M3 18H4"
      stroke-linecap="round"
      stroke-linejoin="round"
    /></svg>
    """
  end

  defp icon(%{name: "min-10"} = assigns) do
    ~H"""
    <svg
      aria-hidden="true"
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="2"
    ><path
      stroke-linecap="round"
      stroke-linejoin="round"
      d="M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z"
    /></svg>
    """
  end
end
