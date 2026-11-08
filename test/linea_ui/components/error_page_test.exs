defmodule LineaUI.Components.ErrorPageTest do
  use LineaUI.ComponentCase, async: true

  defp text(html, selector),
    do: html |> find(selector) |> Enum.map(&LazyHTML.text/1) |> Enum.map(&String.trim/1)

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "error_page takes the defaults of the code" do
    html = render(~H|<.error_page code={404} />|)

    assert ["sg-err"] == classes(html, "#error-page")
    assert attr_of(html, "#error-page", "data-tone") == ["neutral"]
    assert text(html, ".sg-err-code") == ["404"]
    assert text(html, ".sg-err-title") == ["We couldn't find this page."]
    assert text(html, ".sg-err-digits") == ["404"]
    assert attr_of(html, ".sg-err-art", "aria-hidden") == ["true"]
    assert find(html, ".sg-err-foot") |> Enum.to_list() == []
  end

  test "the tone follows the code and can be overridden" do
    assert attr_of(render(~H|<.error_page code={500} />|), ".sg-err", "data-tone") == ["error"]
    assert attr_of(render(~H|<.error_page code={503} />|), ".sg-err", "data-tone") == ["accent"]
    assert attr_of(render(~H|<.error_page code="off" />|), ".sg-err", "data-tone") == ["warning"]

    assert attr_of(render(~H|<.error_page code={418} tone="accent" />|), ".sg-err", "data-tone") ==
             ["accent"]

    assert attr_of(render(~H|<.error_page code={599} />|), ".sg-err", "data-tone") == ["error"]
  end

  test "error_page with texts, slots and the request id" do
    html =
      render(~H"""
      <.error_page
        code={403}
        label="Acesso negado"
        title="Sem acesso"
        description="Peça acesso."
        request_id="req_1"
        timestamp="06/11/2026 08:41"
      >
        <:brand><b id="brand">Linea</b></:brand>
        <:status href="/status" status="warning">Instabilidade</:status>
        <:actions><a id="home" href="/">Início</a></:actions>
        <.error_links title="Quem pode liberar">
          <:link href="mailto:a@b.c" icon="huge-user" description="Administrador">Alex</:link>
        </.error_links>
        <:card><span id="card">Permissões</span></:card>
        <:footer><a href="/ajuda">Ajuda</a></:footer>
      </.error_page>
      """)

    assert text(html, ".sg-err-label") == ["403Acesso negado"]
    assert text(html, ".sg-err-desc") == ["Peça acesso."]
    assert [_] = find(html, ".sg-err-top #brand") |> Enum.to_list()
    assert attr_of(html, ".sg-err-status", "data-status") == ["warning"]
    assert attr_of(html, ".sg-err-status", "href") == ["/status"]
    assert [_] = find(html, ".sg-err-actions #home") |> Enum.to_list()
    assert text(html, ".sg-err-links .t b") == ["Alex"]
    assert text(html, ".sg-err-links .t span") == ["Administrador"]
    assert [_] = find(html, ".sg-err-card #card") |> Enum.to_list()
    assert attr_of(html, ".sg-err-art", "aria-hidden") in [[], [nil]]
    assert text(html, ".sg-err-foot code") == ["req_1"]
    assert attr_of(html, "#error-page-copy", "aria-label") == ["Copy request ID"]
    assert text(html, ".sg-err-foot .end") == ["Ajuda"]
  end

  test "error_page without the copy button" do
    html = render(~H|<.error_page code={500} request_id="req_2" copy={false} />|)
    assert find(html, "#error-page-copy") |> Enum.to_list() == []
  end

  test "error_state: the code with the icon tile, centered" do
    html =
      render(~H"""
      <.error_state code={404} title="Pedido #2499 não encontrado">
        Pode ter sido excluído.
        <:actions><a id="all" href="/pedidos">Ver todos</a></:actions>
        <:more>
          <table id="recent"></table>
        </:more>
      </.error_state>
      """)

    assert ["sg-err-state"] == classes(html, "section")
    assert text(html, "h1") == ["Pedido #2499 não encontrado"]
    assert text(html, "p") == ["Pode ter sido excluído."]
    assert "huge-search-01" in classes(html, ".tile > span")
    assert [_] = find(html, ".more #recent") |> Enum.to_list()
  end

  test "error_state falls back to the description and the icon of the code" do
    html = render(~H|<.error_state code={500} icon="huge-copy-01" />|)

    assert text(html, "p") == [
             "Nothing you did caused this. The team got the error report and your data is safe; try again in a moment."
           ]

    assert "huge-copy-01" in classes(html, ".tile > span")
    assert attr_of(html, "section", "data-tone") == ["error"]
  end

  test "error_state derives the title id from id, and keeps err-<code>-title without it" do
    html = render(~H|<.error_state code={404} id="orders-missing" />|)
    assert attr_of(html, "section", "id") == ["orders-missing"]
    assert attr_of(html, "section", "aria-labelledby") == ["orders-missing-title"]
    assert attr_of(html, "h1", "id") == ["orders-missing-title"]

    html = render(~H|<.error_state code={404} />|)
    assert attr_of(html, "section", "aria-labelledby") == ["err-404-title"]
    assert attr_of(html, "h1", "id") == ["err-404-title"]
  end

  test "error_state has no label attr and error_page still defaults its label" do
    refute Enum.any?(
             LineaUI.Components.ErrorPage.__components__().error_state.attrs,
             &(&1.name == :label)
           )

    html = render(~H|<.error_page code={404} />|)
    assert text(html, ".sg-err-label") == ["404Page not found"]
  end
end
