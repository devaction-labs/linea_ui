defmodule LineaUI.Components.KpiCardTest do
  use LineaUI.ComponentCase, async: true

  test "renders label, figure, change and sparkline" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kpi_card
        label="Faturamento"
        value="R$ 482"
        delta="12,4%"
        trend="up"
        hint="vs. setembro"
        spark={[1, 3, 2, 5]}
      />
      """)

    assert html =~ "Faturamento"
    assert html =~ "R$ 482"
    assert html =~ "12,4%"
    assert html =~ "bg-success/10"
    assert html =~ "vs. setembro"
    assert html =~ "<svg"
    assert html =~ "vector-effect"
  end

  test "a rise can be bad, bars and goal" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kpi_card
        label="Inad."
        value="2,4%"
        delta="0,6"
        trend="up"
        delta_tone="error"
        spark={[1, 2, 3]}
        spark_type="bar"
        goal={78}
      />
      """)

    assert html =~ "bg-error/10"
    assert html =~ ~s(aria-valuenow="78")
    refute html =~ "vector-effect"
  end

  test "loading and a flat series" do
    assigns = %{}

    assert rendered_to_string(~H"""
           <.kpi_card loading />
           """) =~ "aria-busy"

    assert rendered_to_string(~H"""
           <.kpi_card value="1" spark={[2, 2, 2]} />
           """) =~ "<svg"
  end
end
