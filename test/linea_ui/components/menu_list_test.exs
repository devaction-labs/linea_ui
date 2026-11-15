defmodule LineaUI.Components.MenuListTest do
  use LineaUI.ComponentCase, async: true

  test "a link list marks the active item" do
    html =
      render(~H"""
      <.menu_list>
        <:item href="/start" active>Getting start</:item>
        <:item href="/shipping">Shipping</:item>
      </.menu_list>
      """)

    assert "space-y-3.5" in classes(html, "ul")
    assert [active, other] = find(html, "li > a") |> Enum.to_list()
    assert LazyHTML.attribute(active, "aria-current") == ["page"]
    assert "text-primary" in classes(LazyHTML.to_html(active), "a")
    assert "inline-flex" in classes(LazyHTML.to_html(other), "a")
    assert "hover:text-slate-800" in classes(LazyHTML.to_html(other), "a")
    assert LazyHTML.attribute(other, "href") == ["/shipping"]
  end

  test "variants and colors pick LineOne's classes" do
    cases = [
      {"solid", "primary", "bg-primary", "rounded-lg"},
      {"solid", "neutral", "bg-slate-150", "rounded-lg"},
      {"pill", "primary", "bg-primary", "rounded-full"},
      {"gradient", "primary", "from-purple-500", "rounded-lg"},
      {"bordered", "primary", "border-slate-150", "rounded-lg"}
    ]

    for {variant, color, active, shape} <- cases do
      assigns = %{variant: variant, color: color}

      html =
        rendered_to_string(~H"""
        <.menu_list variant={@variant} color={@color}>
          <:item href="#" active>A</:item>
          <:item href="#">B</:item>
        </.menu_list>
        """)

      assert "space-y-1.5" in classes(html, "ul")
      assert active in classes(html, "a[aria-current]")
      assert shape in classes(html, "a[aria-current]")
    end
  end

  test "inactive pill icons turn primary on hover" do
    html = render(~H|<.menu_list variant="pill">
  <:item href="#">B</:item>
</.menu_list>|)
    assert "group-hover:[&>svg]:text-primary" in classes(html, "a")
  end

  test "on_select pushes the item's value to the target" do
    html =
      render(~H"""
      <.menu_list on_select="pick" target="#c">
        <:item value="shipping">Shipping</:item>
      </.menu_list>
      """)

    assert [a] = find(html, "a[role=button]") |> Enum.to_list()
    assert LazyHTML.attribute(a, "phx-click") == ["pick"]
    assert LazyHTML.attribute(a, "phx-value-value") == ["shipping"]
    assert LazyHTML.attribute(a, "phx-target") == ["#c"]
  end

  test "a standalone menu_item with a JS command" do
    html =
      render(~H"""
      <.menu_item on_select={Phoenix.LiveView.JS.push("go")} value="x">X</.menu_item>
      """)

    assert [click] = find(html, "a") |> LazyHTML.attribute("phx-click")
    assert click =~ "go"
  end

  test "icon and count slots, and the count attr of a list item" do
    html =
      render(~H"""
      <.menu_item id="x" navigate="/inbox" variant="solid">
        <:icon><svg id="ic"></svg></:icon>
        Inbox
        <:count>12</:count>
      </.menu_item>
      <.menu_list id="l">
        <:item href="#" count="3">Drafts</:item>
        <:item href="#">Sent</:item>
      </.menu_list>
      """)

    assert [_] = find(html, "a#x > svg#ic") |> Enum.to_list()
    assert find(html, "a#x > span.ml-auto") |> LazyHTML.text() =~ "12"
    assert [_] = find(html, "#l span.ml-auto") |> Enum.to_list()
    assert find(html, "#l span.ml-auto") |> LazyHTML.text() == "3"
  end

  test "a static list renders sg-list with sg-li rows" do
    html =
      render(~H"""
      <.menu_list variant="static" id="l" class="mt-2">
        <:item title="Admin" sub="3 users" unread>x</:item>
        <:item href="/a">Link</:item>
      </.menu_list>
      <.menu_list variant="static" id="m">
        <:row>
          <.menu_row phx-click="open" title="T" sub="S">
            <:icon><b id="ic">i</b></:icon><:value>9</:value>
          </.menu_row>
        </:row>
      </.menu_list>
      """)

    assert ["sg-list", "mt-2"] -- classes(html, "div#l") == []
    assert [_, _] = find(html, "#l > .sg-li") |> Enum.to_list()
    assert [_] = find(html, "#l > a.sg-li[href='/a']") |> Enum.to_list()
    assert [_] = find(html, "#l span[aria-label=Unread]") |> Enum.to_list()
    assert [] = find(html, "#l ul") |> Enum.to_list()
  end

  test "a menu_row is a div, a link or a click target" do
    html =
      render(~H"""
      <.menu_row id="a" title="Title" sub="Sub">
        <:icon><i id="ic">i</i></:icon><:value>R$ 1</:value>
      </.menu_row>
      <.menu_row id="b" navigate="/x">
        <div class="t">Own</div>
      </.menu_row>
      <.menu_row id="c" phx-click="open" phx-value-id="3" title="C" />
      """)

    assert "sg-li" in classes(html, "div#a")
    assert find(html, "#a .t") |> LazyHTML.text() == "Title"
    assert find(html, "#a .s") |> LazyHTML.text() == "Sub"
    assert [_] = find(html, "#a > i#ic") |> Enum.to_list()
    assert [_] = find(html, "a#b.sg-li[data-phx-link=redirect]") |> Enum.to_list()
    assert find(html, "#b .t") |> LazyHTML.text() == "Own"
    assert LazyHTML.attribute(find(html, "div#c"), "phx-click") == ["open"]
    assert [] = find(html, "#a [aria-label]") |> Enum.to_list()
  end
