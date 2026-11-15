defmodule LineaUI.Components.SidebarCanvasTest do
  use LineaUI.ComponentCase, async: false

  @nav [
    %{
      group: "Gestão",
      items: [
        %{
          label: "Tarefas",
          icon: "kanban",
          navigate: "/app/tasks",
          count: 12,
          children: [%{label: "Minhas", navigate: "/app/tasks/mine"}]
        },
        %{label: "Painel", icon: "home", navigate: "/app", match: "exact"},
        %{label: "Relatórios", icon: "chart", disabled: true, title: "Em breve", count: 3}
      ]
    }
  ]

  defp attrs(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp tree(assigns) do
    assigns =
      assigns
      |> Map.put_new(:current, nil)
      |> Map.put_new(:match, "exact")
      |> Map.put_new(:persist_groups, false)
      |> Map.put_new(:format, "tree")

    ~H"""
    <.sidebar
      id="sb"
      format={@format}
      nav={@nav}
      current={@current}
      match={@match}
      persist_groups={@persist_groups}
      version="v1.0"
      footer="version"
    >
      <:sidebar_footer>
        <button type="button" id="rec" data-rail-toggle="sb">Recolher menu</button>
      </:sidebar_footer>
      <:mobile_drawer :if={@drawer}><a id="out" href="/sair">Sair</a></:mobile_drawer>
    </.sidebar>
    """
  end

  defp html(assigns),
    do:
      assigns
      |> Map.put_new(:nav, @nav)
      |> Map.put_new(:drawer, false)
      |> Map.put(:__changed__, nil)
      |> tree()
      |> rendered_to_string()

  test "a group has a chevron button with aria-expanded and aria-controls, and children draw a line" do
    html = html(%{current: "/app/tasks"})

    assert attrs(html, "button.sg-sb-gt", "aria-expanded") == ["true"]
    assert [id] = attrs(html, "button.sg-sb-gt", "aria-controls")
    assert [_] = Enum.to_list(find(html, "##{id}.sg-sb-grp"))
    assert [_] = Enum.to_list(find(html, ".sg-sb-tree.line"))
    assert [_] = Enum.to_list(find(html, ".sg-sb-tree.line > svg.tb"))
  end

  test "the count is mono (sg-sb-n)" do
    assert [_, _] = Enum.to_list(find(html(%{}), ".sg-sb-n"))
  end

  test "a disabled item is a span with a title, not a link, and never active" do
    html = html(%{current: "/app/tasks"})

    assert [span] = Enum.to_list(find(html, "span.sg-sb-a.dis"))
    assert LazyHTML.attribute(span, "title") == ["Em breve"]
    assert LazyHTML.attribute(span, "aria-disabled") == ["true"]
    assert find(html, "a[href='#']") |> Enum.empty?()
    assert [_] = Enum.to_list(find(html, "span.sg-sb-a.dis > .sg-sb-n"))
  end

  test "a disabled item with no title uses its label, and a string disabled is the title" do
    nav = [
      %{label: "Um", disabled: true},
      %{label: "Dois", disabled: "Chega logo"}
    ]

    html = html(%{nav: nav})
    assert attrs(html, "span.sg-sb-a.dis", "title") == ["Um", "Chega logo"]
  end

  test "match prefix marks the item with aria-current for a deeper path" do
    html = html(%{current: "/app/tasks/NXP-1", match: "prefix"})

    assert attrs(html, "a[aria-current=page]", "href") == ["/app/tasks"]
    assert find(html, "a.sg-sb-a.on[href='/app']") |> Enum.empty?()
  end

  test "exact is the default: a deeper path marks nothing" do
    html = html(%{current: "/app/tasks/NXP-1"})
    assert find(html, "a[aria-current]") |> Enum.empty?()
  end

  test "an item's own match wins over the component's" do
    nav = [
      %{label: "A", navigate: "/a", match: "prefix"},
      %{label: "B", navigate: "/b"}
    ]

    html = html(%{nav: nav, current: "/a/1"})
    assert attrs(html, "a[aria-current=page]", "href") == ["/a"]

    html = html(%{nav: nav, current: "/b/1", match: "prefix"})
    assert attrs(html, "a[aria-current=page]", "href") == ["/b"]
  end

  test "the root path is always exact" do
    nav = [%{label: "Home", navigate: "/"}]

    assert find(html(%{nav: nav, current: "/x", match: "prefix"}), "a[aria-current]")
           |> Enum.empty?()

    assert [_] =
             Enum.to_list(
               find(html(%{nav: nav, current: "/", match: "prefix"}), "a[aria-current]")
             )
  end

  test "the footer slot holds the collapse button together with the version line" do
    html = html(%{})

    assert [_] = Enum.to_list(find(html, ".sg-sb-foot > #rec[data-rail-toggle=sb]"))
    assert [_] = Enum.to_list(find(html, ".sg-sb-ver"))
  end

  test "the mobile drawer slot is drawn only when given" do
    assert find(html(%{}), ".sg-sb-drawer") |> Enum.empty?()

    for format <- ["tree", "sections", "rail"] do
      html = html(%{drawer: true, format: format})
      assert [_] = Enum.to_list(find(html, ".sg-sb-body > .sg-sb-drawer > #out"))
    end
  end

  test "persist_groups is off by default and a data attribute when on" do
    assert attrs(html(%{}), "nav#sb", "data-persist-groups") == []
    assert attrs(html(%{persist_groups: true}), "nav#sb", "data-persist-groups") == ["true"]
  end

  test "the shell passes match, persist_groups and the drawer to the menu" do
    html =
      render(~H"""
      <.shell
        id="app"
        nav={[%{label: "T", navigate: "/t"}]}
        sidebar="tree"
        current="/t/1"
        match="prefix"
        persist_groups
      >
        <:mobile_drawer><a id="out" href="/sair">Sair</a></:mobile_drawer>
        page
      </.shell>
      """)

    assert attrs(html, "a[aria-current=page]", "href") == ["/t"]
    assert attrs(html, "nav", "data-persist-groups") == ["true"]
    assert [_] = Enum.to_list(find(html, ".sg-sb-drawer > #out"))
  end
end
