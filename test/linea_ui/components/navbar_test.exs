defmodule LineaUI.Components.NavbarTest do
  use LineaUI.ComponentCase, async: true

  import LineaUI.Components.Navbar

  defp text(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

  defp attrs(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)
  defp count(html, selector), do: html |> find(selector) |> Enum.count()

  @user %{
    name: "Marina Costa",
    email: "marina@lojabomfim.com.br",
    role: "Administradora",
    color: "#8a5cd6"
  }

  describe "navbar" do
    test "the default bar: left side, then the end" do
      html =
        render(~H"""
        <.navbar id="top">
          <span id="left">left</span>
          <:end><span id="right">right</span></:end>
        </.navbar>
        """)

      assert ["sg-nb"] == classes(html, "header")
      assert attrs(html, "header", "id") == ["top"]
      assert text(html, "header > #left") == ["left"]
      assert text(html, "header > .sg-nb-end > #right") == ["right"]
      assert count(html, ".sg-nb-floatwrap") == 0
      assert count(html, ".sg-nb-row") == 0
    end

    test "no end slot, no .sg-nb-end" do
      html = render(~H|<.navbar>x</.navbar>|)
      assert count(html, ".sg-nb-end") == 0
    end

    test "float is wrapped in the float wrap" do
      html = render(~H|<.navbar variant="float">x</.navbar>|)
      assert count(html, ".sg-nb-floatwrap > header.sg-nb.float") == 1
    end

    test "clear, dense and mobile" do
      assert ["sg-nb", "clear"] ==
               classes(render(~H|<.navbar variant="clear">x</.navbar>|), "header")

      assert ["sg-nb", "dense"] ==
               classes(render(~H|<.navbar variant="dense">x</.navbar>|), "header")

      assert ["sg-nb", "mob"] ==
               classes(render(~H|<.navbar variant="mobile">x</.navbar>|), "header")
    end

    test "tabs make it tall, with the content in a row and the tabs after it" do
      html =
        render(~H"""
        <.navbar>
          <span id="left">left</span>
          <:end><span id="right">right</span></:end>
          <:tabs><.navbar_tabs items={[%{label: "Quadro", active: true}]} /></:tabs>
        </.navbar>
        """)

      assert ["sg-nb", "tall"] == classes(html, "header")
      assert count(html, "header > .sg-nb-row > #left") == 1
      assert count(html, "header > .sg-nb-row > .sg-nb-end > #right") == 1
      assert count(html, "header > nav.sg-nb-tabs") == 1
    end

    test "center and class" do
      html = render(~H|<.navbar class="x">
  <:center><i id="c"></i></:center>
</.navbar>|)
      assert ["sg-nb", "x"] == classes(html, "header")
      assert count(html, "header > #c") == 1
    end
  end

  describe "left side" do
    test "brand with a letter, a name, or a picture" do
      html = render(~H|<.navbar_brand name="Linea" />|)
      assert ["row", "sg-nb-brandrow"] == classes(html, "span.row")
      assert text(html, ".sg-nb-logo") == ["L"]
      assert text(html, "b.sg-nb-brand") == ["Linea"]

      html = render(~H|<.navbar_brand name="Linea" logo="Z" />|)
      assert text(html, ".sg-nb-logo") == ["Z"]

      html = render(~H|<.navbar_brand name="Linea" src="/logo.svg" />|)
      assert attrs(html, ".sg-nb-logo img", "src") == ["/logo.svg"]
    end

    test "crumbs: links, separators and the last one in bold" do
      html =
        render(~H"""
        <.navbar_crumbs items={[
          %{label: "Início", navigate: "/"},
          %{label: "Projetos", href: "/p"},
          %{label: "Site novo"}
        ]} />
        """)

      assert ["sg-nb-crumb"] == classes(html, "nav")
      assert attrs(html, "nav", "aria-label") == ["Breadcrumb"]
      assert text(html, "nav a") == ["Início", "Projetos"]
      assert text(html, "nav > b") == ["Site novo"]
      assert attrs(html, "nav > b", "aria-current") == ["page"]
      assert text(html, "nav .sep") == ["/", "/"]
    end

    test "a crumb with no link in the middle is plain text" do
      html =
        render(~H|<.navbar_crumbs items={[%{label: "A"}, %{label: "B"}]} label="Caminho" />|)

      assert attrs(html, "nav", "aria-label") == ["Caminho"]
      assert count(html, "nav a") == 0
      assert text(html, "nav > span:not(.sep)") == ["A"]
      assert text(html, "nav > b") == ["B"]
    end

    test "workspace is a button in .sg-nb-start" do
      html =
        render(~H|<.navbar_workspace name="Loja Bom Fim" sub="Plano Pro" phx-click="ws" />|)

      assert count(html, ".sg-nb-start > button.sg-nb-ws") == 1
      assert attrs(html, "button", "phx-click") == ["ws"]
      assert text(html, ".sg-nb-logo") == ["L"]
      assert text(html, ".col b") == ["Loja Bom Fim"]
      assert text(html, ".col span") == ["Plano Pro"]
    end

    test "chip with square, color and tag; slash" do
      html =
        render(~H|<.navbar_chip label="Loja" square="LB" color="#1a7f4b" tag="Pro" />|)

      assert text(html, "button.sg-nb-chip b") == ["Loja"]
      assert text(html, ".sg-nb-sq") == ["LB"]
      assert attrs(html, ".sg-nb-sq", "style") == ["background:#1a7f4b"]
      assert text(html, ".sg-nb-tag") == ["Pro"]
      assert text(html, "button.sg-nb-chip span.tag") == ["Pro"]

      assert text(render(~H|<.navbar_slash />|), ".sg-nb-slash") == ["/"]
    end
  end

  describe "middle" do
    test "links mark the active one by flag or by current" do
      html =
        render(~H"""
        <.navbar_links items={[
          %{label: "Início", navigate: "/"},
          %{label: "Projetos", navigate: "/p", active: true}
        ]} />
        """)

      assert ["sg-nb-links"] == classes(html, "nav")
      assert text(html, "a.on") == ["Projetos"]
      assert attrs(html, "a.on", "aria-current") == ["page"]
      assert count(html, "a[aria-current]") == 1

      html =
        render(~H"""
        <.navbar_links
          current="/"
          items={[%{label: "Início", navigate: "/"}, %{label: "Projetos", navigate: "/p"}]}
        />
        """)

      assert text(html, "a.on") == ["Início"]
    end

    test "tabs with a count" do
      html =
        render(~H"""
        <.navbar_tabs items={[
          %{label: "Quadro", patch: "/q", active: true},
          %{label: "Arquivos", patch: "/f", count: 12}
        ]} />
        """)

      assert ["sg-nb-tabs"] == classes(html, "nav")
      assert text(html, "a.on") == ["Quadro"]
      assert text(html, "a .n") == ["12"]
      assert count(html, ".n") == 1
    end

    test "mobile title" do
      assert text(render(~H|<.navbar_title>Site novo</.navbar_title>|), "b.sg-nb-mtitle") == [
               "Site novo"
             ]
    end
  end

  describe "right side" do
    test "search is a button trigger with the shortcut" do
      html = render(~H|<.navbar_search placeholder="Buscar" phx-click="palette" />|)
      assert ["sg-nb-search"] == classes(html, "button")
      assert attrs(html, "button", "type") == ["button"]
      assert attrs(html, "button", "phx-click") == ["palette"]
      assert text(html, "button > span:not([class])") == ["Buscar"]
      assert text(html, "kbd") == ["⌘K"]
    end

    test "search wide, width and no shortcut" do
      html = render(~H|<.navbar_search wide width="440px" kbd={nil} />|)
      assert ["sg-nb-search", "wide"] == classes(html, "button")
      assert attrs(html, "button", "style") == ["width:440px"]
      assert count(html, "kbd") == 0
    end

    test "bell with and without the dot" do
      html = render(~H|<.navbar_bell dot label="Avisos" phx-click="bell" />|)
      assert count(html, "span.sg-nb-bell > button.sg-ib") == 1
      assert attrs(html, "button", "aria-label") == ["Avisos"]
      assert attrs(html, "button", "phx-click") == ["bell"]
      assert count(html, ".sg-nb-bell > i") == 1

      html = render(~H|<.navbar_bell size="sm" />|)
      assert ["sg-ib", "sm"] == classes(html, "button")
      assert count(html, ".sg-nb-bell > i") == 0
    end

    test "generic icon button" do
      html = render(~H|<.navbar_icon name="huge-search-01" label="Buscar" phx-click="s" />|)
      assert ["sg-ib"] == classes(html, "button")
      assert attrs(html, "button", "aria-label") == ["Buscar"]
      assert count(html, "button .huge-search-01") == 1
    end

    test "lang from strings and from maps" do
      html = render(~H|<.navbar_lang locales={["PT", "EN"]} current="PT" />|)
      assert ["sg-nb-lang"] == classes(html, "span")
      assert attrs(html, "span", "role") == ["group"]
      assert text(html, "a.on") == ["PT"]
      assert text(html, "a") == ["PT", "EN"]

      html =
        render(~H"""
        <.navbar_lang locales={[
          %{code: "PT", href: "/pt"},
          %{code: "EN", href: "/en", active: true},
          %{code: "ES", click: "es"}
        ]} />
        """)

      assert text(html, "a.on") == ["EN"]
      assert attrs(html, "a", "href") == ["/pt", "/en", "#"]
      assert attrs(html, "a", "phx-click") == ["es"]
    end

    test "sep, env, sync" do
      assert ["sg-nb-sep"] == classes(render(~H|<.navbar_sep />|), "span")

      html = render(~H|<.navbar_env label="Produção" />|)
      assert ["sg-nb-env"] == classes(html, "span")
      assert text(html, "span") == ["Produção"]

      html = render(~H|<.navbar_env label="Homologação" tone="warn" />|)
      assert ["sg-nb-env", "warn"] == classes(html, "span")

      html = render(~H|<.navbar_sync text="Salvo há 2 min" />|)
      assert text(html, ".sg-nb-sync") == ["Salvo há 2 min"]
      assert count(html, ".sg-nb-sync .huge-tick-02") == 1
    end

    test "avatars with the +N bubble" do
      users =
        for n <- ["Marina Costa", "Rafael Souza", "Lia Furtado", "Zé Maria", "Ana Lima"],
            do: %{name: n}

      assigns = %{users: users}
      html = rendered_to_string(~H|<.navbar_avatars users={@users} max={3} />|)

      assert count(html, ".sg-nb-avs .sg-av.sm") == 3
      assert text(html, ".sg-av") == ["MC", "RS", "LF"]
      assert text(html, ".more") == ["+2"]

      html = rendered_to_string(~H|<.navbar_avatars users={@users} max={5} />|)
      assert count(html, ".more") == 0

      html = rendered_to_string(~H|<.navbar_avatars users={@users} max={3} total={9} />|)
      assert text(html, ".more") == ["+6"]
    end
  end

  describe "user" do
    test "the avatar variant is a plain button" do
      assigns = %{user: @user}
      html = rendered_to_string(~H|<.navbar_user user={@user} phx-click="me" />|)

      assert ["sg-nb-me"] == classes(html, "button")
      assert attrs(html, "button", "aria-label") == ["Account menu"]
      assert attrs(html, "button", "phx-click") == ["me"]
      assert attrs(html, "button", "aria-haspopup") == []
      assert text(html, ".sg-av") == ["MC"]
      assert attrs(html, ".sg-av", "style") == ["background:#8a5cd6"]
      assert count(html, ".sg-nb-mewrap") == 0
    end

    test "ring and named" do
      assigns = %{user: @user}

      assert ["sg-nb-me", "ring"] ==
               classes(
                 rendered_to_string(~H|<.navbar_user user={@user} variant="ring" />|),
                 "button"
               )

      html = rendered_to_string(~H|<.navbar_user user={@user} variant="named" />|)
      assert ["sg-nb-me", "named"] == classes(html, "button")
      assert text(html, ".sg-nb-who b") == ["Marina Costa"]
      assert text(html, ".sg-nb-who span") == ["Administradora"]
      assert classes(html, ".sg-nb-who") |> Enum.member?("col")
    end

    test "the picture instead of the initials" do
      assigns = %{user: Map.put(@user, :avatar, "/me.jpg")}
      html = rendered_to_string(~H|<.navbar_user user={@user} />|)
      assert attrs(html, ".sg-av img", "src") == ["/me.jpg"]
      assert text(html, ".sg-av") == [""]
    end

    test "with a menu: hidden, role menu, toggled by JS" do
      assigns = %{user: @user}

      html =
        rendered_to_string(~H"""
        <.navbar_user id="me" user={@user}>
          <:menu>
            <.navbar_menu_item navigate="/perfil">Perfil</.navbar_menu_item>
          </:menu>
        </.navbar_user>
        """)

      assert count(html, "div#me.sg-nb-mewrap") == 1
      assert attrs(html, "button", "id") == ["me-trigger"]
      assert attrs(html, "button", "aria-haspopup") == ["menu"]
      assert attrs(html, "button", "aria-expanded") == ["false"]
      assert attrs(html, "button", "aria-controls") == ["me-menu"]
      assert [click] = attrs(html, "button", "phx-click")
      assert click =~ "toggle_attr"
      assert click =~ "#me-menu"
      assert click =~ "#me-trigger"
      assert click =~ "toggle_class"

      assert [menu] = html |> find("#me-menu") |> Enum.to_list()
      assert LazyHTML.attribute(menu, "role") == ["menu"]
      assert LazyHTML.attribute(menu, "hidden") != []
      assert classes(html, "#me-menu") == ["sg-am", "sg-nb-menu"]

      assert [away] = attrs(html, "#me", "phx-click-away")
      assert away =~ "hidden"
      assert attrs(html, "#me", "phx-key") == ["Escape"]
      assert [_] = attrs(html, "#me", "phx-window-keydown")
    end

    test "menu pieces" do
      assigns = %{user: @user}

      html =
        rendered_to_string(~H"""
        <.navbar_menu_head user={@user}>
          <:badge><b id="badge">Admin</b></:badge>
        </.navbar_menu_head>
        <.navbar_menu_status label="Disponível">
          <:action>Mudar</:action>
        </.navbar_menu_status>
        <.navbar_menu_row label="Tema"><i id="ctl"></i></.navbar_menu_row>
        <.navbar_menu_item icon="huge-settings-02" kbd="⌘," href="/c">Configurações</.navbar_menu_item>
        <.navbar_menu_item danger href="/sair" method="delete">Sair</.navbar_menu_item>
        """)

      assert text(html, ".sg-nb-mhead .col b") == ["Marina Costa"]
      assert text(html, ".sg-nb-mhead .col span") == ["marina@lojabomfim.com.br"]
      assert text(html, ".sg-nb-mhead .sg-av") == ["MC"]
      assert text(html, ".sg-nb-mhead #badge") == ["Admin"]
      assert [status] = text(html, ".sg-nb-mstatus")
      assert status =~ "Disponível"
      assert text(html, ".sg-nb-mstatus .faint") == ["Mudar"]
      assert text(html, ".sg-nb-mrow > span") == ["Tema"]
      assert count(html, ".sg-nb-mrow #ctl") == 1
      assert attrs(html, "a[role=menuitem]", "href") == ["/c", "/sair"]
      assert text(html, "a .t") == ["Configurações", "Sair"]
      assert text(html, "a .sg-kbd") == ["⌘,"]
      assert classes(html, "a.neg") == ["neg"]
      assert count(html, "a .huge-settings-02") == 1
    end
  end
end
