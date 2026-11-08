defmodule LineaUI.Components.SidebarTest do
  use LineaUI.ComponentCase, async: false

  @nav [
    %{label: "Início", icon: "home", navigate: "/"},
    %{label: "Assistente", icon: "spark", navigate: "/assistente"},
    %{
      group: "Vendas",
      icon: "cart",
      action: %{label: "Novo pedido", navigate: "/pedidos/novo"},
      try: %{
        label: "Experimente",
        items: [%{label: "Conectar banco", icon: "bank", navigate: "/banco"}]
      },
      items: [
        %{
          label: "Pedidos",
          icon: "cart",
          navigate: "/pedidos",
          count: 12,
          children: [
            %{
              label: "Abertos",
              icon: "doc",
              color: "blue",
              navigate: "/pedidos?status=aberto",
              count: 8
            },
            %{
              label: "Cancelados",
              icon: "cancel",
              color: "#f43f5e",
              navigate: "/pedidos?status=cancelado"
            }
          ]
        },
        %{label: "Clientes", icon: "users", navigate: "/clientes"},
        %{group: "Notas", items: [%{label: "Emitidas", icon: "invoice", navigate: "/notas"}]}
      ]
    },
    %{
      group: "Financeiro",
      icon: "wallet",
      items: [%{label: "Caixa", icon: "card", color: "ink", badge: true, navigate: "/caixa"}]
    },
    %{
      group: "Configurações e ajuda",
      footer: true,
      items: [
        %{label: "Ajuda", icon: "help", navigate: "/ajuda"},
        %{
          label: "Avisos",
          icon: "bell",
          badge: "Novos avisos",
          navigate: "/avisos",
          formats: ["rail"]
        }
      ]
    }
  ]

  @brand %{name: "Linea", logo: "S"}
  @user %{name: "Marina Costa", email: "marina@linea.com", color: "#8a5cd6"}
  @plan %{name: "Linea", badge: "Pro"}
  @trial %{
    title: "Termina em 7 dias",
    label: "Teste",
    text: "Acesso completo",
    value: 32,
    action: "Assinar",
    navigate: "/assinar"
  }
  @extra [%{label: "Mapa", icon: "pin", color: "#f97316", navigate: "/mapa"}]

  defp sb(assigns) do
    assigns =
      assigns
      |> Map.put_new(:format, nil)
      |> Map.put_new(:nav, @nav)
      |> Map.put_new(:current, nil)
      |> Map.put_new(:brand, @brand)
      |> Map.put_new(:user, @user)
      |> Map.put_new(:plan, @plan)
      |> Map.put_new(:trial, @trial)
      |> Map.put_new(:rail_extra, @extra)
      |> Map.put_new(:collapsed, false)
      |> Map.put_new(:collapsible, true)

    ~H"""
    <.sidebar
      id="sb"
      format={@format}
      nav={@nav}
      current={@current}
      brand={@brand}
      user={@user}
      plan={@plan}
      trial={@trial}
      rail_extra={@rail_extra}
      collapsed={@collapsed}
      collapsible={@collapsible}
    />
    """
  end

  defp html(assigns \\ %{}),
    do: assigns |> Map.put(:__changed__, nil) |> sb() |> rendered_to_string()

  defp texts(html, selector),
    do:
      html
      |> find(selector)
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.split() |> Enum.join(" ")))

  defp attrs(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  setup do
    previous = Application.get_env(:linea_ui, :shell)
    on_exit(fn -> restore(previous) end)
    Application.delete_env(:linea_ui, :shell)
    :ok
  end

  defp restore(nil), do: Application.delete_env(:linea_ui, :shell)
  defp restore(value), do: Application.put_env(:linea_ui, :shell, value)

  describe "sections" do
    test "is the default, with the brand, the switcher, the group labels and the plan card" do
      html = html()

      assert "sec" in classes(html, "nav#sb")
      assert attrs(html, "nav#sb", "data-format") == ["sections"]
      assert texts(html, ".sg-sb-brand > b") == ["Linea"]
      assert texts(html, ".sg-sb-brand > .sg-sb-logo") == ["S"]
      assert attrs(html, ".sg-sb-brand button.sw", "aria-label") == ["Switch company"]
      assert texts(html, ".sg-sb-h") == ["Vendas", "Notas", "Financeiro"]
      assert texts(html, ".sg-sb-h2") == ["Configurações e ajuda"]
      assert texts(html, ".sg-sb-plan > b") == ["Linea"]
      assert texts(html, ".sg-sb-plan .pro") == ["Pro"]
      assert find(html, ".sg-sb-rail") |> Enum.empty?()
    end

    test "the items of the format only: the foot has its items and `formats` hides the rail ones" do
      html = html()

      assert texts(html, ".sg-sb-foot .sg-sb-a > .lbl") == ["Ajuda"]

      assert texts(html, ".sg-sb-scroll > .sg-sb-a > .lbl") == [
               "Início",
               "Assistente",
               "Pedidos",
               "Clientes",
               "Emitidas",
               "Caixa"
             ]
    end

    test "counts, badges and children" do
      html = html()

      assert texts(html, ".sg-sb-scroll > .sg-sb-a > .sg-sb-n") == ["12"]
      assert texts(html, ".sg-sb-tree .sg-sb-a > .lbl") == ["Abertos", "Cancelados"]
      assert texts(html, ".sg-sb-tree .sg-sb-n") == ["8"]
      assert find(html, ".sg-sb-tree.line") |> Enum.empty?()
      assert [_] = Enum.to_list(find(html, ".sg-sb-a > .red"))
    end

    test "an item has an icon, a tooltip for the collapsed menu and a name" do
      html = html()

      assert "huge-home-01" in classes(html, ".sg-sb-scroll > .sg-sb-a:first-child > .i")
      assert texts(html, ".sg-sb-scroll > .sg-sb-a:first-child > .rail-tip") == ["Início"]

      assert attrs(html, ".sg-sb-scroll > .sg-sb-a:first-child > .rail-tip", "role") == [
               "tooltip"
             ]

      assert attrs(html, ".sg-sb-scroll > .sg-sb-a:first-child", "data-rail-tip") == [""]
    end
  end

  describe "the active item" do
    test "is the one whose path is the current one, with aria-current" do
      html = html(%{current: "/clientes"})

      assert texts(html, ".sg-sb-a.on > .lbl") == ["Clientes"]
      assert attrs(html, ".sg-sb-a.on", "aria-current") == ["page"]
      assert attrs(html, "a[href=\"/\"]", "aria-current") == []
    end

    test "compares the query too, so a child is active and its parent is not" do
      html = html(%{current: "/pedidos?status=aberto"})
      assert texts(html, ".sg-sb-a.on > .lbl") == ["Abertos"]

      html = html(%{current: "/pedidos"})
      assert texts(html, ".sg-sb-a.on > .lbl") == ["Pedidos"]
    end

    test "`active: true` marks it without a path" do
      nav = [%{label: "A", icon: "home", href: "/a", active: true}, %{label: "B", href: "/b"}]
      assert texts(html(%{nav: nav}), ".sg-sb-a.on > .lbl") == ["A"]
    end
  end

  describe "rail" do
    setup do
      %{html: html(%{format: "rail", current: "/pedidos"})}
    end

    test "has the rail and the panel of the module of the current item", %{html: html} do
      assert "railx" in classes(html, "nav#sb")
      assert attrs(html, "nav#sb", "data-format") == ["rail"]
      assert texts(html, ".sg-sb-ph > b") == ["Vendas"]
      assert texts(html, ".sg-sb-rail > .sg-sb-logo") == ["S"]
      assert find(html, ".sg-sb-brand") |> Enum.empty?()
    end

    test "the rail: home, the person, one icon per module, the other items, extra apps and the foot",
         %{html: html} do
      labels = attrs(html, ".sg-sb-rail > a", "aria-label")
      assert labels == ["Início", "Vendas", "Financeiro", "Assistente", "Mapa", "Ajuda", "Avisos"]

      assert texts(html, ".sg-sb-rail > .sg-av") == ["MC"]
      assert attrs(html, ".sg-sb-rail > .sg-av", "aria-label") == ["Marina Costa"]
      assert attrs(html, ".sg-sb-rail > a.on", "aria-label") == ["Vendas"]
      assert attrs(html, ".sg-sb-rail > a.on", "aria-current") == ["page"]
      assert attrs(html, ".sg-sb-rail > a[data-module]", "aria-label") == ["Vendas", "Financeiro"]
      assert attrs(html, ".sg-sb-rail > a[data-module]", "href") == ["/pedidos", "/caixa"]
      assert attrs(html, ".sg-sb-rail a.dot", "style") == ["background:#f97316"]
      assert attrs(html, ".sg-sb-rail > a.has-badge", "aria-label") == ["Avisos"]
      assert texts(html, ".sg-sb-rail > a.r > .rail-tip") |> Enum.take(2) == ["Início", "Vendas"]
      assert attrs(html, ".sg-sb-rail > a.r", "data-rail-tip") |> Enum.uniq() == ["always"]
    end

    test "the panel: the create button, the items, the nested group, the coloured tree and the shortcuts",
         %{html: html} do
      assert texts(html, ".sg-sb-panel a.sg-sb-new") == ["Novo pedido"]
      assert attrs(html, "a.sg-sb-new", "href") == ["/pedidos/novo"]
      assert texts(html, ".sg-sb-panel .sg-sb-gh") == ["Notas", "Experimente"]
      assert attrs(html, ".sg-sb-gh button.tg", "aria-expanded") == ["true"]
      assert attrs(html, ".sg-sb-gh button.tg", "aria-controls") |> length() == 1
      assert texts(html, ".sg-sb-tree a.t .lbl") == ["Abertos", "Cancelados"]
      assert classes(html, ".sg-sb-tree a.t:first-child > span") |> Enum.take(2) == ["ci", "blue"]

      assert attrs(html, ".sg-sb-tree a.t:last-child > span.ci", "style") == [
               "background:#f43f5e"
             ]

      assert texts(html, ".sg-sb-scroll > a.sg-sb-a > .lbl") ==
               ["Conectar banco"]
               |> then(&(&1 -- &1))
               |> Kernel.++(texts(html, ".sg-sb-scroll > a.sg-sb-a > .lbl"))

      assert "Conectar banco" in texts(html, ".sg-sb-scroll .sg-sb-a > .lbl")
      assert attrs(html, ".sg-sb-panel [data-rail-toggle]", "data-rail-toggle") == ["sb"]
    end

    test "the trial card", %{html: html} do
      assert texts(html, ".sg-sb-trial .row1 > b") == ["Termina em 7 dias"]
      assert texts(html, ".sg-sb-trial .free") == ["Teste"]
      assert texts(html, ".sg-sb-trial .row2 > span") == ["Acesso completo"]
      assert attrs(html, ".sg-sb-trial .row2 a", "href") == ["/assinar"]
      assert texts(html, ".sg-sb-trial .row2 a") == ["Assinar"]
      assert attrs(html, ".sg-sb-trial .bar i", "style") == ["width:32%"]
      assert attrs(html, ".sg-sb-trial .bar", "aria-valuenow") == ["32"]
    end

    test "the panel follows the module that holds the active item, and the first one without it" do
      assert texts(html(%{format: "rail", current: "/caixa"}), ".sg-sb-ph > b") == ["Financeiro"]
      assert texts(html(%{format: "rail", current: "/x"}), ".sg-sb-ph > b") == ["Vendas"]
    end

    test "the panel button is left out with `collapsible` false" do
      html = html(%{format: "rail", collapsible: false})
      assert find(html, ".sg-sb-panel [data-rail-toggle]") |> Enum.empty?()
    end
  end

  describe "tree" do
    setup do
      %{html: html(%{format: "tree", current: "/caixa"})}
    end

    test "the brand with the collapse button, the groups with a chevron and the user card", %{
      html: html
    } do
      assert "treex" in classes(html, "nav#sb")
      assert attrs(html, ".sg-sb-brand button.col", "data-rail-toggle") == ["sb"]
      assert attrs(html, ".sg-sb-brand button.col", "aria-label") == ["Collapse menu"]
      assert texts(html, "button.sg-sb-gt") == ["Vendas", "Notas", "Financeiro"]
      assert attrs(html, "button.sg-sb-gt", "aria-expanded") == ["true", "true", "true"]
      assert texts(html, ".sg-sb-user .who > b") == ["Marina Costa"]
      assert texts(html, ".sg-sb-user .who > span") == ["marina@linea.com"]
      assert texts(html, ".sg-sb-user .sg-av") == ["MC"]
    end

    test "children are joined by a line, items with colour are squares and the badge is a dot", %{
      html: html
    } do
      assert [_] = Enum.to_list(find(html, ".sg-sb-tree.line"))
      assert classes(html, ".sg-sb-tree.line > a") == ["sg-sb-a"]
      assert classes(html, "a.sq") == ["sg-sb-a", "on", "sq"]
      assert classes(html, "a.sq > span") |> Enum.take(2) == ["sqi", "ink"]
      assert [_] = Enum.to_list(find(html, "a.sq > .red"))
      assert attrs(html, "a.sq", "aria-current") == ["page"]
    end

    test "a group with `collapsible: false` has a label without a button" do
      nav = [%{group: "Fixo", collapsible: false, items: [%{label: "A", href: "/a"}]}]
      html = html(%{format: "tree", nav: nav})
      assert find(html, "button.sg-sb-gt") |> Enum.empty?()
      assert texts(html, "div.sg-sb-gt") == ["Fixo"]
    end

    test "the foot of the menu has the items of the foot group without its label", %{html: html} do
      assert texts(html, ".sg-sb-foot .sg-sb-a > .lbl") == ["Ajuda"]
      assert find(html, ".sg-sb-h2") |> Enum.empty?()
    end
  end

  describe "collapsed" do
    for format <- ~w(sections rail tree) do
      test "#{format} starts collapsed with the hook, the persistence and the tooltips" do
        html = html(%{format: unquote(format), collapsed: true})

        assert attrs(html, "nav#sb", "phx-hook") == ["LineaUI.ShellRail"]
        assert attrs(html, "nav#sb", "data-collapsed") == ["true"]
        assert attrs(html, "nav#sb", "data-server-collapsed") == ["true"]
        assert attrs(html, "nav#sb", "data-persist") == ["true"]
        assert attrs(html, "nav#sb", "data-mobile-open") == ["false"]
        assert [_ | _] = Enum.to_list(find(html, "[data-rail-tip] > .rail-tip[role=tooltip]"))
        assert attrs(html, "[data-mobile-toggle]", "aria-label") == ["Menu"]
      end
    end

    test "is expanded by default" do
      assert attrs(html(), "nav#sb", "data-collapsed") == ["false"]
    end

    test "the labels, the collapse event and the target go to the hook" do
      html =
        render(~H"""
        <.sidebar
          id="m"
          nav={[%{label: "A", href: "/a"}]}
          on_collapse="collapse"
          persist={false}
          collapse_label="Recolher"
          mobile_label="Abrir"
          label="Principal"
          format="tree"
          brand={%{name: "X"}}
        />
        """)

      assert attrs(html, "#m", "data-on-collapse") == ["collapse"]
      assert attrs(html, "#m", "data-persist") == ["false"]
      assert attrs(html, "#m", "aria-label") == ["Principal"]
      assert attrs(html, "#m .col", "aria-label") == ["Recolher"]
      assert attrs(html, "#m [data-mobile-toggle]", "aria-label") == ["Abrir"]
    end
  end

  describe "the brand and the slots" do
    test "the `:brand_mark` slot replaces the logo and the name, `:sidebar_footer` ends the foot" do
      html =
        render(~H"""
        <.sidebar id="m" nav={[%{label: "A", href: "/a"}]} brand={%{name: "X", logo: "X"}}>
          <:brand_mark><img id="mine" src="/m.svg" alt="" /></:brand_mark>
          <:sidebar_footer>
            <p id="extra">extra</p>
          </:sidebar_footer>
        </.sidebar>
        """)

      assert [_] = Enum.to_list(find(html, ".sg-sb-brand > #mine"))
      assert find(html, ".sg-sb-brand > b") |> Enum.empty?()
      assert [_] = Enum.to_list(find(html, ".sg-sb-foot > #extra"))
    end

    test "the logo can be an image and the switcher can be left out or labelled" do
      html = html(%{brand: %{name: "L", src: "/logo.svg"}})
      assert attrs(html, ".sg-sb-brand .sg-sb-logo img", "src") == ["/logo.svg"]

      assert find(html(%{brand: %{name: "L", switch: false}}), "button.sw") |> Enum.empty?()

      html = html(%{brand: %{name: "L", switch: %{label: "Trocar de empresa", click: "switch"}}})
      assert attrs(html, "button.sw", "aria-label") == ["Trocar de empresa"]
      assert attrs(html, "button.sw", "phx-click") == ["switch"]
    end

    test "without a user, a plan or a trial there are no cards" do
      html = html(%{format: "tree", user: nil, plan: nil})
      assert find(html, ".sg-sb-user") |> Enum.empty?()

      html = html(%{plan: nil})
      assert find(html, ".sg-sb-plan") |> Enum.empty?()

      html = html(%{format: "rail", user: nil, trial: nil, rail_extra: []})
      assert find(html, ".sg-sb-trial, .sg-av, a.dot") |> Enum.empty?()
    end
  end

  describe "icons" do
    test "short names are the canvas Hugeicons, the rest goes through" do
      nav = [
        %{label: "A", icon: "cart", href: "/a"},
        %{label: "B", icon: "huge-user-02", href: "/b"},
        %{label: "C", icon: "fa-solid fa-house", href: "/c"}
      ]

      html = html(%{nav: nav})
      assert "huge-shopping-cart-01" in classes(html, ".sg-sb-a:nth-child(1) > .i")
      assert "huge-user-02" in classes(html, ".sg-sb-a:nth-child(2) > .i")

      assert classes(html, ".sg-sb-a:nth-child(3) > .i") |> Enum.take(3) == [
               "fa-solid",
               "fa-house",
               "i"
             ]
    end

    test "every short name maps to a Hugeicons class" do
      for {_name, class} <- LineaUI.Components.Sidebar.Nav.icon_names(),
          do: assert(class =~ ~r/^huge-/)
    end
  end

  describe "configuration" do
    test "the format and the nav come from `config :linea_ui, :shell`" do
      Application.put_env(:linea_ui, :shell, sidebar: :rail, nav: {__MODULE__, :config_nav})
      html = render(~H|<.sidebar id="c" current="/c" />|)

      assert attrs(html, "#c", "data-format") == ["rail"]
      assert texts(html, ".sg-sb-ph > b") == ["Config"]
      assert attrs(html, ".sg-sb-panel a.on", "aria-current") == ["page"]
    end

    test "a string works and so does an unknown value (sections)" do
      Application.put_env(:linea_ui, :shell, sidebar: "tree")
      assert attrs(html(), "nav#sb", "data-format") == ["tree"]

      Application.put_env(:linea_ui, :shell, sidebar: :nope)
      assert attrs(html(), "nav#sb", "data-format") == ["sections"]
    end

    test "attributes win over the config" do
      Application.put_env(:linea_ui, :shell, sidebar: :rail, nav: {__MODULE__, :config_nav})
      html = html(%{format: :tree})

      assert attrs(html, "nav#sb", "data-format") == ["tree"]
      assert texts(html, "button.sg-sb-gt") == ["Vendas", "Notas", "Financeiro"]
    end

    test "the nav function gets the assigns of the component" do
      Application.put_env(:linea_ui, :shell, nav: {__MODULE__, :current_nav})
      html = render(~H|<.sidebar id="c" current="/ola" />|)

      assert texts(html, ".sg-sb-a > .lbl") == ["/ola"]
    end

    test "without config or nav the menu is empty" do
      html = render(~H|<.sidebar id="c" />|)
      assert attrs(html, "#c", "data-format") == ["sections"]
      assert find(html, ".sg-sb-a") |> Enum.empty?()
    end
  end

  def config_nav(_assigns) do
    [
      %{
        group: "Config",
        icon: "settings",
        items: [%{label: "Perfil", icon: "user", navigate: "/c"}]
      }
    ]
  end

  def current_nav(assigns), do: [%{label: assigns.current, href: assigns.current}]
end
