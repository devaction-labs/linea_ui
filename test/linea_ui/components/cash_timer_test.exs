defmodule LineaUI.Components.CashTimerTest do
  use LineaUI.ComponentCase, async: true

  test "an open register shows the clock, ticking with the timer hook" do
    html =
      render(~H|<.cash_timer
  id="c"
  title="Caixa 2 aberto"
  subtitle="desde 08:00"
  elapsed={24_130}
  amount="R$ 6.412,30"
/>|)

    assert LazyHTML.attribute(find(html, "#c"), "phx-hook") == ["LineaUI.Timer"]
    assert LazyHTML.attribute(find(html, "#c"), "data-elapsed") == ["24130"]
    assert find(html, "#c [data-time]") |> LazyHTML.text() == "06:42:10"
    assert find(html, "#c .linea-cash-amount") |> LazyHTML.text() == "R$ 6.412,30"
    assert "pos" in classes(html, "#c .sg-ic")
  end

  test "a closed register takes an action; an alert a difference and stats" do
    closed =
      render(~H"""
      <.cash_timer id="c" state="closed" title="Caixa 2 fechado">
        <:action><button id="open">Abrir caixa</button></:action>
      </.cash_timer>
      """)

    alert =
      render(~H"""
      <.cash_timer id="a" state="alert" title="Conferência" difference="− R$ 12,50">
        <:stat label="Esperado">R$ 6.412,30</:stat>
        <:stat label="Contado">R$ 6.399,80</:stat>
      </.cash_timer>
      """)

    assert LazyHTML.attribute(find(closed, "#c"), "phx-hook") == []
    assert [_] = find(closed, "#c #open") |> Enum.to_list()
    assert "warn" in classes(alert, "#a .sg-ic")
    assert find(alert, "#a .linea-cash-diff") |> LazyHTML.text() == "− R$ 12,50"
    assert find(alert, "#a .sg-stat dt") |> Enum.map(&LazyHTML.text/1) == ["Esperado", "Contado"]
  end
end
