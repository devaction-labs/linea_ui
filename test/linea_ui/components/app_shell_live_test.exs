defmodule LineaUI.Components.AppShellLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule ShellLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, _session, socket),
      do:
        {:ok, assign(socket, open: true, current: "/one", toggles: [], drawer: false, closed: 0)}

    def handle_event("sidebar", %{"open" => open} = params, socket),
      do: {:noreply, assign(socket, open: open, toggles: [params | socket.assigns.toggles])}

    def handle_event("close-sidebar", _params, socket),
      do: {:noreply, assign(socket, open: false)}

    def handle_event("go", %{"to" => to}, socket), do: {:noreply, assign(socket, current: to)}
    def handle_event("open-drawer", _params, socket), do: {:noreply, assign(socket, drawer: true)}

    def handle_event("drawer-closed", _params, socket),
      do: {:noreply, assign(socket, drawer: false, closed: socket.assigns.closed + 1)}

    def handle_event("push-toggle", _params, socket),
      do: {:noreply, LineaUI.toggle(socket, "shell")}

    def render(assigns) do
      ~H"""
      <.app_shell id="shell" sidebar_open={@open} on_toggle="sidebar">
        <:sidebar>
          <.main_sidebar current={@current}>
            <:item navigate="/one" label="One">1</:item>
            <:item navigate="/two" label="Two">2</:item>
          </.main_sidebar>
          <.sidebar_panel title="Pages">
            <.sidebar_nav>
              <.sidebar_nav_group label="Group" current={@current}>
                <:item navigate="/one">One</:item>
                <:item navigate="/two">Two</:item>
              </.sidebar_nav_group>
            </.sidebar_nav>
          </.sidebar_panel>
        </:sidebar>
        <:header>
          <.header right_sidebar="drawer">
            <:start>
              <.page_header title="Page">
                <:crumb patch="/one">Home</:crumb>
                <:crumb>Page</:crumb>
              </.page_header>
            </:start>
            <:notifications><.link navigate="/notes">All notes</.link></:notifications>
          </.header>
        </:header>
        <:aside>
          <.right_sidebar id="drawer" open={@drawer} on_close="drawer-closed">Body</.right_sidebar>
        </:aside>
        <button id="close" phx-click="close-sidebar">close</button>
        <button id="go" phx-click="go" phx-value-to="/two">go</button>
        <button id="open-drawer" phx-click="open-drawer">open</button>
        <button id="push" phx-click="push-toggle">push</button>
        <span id="toggles">{length(@toggles)}</span>
        <span id="closed">{@closed}</span>
      </.app_shell>
      """
    end
  end

  test "the server state reaches the shell", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, ShellLive)
    assert "is-sidebar-open" in classes(html, "#shell")
    assert ["true"] = html |> find("#shell") |> LazyHTML.attribute("data-open")

    html = view |> element("#close") |> render_click()
    assert ["false"] = html |> find("#shell") |> LazyHTML.attribute("data-open")
  end

  test "the hook's on_toggle event updates the server", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, ShellLive)

    html =
      view |> element("#shell") |> render_hook("sidebar", %{"id" => "shell", "open" => false})

    assert ["false"] = html |> find("#shell") |> LazyHTML.attribute("data-open")
    assert html |> find("#toggles") |> LazyHTML.text() == "1"
  end

  test "the active item follows the current path", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, ShellLive)

    assert ["/one"] =
             html |> find(".main-sidebar a[aria-current=page]") |> LazyHTML.attribute("href")

    html = view |> element("#go") |> render_click()

    assert ["/two"] =
             html |> find(".main-sidebar a[aria-current=page]") |> LazyHTML.attribute("href")

    assert ["/two"] = html |> find("details a[aria-current=page]") |> LazyHTML.attribute("href")
    assert ["true"] = html |> find("details") |> LazyHTML.attribute("data-open")
  end

  test "items are live navigation links", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, ShellLive)

    assert ["redirect", "redirect"] =
             html |> find(".main-sidebar a") |> LazyHTML.attribute("data-phx-link")

    assert ["patch"] = html |> find("nav.header ul a") |> LazyHTML.attribute("data-phx-link")

    assert ["redirect"] =
             html
             |> find("#app-header-notifications-box a")
             |> LazyHTML.attribute("data-phx-link")
  end

  test "LineaUI.toggle(socket, id) pushes the command to the shell", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, ShellLive)
    view |> element("#push") |> render_click()
    assert_push_event(view, "linea:toggle", %{id: "#shell"})
  end

  test "the right sidebar's open and on_close", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, ShellLive)
    html = view |> element("#open-drawer") |> render_click()
    assert ["true"] = html |> find("#drawer") |> LazyHTML.attribute("data-open")

    html = view |> element("#drawer") |> render_hook("drawer-closed", %{"id" => "drawer"})
    assert ["false"] = html |> find("#drawer") |> LazyHTML.attribute("data-open")
    assert html |> find("#closed") |> LazyHTML.text() == "1"
  end
end
