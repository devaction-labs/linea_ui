defmodule PreviewWeb.Pages.KpiCard do
  use PreviewWeb.Page, title: "KPI card", category: :components

  def render(assigns) do
    ~H"""
    <.example
      title="Metric cards"
      text="A figure, how it moved, and a sparkline, bars or a progress toward a goal."
      class="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3"
    >
      <.kpi_card
        label="Faturamento"
        value="R$ 482,3 mil"
        delta="12,4%"
        trend="up"
        hint="vs. setembro"
        spark={[40, 52, 47, 61, 58, 70, 77, 74, 90]}
      >
        <:icon><.icon name="huge-money-bag-01" class="size-4" /></:icon>
      </.kpi_card>
      <.kpi_card
        label="Pedidos"
        value="1.284"
        delta="3,1%"
        trend="down"
        hint="vs. setembro"
        spark={[22, 32, 26, 40, 31, 28, 35, 24, 18, 14]}
        spark_type="bar"
      />
      <.kpi_card
        label="Ticket médio"
        value="R$ 375"
        unit=",60"
        delta="0,0%"
        trend="flat"
        hint="estável no mês"
        spark={[5, 6, 5, 7, 6, 5, 6, 6]}
      />
      <.kpi_card label="Meta do trimestre" value="78%" goal={78}>
        <:footer>
          <span>R$ 1,17 mi de R$ 1,5 mi</span><span>faltam 23 dias</span>
        </:footer>
      </.kpi_card>
      <.kpi_card
        label="Inadimplência"
        value="2,4%"
        delta="0,6 p.p."
        trend="up"
        delta_tone="error"
        hint="pior que o mês anterior"
        spark={[10, 12, 11, 15, 18, 17, 21]}
        color="error"
      />
      <.kpi_card loading />
    </.example>
    """
  end
end
