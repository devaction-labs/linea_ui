defmodule LineaUI.Components.ShellTest do
  use LineaUI.ComponentCase, async: false

  @nav [
    %{label: "Início", icon: "home", navigate: "/"},
    %{
      group: "Vendas",
      icon: "cart",
      items: [
        %{label: "Pedidos", icon: "cart", navigate: "/pedidos", count: 12},
        %{label: "Clientes", icon: "users", navigate: "/clientes"}
      ]
    }
  ]

  defp sh(assigns) do
    assigns =
      assigns
      |> Map.put_new(:sidebar, nil)
      |> Map.put_new(:nav, @nav)
      |> Map.put_new(:current, nil)
      |> Map.put_new(:collapsible, true)
      |> Map.put_new(:collapsed, false)
      |> Map.put_new(:show_user, nil)
      |> Map.put_new(:version, nil)

    ~H"""
    <.shell
      id="app"
      sidebar={@sidebar}
      nav={@nav}
      current={@current}
      collapsible={@collapsible}
      collapsed={@collapsed}
      show_user={@show_user}
      version={@version}
      brand={%{name: "Linea", logo: "S"}}
      user={%{name: "Marina Costa"}}
      plan={%{name: "Linea", badge: "Pro"}}
    >
      <p id="page">page</p>
    </.shell>
    """
  end

  defp html(assigns \\ %{}),
    do: assigns |> Map.put(:__changed__, nil) |> sh() |> rendered_to_string()

  defp attrs(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  defp texts(html, selector),
    do:
      html
      |> find(selector)
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

  setup do
    previous = Application.get_env(:linea_ui, :shell)
    Application.delete_env(:linea_ui, :shell)

    on_exit(fn ->
      if previous,
        do: Application.put_env(:linea_ui, :shell, previous),
        else: Application.delete_env(:linea_ui, :shell)
    end)
  end

  test "is the framed shell: the canvas frame, the menu on it and the page in a rounded panel" do
    html = html()

    assert ["sg", "linea-frame", "md:flex-row", "md:p-2.5"] -- classes(html, "#app") == []
    assert [_] = Enum.to_list(find(html, "#app > nav#app-menu.sg-sb"))
    assert ["md:rounded-[22px]", "bg-white"] -- classes(html, "#app > main") == []
    assert [_] = Enum.to_list(find(html, "#app > main > #page"))
  end

  test "the menu is `sections` by default and reads the items" do
    html = html(%{current: "/clientes"})

    assert attrs(html, "#app-menu", "data-format") == ["sections"]
    assert texts(html, ".sg-sb-h") == ["Vendas"]
    assert texts(html, ".sg-sb-a.on > .lbl") == ["Clientes"]
    assert texts(html, ".sg-sb-plan .pro") == ["Pro"]
  end

  for format <- ~w(rail tree) do
    test "`sidebar=\"#{format}\"` changes the format and keeps the items" do
      html = html(%{sidebar: unquote(format), current: "/pedidos"})

      assert attrs(html, "#app-menu", "data-format") == [unquote(format)]
      assert "Pedidos" in texts(html, ".sg-sb-a > .lbl")
      assert texts(html, ".sg-sb-a.on > .lbl") == ["Pedidos"]
    end
  end

  test "an atom works as the format" do
    assert attrs(html(%{sidebar: :tree}), "#app-menu", "data-format") == ["tree"]
  end

  test "the format and the items come from the config, and the attributes win" do
    Application.put_env(:linea_ui, :shell, sidebar: :tree, nav: {__MODULE__, :config_nav})
    html = render(~H|<.shell id="app" current="/x">
  <p>page</p>
</.shell>|)

    assert attrs(html, "#app-menu", "data-format") == ["tree"]
    assert texts(html, ".sg-sb-gt") == ["Config"]
    assert texts(html, ".sg-sb-a.on > .lbl") == ["Perfil"]

    html = html(%{sidebar: "rail"})
    assert attrs(html, "#app-menu", "data-format") == ["rail"]
    assert "Pedidos" in texts(html, ".sg-sb-a > .lbl")
    refute "Perfil" in texts(html, ".sg-sb-a > .lbl")
  end

  test "`show_user` and `version` reach the menu, from the attributes or the config (the attributes win)" do
    html = html(%{sidebar: "tree"})
    assert find(html, ".sg-sb-user") != []
    assert find(html, ".sg-sb-ver") |> Enum.empty?()

    html = html(%{sidebar: "tree", show_user: false, version: "v1.4.2"})
    assert find(html, ".sg-sb-user") |> Enum.empty?()
    assert texts(html, ".sg-sb-ver") == ["v1.4.2"]
    assert attrs(html, ".sg-sb-ver", "aria-label") == ["v1.4.2"]

    Application.put_env(:linea_ui, :shell, sidebar: :tree, show_user: false, version: "v9.0.0")
    html = html()
    assert find(html, ".sg-sb-user") |> Enum.empty?()
    assert texts(html, ".sg-sb-ver") == ["v9.0.0"]

    html = html(%{show_user: true, version: "v2.0.0"})
    assert find(html, ".sg-sb-user") != []
    assert texts(html, ".sg-sb-ver") == ["v2.0.0"]
  end

  test "the menu collapses: the hook, the start state and the toggle of `sections` in the top bar" do
    html = html(%{collapsed: true})

    assert attrs(html, "#app-menu", "phx-hook") == ["LineaUI.ShellRail"]
    assert attrs(html, "#app-menu", "data-collapsed") == ["true"]
    assert attrs(html, "#app > main [data-rail-toggle]", "data-rail-toggle") == ["app-menu"]
  end

  test "`rail` and `tree` have their own button, so the top bar has none" do
    for format <- ~w(rail tree) do
      html = html(%{sidebar: format})
      assert find(html, "#app > main [data-rail-toggle]") |> Enum.empty?()
      assert find(html, "#app > main > div") |> Enum.empty?()
    end
  end

  test "`collapsible` false takes the toggle away" do
    html = html(%{collapsible: false})
    assert find(html, "[data-rail-toggle]") |> Enum.empty?()
  end

  test "the `:topbar`, `:brand_mark` and `:sidebar_footer` slots" do
    html =
      render(~H"""
      <.shell id="app" nav={[%{label: "A", href: "/a"}]} sidebar="tree" brand={%{name: "X"}}>
        <:topbar><span id="crumbs">crumbs</span></:topbar>
        <:brand_mark><i id="mark"></i></:brand_mark>
        <:sidebar_footer>
          <p id="foot">foot</p>
        </:sidebar_footer>
        page
      </.shell>
      """)

    assert [_] = Enum.to_list(find(html, "#app > main > div > #crumbs"))
    assert [_] = Enum.to_list(find(html, ".sg-sb-brand > #mark"))
    assert [_] = Enum.to_list(find(html, ".sg-sb-foot > #foot"))
  end

  test "the class goes on the frame" do
    html = render(~H|<.shell id="app" nav={[]} class="mine">page</.shell>|)
    assert "mine" in classes(html, "#app")
  end

  def config_nav(_assigns),
    do: [%{group: "Config", items: [%{label: "Perfil", navigate: "/x"}]}]
end
