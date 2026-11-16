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
      |> Map.put_new(:footer, nil)
      |> Map.put_new(:show_user, nil)
      |> Map.put_new(:version, nil)
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
      footer={@footer}
      show_user={@show_user}
      version={@version}
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
      assert texts(html, ".lo-sb-brand > b") == ["Linea"]
      assert texts(html, ".lo-sb-brand > .lo-sb-logo") == ["S"]
      assert attrs(html, ".lo-sb-brand button.sw", "aria-label") == ["Switch company"]
      assert texts(html, ".lo-sb-title") == ["Vendas", "Notas", "Financeiro"]
      assert texts(html, ".lo-sb-title2") == ["Configurações e ajuda"]
      assert texts(html, ".lo-sb-plan > b") == ["Linea"]
      assert texts(html, ".lo-sb-plan .pro") == ["Pro"]
      assert find(html, ".lo-sb-rail") |> Enum.empty?()
    end

    test "the items of the format only: the foot has its items and `formats` hides the rail ones" do
      html = html()

      assert texts(html, ".lo-sb-foot .lo-sb-item > .lbl") == ["Ajuda"]

      assert texts(html, ".lo-sb-scroll > ul > li > .lo-sb-item > .lbl") == [
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

      assert texts(html, ".lo-sb-scroll > ul > li > .lo-sb-item > .lo-sb-count") == ["12"]
      assert texts(html, ".lo-sb-children .lo-sb-item > .lbl") == ["Abertos", "Cancelados"]
      assert texts(html, ".lo-sb-children .lo-sb-count") == ["8"]
      assert find(html, "svg.tb") |> Enum.empty?()
      assert [_] = Enum.to_list(find(html, ".lo-sb-item > .red"))
    end

    test "an item has an icon, a tooltip for the collapsed menu and a name" do
      html = html()

      assert "huge-home-01" in classes(
               html,
               ".lo-sb-scroll > ul > li:first-child > .lo-sb-item > .i"
             )

      assert texts(html, ".lo-sb-scroll > ul > li:first-child > .lo-sb-item > .rail-tip") == [
               "Início"
             ]

      assert attrs(html, ".lo-sb-scroll > ul > li:first-child > .lo-sb-item > .rail-tip", "role") ==
               [
                 "tooltip"
               ]

      assert attrs(html, ".lo-sb-scroll > ul > li:first-child > .lo-sb-item", "data-rail-tip") ==
               [""]
    end
  end

  describe "the active item" do
    test "is the one whose path is the current one, with aria-current" do
      html = html(%{current: "/clientes"})

      assert texts(html, ".lo-sb-item.on > .lbl") == ["Clientes"]
      assert attrs(html, ".lo-sb-item.on", "aria-current") == ["page"]
      assert attrs(html, "a[href=\"/\"]", "aria-current") == []
    end

    test "compares the query too, so a child is active and its parent is not" do
      html = html(%{current: "/pedidos?status=aberto"})
      assert texts(html, ".lo-sb-item.on > .lbl") == ["Abertos"]

      html = html(%{current: "/pedidos"})
      assert texts(html, ".lo-sb-item.on > .lbl") == ["Pedidos"]
    end

    test "`active: true` marks it without a path" do
      nav = [%{label: "A", icon: "home", href: "/a", active: true}, %{label: "B", href: "/b"}]
      assert texts(html(%{nav: nav}), ".lo-sb-item.on > .lbl") == ["A"]
    end
  end

  describe "rail" do
    setup do
      %{html: html(%{format: "rail", current: "/pedidos"})}
    end

    test "has the rail and the panel of the module of the current item", %{html: html} do
      assert "railx" in classes(html, "nav#sb")
      assert attrs(html, "nav#sb", "data-format") == ["rail"]
      assert texts(html, ".lo-sb-ph > b") == ["Vendas"]
      assert texts(html, ".lo-sb-rail > .lo-sb-logo") == ["S"]
      assert find(html, ".lo-sb-brand") |> Enum.empty?()
    end

    test "the rail: home, the person, one icon per module, the other items, extra apps and the foot",
         %{html: html} do
      labels = attrs(html, ".lo-sb-rail > a", "aria-label")
      assert labels == ["Início", "Vendas", "Financeiro", "Assistente", "Mapa", "Ajuda", "Avisos"]

      assert texts(html, ".lo-sb-rail > .lo-sb-av") == ["MC"]
      assert attrs(html, ".lo-sb-rail > .lo-sb-av", "aria-label") == ["Marina Costa"]
      assert attrs(html, ".lo-sb-rail > a.on", "aria-label") == ["Vendas"]
      assert attrs(html, ".lo-sb-rail > a.on", "aria-current") == ["page"]
      assert attrs(html, ".lo-sb-rail > a[data-module]", "aria-label") == ["Vendas", "Financeiro"]
      assert attrs(html, ".lo-sb-rail > a[data-module]", "href") == ["/pedidos", "/caixa"]
      assert attrs(html, ".lo-sb-rail a.dot", "style") == ["background:#f97316"]
      assert attrs(html, ".lo-sb-rail > a.has-badge", "aria-label") == ["Avisos"]
      assert texts(html, ".lo-sb-rail > a.r > .rail-tip") |> Enum.take(2) == ["Início", "Vendas"]
      assert attrs(html, ".lo-sb-rail > a.r", "data-rail-tip") |> Enum.uniq() == ["always"]
    end

    test "the panel: the create button, the items, the nested group, the coloured tree and the shortcuts",
         %{html: html} do
      assert texts(html, ".lo-sb-panel a.lo-sb-new") == ["Novo pedido"]
      assert attrs(html, "a.lo-sb-new", "href") == ["/pedidos/novo"]
      assert texts(html, ".lo-sb-panel .lo-sb-gh") == ["Notas", "Experimente"]
      assert attrs(html, ".lo-sb-gh > button", "aria-expanded") == ["false"]
      assert attrs(html, ".lo-sb-gh > button", "aria-controls") |> length() == 1
      assert texts(html, ".lo-sb-children a.t .lbl") == ["Abertos", "Cancelados"]

      assert classes(html, ".lo-sb-children > li:first-child > a.t > span") |> Enum.take(2) == [
               "ci",
               "blue"
             ]

      assert attrs(html, ".lo-sb-children > li:last-child > a.t > span.ci", "style") == [
               "background:#f43f5e"
             ]

      assert texts(html, ".lo-sb-scroll > ul > li > a.lo-sb-item > .lbl") ==
               ["Conectar banco"]
               |> then(&(&1 -- &1))
               |> Kernel.++(texts(html, ".lo-sb-scroll > ul > li > a.lo-sb-item > .lbl"))

      assert "Conectar banco" in texts(html, ".lo-sb-scroll .lo-sb-item > .lbl")
      assert attrs(html, ".lo-sb-panel [data-rail-toggle]", "data-rail-toggle") == ["sb"]
    end

    test "the trial card", %{html: html} do
      assert texts(html, ".lo-sb-trial .row1 > b") == ["Termina em 7 dias"]
      assert texts(html, ".lo-sb-trial .free") == ["Teste"]
      assert texts(html, ".lo-sb-trial .row2 > span") == ["Acesso completo"]
      assert attrs(html, ".lo-sb-trial .row2 a", "href") == ["/assinar"]
      assert texts(html, ".lo-sb-trial .row2 a") == ["Assinar"]
      assert attrs(html, ".lo-sb-trial progress.progress", "value") == ["32"]
      assert attrs(html, ".lo-sb-trial progress.progress", "max") == ["100"]
    end

    test "the panel follows the module that holds the active item, and the first one without it" do
      assert texts(html(%{format: "rail", current: "/caixa"}), ".lo-sb-ph > b") == ["Financeiro"]
      assert texts(html(%{format: "rail", current: "/x"}), ".lo-sb-ph > b") == ["Vendas"]
    end

    test "a nested group of the panel starts closed, and open when it holds the current item" do
      html = html(%{format: "rail", current: "/pedidos"})
      assert attrs(html, ".lo-sb-gh > button", "aria-expanded") == ["false"]
      assert find(html, "ul.lo-sb-group[data-closed]") |> Enum.count() == 1

      html = html(%{format: "rail", current: "/notas"})
      assert attrs(html, ".lo-sb-gh > button", "aria-expanded") == ["true"]
      assert find(html, "ul.lo-sb-group[data-closed]") |> Enum.empty?()
    end

    test "the header of a nested group is the toggle, with the chevron decorative inside" do
      html = html(%{format: "rail", current: "/pedidos"})
      assert texts(html, ".lo-sb-gh > button") == ["Notas"]
      assert attrs(html, ".lo-sb-gh > button", "type") == ["button"]
      [controls] = attrs(html, ".lo-sb-gh > button", "aria-controls")
      assert attrs(html, "ul.lo-sb-group", "id") |> Enum.member?(controls)
      assert find(html, ".lo-sb-gh > button button") |> Enum.empty?()
      assert attrs(html, ".lo-sb-gh > button > span.tg", "aria-hidden") == ["true"]
      assert find(html, ".lo-sb-gh > button .tg svg") |> Enum.count() == 1
    end

    test "the panel button is left out with `collapsible` false" do
      html = html(%{format: "rail", collapsible: false})
      assert find(html, ".lo-sb-panel [data-rail-toggle]") |> Enum.empty?()
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
      assert attrs(html, ".lo-sb-brand button.col", "data-rail-toggle") == ["sb"]
      assert attrs(html, ".lo-sb-brand button.col", "aria-label") == ["Collapse menu"]
      assert texts(html, ".lo-sb-gt > button") == ["Vendas", "Notas", "Financeiro"]
      assert attrs(html, ".lo-sb-gt > button", "aria-expanded") == ["false", "false", "true"]
      assert texts(html, ".lo-sb-user .who > b") == ["Marina Costa"]
      assert texts(html, ".lo-sb-user .who > span") == ["marina@linea.com"]
      assert texts(html, ".lo-sb-user .lo-sb-av") == ["MC"]
    end

    test "children are joined by a line, items with colour are squares and the badge is a dot", %{
      html: html
    } do
      assert [_] = Enum.to_list(find(html, ".lo-sb-children"))
      assert classes(html, ".lo-sb-children > li > a") == ["lo-sb-item"]
      assert classes(html, "a.sq") == ["lo-sb-item", "on", "menu-active", "sq"]
      assert classes(html, "a.sq > span") |> Enum.take(2) == ["sqi", "ink"]
      assert [_] = Enum.to_list(find(html, "a.sq > .red"))
      assert attrs(html, "a.sq", "aria-current") == ["page"]
    end

    test "children are a nested daisyUI menu list, without a drawn connector" do
      nav = [
        %{group: "G", items: [%{label: "P", href: "/p", children: [%{label: "A", href: "/a"}]}]}
      ]

      html = html(%{format: "tree", nav: nav, current: "/a"})
      assert [_] = Enum.to_list(find(html, "ul.menu li.lo-sb-li > ul.lo-sb-children > li > a"))
      assert find(html, "svg.tb") |> Enum.empty?()

      assert classes(html, ".lo-sb-children a[aria-current]") == [
               "lo-sb-item",
               "on",
               "menu-active"
             ]
    end

    test "a group with `collapsible: false` has a label without a button" do
      nav = [%{group: "Fixo", collapsible: false, items: [%{label: "A", href: "/a"}]}]
      html = html(%{format: "tree", nav: nav})
      assert find(html, ".lo-sb-gt > button") |> Enum.empty?()
      assert texts(html, ".lo-sb-gt > span") == ["Fixo"]
    end

    test "an item with children has a chevron button, sibling of its link, tied to the children",
         %{
           html: html
         } do
      assert attrs(html, "button.lo-sb-caret", "aria-expanded") == ["false"]
      assert attrs(html, "button.lo-sb-caret", "aria-label") == ["Pedidos"]
      assert find(html, "a button") |> Enum.empty?()
      assert find(html, "button.lo-sb-caret svg path[d='M7 10l5 5 5-5']") |> Enum.count() == 1
      [controls] = attrs(html, "button.lo-sb-caret", "aria-controls")
      assert attrs(html, "ul.lo-sb-children", "id") == [controls]
      assert find(html, "ul#" <> controls <> " a") |> Enum.count() == 2
      assert find(html, "ul#" <> controls <> "[data-closed]") |> Enum.count() == 1
    end

    test "an item without destination is a button that toggles its tree" do
      nav = [%{group: "G", items: [%{label: "P", children: [%{label: "A", href: "/a"}]}]}]
      html = html(%{format: "tree", nav: nav})
      assert find(html, "button.lo-sb-caret") |> Enum.empty?()
      assert texts(html, "button.lo-sb-item .lbl") == ["P"]
      assert attrs(html, "button.lo-sb-item", "type") == ["button"]
      assert attrs(html, "button.lo-sb-item", "aria-expanded") == ["false"]
      [controls] = attrs(html, "button.lo-sb-item", "aria-controls")
      assert attrs(html, "ul.lo-sb-children", "id") == [controls]
      assert find(html, "button.lo-sb-item > span.cv svg") |> Enum.count() == 1
      assert find(html, "button.lo-sb-item button") |> Enum.empty?()
    end

    test "an item with destination keeps its link, and the click also opens the children", %{
      html: html
    } do
      assert find(html, "button.lo-sb-item") |> Enum.empty?()
      [controls] = attrs(html, "button.lo-sb-caret", "aria-controls")
      [id] = attrs(html, "button.lo-sb-caret", "id")
      assert id == controls <> "-btn"
      [click] = attrs(html, "a.lo-sb-item[phx-click]", "phx-click")
      assert click =~ "aria-expanded"
      assert click =~ "#" <> id
      assert click =~ "data-closed"
      assert click =~ "#" <> controls
    end

    test "`collapsible: false` takes the chevron of an item away" do
      nav = [
        %{
          group: "G",
          items: [%{label: "P", collapsible: false, children: [%{label: "A", href: "/a"}]}]
        }
      ]

      html = html(%{format: "tree", nav: nav})
      assert find(html, "button.lo-sb-caret") |> Enum.empty?()
      assert find(html, ".lo-sb-children") |> Enum.count() == 1
    end

    test "an active child opens the children and its group" do
      html = html(%{format: "tree", current: "/pedidos?status=aberto"})
      assert attrs(html, "button.lo-sb-caret", "aria-expanded") == ["true"]
      assert find(html, "ul.lo-sb-children[data-closed]") |> Enum.empty?()
      assert texts(html, ".lo-sb-children a.on .lbl") == ["Abertos"]
      assert attrs(html, ".lo-sb-gt > button", "aria-expanded") == ["true", "false", "false"]
    end

    test "without a current route every group and tree starts closed" do
      html = html(%{format: "tree"})
      assert attrs(html, ".lo-sb-gt > button", "aria-expanded") == ["false", "false", "false"]
      assert attrs(html, "button.lo-sb-caret", "aria-expanded") == ["false"]
      assert find(html, "ul.lo-sb-group[data-closed]") |> Enum.count() == 3
      assert find(html, "ul.lo-sb-children[data-closed]") |> Enum.count() == 1
    end

    test "the current route in group B opens only B" do
      html = html(%{format: "tree", current: "/caixa"})
      assert attrs(html, ".lo-sb-gt > button", "aria-expanded") == ["false", "false", "true"]
      closed = attrs(html, "ul.lo-sb-group[data-closed]", "id")
      assert closed == ["sb-g2", "sb-g2-2"]
    end

    test "`open` overrides the first state of groups and items" do
      nav = [
        %{
          group: "A",
          open: true,
          items: [%{label: "P", open: true, children: [%{label: "X", href: "/x"}]}]
        },
        %{
          group: "B",
          open: false,
          items: [%{label: "Q", open: false, children: [%{label: "Y", href: "/y"}]}]
        }
      ]

      html = html(%{format: "tree", nav: nav, current: "/y"})
      assert attrs(html, ".lo-sb-gt > button", "aria-expanded") == ["true", "false"]
      assert attrs(html, "button.lo-sb-item", "aria-expanded") == ["true", "false"]
      assert find(html, "ul.lo-sb-group[data-closed]") |> Enum.count() == 1
      assert find(html, "ul.lo-sb-children[data-closed]") |> Enum.count() == 1
    end

    test "`collapsible: false` never gets data-closed" do
      nav = [
        %{
          group: "Fixo",
          collapsible: false,
          open: false,
          items: [
            %{label: "P", collapsible: false, open: false, children: [%{label: "A", href: "/a"}]}
          ]
        }
      ]

      html = html(%{format: "tree", nav: nav})
      assert find(html, "[data-closed]") |> Enum.empty?()
    end

    test "the ids of groups and children are unique and stable" do
      nav = [
        %{label: "A", href: "/a", children: [%{label: "A1", href: "/a1"}]},
        %{
          group: "G",
          items: [
            %{label: "B", href: "/b", children: [%{label: "B1", href: "/b1"}]},
            %{label: "C", href: "/c", children: [%{label: "C1", href: "/c1"}]}
          ]
        }
      ]

      first = html(%{format: "tree", nav: nav})
      ids = attrs(first, "button.lo-sb-caret, .lo-sb-gt > button", "aria-controls")
      assert length(ids) == 4
      assert ids == Enum.uniq(ids)

      assert attrs(first, "ul.lo-sb-children, ul.lo-sb-group", "id") |> Enum.sort() ==
               Enum.sort(ids)

      assert ids ==
               attrs(
                 html(%{format: "tree", nav: nav}),
                 "button.lo-sb-caret, .lo-sb-gt > button",
                 "aria-controls"
               )
    end

    test "the sections and rail formats have no chevron on items" do
      for format <- ~w(sections rail) do
        assert find(html(%{format: format}), "button.lo-sb-caret") |> Enum.empty?()
      end
    end

    test "the foot of the menu has the items of the foot group without its label", %{html: html} do
      assert texts(html, ".lo-sb-foot .lo-sb-item > .lbl") == ["Ajuda"]
      assert find(html, ".lo-sb-title2") |> Enum.empty?()
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

      assert [_] = Enum.to_list(find(html, ".lo-sb-brand > #mine"))
      assert find(html, ".lo-sb-brand > b") |> Enum.empty?()
      assert [_] = Enum.to_list(find(html, ".lo-sb-foot > #extra"))
    end

    test "the logo can be an image and the switcher can be left out or labelled" do
      html = html(%{brand: %{name: "L", src: "/logo.svg"}})
      assert attrs(html, ".lo-sb-brand .lo-sb-logo img", "src") == ["/logo.svg"]

      assert find(html(%{brand: %{name: "L", switch: false}}), "button.sw") |> Enum.empty?()

      html = html(%{brand: %{name: "L", switch: %{label: "Trocar de empresa", click: "switch"}}})
      assert attrs(html, "button.sw", "aria-label") == ["Trocar de empresa"]
      assert attrs(html, "button.sw", "phx-click") == ["switch"]
    end

    test "without a user, a plan or a trial there are no cards" do
      html = html(%{format: "tree", user: nil, plan: nil})
      assert find(html, ".lo-sb-user") |> Enum.empty?()

      html = html(%{plan: nil})
      assert find(html, ".lo-sb-plan") |> Enum.empty?()

      html = html(%{format: "rail", user: nil, trial: nil, rail_extra: []})
      assert find(html, ".lo-sb-trial, .lo-sb-av, a.dot") |> Enum.empty?()
    end
  end

  describe "the user and the version" do
    @photo %{name: "Marina Costa", avatar: "/marina.png"}

    test "the photo is a bare <img>: the size and the crop come from the CSS of the kit" do
      for format <- ["tree", "rail"] do
        html = html(%{format: format, user: @photo})
        assert attrs(html, ".lo-sb-av > img", "src") == ["/marina.png"]
        assert attrs(html, ".lo-sb-av > img", "class") == []
      end
    end

    test "the image of the brand logo is a bare <img> too" do
      for format <- ["sections", "tree", "rail"] do
        html = html(%{format: format, brand: %{name: "Linea", src: "/logo.png"}})
        assert attrs(html, ".lo-sb-logo > img", "src") |> Enum.uniq() == ["/logo.png"]
        assert attrs(html, ".lo-sb-logo > img", "class") |> Enum.reject(&is_nil/1) == []
      end
    end

    test "no `footer`: each format keeps its own (the user card, the plan card, the avatar)" do
      html = html(%{format: "tree"})
      assert find(html, ".lo-sb-user") != []
      assert find(html, ".lo-sb-ver, .lo-sb-plan") |> Enum.empty?()

      html = html(%{format: "sections"})
      assert find(html, ".lo-sb-plan") != []
      assert find(html, ".lo-sb-user, .lo-sb-ver") |> Enum.empty?()

      html = html(%{format: "rail"})
      assert find(html, ".lo-sb-rail > .lo-sb-av") != []
      assert find(html, ".lo-sb-ver") |> Enum.empty?()
    end

    test "`footer=\"user\"`: the card (tree, sections), the avatar (rail); an atom works too" do
      for footer <- ["user", :user] do
        html = html(%{format: "tree", footer: footer})
        assert texts(html, ".lo-sb-body > .lo-sb-user b") == ["Marina Costa"]

        html = html(%{format: "sections", footer: footer})
        assert texts(html, ".lo-sb-body > .lo-sb-user b") == ["Marina Costa"]
        assert find(html, ".lo-sb-plan") |> Enum.empty?()

        html = html(%{format: "rail", footer: footer, version: "v1.0.0"})
        assert find(html, ".lo-sb-rail > .lo-sb-av") != []
        assert find(html, ".lo-sb-ver") |> Enum.empty?()
      end
    end

    test "`footer=\"version\"`: the line, in place of the user (tree, rail) or of the plan card (sections)" do
      for format <- ["tree", "rail", "sections"] do
        html = html(%{format: format, footer: "version", version: "v1.4.2"})
        assert texts(html, ".lo-sb-ver") == ["v1.4.2"]
        assert find(html, ".lo-sb-user, .lo-sb-plan, .lo-sb-rail > .lo-sb-av") |> Enum.empty?()
        assert attrs(html, ".lo-sb-ver", "aria-label") == ["Version v1.4.2"]
        assert attrs(html, ".lo-sb-ver", "title") == ["Version v1.4.2"]
        assert attrs(html, ".lo-sb-ver > .dot", "aria-hidden") == ["true"]
        assert find(html, ".lo-sb-ver .b, .lo-sb-ver a") |> Enum.empty?()
      end

      assert texts(
               html(%{format: "tree", footer: "version", version: "v1"}),
               ".lo-sb-body > .lo-sb-ver"
             ) ==
               ["v1"]

      assert find(
               html(%{format: "rail", footer: :version, version: "v1"}),
               ".lo-sb-panel > .lo-sb-ver"
             ) !=
               []

      html = html(%{format: "sections", footer: :version, version: "v1"})
      assert find(html, ".lo-sb-foot + .lo-sb-ver") != []
    end

    test "`footer=\"version\"` without a version draws nothing, and the plan card is gone" do
      for format <- ["tree", "rail", "sections"] do
        html = html(%{format: format, footer: "version"})

        assert find(html, ".lo-sb-user, .lo-sb-plan, .lo-sb-ver, .lo-sb-rail > .lo-sb-av")
               |> Enum.empty?()
      end
    end

    test "`footer=\"none\"`: nothing, even with a version" do
      for format <- ["tree", "rail", "sections"] do
        html = html(%{format: format, footer: "none", version: "v1.4.2"})

        assert find(html, ".lo-sb-user, .lo-sb-plan, .lo-sb-ver, .lo-sb-rail > .lo-sb-av")
               |> Enum.empty?()
      end
    end

    test "`version` as a map: build, link, label, title and status" do
      version = %{
        version: "v1.4.2",
        build: "2a9f1c3",
        navigate: "/changelog",
        label: "Novidades",
        title: "Hoje"
      }

      for format <- ["tree", "rail", "sections"] do
        html = html(%{format: format, footer: "version", version: version})
        assert texts(html, ".lo-sb-ver .v") == ["v1.4.2"]
        assert texts(html, ".lo-sb-ver .b") == ["2a9f1c3"]
        assert attrs(html, ".lo-sb-ver", "aria-label") == ["Version v1.4.2 (2a9f1c3)"]
        assert attrs(html, ".lo-sb-ver a.new", "href") == ["/changelog"]
        assert attrs(html, ".lo-sb-ver a.new", "title") == ["Hoje"]
        assert texts(html, ".lo-sb-ver a.new") == ["Novidades"]
        assert attrs(html, ".lo-sb-ver a.new > svg", "aria-hidden") == ["true"]
        assert attrs(html, ".lo-sb-ver", "data-status") == ["ok"]
      end
    end

    test "the link needs a destination; navigate, patch and href all work; the label defaults to English" do
      html = html(%{format: "tree", footer: "version", version: %{version: "v1", build: "abc"}})
      assert find(html, ".lo-sb-ver a") |> Enum.empty?()

      for key <- [:navigate, :patch, :href] do
        html =
          html(%{format: "tree", footer: "version", version: %{:version => "v1", key => "/novo"}})

        assert attrs(html, ".lo-sb-ver a.new", "href") == ["/novo"]
        assert texts(html, ".lo-sb-ver a.new") == ["What's new"]
        assert attrs(html, ".lo-sb-ver a.new", "title") == []
      end
    end

    test "`status` colours the dot: ok by default, warning and down; the rest is ok" do
      for {status, expected} <- [
            {:warning, "warning"},
            {"down", "down"},
            {:ok, "ok"},
            {:nope, "ok"},
            {nil, "ok"}
          ] do
        html =
          html(%{format: "tree", footer: "version", version: %{version: "v1", status: status}})

        assert attrs(html, ".lo-sb-ver", "data-status") == [expected]
      end
    end

    test "`version` without `footer` shows the line, in place of the user" do
      for format <- ["tree", "rail", "sections"] do
        html = html(%{format: format, version: "v1.4.2"})
        assert texts(html, ".lo-sb-ver") == ["v1.4.2"]
        assert find(html, ".lo-sb-user, .lo-sb-plan, .lo-sb-rail > .lo-sb-av") |> Enum.empty?()
      end
    end

    test "`show_user={false}` (deprecated) is `footer=\"none\"`, or the version when there is one" do
      for format <- ["tree", "rail", "sections"] do
        html = html(%{format: format, show_user: false})
        assert find(html, ".lo-sb-user, .lo-sb-ver, .lo-sb-rail > .lo-sb-av") |> Enum.empty?()

        html = html(%{format: format, show_user: false, version: "v1.4.2"})
        assert texts(html, ".lo-sb-ver") == ["v1.4.2"]
        assert find(html, ".lo-sb-user, .lo-sb-rail > .lo-sb-av") |> Enum.empty?()
      end
    end

    test "the config sets `footer` and `version` (a string or a map), and the attributes win" do
      Application.put_env(:linea_ui, :shell, footer: :version, version: "v9.0.0")
      html = html(%{format: "tree"})
      assert find(html, ".lo-sb-user") |> Enum.empty?()
      assert texts(html, ".lo-sb-ver") == ["v9.0.0"]

      assert attrs(
               html(%{format: "tree", version: %{version: "v8", build: "abc"}}),
               ".lo-sb-ver",
               "aria-label"
             ) ==
               ["Version v8 (abc)"]

      html = html(%{format: "tree", footer: "user"})
      assert find(html, ".lo-sb-user") != []
      assert find(html, ".lo-sb-ver") |> Enum.empty?()

      html = html(%{format: "tree", footer: "none"})
      assert find(html, ".lo-sb-user, .lo-sb-ver") |> Enum.empty?()

      Application.put_env(:linea_ui, :shell, version: %{version: "v7.0.0", navigate: "/n"})
      html = html(%{format: "sections"})
      assert texts(html, ".lo-sb-ver .v") == ["v7.0.0"]
      assert attrs(html, ".lo-sb-ver a", "href") == ["/n"]

      Application.put_env(:linea_ui, :shell, footer: :none)
      assert find(html(%{format: "tree"}), ".lo-sb-user, .lo-sb-ver") |> Enum.empty?()

      Application.put_env(:linea_ui, :shell, footer: :version)
      assert find(html(%{format: "tree"}), ".lo-sb-user, .lo-sb-ver") |> Enum.empty?()
    end

    test "the config `show_user: false` still takes the user out" do
      Application.put_env(:linea_ui, :shell, show_user: false)
      assert find(html(%{format: "tree"}), ".lo-sb-user") |> Enum.empty?()

      html = html(%{format: "tree", footer: "user"})
      assert find(html, ".lo-sb-user") != []
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
      assert "huge-shopping-cart-01" in classes(html, "li:nth-child(1) > .lo-sb-item > .i")
      assert "huge-user-02" in classes(html, "li:nth-child(2) > .lo-sb-item > .i")

      assert classes(html, "li:nth-child(3) > .lo-sb-item > .i") |> Enum.take(3) == [
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
      assert texts(html, ".lo-sb-ph > b") == ["Config"]
      assert attrs(html, ".lo-sb-panel a.on", "aria-current") == ["page"]
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
      assert texts(html, ".lo-sb-gt > button") == ["Vendas", "Notas", "Financeiro"]
    end

    test "the nav function gets the assigns of the component" do
      Application.put_env(:linea_ui, :shell, nav: {__MODULE__, :current_nav})
      html = render(~H|<.sidebar id="c" current="/ola" />|)

      assert texts(html, ".lo-sb-item > .lbl") == ["/ola"]
    end

    test "without config or nav the menu is empty" do
      html = render(~H|<.sidebar id="c" />|)
      assert attrs(html, "#c", "data-format") == ["sections"]
      assert find(html, ".lo-sb-item") |> Enum.empty?()
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

  describe "variant and shortcut" do
    test "the floating card has no variant attribute; sidebar and inset do, and Ctrl/⌘+B is on by default" do
      html = html()
      assert attrs(html, "nav#sb", "data-variant") == []
      assert attrs(html, "nav#sb", "data-shortcut") == ["b"]

      html =
        render(~H"""
        <.sidebar id="flush" nav={[%{label: "Início", navigate: "/"}]} variant="sidebar" shortcut={nil} />
        <.sidebar id="ins" nav={[%{label: "Início", navigate: "/"}]} variant="inset" shortcut="m" />
        """)

      assert attrs(html, "nav#flush", "data-variant") == ["sidebar"]
      assert attrs(html, "nav#flush", "data-shortcut") == []
      assert attrs(html, "nav#ins", "data-variant") == ["inset"]
      assert attrs(html, "nav#ins", "data-shortcut") == ["m"]
    end
  end

  @nested_nav [
    %{
      group: "Platform",
      items: [
        %{
          label: "Playground",
          icon: "doc",
          children: [
            %{label: "History", navigate: "/history"},
            %{label: "Starred", navigate: "/starred"}
          ]
        },
        %{label: "Models", icon: "box", navigate: "/models"}
      ]
    }
  ]

  defp nested_html(extra \\ %{}) do
    assigns =
      Map.merge(
        %{
          nav: @nested_nav,
          brand: %{
            name: "Acme Inc",
            logo: "A",
            plan: "Enterprise",
            menu: [%{label: "Acme Corp.", navigate: "/teams/2", hint: "⌘2"}]
          },
          user: %{
            name: "Marina Costa",
            email: "marina@linea.com",
            menu: [
              %{label: "Account", icon: "user", navigate: "/account"},
              :separator,
              %{label: "Log out", href: "/users/log-out", method: "delete", danger: true}
            ]
          },
          current: "/history"
        },
        extra
      )
      |> Map.put(:__changed__, nil)

    rendered_to_string(~H"""
    <.sidebar id="ns" format="nested" nav={@nav} brand={@brand} user={@user} current={@current} />
    """)
  end

  describe "nested" do
    test "the team switcher and the user row open their menus" do
      html = nested_html()

      assert "nestx" in classes(html, "nav#ns")
      assert texts(html, "#ns-team .lo-sb-mb > b") == ["Acme Inc"]
      assert texts(html, "#ns-team .lo-sb-mb > .sub") == ["Enterprise"]
      assert attrs(html, "#ns-team-menu [role=menuitem]", "href") == ["/teams/2"]
      assert texts(html, "#ns-user .lo-sb-mm-h .who b") == ["Marina Costa"]
      assert attrs(html, "#ns-user-menu a[role=menuitem]", "data-method") == ["delete"]
      assert find(html, "#ns-user-menu [role=separator]") |> Enum.count() == 2
    end

    test "groups have a label; an item with children toggles them and opens on the active child" do
      html = nested_html()

      assert texts(html, "#ns .lo-sb-title") == ["Platform"]
      assert attrs(html, "#ns button.lo-sb-item.rw", "aria-expanded") == ["true"]
      assert texts(html, "#ns .lo-sb-children .lo-sb-item .lbl") == ["History", "Starred"]
      assert attrs(html, "#ns .lo-sb-children a.on", "aria-current") == ["page"]
    end

    test "without menus the header and the foot are plain rows" do
      html = nested_html(%{brand: %{name: "Acme Inc", logo: "A"}, user: %{name: "Marina Costa"}})

      assert find(html, "#ns-team") |> Enum.empty?()
      assert texts(html, "#ns .lo-sb-team > b") == ["Acme Inc"]
      assert texts(html, "#ns .lo-sb-user b") == ["Marina Costa"]
    end
  end

  def current_nav(assigns), do: [%{label: assigns.current, href: assigns.current}]
end
