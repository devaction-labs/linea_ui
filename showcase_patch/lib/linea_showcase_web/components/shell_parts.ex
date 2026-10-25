defmodule LineaShowcaseWeb.ShellParts do
  @moduledoc """
  The two pieces of LineOne's header that open a box: the notifications popover (`notifications/1`,
  for the `:notifications` slot of `header/1`) and the right drawer (`right_drawer/1`, for the
  `:aside` slot of the shell) with its Home, Projects and Activity panels.

  The drawer switches panels in the browser with `Phoenix.LiveView.JS` commands: the panel, the
  title in the top bar and the pill in the bottom bar are toggled by class, and the static parts
  carry `phx-update="ignore"` so a patch of the page leaves the chosen panel alone.
  """

  use LineaShowcaseWeb, :html

  @tones %{
    "secondary" => %{
      box: "bg-secondary/10 dark:bg-secondary-light/15",
      icon: "text-secondary dark:text-secondary-light"
    },
    "info" => %{box: "bg-info/10 dark:bg-info/15", icon: "text-info"},
    "primary" => %{
      box: "bg-primary/10 dark:bg-accent-light/15",
      icon: "text-primary dark:text-accent-light"
    },
    "success" => %{box: "bg-success/10 dark:bg-success/15", icon: "text-success"},
    "warning" => %{box: "bg-warning/10 dark:bg-warning/15", icon: "text-warning"},
    "error" => %{box: "bg-error/10 dark:bg-error/15", icon: "text-error"}
  }

  @notices %{
    photo: %{
      tone: "secondary",
      icon: "huge-user-edit-01",
      title: "User Photo Changed",
      text: "John Doe changed his avatar photo"
    },
    images: %{
      tone: "primary",
      icon: "huge-image-01",
      title: "Images Added",
      text: "Mores Clarke added new image gallery"
    },
    design: %{
      tone: "success",
      icon: "huge-leaf-01",
      title: "Design Completed",
      text: "Robert Nolan completed the design of the CRM application"
    },
    diagram: %{
      tone: "warning",
      icon: "huge-workflow-square-01",
      title: "ER Diagram",
      text: "Team completed the ER diagram app"
    },
    report: %{
      tone: "error",
      icon: "huge-time-quarter-pass",
      title: "Weekly Report",
      text: "The weekly report was uploaded"
    },
    frontend: %{
      tone: "info",
      icon: "huge-calendar-03",
      title: "Mon, June 14, 2021",
      time: "08:00 - 09:00",
      text: "Frontend Conf"
    },
    uiux: %{
      tone: "info",
      icon: "huge-calendar-03",
      title: "Wed, June 21, 2021",
      time: "16:00 - 20:00",
      text: "UI/UX Conf"
    },
    interview: %{
      tone: "warning",
      icon: "huge-mic-01",
      title: "THU, May 11, 2021",
      time: "10:00 - 11:30",
      text: "Interview, Konnor Guzman"
    },
    laravel: %{
      tone: "info",
      icon: "huge-calendar-03",
      title: "Mon, Jul 16, 2021",
      time: "06:00 - 16:00",
      text: "Laravel Conf"
    },
    interview_two: %{
      tone: "warning",
      icon: "huge-mic-01",
      title: "Wed, Jun 16, 2021",
      time: "15:30 - 11:30",
      text: "Interview, Jonh Doe"
    }
  }

  @notification_tabs [
    {"all", "All", ~w(photo frontend images design uiux diagram interview report)a},
    {"alerts", "Alerts", ~w(photo images design diagram report)a},
    {"events", "Events", ~w(frontend uiux interview laravel interview_two)a},
    {"logs", "Logs", []}
  ]

  @pinned [
    {"Kanban", "success", "huge-kanban", "/apps/kanban"},
    {"Analytics", "warning", "huge-dollar-circle", "/dashboards/crm-analytics"},
    {"Chat", "info", "huge-comment-01", "/apps/chat"},
    {"Files", "error", "huge-cloud", "/apps/filemanager"},
    {"Banking", "secondary", "huge-balance-scale", "/dashboards/banking-1"}
  ]

  @cards [
    {"from-purple-500 to-indigo-600", "reuleaux-triangle", "top-0"},
    {"from-pink-500 to-rose-500", "diamond", "bottom-0"},
    {"from-info to-info-focus", "hexagon-2", "top-0"}
  ]

  @news [
    {"What is Tailwind CSS?", "John D.", "2 min read", "avatar-20", "object-18"},
    {"Tailwind CSS Card Example", "Travis F.", "5 min read", "avatar-19", "object-2"},
    {"10 Tips for Making a Good Camera Even Better", "Alfredo E .", "4 min read", "avatar-18",
     "object-1"}
  ]

  @projects [
    {"LMS App Design", "lms-ui", "7 Sep", 33.33, "25%",
     [{"avatar-16", nil}, {nil, {"jd", "info"}}, {"avatar-20", nil}]},
    {"Store Dashboard", "store-ui", "11 Sep", 50, "49%",
     [{"avatar-17", nil}, {nil, {"dv", "warning"}}, {"avatar-19", nil}]},
    {"Chat Mobile App", "chat-ui", "19 Sep", 16.67, "13%",
     [{"avatar-5", nil}, {nil, {"gt", "error"}}, {"avatar-11", nil}]},
    {"NFT Marketplace App", "nft", "5 Sep", 75, "78%",
     [{"avatar-8", nil}, {nil, {"jd", "success"}}, {"avatar-12", nil}]}
  ]

  @members [
    {"avatar-16", nil},
    {nil, {"jd", "info"}},
    {"avatar-20", nil},
    {"avatar-8", nil},
    {"avatar-5", nil}
  ]

  @drawer_tabs [
    {"home", "Home", "25 May, 2022", "huge-calendar-03", "huge-home-01"},
    {"project", "Projects", "Projects", "huge-chart-line-data-01", "huge-chart-line-data-01"},
    {"activity", "Activity", "Activity", "huge-clock-01", "huge-clock-01"}
  ]

  @nav_active "text-primary dark:text-accent"
  @nav_default "text-slate-500 dark:text-navy-300"

  @stats [
    %{
      value: "11.3",
      unit: "hr",
      label: "Working Hours",
      color: "secondary",
      bar_class: "dark:bg-secondary-light",
      icon: "huge-clock-01",
      icon_class: "text-secondary dark:text-secondary-light",
      bar: 66.67,
      percent: "71%",
      active: true
    },
    %{
      value: "13",
      unit: "/22",
      label: "Completed tasks",
      color: "success",
      bar_class: nil,
      icon: "huge-checkmark-badge-01",
      icon_class: "text-success",
      bar: 50,
      percent: "49%",
      active: false
    }
  ]

  @stocks [
    {"bitcoin", "BTC", "Bitcoin", "60.33$", "+3.3%"},
    {"solana", "SOL", "Solana", "20.56$", "+4.11%"}
  ]

  @tiles [
    {"14", "Pending", "huge-clock-01", "text-primary dark:text-accent"},
    {"36", "Completed", "huge-checkmark-badge-01", "text-success"},
    {"143", "In Progress", "huge-loading-03", "text-warning"},
    {"279", "Total", "huge-task-done-01", "text-info"}
  ]

  @doc "The notifications box: title, count, settings, the four tabs and their lists."
  attr :id, :string, default: "notifications"

  def notifications(assigns) do
    assigns = assign(assigns, tabs: @notification_tabs, notices: @notices)

    ~H"""
    <div class="rounded-t-lg bg-slate-100 text-slate-600 dark:bg-navy-800 dark:text-navy-200">
      <div class="flex items-center justify-between px-4 pt-2">
        <div class="flex items-center space-x-2">
          <h3 class="font-medium text-slate-700 dark:text-navy-100">Notifications</h3>
          <.badge color="primary" variant="soft" shape="pill" size="sm" class="px-1.5">26</.badge>
        </div>
        <.button
          icon
          size="sm"
          shape="pill"
          variant="flat"
          color="current"
          class="-mr-1.5"
          aria-label="Notification settings"
        >
          <.icon name="huge-settings-02" class="size-4.5" />
        </.button>
      </div>
    </div>
    <.tabs
      id={@id <> "-tabs"}
      class="flex min-h-0 flex-col overflow-hidden"
      list_class="bg-slate-100 px-3 text-slate-600 dark:bg-navy-800 dark:text-navy-200"
      panels_class="flex flex-col overflow-hidden pt-0"
    >
      <:tab :for={{name, label, _ids} <- @tabs} name={name} class="px-3.5 py-2.5 font-normal">
        <span>{label}</span>
      </:tab>
      <:panel :for={{name, _label, ids} <- @tabs} name={name} class={panel_class(ids)}>
        <.notice :for={id <- ids} notice={Map.fetch!(@notices, id)} />
        <.no_logs :if={ids == []} />
      </:panel>
    </.tabs>
    """
  end

  defp panel_class([]), do: "is-scrollbar-hidden overflow-y-auto px-4"
  defp panel_class(_ids), do: "is-scrollbar-hidden space-y-4 overflow-y-auto px-4 py-4"

  attr :notice, :map, required: true

  defp notice(assigns) do
    assigns = assign(assigns, :tone, Map.fetch!(@tones, assigns.notice.tone))

    ~H"""
    <div class="flex items-center space-x-3">
      <div class={["flex size-10 shrink-0 items-center justify-center rounded-lg", @tone.box]}>
        <.notice_icon icon={@notice.icon} tone={@tone} />
      </div>
      <div>
        <p class="font-medium text-slate-600 dark:text-navy-100">{@notice.title}</p>
        <.notice_text notice={@notice} />
      </div>
    </div>
    """
  end

  defp notice_icon(assigns) do
    ~H"""
    <.icon name={@icon} class={["size-5", @tone.icon]} />
    """
  end

  defp notice_text(%{notice: %{time: time, text: text}} = assigns) do
    assigns = assign(assigns, time: time, text: text)

    ~H"""
    <div class="mt-1 flex text-xs text-slate-400 dark:text-navy-300">
      <span class="shrink-0">{@time}</span>
      <div class="mx-2 my-1 w-px bg-slate-200 dark:bg-navy-500"></div>
      <span class="line-clamp-1">{@text}</span>
    </div>
    """
  end

  defp notice_text(%{notice: %{text: text}} = assigns) do
    assigns = assign(assigns, :text, text)

    ~H"""
    <div class="mt-1 text-xs text-slate-400 line-clamp-1 dark:text-navy-300">{@text}</div>
    """
  end

  defp no_logs(assigns) do
    ~H"""
    <div class="mt-8 pb-8 text-center">
      <img class="mx-auto w-36" src="/images/illustrations/empty-girl-box.svg" alt="" />
      <div class="mt-5">
        <p class="text-base font-semibold text-slate-700 dark:text-navy-100">No any logs</p>
        <p class="text-slate-400 dark:text-navy-300">There are no unread logs yet</p>
      </div>
    </div>
    """
  end

  @doc """
  The right drawer, opened by the header's grid button (`header right_sidebar={id}`): a title in the
  top bar per panel, the three panels and the floating pill bar that switches them.
  """
  attr :id, :string, default: "right-sidebar"
  attr :initial, :string, default: "home", values: ~w(home project activity)

  def right_drawer(assigns) do
    assigns = assign(assigns, tabs: @drawer_tabs)

    ~H"""
    <.right_sidebar id={@id} label="Right sidebar" persist_tab>
      <:title>
        <p
          :for={{name, _label, title, icon, _nav_icon} <- @tabs}
          id={"#{@id}-title-#{name}"}
          phx-update="ignore"
          class={["rs-title flex shrink-0 items-center space-x-1.5", name != @initial && "hidden"]}
        >
          <.icon name={icon} class="size-4" />
          <span class="text-xs">{title}</span>
        </p>
      </:title>
      <.home_panel id={"#{@id}-panel-home"} active={@initial == "home"} />
      <.project_panel id={"#{@id}-panel-project"} active={@initial == "project"} />
      <.activity_panel id={"#{@id}-panel-activity"} active={@initial == "activity"} />
      <:footer>
        <div
          id={"#{@id}-nav"}
          phx-update="ignore"
          class="pointer-events-none absolute bottom-4 flex w-full justify-center"
        >
          <div class="pointer-events-auto mx-auto flex space-x-1 rounded-full border border-slate-150 bg-white px-4 py-0.5 shadow-lg dark:border-navy-700 dark:bg-navy-900">
            <button
              :for={{name, label, _title, _icon, nav_icon} <- @tabs}
              id={"#{@id}-nav-#{name}"}
              type="button"
              aria-label={label}
              data-tab={name}
              phx-click={switch(@id, name)}
              class={[
                "rs-nav btn h-9 rounded-full py-0 px-4 hover:bg-slate-300/20 hover:text-primary focus:bg-slate-300/20 focus:text-primary active:bg-slate-300/25 dark:hover:bg-navy-300/20 dark:hover:text-accent dark:focus:bg-navy-300/20 dark:focus:text-accent dark:active:bg-navy-300/25",
                nav_state(name == @initial)
              ]}
            >
              <.icon name={nav_icon} class="size-5 shrink-0" />
            </button>
          </div>
        </div>
      </:footer>
    </.right_sidebar>
    """
  end

  defp nav_state(true), do: @nav_active
  defp nav_state(false), do: @nav_default

  defp switch(id, tab) do
    JS.remove_class("is-active", to: "##{id} .rs-panel")
    |> JS.add_class("is-active", to: "##{id}-panel-#{tab}")
    |> JS.add_class("hidden", to: "##{id} .rs-title")
    |> JS.remove_class("hidden", to: "##{id}-title-#{tab}")
    |> JS.remove_class(@nav_active, to: "##{id} .rs-nav")
    |> JS.add_class(@nav_default, to: "##{id} .rs-nav")
    |> JS.remove_class(@nav_default, to: "##{id}-nav-#{tab}")
    |> JS.add_class(@nav_active, to: "##{id}-nav-#{tab}")
  end

  attr :id, :string, required: true
  attr :active, :boolean, required: true

  defp home_panel(assigns) do
    assigns =
      assign(assigns,
        cards: @cards,
        pinned: @pinned,
        stats: @stats,
        stocks: @stocks,
        news: @news
      )

    ~H"""
    <div
      id={@id}
      phx-update="ignore"
      class={[
        "rs-panel tab-content tab-shift-up is-scrollbar-hidden overflow-y-auto overscroll-contain pt-1",
        @active && "is-active"
      ]}
    >
      <div class="px-3">
        <.input
          name="drawer-search"
          variant="filled"
          size="sm"
          placeholder="Search here..."
          aria-label="Search here..."
        >
          <:prefix>
            <.icon name="huge-search-01" class="size-4.5" />
          </:prefix>
        </.input>
      </div>
      <div class="mt-3">
        <h2 class="px-3 text-xs-plus font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100">
          Banking cards
        </h2>
        <div class="scrollbar-sm mt-3 flex space-x-4 overflow-x-auto px-3">
          <div
            :for={{gradient, shape, side} <- @cards}
            class={[
              "relative flex h-28 w-48 shrink-0 flex-col overflow-hidden rounded-xl bg-linear-to-br p-3",
              gradient
            ]}
          >
            <div class="grow">
              <img class="h-3" src="/images/payments/cc-visa-white.svg" alt="" />
            </div>
            <div class="text-white">
              <p class="text-lg font-semibold tracking-wide">$2,139.22</p>
              <p class="mt-1 text-xs font-medium">**** **** **** 8945</p>
            </div>
            <.mask shape={shape} class={["absolute right-0 -m-3 size-16 bg-white/20", side]} />
          </div>
        </div>
      </div>
      <div class="mt-2 px-3">
        <h2 class="text-xs-plus font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100">
          Pinned Apps
        </h2>
        <div class="mt-3 flex space-x-3">
          <.link
            :for={{label, color, icon, path} <- @pinned}
            navigate={path}
            class="flex w-12 flex-col items-center text-center"
          >
            <.avatar shape="squircle" color={color}>
              <.icon name={icon} class="size-5" />
            </.avatar>
            <p class="mt-1.5 w-full overflow-hidden text-ellipsis whitespace-nowrap text-xs text-slate-700 dark:text-navy-100">
              {label}
            </p>
          </.link>
        </div>
      </div>
      <div class="mt-4">
        <div class="grid grid-cols-2 gap-3 px-3">
          <div :for={stat <- @stats} class="rounded-lg bg-slate-150 px-2.5 py-2 dark:bg-navy-600">
            <div class="flex items-center justify-between space-x-1">
              <p>
                <span class="text-lg font-medium text-slate-700 dark:text-navy-100">
                  {stat.value}
                </span>
                <span class="text-xs">{stat.unit}</span>
              </p>
              <.icon name={stat.icon} class={["size-4.5", stat.icon_class]} />
            </div>
            <p class="mt-0.5 text-tiny-plus uppercase">{stat.label}</p>
            <.progress
              value={stat.bar}
              color={stat.color}
              variant="soft"
              height="1.5"
              active={stat.active}
              bar_class={stat.bar_class}
              class="mt-3"
              label={stat.label}
            />
            <div class="mt-1.5 flex items-center justify-between text-xs text-slate-400 dark:text-navy-300">
              <.button
                icon
                size="xs"
                shape="pill"
                variant="flat"
                color="current"
                class="-ml-1"
                aria-label="Settings"
              >
                <.icon name="huge-settings-02" class="size-4" />
              </.button>
              <span>{stat.percent}</span>
            </div>
          </div>
        </div>
      </div>
      <div class="mt-4">
        <h2 class="px-3 text-xs-plus font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100">
          Stock Market
        </h2>
        <div class="mt-3 grid grid-cols-2 gap-3 px-3">
          <div
            :for={{logo, symbol, name, price, change} <- @stocks}
            class="rounded-lg bg-slate-100 p-2.5 dark:bg-navy-600"
          >
            <div class="flex items-center space-x-2">
              <img class="size-10" src={"/images/logos/#{logo}.svg"} alt="" />
              <div>
                <h2 class="font-medium tracking-wide text-slate-700 dark:text-navy-100">
                  {symbol}
                </h2>
                <p class="text-xs">{name}</p>
              </div>
            </div>
            <div class="mt-2 flex items-center justify-between">
              <p class="font-medium tracking-wide text-slate-700 dark:text-navy-100">{price}</p>
              <p class="text-xs font-medium tracking-wide text-success">{change}</p>
            </div>
          </div>
        </div>
      </div>
      <div class="mt-4">
        <h2 class="px-3 text-xs-plus font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100">
          Latest News
        </h2>
        <div class="mt-3 space-y-3 px-2">
          <div
            :for={{title, author, read, avatar, image} <- @news}
            class="flex justify-between space-x-2 rounded-lg bg-slate-100 p-2.5 dark:bg-navy-700"
          >
            <div class="flex flex-1 flex-col justify-between">
              <div class="line-clamp-2">
                <a
                  href="#"
                  class="font-medium text-slate-700 hover:text-primary focus:text-primary dark:text-navy-100 dark:hover:text-accent-light dark:focus:text-accent-light"
                >
                  {title}
                </a>
              </div>
              <div class="flex items-center justify-between">
                <div class="flex items-center space-x-2">
                  <.avatar src={"/images/avatar/#{avatar}.jpg"} size="2xs" />
                  <div>
                    <p class="text-xs font-medium line-clamp-1">{author}</p>
                    <p class="text-tiny-plus text-slate-400 line-clamp-1 dark:text-navy-300">
                      {read}
                    </p>
                  </div>
                </div>
                <div class="flex">
                  <.button
                    icon
                    size="sm"
                    shape="pill"
                    variant="flat"
                    color="current"
                    aria-label="Like"
                  >
                    <.icon name="huge-thumbs-up" class="size-4" />
                  </.button>
                  <.button
                    icon
                    size="sm"
                    shape="pill"
                    variant="flat"
                    color="current"
                    aria-label="Save"
                  >
                    <.icon name="huge-bookmark-01" class="size-4" />
                  </.button>
                </div>
              </div>
            </div>
            <img
              src={"/images/object/#{image}.jpg"}
              class="size-20 rounded-lg object-cover object-center"
              alt=""
            />
          </div>
        </div>
      </div>
      <div class="mt-3 px-3">
        <div class="rounded-lg bg-slate-100 p-3 dark:bg-navy-600">
          <div class="flex items-center justify-between">
            <p><span class="font-medium text-slate-600 dark:text-navy-100">35GB</span> of 1TB</p>
            <a
              href="#"
              class="text-xs-plus font-medium text-primary outline-hidden transition-colors duration-300 hover:text-primary/70 focus:text-primary/70 dark:text-accent-light dark:hover:text-accent-light/70 dark:focus:text-accent-light/70"
            >
              Upgrade
            </a>
          </div>
          <.progress value={58.33} color="info" height="2" label="Storage" class="mt-2" />
        </div>
      </div>
      <div class="h-18"></div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :active, :boolean, required: true

  defp project_panel(assigns) do
    assigns = assign(assigns, tiles: @tiles, projects: @projects)

    ~H"""
    <div
      id={@id}
      phx-update="ignore"
      class={[
        "rs-panel tab-content tab-shift-up is-scrollbar-hidden overflow-y-auto overscroll-contain px-3 pt-1",
        @active && "is-active"
      ]}
    >
      <div class="grid grid-cols-2 gap-3">
        <div
          :for={{value, label, icon, icon_class} <- @tiles}
          class="rounded-lg bg-slate-100 p-3 dark:bg-navy-600"
        >
          <div class="flex justify-between space-x-1">
            <p class="text-xl font-semibold text-slate-700 dark:text-navy-100">{value}</p>
            <.icon name={icon} class={["size-5", icon_class]} />
          </div>
          <p class="mt-1 text-xs-plus">{label}</p>
        </div>
      </div>
      <div
        :for={{name, image, updated, bar, percent, members} <- @projects}
        class="mt-4 rounded-lg border border-slate-150 p-3 dark:border-navy-600"
      >
        <div class="flex items-center space-x-3">
          <img
            class="size-10 rounded-lg object-cover object-center"
            src={"/images/illustrations/#{image}.svg"}
            alt=""
          />
          <div>
            <p class="font-medium leading-snug text-slate-700 dark:text-navy-100">{name}</p>
            <p class="text-xs text-slate-400 dark:text-navy-300">Updated at {updated}</p>
          </div>
        </div>
        <div class="mt-4">
          <.progress value={bar} color="primary" height="1.5" label={name} />
          <p class="mt-2 text-right text-xs-plus font-medium text-primary dark:text-accent-light">
            {percent}
          </p>
        </div>
        <div class="mt-3 flex items-center justify-between space-x-2">
          <.members members={members} />
          <.open_button />
        </div>
      </div>
      <div class="h-18"></div>
    </div>
    """
  end

  slot :inner_block, required: true

  defp hash_link(assigns) do
    ~H"""
    <a
      href="#"
      class="text-xs text-primary hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  attr :members, :list, required: true
  attr :overlap, :string, default: "3"

  defp members(assigns) do
    ~H"""
    <.avatar_group overlap={@overlap} class="flex-wrap">
      <.member :for={member <- @members} member={member} />
    </.avatar_group>
    """
  end

  attr :member, :any, required: true

  defp member(%{member: {photo, nil}} = assigns) do
    assigns = assign(assigns, :photo, photo)

    ~H"""
    <.avatar src={"/images/avatar/#{@photo}.jpg"} size="2xs" ring class="hover:z-10" />
    """
  end

  defp member(%{member: {nil, {initials, color}}} = assigns) do
    assigns = assign(assigns, initials: initials, color: color)

    ~H"""
    <.avatar initials={@initials} color={@color} size="2xs" ring class="hover:z-10" />
    """
  end

  defp open_button(assigns) do
    ~H"""
    <.button
      icon
      size="sm"
      shape="pill"
      aria-label="Open"
      class="bg-slate-150 font-medium text-slate-800 hover:bg-slate-200 focus:bg-slate-200 active:bg-slate-200/80 dark:bg-navy-500 dark:text-navy-50 dark:hover:bg-navy-450 dark:focus:bg-navy-450 dark:active:bg-navy-450/90"
    >
      <.icon name="huge-arrow-up-right-01" class="size-5" />
    </.button>
    """
  end

  attr :id, :string, required: true
  attr :active, :boolean, required: true

  defp activity_panel(assigns) do
    assigns = assign(assigns, :members, @members)

    ~H"""
    <div
      id={@id}
      phx-update="ignore"
      class={[
        "rs-panel tab-content tab-shift-up is-scrollbar-hidden overflow-y-auto overscroll-contain pt-1",
        @active && "is-active"
      ]}
    >
      <div class="mx-3 flex flex-col items-center rounded-lg bg-slate-100 py-3 px-8 dark:bg-navy-600">
        <.icon name="huge-clock-01" class="size-8 text-secondary dark:text-secondary-light" />
        <p class="mt-2 text-xs">Today</p>
        <p class="text-lg font-medium text-slate-700 dark:text-navy-100">6hr 22m</p>
        <.progress
          value={66.67}
          color="secondary"
          variant="soft"
          height="2"
          active
          bar_class="dark:bg-secondary-light"
          label="Today"
          class="mt-3"
        />
        <.button
          variant="outline"
          shape="pill"
          class="mt-5 space-x-2 px-3 text-xs-plus font-medium text-slate-700 dark:text-navy-100"
        >
          <.icon name="huge-download-01" class="size-4.5 text-slate-400 dark:text-navy-300" />
          <span>Download Report</span>
        </.button>
      </div>
      <.timeline
        size="lg"
        line_space
        class="mt-5 px-4 [&_.timeline-item-content]:pl-4 sm:[&_.timeline-item-content]:pl-4"
      >
        <.timeline_item
          title="User Photo Changed"
          time="12 minute ago"
          color="secondary"
          variant="icon"
          description="John Doe changed his avatar photo"
        >
          <:point><.icon name="huge-user-edit-01" class="size-3" /></:point>
          <.avatar src="/images/avatar/avatar-19.jpg" shape="squircle" size="xl" class="mt-2" />
        </.timeline_item>
        <.timeline_item
          title="Images Added"
          time="1 hour ago"
          color="primary"
          variant="icon"
          description="Mores Clarke added new image gallery"
        >
          <:point><.icon name="huge-image-01" class="size-3" /></:point>
          <div class="mt-4 grid grid-cols-3 gap-3">
            <img
              :for={n <- 1..6}
              class="rounded-lg"
              src={"/images/object/object-#{n}.jpg"}
              alt=""
            />
          </div>
          <div class="mt-4">
            <span class="font-medium text-slate-600 dark:text-navy-100">Category:</span>
            <.hash_link>#Tag</.hash_link>
            <.hash_link>#Category</.hash_link>
          </div>
        </.timeline_item>
        <.timeline_item
          title="Design Completed"
          time="3 hours ago"
          color="success"
          variant="icon"
          description="Robert Nolan completed the design of the CRM application"
        >
          <:point><.icon name="huge-leaf-01" class="size-3" /></:point>
          <a
            href="#"
            class="inline-flex items-center space-x-1 pt-2 text-slate-600 transition-colors hover:text-primary dark:text-navy-100 dark:hover:text-accent"
          >
            <.icon name="huge-file-01" class="size-5" />
            <span>File_final.fig</span>
          </a>
          <div class="pt-2">
            <.tag href="#" color="secondary" variant="bordered" shape="pill">UI/UX</.tag>
            <.tag href="#" color="info" variant="bordered" shape="pill">CRM</.tag>
            <.tag href="#" color="success" variant="bordered" shape="pill">Dashboard</.tag>
          </div>
        </.timeline_item>
        <.timeline_item
          title="ER Diagram"
          time="a day ago"
          color="warning"
          variant="icon"
          description="Team completed the ER diagram app"
        >
          <:point><.icon name="huge-workflow-square-01" class="size-3" /></:point>
          <div>
            <p class="text-xs text-slate-400 dark:text-navy-300">Members:</p>
            <div class="mt-2 flex justify-between">
              <.members members={@members} overlap="2" />
              <.open_button />
            </div>
          </div>
        </.timeline_item>
        <.timeline_item
          title="Weekly Report"
          time="a day ago"
          color="error"
          variant="icon"
          description="The weekly report was uploaded"
        >
          <:point><.icon name="huge-time-quarter-pass" class="size-3" /></:point>
        </.timeline_item>
      </.timeline>
      <div class="h-18"></div>
    </div>
    """
  end
end
