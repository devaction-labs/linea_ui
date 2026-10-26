defmodule LineaUI.Components.ConnectionBannerTest do
  use LineaUI.ComponentCase, async: true

  test "hidden at rest, shown on disconnect and hidden again on connect" do
    html = render(~H|<.connection_banner />|)
    [cls] = find(html, "#linea-connection-banner") |> LazyHTML.attribute("class")

    assert cls =~ "hidden"
    assert find(html, "#linea-connection-banner") |> LazyHTML.attribute("role") == ["status"]
    assert find(html, "#linea-connection-banner") |> LazyHTML.attribute("phx-disconnected") != []
    assert find(html, "#linea-connection-banner") |> LazyHTML.attribute("phx-connected") != []
  end

  test "texts, position and id are configurable" do
    html =
      render(~H|<.connection_banner
  id="cb"
  title="Sem conexão"
  description="Tentando reconectar"
  position="bottom"
/>|)

    assert LazyHTML.text(find(html, "#cb")) =~ "Sem conexão"
    assert LazyHTML.text(find(html, "#cb")) =~ "Tentando reconectar"
    assert find(html, "#cb") |> LazyHTML.attribute("data-position") == ["bottom"]
    assert find(html, "#cb") |> LazyHTML.attribute("class") |> hd() =~ "bottom-4"
  end
end
