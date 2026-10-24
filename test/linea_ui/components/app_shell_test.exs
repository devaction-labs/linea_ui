defmodule LineaUI.Components.AppShellTest do
  use LineaUI.ComponentCase, async: true

  alias Phoenix.LiveView.JS

  describe "app_shell" do
    test "renders LineOne's body classes and the hook" do
      html = render(~H"<.app_shell>Content</.app_shell>")
      classes = classes(html, "#app-shell")

      assert "is-sidebar-open" in classes
      assert "is-header-blur" in classes
      assert "min-h-100vh" in classes
      assert [shell] = find(html, "#app-shell[phx-hook='LineaUI.AppShell']") |> Enum.to_list()
      assert LazyHTML.attribute(shell, "data-open") == ["true"]
      assert LazyHTML.attribute(shell, "data-persist") == ["true"]
      assert [_] = find(html, "main.main-content") |> Enum.to_list()
    end

    test "each layout sets its class and its default state" do
      minimal = render(~H|<.app_shell layout="minimal">x</.app_shell>|)
      assert "has-min-sidebar" in classes(minimal, "#app-shell")
      refute "is-sidebar-open" in classes(minimal, "#app-shell")

      sideblock = render(~H|<.app_shell layout="sideblock">x</.app_shell>|)
      assert "navigation:sideblock" in classes(sideblock, "#app-shell")
      assert "is-sidebar-open" in classes(sideblock, "#app-shell")

      horizontal =
        render(~H|<.app_shell layout="horizontal"><:sidebar>s</:sidebar>x</.app_shell>|)

      assert "navigation:horizontal" in classes(horizontal, "#app-shell")
      assert "sm:hidden" in classes(horizontal, ".sidebar")
    end

    test "sidebar_open, header options, preloader and on_toggle" do
      html =
        render(~H"""
        <.app_shell
          id="s"
          sidebar_open={false}
          header_blur={false}
          header_sticky={false}
          preloader
          on_toggle="sidebar"
          target="#comp"
        >
          x
        </.app_shell>
        """)

      classes = classes(html, "#s")
      refute "is-sidebar-open" in classes
      assert "is-header-solid" in classes
      assert "is-header-not-sticky" in classes
      assert [shell] = find(html, "#s") |> Enum.to_list()
      assert LazyHTML.attribute(shell, "data-toggle-event") == ["sidebar"]
      assert LazyHTML.attribute(shell, "data-target") == ["#comp"]
      assert [_] = find(html, "[data-app-preloader].app-preloader") |> Enum.to_list()
    end

    test "on_toggle accepts a JS command" do
      html = render(~H|<.app_shell on_toggle={JS.push("x")}>x</.app_shell>|)
      assert [shell] = find(html, "#app-shell") |> Enum.to_list()
      assert [js] = LazyHTML.attribute(shell, "data-on-toggle")
      assert js =~ "push"
    end
  end

  describe "main_sidebar" do
    test "renders the logo, items with tooltips and the active item from current" do
      html =
        render(~H"""
        <.main_sidebar current="/forms?tab=1">
          <:logo navigate="/" src="/logo.svg" />
          <:item navigate="/dash" label="Dashboards">D</:item>
          <:item navigate="/forms" label="Forms">F</:item>
          <:item href="#" label="Pages" active>P</:item>
          <:bottom><.main_sidebar_link href="/settings">S</.main_sidebar_link></:bottom>
        </.main_sidebar>
        """)

      assert [_] =
               find(html, "#main-sidebar.main-sidebar[phx-hook='LineaUI.ShellTooltips']")
               |> Enum.to_list()

      assert [_] = find(html, "img[src='/logo.svg']") |> Enum.to_list()

      assert ["Dashboards", "Forms", "Pages"] =
               find(html, "[role=tooltip]")
               |> Enum.map(&LazyHTML.text/1)
               |> Enum.map(&String.trim/1)

      assert ["/forms", "#"] =
               find(html, "a[aria-current=page]")
               |> Enum.flat_map(&LazyHTML.attribute(&1, "href"))

      assert "bg-primary/10" in classes(html, "a[href='/forms']")
      refute "bg-primary/10" in classes(html, "a[href='/dash']")
      assert [_] = find(html, "a[href='/settings']") |> Enum.to_list()
    end

    test "centered moves the links to the middle" do
      html = render(~H|<.main_sidebar centered>
  <:item href="#">x</:item>
</.main_sidebar>|)
      assert "justify-between" in classes(html, ".main-sidebar > div")
    end
  end

  test "sidebar_profile renders the avatar, the box and its links" do
    html =
      render(~H"""
      <.sidebar_profile id="p" src="/a.jpg" name="Travis" subtitle="Designer">
        <:item navigate="/profile" color="warning" title="Profile" description="Settings">i</:item>
        <:footer><button>Logout</button></:footer>
      </.sidebar_profile>
      """)

    assert [_] =
             find(html, "#p[phx-hook='LineaUI.ShellPopper'][data-placement=right-end]")
             |> Enum.to_list()

    assert [_] = find(html, "#p-ref[data-popper-ref][aria-expanded=false]") |> Enum.to_list()
    assert [_] = find(html, "#p-box.popper-root[data-popper-box]") |> Enum.to_list()
    assert "bg-warning" in classes(html, "a[href='/profile'] > div")
    assert "bg-success" in classes(html, "#p-ref span")
    assert html =~ "Logout"
  end

  describe "sidebar panel" do
    test "renders the title, the close button and the links" do
      html =
        render(~H"""
        <.sidebar_panel title="Layouts">
          <.sidebar_nav>
            <.sidebar_nav_link navigate="/a" current="/a">A</.sidebar_nav_link>
            <.sidebar_nav_link navigate="/b" current="/a">B</.sidebar_nav_link>
          </.sidebar_nav>
          <.sidebar_nav_divider />
        </.sidebar_panel>
        """)

      assert html =~ "Layouts"
      assert [_] = find(html, ".sidebar-panel button[data-sidebar-close]") |> Enum.to_list()
      assert "text-primary" in classes(html, "a[href='/a']")
      assert "text-slate-600" in classes(html, "a[href='/b']")
      assert [_] = find(html, "div.h-px") |> Enum.to_list()
    end

    test "a group opens when an item is active and keeps its client state" do
      html =
        render(~H"""
        <.sidebar_nav_group label="Starter Pages" current="/two">
          <:item navigate="/one">One</:item>
          <:item navigate="/two">Two</:item>
        </.sidebar_nav_group>
        <.sidebar_nav_group label="Other">
          <:item navigate="/x">X</:item>
        </.sidebar_nav_group>
        """)

      assert [open] = find(html, "details#sidebar-group-starter-pages[open]") |> Enum.to_list()
      assert LazyHTML.attribute(open, "data-open") == ["true"]
      assert LazyHTML.attribute(open, "phx-hook") == ["LineaUI.SidebarGroup"]
      assert LazyHTML.attribute(open, "name") == ["sidebar-nav"]
      assert [] = find(html, "details#sidebar-group-other[open]") |> Enum.to_list()
      assert "text-primary" in classes(html, "a[href='/two']")
    end

    test "open overrides the items" do
      html = render(~H|<.sidebar_nav_group id="g" label="G" open>
  <:item href="#">x</:item>
</.sidebar_nav_group>|)
      assert [_] = find(html, "details#g[open]") |> Enum.to_list()
    end

    test "the minimized panel and its links" do
      html =
        render(~H"""
        <.sidebar_panel_min>
          <:header>H</:header>
          <.sidebar_min_group>
            <.sidebar_min_link href="/a" active label="A">a</.sidebar_min_link>
            <.sidebar_min_link href="/b" color="error" label="B">b</.sidebar_min_link>
          </.sidebar_min_group>
          <.sidebar_min_divider />
          <:footer>F</:footer>
        </.sidebar_panel_min>
        """)

      assert [_] = find(html, ".sidebar-panel-min") |> Enum.to_list()
      assert "bg-primary/10" in classes(html, "a[href='/a']")
      assert "text-error" in classes(html, "a[href='/b']")
      assert html =~ "F"
    end

    test "the sideblock" do
      html = render(~H|<.sideblock><:logo href="/" src="/l.svg" />nav</.sideblock>|)
      assert [_] = find(html, ".sidebar-panel img[src='/l.svg']") |> Enum.to_list()
      assert [_] = find(html, "[data-sidebar-close]") |> Enum.to_list()
    end
  end

  describe "header" do
    test "renders the toggle, the search, the toggles, notifications and the right sidebar button" do
      html =
        render(~H"""
        <.header right_sidebar="rs" search_input={%{"name" => "q"}}>
          <:start>Title</:start>
          <:search_results>Results</:search_results>
          <:notifications>Notes</:notifications>
          <:profile>Me</:profile>
        </.header>
        """)

      assert [_] = find(html, "nav.header .sidebar-toggle[data-sidebar-toggle]") |> Enum.to_list()

      assert [_] =
               find(
                 html,
                 "#app-header-search[phx-hook='LineaUI.ShellPopper'][data-trigger=focus]"
               )
               |> Enum.to_list()

      assert [_] = find(html, "#app-header-search-input[name=q]") |> Enum.to_list()

      assert [_] =
               find(html, "#app-header-theme[phx-hook='LineaUI.ThemeToggle']") |> Enum.to_list()

      assert [_] =
               find(html, "#app-header-monochrome[phx-hook='LineaUI.MonochromeToggle']")
               |> Enum.to_list()

      assert [_] = find(html, "#app-header-notifications .animate-ping") |> Enum.to_list()
      assert [_] = find(html, "button[aria-controls=rs]") |> Enum.to_list()

      assert [_] =
               find(html, "#app-header-mobile-search.mobile-searchbar[data-mobile-searchbar]")
               |> Enum.to_list()

      assert html =~ "Results" and html =~ "Notes" and html =~ "Me" and html =~ "Title"
    end

    test "options turn parts off" do
      html =
        render(~H"""
        <.header toggle={false} search={false} theme_toggle={false} monochrome_toggle={false}>
          <:notifications dot={false}>n</:notifications>
        </.header>
        """)

      assert [] = find(html, ".sidebar-toggle") |> Enum.to_list()
      assert [] = find(html, ".mobile-searchbar") |> Enum.to_list()
      assert [] = find(html, ".darkmode-toggle") |> Enum.to_list()
      assert [] = find(html, ".monochrome-toggle") |> Enum.to_list()
      assert [] = find(html, ".animate-ping") |> Enum.to_list()
    end

    test "a :nav slot makes the horizontal header" do
      html =
        render(~H"""
        <.header>
          <:brand navigate="/" src="/l.svg" label="lineone" />
          <:nav>
            <.horizontal_nav_menu id="m" label="Pages" current="/p">
              <:item navigate="/p">P</:item>
              <.horizontal_nav_divider />
              <.horizontal_nav_link href="/x">X</.horizontal_nav_link>
            </.horizontal_nav_menu>
          </:nav>
        </.header>
        """)

      assert "sm:flex-col" in classes(html, ".header-container")
      assert "sm:hidden" in classes(html, "nav.header div.size-7")
      assert html =~ "lineone"

      assert [_] =
               find(html, "#m[phx-hook='LineaUI.ShellPopper'][data-placement=bottom-start]")
               |> Enum.to_list()

      assert "bg-primary/10" in classes(html, "#m-ref")

      assert [_] =
               find(html, "a[href='/p'][aria-current=page][data-popper-close]") |> Enum.to_list()

      assert [_] = find(html, "[role=separator]") |> Enum.to_list()
    end
  end

  test "right_sidebar renders the drawer with its parts and events" do
    html =
      render(~H"""
      <.right_sidebar id="rs" open on_open="opened" on_close={JS.push("closed")}>
        <:title>Today</:title>
        Body
      </.right_sidebar>
      """)

    assert [root] =
             find(html, "#rs.drawer.drawer-right[phx-hook='LineaUI.RightSidebar']")
             |> Enum.to_list()

    assert LazyHTML.attribute(root, "data-open") == ["true"]
    assert LazyHTML.attribute(root, "data-open-event") == ["opened"]
    assert [js] = LazyHTML.attribute(root, "data-on-close")
    assert js =~ "closed"
    assert [_] = find(html, "#rs-overlay[data-drawer-overlay].hidden") |> Enum.to_list()
    assert [_] = find(html, "#rs-content[role=dialog][aria-modal=true]") |> Enum.to_list()
    assert [_] = find(html, "[data-drawer-close]") |> Enum.to_list()
  end

  test "page_header renders the title and the breadcrumb" do
    html =
      render(~H"""
      <.page_header title="Avatar">
        <:crumb navigate="/elements">Elements</:crumb>
        <:crumb>Avatar</:crumb>
      </.page_header>
      """)

    assert html =~ "Avatar"
    assert [_] = find(html, "a[href='/elements'][data-phx-link=redirect]") |> Enum.to_list()
    assert [_] = find(html, "span[aria-current=page]") |> Enum.to_list()
    assert [_] = find(html, "li svg") |> Enum.to_list()
  end

  test "page_header puts its actions at the right end and omits the box without them" do
    with_actions =
      render(~H"""
      <.page_header title="Invoice">
        <:actions><button id="new">New</button></:actions>
      </.page_header>
      """)

    assert [_] = find(with_actions, ".ml-auto #new") |> Enum.to_list()
    refute render(~H|<.page_header title="Invoice" />|) =~ "ml-auto"
  end

  test "theme_toggle, monochrome_toggle and theme_script" do
    html =
      render(~H"""
      <.theme_toggle on_change="theme" />
      <.monochrome_toggle variant="switch" id="m">Toggle</.monochrome_toggle>
      <.theme_script />
      """)

    assert [toggle] = find(html, "#theme-toggle.darkmode-toggle") |> Enum.to_list()
    assert LazyHTML.attribute(toggle, "data-change-event") == ["theme"]
    assert [_] = find(html, ".darkmode-moon") |> Enum.to_list()

    assert [_] =
             find(html, "input#m[type=checkbox][phx-hook='LineaUI.MonochromeToggle'].form-switch")
             |> Enum.to_list()

    assert html =~ "dark-mode"
    assert html =~ "monochrome-mode"
  end

  test "class merges last" do
    html = render(~H|<.page_header title="T" class="py-0" />|)
    assert "py-0" in classes(html, "div")
    refute "py-5" in classes(html, "div")
  end

  describe "the framed shell" do
    defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

    test "a grey frame with the menu and a rounded main panel" do
      html =
        render(~H"""
        <.app_shell id="s" layout="framed">
          <:sidebar>
            <aside id="menu">m</aside>
          </:sidebar>
          <p id="page">Page</p>
        </.app_shell>
        """)

      assert ["linea-frame", "bg-slate-150", "md:flex-row", "md:p-2.5"] --
               classes(html, "#s") == []

      refute "is-sidebar-open" in classes(html, "#s")
      assert [_] = find(html, "#s > #menu") |> Enum.to_list()
      assert ["md:rounded-xl", "bg-white"] -- classes(html, "#s > main") == []
      assert [_] = find(html, "#s > main > #page") |> Enum.to_list()
    end

    test "the menu is a rail that remembers its state and turns into a top bar" do
      html =
        render(~H"""
        <.framed_sidebar id="menu" collapsed on_collapse="collapse" mobile_label="Menu">
          <:brand><img id="mark" alt="" src="/m.svg" /></:brand>
          <:wordmark>Signetum</:wordmark>
          <:workspace>Farmacia</:workspace>
          <:bottom>
            <div id="me">me</div>
          </:bottom>
          <a id="x" href="/">x</a>
        </.framed_sidebar>
        """)

      assert attr_of(html, "#menu", "phx-hook") == ["LineaUI.ShellRail"]
      assert attr_of(html, "#menu", "data-collapsed") == ["true"]
      assert attr_of(html, "#menu", "data-server-collapsed") == ["true"]
      assert attr_of(html, "#menu", "data-persist") == ["true"]
      assert attr_of(html, "#menu", "data-on-collapse") == ["collapse"]
      assert attr_of(html, "#menu", "data-mobile-open") == ["false"]
      assert attr_of(html, "#menu", "phx-mounted") |> hd() =~ "data-collapsed"
      assert [_] = find(html, "#menu .rail-mark #mark") |> Enum.to_list()
      assert "rail-label" in classes(html, "#menu .rail-wordmark")

      assert [_] =
               find(html, "#menu button[data-mobile-toggle][aria-label=Menu]") |> Enum.to_list()

      assert [_] = find(html, "#menu #menu-body nav.rail-nav > #x") |> Enum.to_list()
      assert [_] = find(html, "#menu #menu-body > #me") |> Enum.to_list()

      open = render(~H|<.framed_sidebar id="m" persist={false}>x</.framed_sidebar>|)
      assert attr_of(open, "#m", "data-collapsed") == ["false"]
      assert attr_of(open, "#m", "data-persist") == ["false"]
    end

    test "the toggle points at the menu" do
      html = render(~H|<.rail_toggle for="menu" label="Recolher" />|)

      assert attr_of(html, "button", "data-rail-toggle") == ["menu"]
      assert attr_of(html, "button", "aria-label") == ["Recolher"]
      assert attr_of(html, "button", "aria-pressed") == ["false"]
      assert [_] = find(html, "button svg") |> Enum.to_list()
    end

    test "a link has its icon, label, badge and tooltip, and follows the current path" do
      html =
        render(~H"""
        <.rail_link id="a" navigate="/orders" label="Orders" badge="3" current="/orders"><i id="i" /></.rail_link>
        <.rail_link id="b" navigate="/chat" label="Chat" current="/orders"><i /></.rail_link>
        """)

      assert "is-active" in classes(html, "#a")
      assert attr_of(html, "#a", "aria-current") == ["page"]
      refute "is-active" in classes(html, "#b")
      assert [_] = find(html, "#a .rail-icon > #i") |> Enum.to_list()
      assert find(html, "#a .rail-badge") |> LazyHTML.text() == "3"
      assert find(html, "#a .rail-tip[role=tooltip]") |> LazyHTML.text() == "Orders"
      assert find(html, "#b .rail-badge") |> Enum.to_list() == []
    end

    test "a module opens the pages under it, and starts open on the current page" do
      html =
        render(~H"""
        <.rail_module id="sales" label="Sales" badge="2" current="/orders">
          <:icon><i id="ic" /></:icon>
          <:item navigate="/orders">Orders</:item>
          <:item navigate="/products">Products</:item>
        </.rail_module>
        <.rail_module id="buy" label="Purchases" current="/orders">
          <:icon><i /></:icon>
          <:item navigate="/suppliers">Suppliers</:item>
        </.rail_module>
        """)

      assert attr_of(html, "#sales", "data-open") == ["true"]
      assert attr_of(html, "#buy", "data-open") == ["false"]
      assert attr_of(html, "#sales > button", "aria-expanded") == ["true"]
      assert attr_of(html, "#sales > button", "data-module") == [""]
      assert "is-active" in classes(html, "#sales > button")
      refute "is-active" in classes(html, "#buy > button")
      assert attr_of(html, "#sales > button", "phx-click") |> hd() =~ "data-open"
      assert attr_of(html, "#sales", "phx-mounted") |> hd() =~ "data-open"
      assert [_, _] = find(html, "#sales-pages > a") |> Enum.to_list()
      assert attr_of(html, "#sales-pages > a", "aria-current") == ["page"]
      assert attr_of(html, "#sales-pages > a", "href") == ["/orders", "/products"]

      closed = render(~H|<.rail_module id="m" label="M" open={false} current="/x">
  <:icon>i</:icon><:item navigate="/x">X</:item>
</.rail_module>|)
      assert attr_of(closed, "#m", "data-open") == ["false"]
    end

    test "the person at the bottom" do
      html =
        render(~H|<.rail_user name="Ana Souza" subtitle="Admin"><b id="av">AS</b></.rail_user>|)

      assert [_] = find(html, ".rail-user > #av") |> Enum.to_list()
      assert find(html, ".rail-user .rail-label") |> LazyHTML.text() =~ "Ana Souza"
      assert find(html, ".rail-user .rail-label") |> LazyHTML.text() =~ "Admin"
    end

    test "the page variant of the header: crumbs, clock, bell, badge, title, context, actions and tabs" do
      html =
        render(~H"""
        <.page_header
          id="ph"
          variant="page"
          title="Order PV-1283"
          description="Clinica"
          clock
          locale="pt-BR"
          bell
        >
          <:crumb navigate="/orders">Orders</:crumb>
          <:crumb>PV-1283</:crumb>
          <:badge><span id="b">Approved</span></:badge>
          <:actions><button id="go">Issue</button></:actions>
          <:tabs><button id="t">Items</button></:tabs>
        </.page_header>
        """)

      assert "text-[28px]" in classes(html, "h1")
      assert find(html, "h1") |> LazyHTML.text() =~ "Order PV-1283"
      assert find(html, "header > div p") |> LazyHTML.text() == "Clinica"
      assert attr_of(html, "nav a", "href") == ["/orders"]
      assert attr_of(html, "nav [aria-current=page]", "aria-current") == ["page"]
      assert attr_of(html, "#ph-clock", "phx-hook") == ["LineaUI.ShellClock"]
      assert attr_of(html, "#ph-clock", "data-locale") == ["pt-BR"]
      assert [_] = find(html, "button[aria-label=Notifications] svg") |> Enum.to_list()
      assert [_] = find(html, "#b") |> Enum.to_list()
      assert [_] = find(html, "#go") |> Enum.to_list()
      assert [_] = find(html, "header > div.border-b > #t") |> Enum.to_list()

      own = render(~H|<.page_header variant="page" title="T" bell>
  <:notifications><i id="own" /></:notifications>
</.page_header>|)
      assert [_] = find(own, "#own") |> Enum.to_list()
      assert find(own, "button[aria-label=Notifications]") |> Enum.to_list() == []

      led = render(~H|<.page_header variant="page" title="T">
  <:leading><i id="lead" /></:leading><:crumb>C</:crumb>
</.page_header>|)
      assert [_] = find(led, "header > div > #lead + nav") |> Enum.to_list()

      inline = render(~H|<.page_header title="T" />|)
      assert find(inline, "h2") |> Enum.count() == 1
    end
  end
end
