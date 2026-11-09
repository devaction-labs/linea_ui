defmodule LineaUI.Components.AuthSplitTest do
  use LineaUI.ComponentCase, async: true

  defp text(html, selector),
    do: html |> find(selector) |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

  defp attr_of(html, selector, name), do: html |> find(selector) |> LazyHTML.attribute(name)

  test "the form on the left, the picture with the testimonial on the right" do
    html =
      render(~H"""
      <.auth_split
        title="Criar conta"
        subtitle="Preencha seus dados."
        src="/auth.jpg"
        divider_label="Ou"
      >
        <:brand><b id="brand">Linea</b></:brand>
        <:providers>
          <.oauth_button provider="google" href="/auth/google">Google</.oauth_button>
          <.oauth_button provider="apple">Apple</.oauth_button>
        </:providers>
        <form id="f"></form>
        <:quote author="Marina Costa" role="Gerente" rating={4}>Em uma semana todos usavam.</:quote>
        <:footer>Já tem conta? <a href="/entrar">Entrar</a></:footer>
      </.auth_split>
      """)

    assert attr_of(html, ".linea-auth", "data-aside") == ["picture"]
    assert [_] = find(html, ".linea-auth-brand #brand") |> Enum.to_list()
    assert text(html, "h1.linea-auth-title") == ["Criar conta"]
    assert text(html, ".linea-auth-sub") == ["Preencha seus dados."]
    assert attr_of(html, ".linea-auth-providers a.linea-oauth", "href") == ["/auth/google"]
    assert "huge-google" in classes(html, ".linea-auth-providers a.linea-oauth > span")
    assert attr_of(html, ".linea-auth-providers button.linea-oauth", "type") == ["button"]
    assert html =~ ~s(<div class="sg-divider" role="separator">Ou</div>)
    assert [_] = find(html, ".linea-auth-body #f") |> Enum.to_list()
    assert attr_of(html, ".linea-auth-aside img", "src") == ["/auth.jpg"]
    assert text(html, ".linea-auth-quote blockquote") == ["Em uma semana todos usavam."]
    assert attr_of(html, ".linea-auth-stars", "aria-label") == ["4 / 5"]
    assert length(find(html, ".linea-auth-stars svg.off") |> Enum.to_list()) == 1
    assert text(html, ".linea-auth-who b") == ["Marina Costa"]
    assert text(html, ".linea-auth-foot a") == ["Entrar"]
  end

  test "without a picture the form takes the card" do
    html = render(~H|<.auth_split title="Entrar" variant="full" glow={false}>
  <form></form>
</.auth_split>|)

    assert attr_of(html, ".linea-auth", "data-aside") == ["none"]
    assert attr_of(html, ".linea-auth", "data-variant") == ["full"]
    assert attr_of(html, ".linea-auth", "data-glow") == ["false"]
    assert find(html, ".linea-auth-aside") |> Enum.to_list() == []
    assert find(html, ".linea-auth-providers") |> Enum.to_list() == []
  end

  test "the aside slot replaces the right half" do
    html =
      render(~H"""
      <.auth_split title="Entrar">
        <form></form>
        <:aside>
          <div id="custom"></div>
        </:aside>
      </.auth_split>
      """)

    assert [_] = find(html, ".linea-auth-aside #custom") |> Enum.to_list()
    assert find(html, ".linea-auth-quote") |> Enum.to_list() == []
  end
end
