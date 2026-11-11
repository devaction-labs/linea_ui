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

  test "auth_sent: the tile with the mail icon, the message, polite status" do
    html = render(~H"<.auth_sent class=\"x\">Abra o <b>e-mail</b>.</.auth_sent>")

    assert attr_of(html, ".linea-auth-sent", "role") == ["status"]
    assert "x" in classes(html, ".linea-auth-sent")
    assert attr_of(html, ".linea-auth-sent .tile svg", "aria-hidden") == ["true"]
    assert text(html, ".linea-auth-sent > span:not(.tile)") == ["Abra o e-mail."]
  end

  test "auth_sent: the :icon slot replaces the mail icon" do
    html = render(~H"<.auth_sent><:icon><i id=\"mine\"></i></:icon>Oi</.auth_sent>")

    assert [_] = find(html, ".tile #mine") |> Enum.to_list()
    assert find(html, ".tile svg") |> Enum.to_list() == []
  end

  test "auth_alert: the icon and the message, as an alert" do
    html = render(~H"<.auth_alert>Corrija os campos.</.auth_alert>")

    assert attr_of(html, ".linea-auth-alert", "role") == ["alert"]
    assert attr_of(html, ".linea-auth-alert svg", "aria-hidden") == ["true"]
    assert text(html, ".linea-auth-alert") == ["Corrija os campos."]
  end

  test "auth_submit: idle is a plain submit button" do
    html = render(~H"<.auth_submit>Cadastrar</.auth_submit>")

    assert attr_of(html, "button", "type") == ["submit"]
    assert classes(html, "button") |> Enum.sort() == ~w(accent block lg sg-btn)
    assert find(html, ".linea-auth-spin") |> Enum.to_list() == []
    assert attr_of(html, "button", "disabled") == []
    assert attr_of(html, "button", "aria-busy") == []
    assert text(html, "button") == ["Cadastrar"]
  end

  test "auth_submit: loading disables, marks aria-busy and shows the spinner and the label" do
    html =
      render(~H"""
      <.auth_submit loading loading_label="Criando a conta…">Cadastrar</.auth_submit>
      """)

    assert [_] = find(html, "button.is-loading > .linea-auth-spin") |> Enum.to_list()
    assert attr_of(html, ".linea-auth-spin", "aria-hidden") == ["true"]
    assert attr_of(html, "button", "disabled") == [""]
    assert attr_of(html, "button", "aria-busy") == ["true"]
    assert text(html, "button") == ["Criando a conta…"]
  end

  test "auth_submit: loading without loading_label keeps the label" do
    html = render(~H"<.auth_submit loading>Cadastrar</.auth_submit>")

    assert text(html, "button") == ["Cadastrar"]
  end
end
