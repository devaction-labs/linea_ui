defmodule LineaUI.Components.TreeviewTest do
  use LineaUI.ComponentCase, async: true

  test "a branch is a details element, a leaf a focusable row" do
    html =
      render(~H"""
      <.treeview id="t">
        <.tree_item id="docs" label="Document" expanded>
          <.tree_item id="readme" label="README" />
        </.tree_item>
      </.treeview>
      """)

    assert [_] = find(html, "ul#t[role=tree][phx-hook='LineaUI.Treeview']") |> Enum.to_list()
    assert [details] = find(html, "details#docs[open][data-server-open=true]") |> Enum.to_list()
    assert LazyHTML.attribute(details, "phx-mounted") |> hd() =~ "ignore_attrs"
    assert [_] = find(html, "details summary[role=treeitem]") |> Enum.to_list()

    assert [_] =
             find(html, "details ul.pl-4 [data-tree-leaf=readme][tabindex='0']") |> Enum.to_list()

    assert "space-y-1" in classes(html, "ul#t")
    assert ["mt-1", "space-y-1", "pl-4"] -- classes(html, "details > ul") == []
    assert "size-4" in classes(html, "details summary .tree-chevron")
  end

  test "a closed branch and a leaf that has only an icon" do
    html =
      render(~H"""
      <.treeview id="t" expanded={["a"]}>
        <.tree_item id="a" label="A"><.tree_item label="B" /></.tree_item>
        <.tree_item id="c" label="C">
          <:icon><svg class="size-6" /></:icon>
        </.tree_item>
      </.treeview>
      """)

    assert [_] = find(html, "details#a[data-server-open=false]:not([open])") |> Enum.to_list()
    assert [_] = find(html, "[data-tree-leaf=c]") |> Enum.to_list()
    assert "text-slate-800" in classes(html, "[data-tree-leaf=c]")
    assert "space-x-1.5" in classes(html, "details#a [data-tree-leaf]")
    assert LazyHTML.attribute(find(html, "#t"), "data-expanded") == [~s(["a"])]
  end

  test "events, target and rows" do
    html =
      render(~H"""
      <.treeview
        id="t"
        on_toggle="toggled"
        on_select="picked"
        target="#c"
        rows={[%{id: 1, name: "x.ex"}]}
        row_id={&"row-#{&1.id}"}
      >
        <:row :let={file}><.tree_item tag="div" id={"file-#{file.id}"} label={file.name} /></:row>
      </.treeview>
      """)

    root = find(html, "#t")
    assert LazyHTML.attribute(root, "data-on-toggle") == ["toggled"]
    assert LazyHTML.attribute(root, "data-on-select") == ["picked"]
    assert LazyHTML.attribute(root, "phx-target") == ["#c"]
    assert [_] = find(html, "li#row-1 > div[role=none] [data-tree-leaf=file-1]") |> Enum.to_list()
  end
end

defmodule LineaUI.Components.TreeviewLiveTest do
  use LineaUI.LiveCase, async: true

  defmodule TreeLive do
    use Phoenix.LiveView
    use LineaUI

    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(open: false, events: [])
       |> stream(:files, [%{id: 1, name: "a.ex"}, %{id: 2, name: "b.ex"}])}
    end

    def render(assigns) do
      ~H"""
      <.treeview id="tree" on_toggle="toggled" on_select="picked">
        <.tree_item id="src" label="src" expanded={@open}>
          <.tree_item id="main" label="main.ex" />
        </.tree_item>
      </.treeview>
      <.treeview id="files" rows={@streams.files}>
        <:row :let={{_id, file}}>
          <.tree_item tag="div" id={"leaf-#{file.id}"} label={file.name} />
        </:row>
      </.treeview>
      <button id="open" phx-click="open">open</button>
      <p id="events">{inspect(@events)}</p>
      """
    end

    def handle_event("open", _params, socket), do: {:noreply, assign(socket, open: true)}

    def handle_event(event, params, socket),
      do: {:noreply, update(socket, :events, &[{event, params} | &1])}
  end

  test "the server's expanded reaches the branch", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, TreeLive)
    assert [_] = find(html, "details#src[data-server-open=false]") |> Enum.to_list()
    html = view |> element("#open") |> render_click()
    assert [_] = find(html, "details#src[open][data-server-open=true]") |> Enum.to_list()
  end

  test "toggles and picks are pushed with their payloads", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, TreeLive)
    render_hook(view, "toggled", %{"id" => "src", "expanded" => true})
    html = render_hook(view, "picked", %{"id" => "main"})
    assert html =~ "&quot;picked&quot;, %{&quot;id&quot; =&gt; &quot;main&quot;}"
    assert html =~ "&quot;expanded&quot; =&gt; true"
  end

  test "a stream renders with phx-update=stream", %{conn: conn} do
    {:ok, _view, html} = live_isolated(conn, TreeLive)
    assert [_] = find(html, "ul#files[phx-update=stream]") |> Enum.to_list()
    assert [_, _] = find(html, "ul#files > li[id^=files-]") |> Enum.to_list()
  end
end