end

defmodule LineaUI.Components.MenuListLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule MenuLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(current: "a")
       |> stream(:pages, [%{id: "a", title: "Alpha"}, %{id: "b", title: "Beta"}])}
    end

    def render(assigns) do
      ~H"""
      <.menu_list id="menu" variant="solid" on_select="pick">
        <:item value="a" active={@current == "a"}>Alpha</:item>
        <:item value="b" active={@current == "b"}>Beta</:item>
      </.menu_list>
      <.menu_list id="pages" rows={@streams.pages}>
        <:row :let={{_id, page}}>
          <.menu_item value={page.id} on_select="pick" active={page.id == @current}>
            {page.title}
          </.menu_item>
        </:row>
      </.menu_list>
      """
    end

    def handle_event("pick", %{"value" => value}, socket),
      do: {:noreply, assign(socket, current: value)}
  end

  test "clicking an item tells the server, which moves the active item", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MenuLive)
    html = view |> element("#menu a", "Beta") |> render_click()
    assert [beta] = find(html, "#menu a[aria-current]") |> Enum.to_list()
    assert LazyHTML.text(beta) =~ "Beta"
  end

  test "a stream renders with phx-update=stream", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, MenuLive)
    assert [_] = find(html, "ul#pages[phx-update=stream]") |> Enum.to_list()
    assert [_, _] = find(html, "ul#pages > li[id^=pages-] > a") |> Enum.to_list()
  end

  defmodule StaticLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, _session, socket),
      do: {:ok, stream(socket, :rows, [%{id: "a", t: "Alpha"}, %{id: "b", t: "Beta"}])}

    def render(assigns) do
      ~H"""
      <.menu_list variant="static" id="st" rows={@streams.rows}>
        <:row :let={{id, row}}><.menu_row id={id} title={row.t} /></:row>
      </.menu_list>
      """
    end
  end

  test "a static list streams its rows", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, StaticLive)
    assert [_] = find(html, "div#st.sg-list[phx-update=stream]") |> Enum.to_list()
    assert [_, _] = find(html, "#st > #rows-a, #st > #rows-b") |> Enum.to_list()
  end
end
