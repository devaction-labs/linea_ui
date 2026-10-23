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
end
