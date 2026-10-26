defmodule LineaUI.Components.ConnectionBannerTest do
  use LineaUI.ComponentCase, async: true

  defp attr_of(html, selector, name),
    do: html |> find(selector) |> LazyHTML.attribute(name) |> hd()

  test "draws nothing: it is a hidden marker" do
    html = render(~H|<.connection_banner />|)

    assert find(html, "#linea-connection-banner") |> LazyHTML.attribute("hidden") != []
    assert LazyHTML.text(find(html, "#linea-connection-banner")) |> String.trim() == ""
  end

  test "a disconnect shows a loading toast with an aura, a connect dismisses it" do
    html =
      render(~H|<.connection_banner title="Sem conexão" description="Tentando reconectar" />|)

    down = attr_of(html, "#linea-connection-banner", "phx-disconnected")
    up = attr_of(html, "#linea-connection-banner", "phx-connected")

    assert down =~ "linea:toast"
    assert down =~ "Sem conexão"
    assert down =~ "Tentando reconectar"
    assert down =~ "loading"
    assert down =~ "linea-connection-banner-toast"
    assert up =~ "linea:toast-dismiss"
    assert up =~ "linea-connection-banner-toast"
  end
end
