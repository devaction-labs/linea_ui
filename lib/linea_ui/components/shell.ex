defmodule LineaUI.Components.Shell do
  @moduledoc """
  The framed shell of the app with the side menu of `sidebar/1`: the grey frame, the menu on it (10px from the
  edges) and the page in a rounded panel beside it. It is `app_shell` with `layout="framed"` and a `sidebar/1`,
  fed by one list of items, so changing `sidebar` changes the menu and not the items.

      <.shell nav={MyAppWeb.Nav.items(assigns)} sidebar="rail" current={@current_path}
        brand={%{name: "Linea", logo: "S"}} user={@user}>
        <:topbar><.breadcrumb>…</.breadcrumb></:topbar>
        …the page…
      </.shell>

  `nav`, `brand`, `user`, `plan`, `trial`, `rail_extra` and `collapsible` are those of `sidebar/1`, which
  documents the data of the items. `sidebar` is the format (`sections`, `rail` or `tree`).

  ## Configuration

      config :linea_ui, :shell, sidebar: :sections, nav: {MyAppWeb.Nav, :items}

  `sidebar` is the format and `nav` is `{module, function}`, called with the assigns of the shell, when the
  attributes are left out. The attributes always win.

  ## The foot of the menu

  `footer` is `"user"`, `"version"` or `"none"` (see "The foot" in `sidebar/1`): the user, the version line
  of the canvas (`version`, a string or `%{version, build, navigate, label, title, status}`) or nothing, in the
  three formats. Left out, each format keeps its own (user card, plan card, avatar). The app already has the
  avatar in its topbar? `footer="none"`. `show_user={false}` still works and is deprecated. The kit does not read
  the version of your app: pass it, from `Application.spec/2`, or write it in the config (which runs before the
  app is loaded, so no `spec` there).

      <.shell footer="version" version={%{version: "v" <> to_string(Application.spec(:my_app, :vsn)),
        build: "2a9f1c3", navigate: ~p"/changelog", label: "Novidades"}} …>

      config :linea_ui, :shell, footer: :version, version: "v1.4.2"

  The `:topbar` slot is a row at the top of the page panel. It takes a `navbar/1`, the canvas top bar
  (breadcrumb, search, notifications, theme, language and the user):

      <:topbar>
        <.navbar><.navbar_crumbs items={[%{label: "Início", navigate: ~p"/"}, %{label: "Projetos"}]} /><:end>…</:end></.navbar>
      </:topbar>

  In the `sections` format, which has no collapse
  button of its own, the row starts with the button that collapses the menu (`collapsible`). Below 768px the
  menu is a top bar with a hamburger.
  """

  use LineaUI.Component

  alias LineaUI.Components.AppShell
  alias LineaUI.Components.Sidebar

  attr :id, :string, default: "shell"

  attr :sidebar, :any,
    default: nil,
    doc:
      "The format of the menu: `sections`, `rail` or `tree` (an atom works too). The `:shell` config `sidebar` when left out, else `sections`."

  attr :nav, :list,
    default: nil,
    doc: "The menu items (see `sidebar/1`). The `{module, function}` of the config when left out."

  attr :current, :string, default: nil, doc: "The current path; marks the active item."
  attr :brand, :map, default: nil, doc: "`%{name, logo}` (or `src`), as in `sidebar/1`."
  attr :user, :map, default: nil, doc: "`%{name, email, initials, avatar, color}`."

  attr :footer, :any,
    default: nil,
    doc:
      "`\"user\"`, `\"version\"` or `\"none\"`: what the foot of the menu shows (see `sidebar/1`). The `:shell` config `footer` when left out, else each format's own."

  attr :show_user, :boolean,
    default: nil,
    doc: "Deprecated, use `footer`: `false` is `footer=\"none\"` (see `sidebar/1`)."

  attr :version, :any,
    default: nil,
    doc:
      "The version of the system: a string or `%{version, build, href | navigate | patch, label, title, status}` (see `sidebar/1`). The `:shell` config `version` when left out."

  attr :plan, :map, default: nil, doc: "`%{name, badge}`, the plan card of `sections`."
  attr :trial, :map, default: nil, doc: "The trial card of the `rail` (see `sidebar/1`)."
  attr :rail_extra, :list, default: [], doc: "The extra apps of the `rail` (see `sidebar/1`)."
  attr :collapsible, :boolean, default: true, doc: "Whether the menu can collapse to icons."
  attr :collapsed, :boolean, default: false, doc: "Whether the menu starts collapsed."
  attr :class, :any, default: nil
  attr :main_class, :any, default: nil, doc: "More classes of the page panel."
  attr :rest, :global

  slot :brand_mark, doc: "Replaces the logo and the name of the brand (see `sidebar/1`)."
  slot :sidebar_footer, doc: "At the end of the foot of the menu."
  slot :topbar, doc: "A row at the top of the page panel."
  slot :inner_block, required: true, doc: "The page."

  def shell(assigns) do
    assigns =
      assigns
      |> assign_derived(:fmt, [:sidebar], fn -> Sidebar.Nav.format(assigns.sidebar) end)
      |> assign_derived(:items, [:nav, :current, :user, :brand, :plan, :trial, :rest], fn ->
        Sidebar.Nav.nav(assigns.nav, assigns)
      end)
      |> assign_derived(:menu_id, [:id], fn -> assigns.id <> "-menu" end)

    ~H"""
    <div
      id={@id}
      class={
        merge([
          "sg linea-frame flex h-dvh flex-col gap-2.5 bg-slate-50 max-md:pt-14 md:flex-row md:p-2.5 dark:bg-navy-900",
          @class
        ])
      }
      {@rest}
    >
      <Sidebar.sidebar
        id={@menu_id}
        format={@fmt}
        nav={@items}
        current={@current}
        brand={@brand}
        user={@user}
        footer={@footer}
        show_user={@show_user}
        version={@version}
        plan={@plan}
        trial={@trial}
        rail_extra={@rail_extra}
        collapsible={@collapsible}
        collapsed={@collapsed}
      >
        <:brand_mark :if={@brand_mark != []}>{render_slot(@brand_mark)}</:brand_mark>
        <:sidebar_footer :if={@sidebar_footer != []}>{render_slot(@sidebar_footer)}</:sidebar_footer>
      </Sidebar.sidebar>
      <main class={
        merge([
          "flex min-w-0 flex-1 flex-col gap-6 overflow-y-auto bg-white px-4 pt-5 pb-10 shadow-[0_0_0_1px_var(--color-slate-150),0_1px_2px_rgb(23_23_26/.04),0_4px_16px_-6px_rgb(23_23_26/.08)] md:rounded-[22px] md:px-8 md:pt-5 md:pb-10 dark:bg-navy-900 dark:shadow-[0_0_0_1px_var(--color-navy-600)]",
          @main_class
        ])
      }>
        <div
          :if={@topbar != [] or (@collapsible and @fmt == "sections")}
          class="flex items-center gap-3"
        >
          <AppShell.rail_toggle :if={@collapsible and @fmt == "sections"} for={@menu_id} />
          {render_slot(@topbar)}
        </div>
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end
end
