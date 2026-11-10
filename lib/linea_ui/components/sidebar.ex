defmodule LineaUI.Components.Sidebar do
  use LineaUI.Component

  alias LineaUI.Components.Icon
  alias LineaUI.Components.Sidebar.Nav

  @icon_table Nav.icon_table()

  @moduledoc """
  The side menu of the Shell, in three formats that read the same data (the canvas "Sidebar" board):

    * `sections` (the default): the brand with a company switcher, groups with an uppercase mono label,
      "settings and help" at the foot and the plan card.
    * `rail`: a 58px rail of icons (logo, home, the person, one icon per group, extra apps in coloured circles,
      the foot items) beside the raised panel of the active module: its title, a create button, its items, a
      coloured tree, the "try" shortcuts and the trial card.
    * `tree`: the brand with a collapse button, groups with a label and a chevron, children joined by a line,
      square coloured icons, a notice dot and the user card at the foot (see "The foot" for the version line instead).

      <.sidebar format="rail" nav={MyAppWeb.Nav.items(assigns)} current={@current_path}
        brand={%{name: "Linea", logo: "S"}} user={%{name: "Marina Costa", email: "marina@linea.com"}} />

  Put it inside a `.sg` root (the framed `shell/1` is one). Changing `format` changes how the menu is drawn,
  never the items.

  ## The menu data

  `nav` is a list of maps, in the order of the menu. A map with `group` is a group, any other is an item.

  Item keys:

    * `label`: the text (also the tooltip of the collapsed menu and the accessible name of an icon).
    * `icon`: see "Icons" below.
    * `navigate`, `patch` or `href`: where it goes (`#` when none).
    * `count`: a number at the right, in mono. A dot when the menu is collapsed.
    * `badge`: a notice dot at the right (the bell of the rail). A string is its accessible name.
    * `color`: a colour for the icon: a round chip in the rail's tree (children), a square chip in the `tree`
      format (items). A name (`blue`, `green`, `rose`, `violet`, `orange`, `ink`) or any CSS colour.
    * `children`: items under it, joined by a line (`tree`), a coloured tree (`rail`) or a plain tree.
    * `collapsible`: in the `tree` format an item with `children` gets a chevron at the right that closes and
      opens them; `false` takes it away. It is `true` when left out. It starts open only when it holds the
      active item (itself or a child), closed otherwise.
    * `open`: `true` or `false` forces a collapsible item open or closed at first, whatever the route.
    * `active`: marks it active; `current` marks the item whose `navigate`/`patch`/`href` is the current
      path (path and query are compared).
    * `formats`: a list of formats that show it (`["rail"]`: only the rail); every format when left out.

  Group keys:

    * `group`: the label.
    * `icon`: the icon of the group in the `rail`.
    * `items`: its items (and, in the `rail` panel, nested groups with a `collapsible` header).
    * `collapsible`: `false` takes the chevron (and the toggle) away and the group is always shown; it is
      `true` when left out. A collapsible group starts open only when it holds the active item.
    * `open`: `true` or `false` forces a collapsible group open or closed at first, whatever the route.
    * `navigate`, `patch`, `href`: where the group's icon goes in the rail (the first item's when left out).
    * `footer: true`: the group is the foot of the menu ("settings and help"): in `sections` under its label,
      in `tree` without it, in the `rail` as icons at the bottom.
    * `action`: `%{label, navigate, icon}`, the create button at the top of the rail panel.
    * `try`: `%{label, items}`, the shortcuts at the foot of the rail panel ("Try").

  The first item that is not in a group is the home of the rail (above the person); the other items without
  a group come after the group icons. The module open in the rail panel is the group that holds the active
  item (the first group when none does).

  ## Icons

  `icon` is a short name of the table below, drawn as the Hugeicons icon the canvas uses, or any class name
  (`huge-…`, `fa-solid fa-house`) that goes through as it is.

  #{@icon_table}

  ## Configuration

      config :linea_ui, :shell, sidebar: :sections, nav: {MyAppWeb.Nav, :items}

  `sidebar` (an atom or a string) is the format when `format` is left out and `nav` is `{module, function}`,
  called with the assigns of the component, when `nav` is left out. `footer: :version` and `version: "v1.4.2"`
  (or a map) are the foot (see "The foot"). What you pass always wins.

  ## The foot

  The foot of the menu is a choice (`footer`, in the three formats):

    * `"user"`: the person. The user card in the `tree` and in `sections` (the same `.sg-sb-user` card, in place
      of the plan card), the avatar in the `rail`.
    * `"version"`: the version line of the canvas (a status dot, `v1.4.2`, the build and the "What's new" link)
      in place of the user (`tree`, `rail`) or of the plan card (`sections`). The line is at the foot of the
      panel in the `rail`, so a `rail` collapsed to icons (which hides the panel) does not show it.
    * `"none"`: nothing, for an app that already shows the user in its topbar.
    * left out: each format as it was, the user card in the `tree`, the plan card in `sections`, the avatar in
      the `rail`.

  `version` is a string or a map; only `version` is required:

      version="v1.4.2"
      version=%{version: "v1.4.2", build: "2a9f1c3", navigate: "/changelog", label: "Novidades",
                title: "Updated today", status: :ok}

    * `build`: the short hash after the version.
    * `navigate`, `patch` or `href`: where the link goes; without one there is no link.
    * `label`: the text of the link (`"What's new"` when left out). `title`: its tooltip.
    * `status`: `:ok` (default, green dot), `:warning` or `:down`.

  `footer: :version` without a `version` draws nothing. A `version` without `footer` shows the version line (as
  in 0.15). `show_user={false}` is deprecated: it is `footer="none"`, or `"version"` when there is a `version`.
  Collapsed to icons the line is the dot, centred, with the version and the build in its `title` and
  `aria-label` (`"Version v1.4.2 (2a9f1c3)"`).

  The kit does not read the version of your app: pass it, from `Application.spec/2`, in the layout.

      <.shell footer="version" version={%{version: "v" <> to_string(Application.spec(:my_app, :vsn)),
        build: "2a9f1c3", navigate: ~p"/changelog", label: "Novidades"}} …>

  ## Collapsing

  In every format the menu collapses to icons (tooltips with the label, counts turn into dots). It uses the
  `LineaUI.ShellRail` hook of the framed menu: `collapsed` is the start, `on_collapse` is pushed with
  `%{"id" => id, "collapsed" => boolean}`, the choice is kept in `localStorage` (`persist`) and
  `<.rail_toggle for="sidebar" />` collapses it from anywhere. The `tree` button, the panel button of the `rail`
  (and a click on a module icon of a collapsed rail) do it by themselves; `sections` has no button of its own.
  Below 768px the menu is a top bar with a hamburger that opens it under the bar.
  """

  # ---------------------------------------------------------------- the component

  attr :id, :string, default: "sidebar"

  attr :format, :any,
    default: nil,
    doc:
      "`sections`, `rail` or `tree` (an atom works too). The `:shell` config `sidebar` when left out, else `sections`."

  attr :nav, :list,
    default: nil,
    doc:
      "The menu: a list of item and group maps. The `{module, function}` of the config when left out."

  attr :current, :string,
    default: nil,
    doc: "The current path; the item that goes there is active."

  attr :brand, :map,
    default: nil,
    doc:
      "`%{name, logo}` (`logo` is a letter, or `src` is an image URL); `switch: false` takes the company switcher out of `sections`, `switch: %{label, click}` gives it a label and a `phx-click`."

  attr :user, :map,
    default: nil,
    doc:
      "`%{name, email, initials, avatar, color}`: the avatar of the rail and the user card of the `tree`. `avatar` is an image URL, `color` the background of the initials."

  attr :footer, :any,
    default: nil,
    doc:
      "What the foot of the menu shows: `\"user\"`, `\"version\"` or `\"none\"` (an atom works too). The `:shell` config `footer` when left out, else each format's own (the user card of the `tree`, the plan card of `sections`, the avatar of the `rail`)."

  attr :show_user, :boolean,
    default: nil,
    doc:
      "Deprecated, use `footer`. `false` is `footer=\"none\"` (or `\"version\"` when there is a `version`). The `:shell` config `show_user` when left out."

  attr :version, :any,
    default: nil,
    doc:
      "The version of the system: a string (`\"v1.4.2\"`) or `%{version, build, href | navigate | patch, label, title, status}` (see \"The foot\"). The `:shell` config `version` when left out."

  attr :plan, :map, default: nil, doc: "`%{name, badge}`: the plan card of `sections`."

  attr :trial, :map,
    default: nil,
    doc:
      "`%{title, label, text, value, action, navigate}`: the trial card of the `rail` (`value` is the percentage of the bar; `action` is the link, to `navigate`, `patch` or `href`)."

  attr :rail_extra, :list,
    default: [],
    doc:
      "Extra apps of the rail, in coloured circles: `%{label, icon, color, navigate}` (`color` as in the items)."

  attr :collapsible, :boolean,
    default: true,
    doc: "Shows the collapse button of the `tree` and of the `rail` panel."

  attr :collapsed, :boolean, default: false, doc: "Whether the menu starts collapsed to icons."

  attr :persist, :boolean,
    default: true,
    doc: "Keeps the choice in `localStorage[\"linea-rail\"]`."

  attr :on_collapse, :string,
    default: nil,
    doc:
      "An event pushed with `%{\"id\" => id, \"collapsed\" => boolean}` when the choice changes."

  attr :target, :any, default: nil, doc: "The `phx-target` of `on_collapse`."
  attr :label, :string, default: "Main menu", doc: "The accessible name of the menu."
  attr :collapse_label, :string, default: "Collapse menu"
  attr :mobile_label, :string, default: "Menu", doc: "The accessible name of the hamburger."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :brand_mark,
    doc:
      "Replaces the logo and the name of the brand. (Not `:brand`: Phoenix does not allow a slot and an attribute with the same name, and `brand` is the map.)"

  slot :sidebar_footer,
    doc: "At the end of the foot of the menu (the end of the panel in the `rail`)."

  def sidebar(assigns) do
    assigns =
      assigns
      |> assign_derived(:fmt, [:format], fn -> Nav.format(assigns.format) end)
      |> assign_derived(:foot, [:footer, :show_user, :version, :user, :plan], fn ->
        ver = Nav.version(assigns.version)
        foot = Nav.footer(assigns.footer, assigns.show_user, assigns.version, ver)

        %{
          user: foot in ["default", "user"] && assigns.user,
          card: foot == "user" && assigns.user,
          plan: foot == "default" && assigns.plan,
          ver: foot == "version" && ver
        }
      end)
      |> assign_derived(:menu, [:nav, :current, :format, :id, :rest], fn ->
        nav = Nav.nav(assigns.nav, assigns)
        Nav.build(nav, assigns.current, Nav.format(assigns.format), assigns.id)
      end)

    ~H"""
    <nav
      id={@id}
      class={merge(["sg-sb", format_class(@fmt), @class])}
      aria-label={@label}
      phx-hook="LineaUI.ShellRail"
      phx-mounted={JS.ignore_attributes(["data-collapsed", "data-mobile-open"])}
      data-format={@fmt}
      data-collapsed={bool(@collapsed)}
      data-server-collapsed={bool(@collapsed)}
      data-mobile-open="false"
      data-persist={bool(@persist)}
      data-on-collapse={@on_collapse}
      data-target={@target}
      {@rest}
    >
      <.sections
        :if={@fmt == "sections"}
        id={@id}
        menu={@menu}
        brand={@brand}
        plan={@foot.plan}
        user={@foot.card}
        version={@foot.ver}
        mobile_label={@mobile_label}
      >
        <:mark :if={@brand_mark != []}>{render_slot(@brand_mark)}</:mark>
        <:footer :if={@sidebar_footer != []}>{render_slot(@sidebar_footer)}</:footer>
      </.sections>
      <.tree
        :if={@fmt == "tree"}
        id={@id}
        menu={@menu}
        brand={@brand}
        user={@foot.user}
        version={@foot.ver}
        collapsible={@collapsible}
        collapse_label={@collapse_label}
        mobile_label={@mobile_label}
      >
        <:mark :if={@brand_mark != []}>{render_slot(@brand_mark)}</:mark>
        <:footer :if={@sidebar_footer != []}>{render_slot(@sidebar_footer)}</:footer>
      </.tree>
      <.rail
        :if={@fmt == "rail"}
        id={@id}
        menu={@menu}
        brand={@brand}
        user={@foot.user}
        version={@foot.ver}
        trial={@trial}
        rail_extra={@rail_extra}
        collapsible={@collapsible}
        collapse_label={@collapse_label}
        mobile_label={@mobile_label}
      >
        <:mark :if={@brand_mark != []}>{render_slot(@brand_mark)}</:mark>
        <:footer :if={@sidebar_footer != []}>{render_slot(@sidebar_footer)}</:footer>
      </.rail>
    </nav>
    """
  end

  defp format_class("sections"), do: "sec"
  defp format_class("rail"), do: "railx"
  defp format_class("tree"), do: "treex"

  # ---------------------------------------------------------------- sections

  attr :id, :string, required: true
  attr :menu, :map, required: true
  attr :brand, :map, default: nil
  attr :plan, :map, default: nil
  attr :user, :map, default: nil
  attr :version, :map, default: nil
  attr :mobile_label, :string, required: true
  slot :mark
  slot :footer

  defp sections(assigns) do
    ~H"""
    <div class="sg-sb-brand">
      <.brand_mark brand={@brand} mark={@mark} />
      <.switcher :if={@brand && @brand[:switch] != false} switch={@brand[:switch]} />
      <.burger id={@id} label={@mobile_label} />
    </div>
    <div id={@id <> "-body"} class="sg-sb-body">
      <div class="sg-sb-scroll">
        <.entry :for={entry <- @menu.body} entry={entry} format="sections" />
      </div>
      <div class="sg-sb-foot">
        <div :if={@menu.footer_label} class="sg-sb-h2">{@menu.footer_label}</div>
        <.row :for={item <- @menu.footer_items} item={item} format="sections" />
        <div :if={@plan} class="sg-sb-plan">
          <.logo brand={@brand} />
          <b>{@plan[:name]}</b>
          <span :if={@plan[:badge]} class="pro">{@plan[:badge]}</span>
        </div>
        {render_slot(@footer)}
      </div>
      <.user_card :if={@user} user={@user} />
      <.version :if={@version} version={@version} />
    </div>
    """
  end

  attr :switch, :any, default: nil

  defp switcher(assigns) do
    ~H"""
    <button
      type="button"
      class="sw"
      aria-label={switch_label(@switch)}
      phx-click={switch_click(@switch)}
    >
      <svg class="i sm" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 9.5l4-4 4 4M8 14.5l4 4 4-4" /></svg>
    </button>
    """
  end

  defp switch_label(%{label: label}), do: label
  defp switch_label(_switch), do: "Switch company"
  defp switch_click(%{click: click}), do: click
  defp switch_click(_switch), do: nil

  # ---------------------------------------------------------------- tree

  attr :id, :string, required: true
  attr :menu, :map, required: true
  attr :brand, :map, default: nil
  attr :user, :map, default: nil
  attr :version, :map, default: nil
  attr :collapsible, :boolean, default: true
  attr :collapse_label, :string, required: true
  attr :mobile_label, :string, required: true
  slot :mark
  slot :footer

  defp tree(assigns) do
    ~H"""
    <div class="sg-sb-brand">
      <.brand_mark brand={@brand} mark={@mark} />
      <button
        :if={@collapsible}
        type="button"
        class="col"
        aria-label={@collapse_label}
        aria-pressed="false"
        title={@collapse_label}
        data-rail-toggle={@id}
      >
        <svg class="i sm" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 7l-5 5 5 5M18 7l-5 5 5 5" /></svg>
      </button>
      <.burger id={@id} label={@mobile_label} />
    </div>
    <div id={@id <> "-body"} class="sg-sb-body">
      <div class="sg-sb-scroll">
        <.entry :for={entry <- @menu.body} entry={entry} format="tree" />
      </div>
      <div class="sg-sb-foot">
        <.row :for={item <- @menu.footer_items} item={item} format="tree" />
        {render_slot(@footer)}
      </div>
      <.user_card :if={@user} user={@user} />
      <.version :if={@version} version={@version} />
    </div>
    """
  end

  # ---------------------------------------------------------------- rail

  attr :id, :string, required: true
  attr :menu, :map, required: true
  attr :brand, :map, default: nil
  attr :user, :map, default: nil
  attr :version, :map, default: nil
  attr :trial, :map, default: nil
  attr :rail_extra, :list, default: []
  attr :collapsible, :boolean, default: true
  attr :collapse_label, :string, required: true
  attr :mobile_label, :string, required: true
  slot :mark
  slot :footer

  defp rail(assigns) do
    ~H"""
    <div class="sg-sb-mbar">
      <.brand_mark brand={@brand} mark={@mark} />
      <.burger id={@id} label={@mobile_label} />
    </div>
    <div id={@id <> "-body"} class="sg-sb-body">
      <div class="sg-sb-rail">
        <.brand_mark brand={@brand} mark={@mark} large />
        <.rail_icon :if={@menu.home} item={@menu.home} />
        <.avatar :if={@user} user={@user} />
        <i :if={@menu.groups != [] or @menu.more != []} class="sep"></i>
        <.rail_icon :for={group <- @menu.groups} item={group} module on={group == @menu.module} />
        <.rail_icon :for={item <- @menu.more} item={item} />
        <i :if={@rail_extra != []} class="sep"></i>
        <.rail_dot :for={extra <- @rail_extra} extra={extra} />
        <span class="grow"></span>
        <.rail_icon :for={item <- @menu.footer_items} item={item} />
      </div>
      <div :if={@menu.module} class="sg-sb-panel">
        <div class="sg-sb-ph">
          <b>{@menu.module.label}</b>
          <span>
            <button
              :if={@collapsible}
              type="button"
              aria-label={@collapse_label}
              aria-pressed="false"
              title={@collapse_label}
              data-rail-toggle={@id}
            >
              <Icon.icon name="huge-sidebar-left" class="i sm" />
            </button>
          </span>
        </div>
        <div class="sg-sb-scroll">
          <.link :if={@menu.module.action} class="sg-sb-new" {@menu.module.action.link}>
            <Icon.icon :if={@menu.module.action.icon} name={@menu.module.action.icon} class="i sm" />{@menu.module.action.label}
          </.link>
          <.entry :for={entry <- @menu.module.items} entry={entry} format="rail" />
          <span class="grow"></span>
          <div :if={@menu.module.try} class="sg-sb-gh plain">{@menu.module.try.label}</div>
          <.row
            :for={item <- (@menu.module.try && @menu.module.try.items) || []}
            item={item}
            format="rail"
          />
        </div>
        <div :if={@trial} class="sg-sb-trial">
          <div class="row1">
            <span class="z"><Icon.icon name="huge-flash" class="i sm" /></span>
            <b>{@trial[:title]}</b>
            <span :if={@trial[:label]} class="free">{@trial[:label]}</span>
          </div>
          <div
            class="bar"
            role="progressbar"
            aria-label={@trial[:title]}
            aria-valuemin="0"
            aria-valuemax="100"
            aria-valuenow={@trial[:value]}
          >
            <i style={"width:#{@trial[:value] || 0}%"}></i>
          </div>
          <div class="row2">
            <span>{@trial[:text]}</span>
            <.link :if={@trial[:action]} {Nav.link_attrs(@trial)}>{@trial[
              :action
            ]}</.link>
          </div>
        </div>
        {render_slot(@footer)}
        <.version :if={@version} version={@version} />
      </div>
    </div>
    """
  end

  attr :item, :map, required: true
  attr :module, :boolean, default: false
  attr :on, :boolean, default: false

  defp rail_icon(assigns) do
    ~H"""
    <.link
      class={["r", (@on or @item[:active]) && "on", @item[:badge] && "has-badge"]}
      aria-label={@item.label}
      aria-current={(@on or @item[:active]) && "page"}
      data-rail-tip="always"
      data-module={@module && ""}
      {@item.link}
    >
      <Icon.icon :if={@item.icon} name={@item.icon} class="i" />
      <span class="rail-tip" role="tooltip">{@item.label}</span>
    </.link>
    """
  end

  attr :extra, :map, required: true

  defp rail_dot(assigns) do
    assigns = assign_derived(assigns, :dot, [:extra], fn -> Nav.dot(assigns.extra) end)

    ~H"""
    <.link
      class={["dot", @dot.color]}
      style={@dot.style}
      aria-label={@extra[:label]}
      data-rail-tip="always"
      {@dot.link}
    >
      <Icon.icon :if={@dot.icon} name={@dot.icon} class="i sm" />
      <span class="rail-tip" role="tooltip">{@extra[:label]}</span>
    </.link>
    """
  end

  # ---------------------------------------------------------------- entries

  attr :entry, :map, required: true
  attr :format, :string, required: true

  # an item, or a group with its label in the three formats
  defp entry(%{entry: %{kind: :item}} = assigns) do
    ~H"""
    <.row item={@entry} format={@format} />
    """
  end

  defp entry(%{entry: %{kind: :group}, format: "sections"} = assigns) do
    ~H"""
    <div class="sg-sb-h">{@entry.label}</div>
    <.row :for={item <- @entry.items} item={item} format="sections" />
    """
  end

  defp entry(%{entry: %{kind: :group}, format: "tree"} = assigns) do
    ~H"""
    <button
      :if={@entry.collapsible}
      type="button"
      class="sg-sb-gt"
      aria-expanded={if @entry.open, do: "true", else: "false"}
      aria-controls={@entry.id}
      phx-mounted={JS.ignore_attributes(["aria-expanded"])}
      phx-click={toggle(@entry.id)}
    >
      {@entry.label}
      <svg class="i sm" viewBox="0 0 24 24" aria-hidden="true"><path d="M7 10l5 5 5-5" /></svg>
    </button>
    <div :if={!@entry.collapsible} class="sg-sb-gt">{@entry.label}</div>
    <div
      id={@entry.id}
      class="sg-sb-grp"
      data-closed={!@entry.open && "true"}
      phx-mounted={JS.ignore_attributes(["data-closed"])}
    >
      <.row :for={item <- @entry.items} item={item} format="tree" />
    </div>
    """
  end

  # a nested group of the rail panel
  defp entry(%{entry: %{kind: :group}, format: "rail"} = assigns) do
    ~H"""
    <div class="sg-sb-gh">
      {@entry.label}
      <button
        :if={@entry.collapsible}
        type="button"
        class="tg"
        aria-label={@entry.label}
        aria-expanded={if @entry.open, do: "true", else: "false"}
        aria-controls={@entry.id}
        phx-mounted={JS.ignore_attributes(["aria-expanded"])}
        phx-click={toggle(@entry.id)}
      >
        <svg class="i sm" viewBox="0 0 24 24" aria-hidden="true"><path d="M7 10l5 5 5-5" /></svg>
      </button>
    </div>
    <div
      id={@entry.id}
      class="sg-sb-grp"
      data-closed={!@entry.open && "true"}
      phx-mounted={JS.ignore_attributes(["data-closed"])}
    >
      <.row :for={item <- @entry.items} item={item} format="rail" />
    </div>
    """
  end

  defp toggle(id) do
    JS.toggle_attribute({"aria-expanded", "true", "false"})
    |> JS.toggle_attribute({"data-closed", "true"}, to: "#" <> id)
  end

  attr :item, :map, required: true
  attr :format, :string, required: true
  attr :child, :boolean, default: false

  # an item row, with its children
  defp row(%{item: %{kind: :group}} = assigns) do
    ~H"""
    <.entry entry={@item} format={@format} />
    """
  end

  defp row(assigns) do
    assigns =
      assign_derived(assigns, :chip, [:item, :format, :child], fn ->
        chip(assigns.item.color || assigns.item.style, assigns.format, assigns.child)
      end)

    ~H"""
    <.link
      class={[
        "sg-sb-a",
        @item.active && "on",
        @child && @format == "rail" && "t",
        @chip == "sqi" && "sq"
      ]}
      aria-current={@item.active && "page"}
      data-rail-tip
      {@item.link}
    >
      <span
        :if={@chip && @item.icon}
        class={[@chip, @item.color]}
        style={@item.style}
      >
        <Icon.icon name={@item.icon} class="i sm" />
      </span>
      <Icon.icon :if={!@chip && @item.icon} name={@item.icon} class="i" />
      <span class="lbl">{@item.label}</span>
      <span :if={@item.count} class="sg-sb-n">{@item.count}</span>
      <span
        :if={@item.badge}
        class="red"
        role={is_binary(@item.badge) && "img"}
        aria-label={is_binary(@item.badge) && @item.badge}
        aria-hidden={!is_binary(@item.badge) && "true"}
      ></span>
      <span class="rail-tip" role="tooltip">{@item.label}</span>
    </.link>
    <button
      :if={@item.collapsible}
      type="button"
      class="sg-sb-ct"
      aria-expanded={if @item.open, do: "true", else: "false"}
      aria-controls={@item.tree_id}
      aria-label={@item.label}
      phx-mounted={JS.ignore_attributes(["aria-expanded"])}
      phx-click={toggle(@item.tree_id)}
    >
      <svg class="i sm" viewBox="0 0 24 24" aria-hidden="true"><path d="M7 10l5 5 5-5" /></svg>
    </button>
    <div
      :if={@item.children != []}
      id={@item.collapsible && @item.tree_id}
      class={["sg-sb-tree", @format == "tree" && "line"]}
      data-closed={!@item.open && "true"}
      phx-mounted={@item.collapsible && JS.ignore_attributes(["data-closed"])}
    >
      <svg
        :if={@item.branch}
        class="tb"
        height={@item.branch.height}
        viewBox={"0 0 24 #{@item.branch.height}"}
        aria-hidden="true"
      >
        <path class="t" d={@item.branch.trunk} />
        <path :if={@item.branch.path} class="a" d={@item.branch.path} />
        <circle :for={n <- @item.branch.nodes} :if={n.on} class="h" cx="16" cy={"#{n.y}.0"} r="7" />
        <circle
          :for={n <- @item.branch.nodes}
          class={["n", n.on && "on"]}
          cx="16"
          cy={"#{n.y}.0"}
          r="3.75"
        />
      </svg>
      <.row :for={child <- @item.children} item={child} format={@format} child />
    </div>
    """
  end

  # the coloured chip of the icon: round in the rail's tree, square on the items of the tree format
  defp chip(nil, _format, _child), do: nil
  defp chip(_color, "rail", true), do: "ci"
  defp chip(_color, "tree", false), do: "sqi"
  defp chip(_color, _format, _child), do: nil

  # ---------------------------------------------------------------- pieces

  attr :brand, :map, default: nil
  attr :large, :boolean, default: false
  attr :mark, :list, default: []

  defp brand_mark(%{mark: [_ | _]} = assigns) do
    ~H"""
    {render_slot(@mark)}
    """
  end

  defp brand_mark(assigns) do
    ~H"""
    <.logo :if={@brand} brand={@brand} large={@large} />
    <b :if={@brand && !@large && @brand[:name]}>{@brand[:name]}</b>
    """
  end

  attr :brand, :map, default: nil
  attr :large, :boolean, default: false

  defp logo(assigns) do
    ~H"""
    <span :if={@brand} class={["sg-sb-logo", @large && "lg"]}>
      <img
        :if={@brand[:src]}
        src={@brand[:src]}
        alt=""
      />
      <%= if !@brand[:src] do %>
        {@brand[:logo]}
      <% end %>
    </span>
    """
  end

  attr :version, :map, required: true

  defp version(assigns) do
    ~H"""
    <div
      class="sg-sb-ver"
      role="group"
      title={@version.aria}
      aria-label={@version.aria}
      data-status={@version.status}
    >
      <span class="dot" aria-hidden="true"></span>
      <span class="v">{@version.version}</span>
      <span :if={@version.build} class="b">{@version.build}</span>
      <.link :if={@version.link} class="new" title={@version.title} {@version.link}>
        {@version.label}<svg class="i sm" viewBox="0 0 24 24" aria-hidden="true"><path d="M9 6l6 6-6 6" /></svg>
      </.link>
    </div>
    """
  end

  attr :user, :map, required: true

  defp user_card(assigns) do
    ~H"""
    <div class="sg-sb-user">
      <div class="me">
        <.avatar user={@user} />
        <div class="who">
          <b>{@user[:name]}</b>
          <span :if={@user[:email]}>{@user[:email]}</span>
        </div>
      </div>
    </div>
    """
  end

  attr :user, :map, required: true

  defp avatar(assigns) do
    ~H"""
    <span
      class="sg-av"
      style={@user[:color] && "background:#{@user[:color]}"}
      title={@user[:name]}
      role="img"
      aria-label={@user[:name]}
    >
      <img
        :if={@user[:avatar]}
        src={@user[:avatar]}
        alt=""
      />
      <%= if !@user[:avatar] do %>
        {Nav.initials(@user)}
      <% end %>
    </span>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true

  defp burger(assigns) do
    ~H"""
    <button
      type="button"
      class="sg-sb-burger"
      aria-expanded="false"
      aria-controls={@id <> "-body"}
      aria-label={@label}
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
    """
  end
end
