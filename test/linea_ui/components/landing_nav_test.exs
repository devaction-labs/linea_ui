defmodule LineaUI.Components.LandingNavTest do
  use LineaUI.ComponentCase, async: true

  import LineaUI.Components.LandingNav

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)
  defp count(html, selector), do: html |> find(selector) |> Enum.count()

  defp text(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

  defp nav(variant) do
    assigns = %{variant: variant}

    rendered_to_string(~H"""
    <.landing_nav id="nav" variant={@variant} brand={%{name: "Linea", logo: "L", href: "/"}}>
      <:link label="Produto">
        <.landing_mega>
          <.landing_feature
            icon="huge-kanban"
            title="Projetos"
            description="Kanban e prazos"
            href="/p"
          />
          <.landing_feature icon="huge-shield-01" title="Segurança" description="2FA" href="/s" />
          <:side>
            <.landing_mega_side eyebrow="Novidade" title="Kanban" thumb link_label="Ver" href="/n">
              Arraste tarefas.
            </.landing_mega_side>
          </:side>
        </.landing_mega>
      </:link>
      <:link label="Preços" href="/precos" active />
      <:link label="Docs" href="/docs" />
      <:actions>
        <.landing_login href="/entrar">Entrar</.landing_login>
        <.landing_cta href="/cadastro" icon="huge-arrow-right-02">Começar</.landing_cta>
      </:actions>
    </.landing_nav>
    """)
  end

  test "the classic bar: brand, links, login and cta" do
    html = nav("default")

    assert ["sg-lp-bar"] == classes(html, "div[data-variant]")
    assert ["sg-lp-nb"] == classes(html, "header")
    assert text(html, ".sg-nb-logo") == ["L"]
    assert text(html, ".sg-nb-brand") == ["Linea"]
    assert count(html, ".sg-lp-floatwrap") == 0
    assert text(html, ".sg-lp-links a") == ["Preços", "Docs"]
    assert attr_of(html, ".sg-lp-links a[aria-current]", "aria-current") == ["page"]
    assert text(html, ".sg-nb-end .sg-lp-login") == ["Entrar"]
    assert ["sg-lp-cta"] == classes(html, ".sg-nb-end a.sg-lp-cta")
  end

  test "float wraps the bar, clear and mobile mark it" do
    float = nav("float")
    assert count(float, ".sg-lp-floatwrap > header.sg-lp-nb.float") == 1
    assert attr_of(float, "div[data-variant]", "data-variant") == ["float"]
    assert count(nav("clear"), "header.sg-lp-nb.clear") == 1
    assert count(nav("mobile"), "header.sg-lp-nb.mob") == 1
  end

  test "sticky mounts the scroll hook; otherwise there is none" do
    sticky =
      render(~H"""
      <.landing_nav id="s" sticky stuck_after={24} variant="clear" />
      """)

    assert attr_of(sticky, "#s", "phx-hook") == ["LineaUI.LandingNav"]
    assert attr_of(sticky, "#s", "data-stuck-after") == ["24"]
    assert count(sticky, "#s[data-sticky]") == 1
    assert count(sticky, "#s[data-stuck]") == 0
    assert attr_of(nav("default"), "#nav", "phx-hook") == []
  end

  test "a link with content is a closed mega trigger with a hidden panel" do
    html = nav("default")

    assert attr_of(html, "button#nav-trigger-1", "aria-expanded") == ["false"]
    assert attr_of(html, "button#nav-trigger-1", "aria-controls") == ["nav-mega-1"]
    assert text(html, "button#nav-trigger-1") == ["Produto"]
    assert attr_of(html, "#nav-mega-1", "style") == ["display: none"]
    assert count(html, "#nav-mega-1.sg-lp-mega") == 1
    assert count(html, "#nav-trigger-2") == 0
    assert count(html, "#nav-mega-2") == 0
    assert [click] = attr_of(html, "#nav-trigger-1", "phx-click")
    assert click =~ "nav-mega-1"
    assert attr_of(html, "#nav", "phx-key") == ["Escape"]
    assert attr_of(html, "#nav", "phx-click-away") != []
  end

  test "features and the side panel" do
    html = nav("default")

    assert text(html, "#nav-mega-1 .sg-lp-feat b") == ["Projetos", "Segurança"]
    assert text(html, "#nav-mega-1 .sg-lp-feat .col span") == ["Kanban e prazos", "2FA"]
    assert attr_of(html, "#nav-mega-1 .sg-lp-feat", "href") == ["/p", "/s"]
    assert count(html, "#nav-mega-1 .sg-lp-feat .ic span.huge-kanban") == 1
    assert count(html, "#nav-mega-1 .sg-lp-grid") == 1
    assert text(html, ".sg-lp-megaside .sg-lp-eb") == ["Novidade"]
    assert text(html, ".sg-lp-megaside b") == ["Kanban"]
    assert count(html, ".sg-lp-megaside .sg-lp-thumb i") == 4
    assert attr_of(html, ".sg-lp-megaside a", "href") == ["/n"]
  end

  test "the phone menu: a button and a hidden panel with every link and the actions" do
    html = nav("default")

    assert attr_of(html, "button.sg-ib.sg-lp-menubtn", "aria-expanded") == ["false"]
    assert attr_of(html, "button.sg-lp-menubtn", "aria-controls") == ["nav-mmenu"]
    assert attr_of(html, "#nav-mmenu", "style") == ["display: none"]
    assert text(html, "#nav-mmenu .sg-lp-mi") == ["Produto", "Preços", "Docs"]
    assert count(html, "#nav-mmenu .sg-lp-mmenu-end .sg-lp-cta") == 1
    assert count(html, "#nav-mmenu .sg-lp-mmenu-end .sg-lp-login") == 1
  end

  test "navigate and patch links, the logo slot" do
    html =
      render(~H"""
      <.landing_nav id="n">
        <:logo><span id="mine">mine</span></:logo>
        <:link label="A" navigate="/a" />
        <:link label="B" patch="/b" />
      </.landing_nav>
      """)

    assert count(html, "#mine") == 1
    assert count(html, ".sg-nb-logo") == 0
    assert attr_of(html, ".sg-lp-links a", "data-phx-link") == ["redirect", "patch"]
    assert attr_of(html, ".sg-lp-links a", "href") == ["/a", "/b"]
  end

  test "cta sizes, block, icon and the button form" do
    html =
      render(~H"""
      <.landing_cta>Plain</.landing_cta>
      <.landing_cta size="lg" block icon="huge-arrow-right-02" href="/x">Go</.landing_cta>
      """)

    assert ["sg-lp-cta"] == classes(html, "button")
    assert ["sg-lp-cta", "lg", "block"] == classes(html, "a")
    assert count(html, "a .huge-arrow-right-02") == 1
  end

  test "the announcement with a link and a close that hides it" do
    html =
      render(~H"""
      <.landing_announcement id="ann" eyebrow="Novo" link_label="Ver" href="/n">
        Kanban chegou
      </.landing_announcement>
      <.landing_announcement id="fixed" dismissible={false}>Fixo</.landing_announcement>
      """)

    assert ["sg-lp-ann"] == classes(html, "#ann")
    assert text(html, "#ann .sg-lp-eb.light") == ["Novo"]
    assert attr_of(html, "#ann a", "href") == ["/n"]
    assert [click] = attr_of(html, "#ann button", "phx-click")
    assert click =~ "#ann"
    assert click =~ "hide"
    assert count(html, "#fixed button") == 0
  end

  describe "landing_mega variant=cards" do
    test "product cards side by side, each one a link with its logo, title, link label and preview" do
      html =
        render(~H"""
        <.landing_mega variant="cards">
          <.landing_product
            name="Cloud"
            logo="huge-cloud"
            title="Publique rápido"
            link_label="Publicar"
            href="/cloud"
            mock
          />
          <.landing_product
            name="Forge"
            title="Servidores"
            link_label="Gerenciar"
            navigate="/forge"
            tone="tint"
          >
            <:preview><img src="/forge.png" alt="" /></:preview>
          </.landing_product>
          <.landing_product title="Observe tudo" href="/watch" tone="dark">
            <:mark><svg viewBox="0 0 24 24"></svg></:mark>
          </.landing_product>
        </.landing_mega>
        """)

      assert count(html, ".sg-lp-cards > a.sg-lp-prod") == 3
      assert count(html, ".sg-lp-grid") == 0
      assert attr_of(html, ".sg-lp-prod", "href") == ["/cloud", "/forge", "/watch"]
      assert text(html, ".sg-lp-prod .t") == ["Publique rápido", "Servidores", "Observe tudo"]
      assert text(html, ".sg-lp-prod .go") == ["Publicar", "Gerenciar"]
      assert text(html, ".sg-lp-prod .hd > span:not(.lg):not(.mk)") == ["Cloud", "Forge"]
      assert count(html, ".sg-lp-prod .lg") == 1
      assert count(html, ".sg-lp-prod .mk svg") == 1
      assert count(html, ".sg-lp-prod .pv.mock[aria-hidden=true]") == 1
      assert attr_of(html, ".sg-lp-prod .pv img", "src") == ["/forge.png"]
      assert "tint" in classes(html, ".sg-lp-prod[href='/forge']")
      assert "dark" in classes(html, ".sg-lp-prod[href='/watch']")
      refute "dark" in classes(html, ".sg-lp-prod[href='/cloud']")
    end

    test "columns sets how many cards fit in a row" do
      html =
        render(~H"""
        <.landing_mega variant="cards" columns={2}>
          <.landing_product title="A" />
        </.landing_mega>
        """)

      assert attr_of(html, ".sg-lp-cards", "style") == ["--n:2"]

      css = File.read!("assets/css/parts/canvas-landing-nav.css")
      assert css =~ ".sg-lp-cards:has(>:only-child){--n:1}"
      assert css =~ ".sg-lp-cards:has(>:nth-child(2):last-child){--n:2}"
      assert css =~ ".sg-lp-prod.dark:focus-visible{"
      assert count(html, ".sg-lp-prod .pv") == 0
    end

    test "accent gives a card its own color, and mock draws an app screen" do
      html = render(~H|<.landing_product title="A" accent="#2563eb" mock />|)

      assert attr_of(html, ".sg-lp-prod", "style") == ["--accent:#2563eb;--accent-ink:#2563eb"]
      assert count(html, ".pv.mock .top") == 1
      assert count(html, ".pv.mock .row") == 4
      assert render(~H|<.landing_product title="A" />|) |> attr_of(".sg-lp-prod", "style") == []
    end
  end
end
