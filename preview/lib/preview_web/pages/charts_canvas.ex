defmodule PreviewWeb.Pages.ChartsCanvas do
  @moduledoc """
  The ten cards of the "Componentes · Gráficos" artboard of the design canvas, drawn with the package
  (`<.chart>` and `<.kpi_card>`) and the sample data of the artboard, to compare them side by side.
  """
  use PreviewWeb.Page, title: "Charts (canvas)", category: :components

  @months ~w(Jan Fev Mar Abr Mai Jun Jul)
  @blue "#2a78d6"
  @orange "#eb6834"
  @green "#1baf7a"
  @amber "#eda100"
  @toggle %{chart: "Gráfico", table: "Tabela", label: "Visualização"}
  @pt %{defaultLocale: "pt-BR", toolbar: %{show: false}}
  @legend %{
    position: "bottom",
    horizontalAlign: "left",
    fontSize: "12.5px",
    markers: %{size: 8, shape: "square"}
  }

  def render(assigns) do
    assigns =
      assign(assigns,
        toggle: @toggle,
        revenue: area(),
        columns: columns(),
        donut: donut(),
        bars: bars(),
        sparks: sparks(),
        today: today(),
        legend: legend(),
        stacked: stacked(),
        lines: lines()
      )

    ~H"""
    <div class="grid grid-cols-1 gap-4 sm:gap-5 lg:grid-cols-3 lg:gap-6">
      <.panel title="Receita e despesas" text="Área, 2 séries · últimos 7 meses">
        <.chart
          id="cv-area"
          table_toggle={@toggle}
          options={@revenue}
          formatters={%{"yaxis.labels.formatter" => "kilo", "tooltip.y.formatter" => "brl_thousands"}}
        />
      </.panel>

      <.panel title="Receita por mês" text="Colunas agrupadas, topo arredondado de 4px">
        <.chart
          id="cv-columns"
          table_toggle={@toggle}
          options={@columns}
          formatters={%{"yaxis.labels.formatter" => "kilo", "tooltip.y.formatter" => "brl_thousands"}}
        />
      </.panel>

      <.panel title="Pedidos por canal" text="Rosca com total no centro; hover mostra a fatia">
        <.chart
          id="cv-donut"
          table_toggle={@toggle}
          options={@donut}
          formatters={%{"tooltip.y.formatter" => "number_br"}}
        />
      </.panel>

      <.panel title="Pedidos por canal" text="Barras horizontais, uma série">
        <.chart id="cv-bars" table_toggle={@toggle} options={@bars} />
      </.panel>

      <.panel
        class="lg:col-span-3"
        title="Indicadores"
        text="Sparkline: série sem eixos, cor por entidade"
      >
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div
            :for={{spark, index} <- Enum.with_index(@sparks)}
            class="grid min-w-0 gap-0.5 rounded-[10px] p-3 ring-1 ring-slate-150 ring-inset dark:ring-navy-500"
          >
            <span class="text-xs text-slate-500 dark:text-navy-200">{spark.label}</span>
            <b class="text-xl font-semibold text-slate-800 dark:text-navy-50">{spark.value}</b>
            <span class="text-xs text-slate-600 dark:text-navy-100">{spark.delta}</span>
            <.chart id={"cv-spark-#{index}"} class="mt-1.5" options={spark.options} />
          </div>
        </div>
        <p class="mt-4 text-xs leading-normal text-slate-500 dark:text-navy-200">
          O pacote desenha tudo em SVG pelo hook <code class="font-mono">LineaUI.Chart</code>, com eixos, grade, legenda e tooltip. Cada gráfico leva também uma tabela oculta com os dados, para leitores de tela.
        </p>
      </.panel>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-3 lg:col-span-3 lg:gap-6">
        <.kpi_card
          label="Receita"
          value="R$ 12.345"
          hint="Últimos 30 dias"
          spark={[0, 9, 4.5, 22.5, 18, 36, 31.5, 49.5, 40.5, 63, 72, 67.5, 90]}
          spark_type="area"
          color="info"
        />
        <.kpi_card
          label="Pedidos"
          value="1.284"
          hint="Últimos 30 dias"
          spark={[11, 0, 22.5, 17, 39.5, 28, 34, 62, 50.5, 56, 79, 73, 90]}
          spark_type="area"
          color="success"
        />
        <.kpi_card
          label="Cancelamentos"
          value="37"
          hint="Últimos 30 dias"
          spark={[90, 90, 75, 75, 60, 60, 45, 30, 30, 15, 15, 0, 0]}
          spark_type="area"
          color="error"
        />
      </div>

      <.panel title="Hoje / Ontem" text="Vendas por hora, hoje contra ontem">
        <.chart
          id="cv-today"
          summary
          options={@today}
          formatters={%{"yaxis.labels.formatter" => "brl_thousands", "tooltip.y.formatter" => "brl"}}
        />
        <p class="mt-2 text-xs leading-normal text-slate-400 dark:text-navy-300">
          O resumo acompanha o cursor; sem o cursor sobre o gráfico, mostra a última hora com dado. Hoje não tem valor depois da hora atual.
        </p>
      </.panel>

      <.panel title="Pedidos por canal" text="Rosca com legenda · este mês">
        <.chart id="cv-legend" options={@legend} formatters={%{"tooltip.y.formatter" => "number_br"}} />
      </.panel>

      <.panel title="Receita por linha" text="Colunas empilhadas · últimos 6 meses">
        <.chart
          id="cv-stacked"
          options={@stacked}
          formatters={
            %{"yaxis.labels.formatter" => "brl_thousands", "tooltip.y.formatter" => "brl_thousands"}
          }
        />
      </.panel>

      <.panel title="Conversão por canal" text="Linhas com pontos · última semana">
        <.chart
          id="cv-lines"
          options={@lines}
          formatters={%{"yaxis.labels.formatter" => "percent", "tooltip.y.formatter" => "percent"}}
        />
      </.panel>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :text, :string, default: nil
  attr :class, :any, default: nil
  slot :inner_block, required: true

  defp panel(assigns) do
    ~H"""
    <section class={[
      "min-w-0 rounded-[14px] bg-white px-5 pt-[18px] pb-4 ring-1 ring-slate-150 dark:bg-navy-700 dark:ring-navy-600",
      @class
    ]}>
      <header class="mb-3">
        <h3 class="text-sm font-semibold text-slate-800 dark:text-navy-50">{@title}</h3>
        <p :if={@text} class="mt-0.5 text-xs text-slate-400 dark:text-navy-300">{@text}</p>
      </header>
      {render_slot(@inner_block)}
    </section>
    """
  end

  defp area do
    %{
      chart: Map.merge(%{type: "area", height: 226}, @pt),
      colors: [@blue, @orange],
      series: [
        %{name: "Receita", data: Enum.map([18, 22, 19, 27, 31, 29, 36], &(&1 * 1000))},
        %{name: "Despesas", data: Enum.map([12, 14, 16, 15, 19, 21, 22], &(&1 * 1000))}
      ],
      xaxis: %{categories: @months},
      yaxis: %{min: 0, max: 40_000, tickAmount: 4},
      stroke: %{curve: "smooth", width: 2},
      fill: %{
        type: "gradient",
        gradient: %{shadeIntensity: 1, opacityFrom: 0.53, opacityTo: 0, stops: [0, 100]}
      },
      dataLabels: %{enabled: false},
      grid: %{strokeDashArray: 3},
      legend: @legend
    }
  end

  defp columns do
    %{
      chart: Map.merge(%{type: "bar", height: 226}, @pt),
      colors: [@blue, @orange],
      series: [
        %{name: "Receita", data: Enum.map([24, 28, 22, 34, 38, 33], &(&1 * 1000))},
        %{name: "Despesas", data: Enum.map([14, 16, 17, 18, 21, 20], &(&1 * 1000))}
      ],
      xaxis: %{categories: Enum.take(@months, 6)},
      yaxis: %{min: 0, max: 50_000, tickAmount: 5},
      plotOptions: %{bar: %{columnWidth: "55%", borderRadius: 4, borderRadiusApplication: "end"}},
      tooltip: %{shared: true, intersect: false},
      dataLabels: %{enabled: false},
      grid: %{strokeDashArray: 3},
      legend: @legend
    }
  end

  defp donut do
    %{
      chart: %{type: "donut", height: 190, defaultLocale: "pt-BR"},
      colors: [@blue, @orange, @green, @amber],
      labels: ["Web", "App", "Parceiros", "Outros"],
      series: [524, 349, 225, 150],
      dataLabels: %{enabled: false},
      stroke: %{width: 0},
      legend: %{
        position: "bottom",
        horizontalAlign: "left",
        fontSize: "12.5px",
        markers: %{size: 8, shape: "square"},
        showPercent: true
      },
      plotOptions: %{
        pie: %{
          donut: %{
            size: "70%",
            labels: %{show: true, total: %{show: true, label: "pedidos", formatter: "total"}}
          }
        }
      }
    }
  end

  defp bars do
    %{
      chart: %{type: "bar", height: 190, toolbar: %{show: false}},
      colors: [@blue],
      series: [%{name: "Pedidos", data: [524, 349, 225, 150, 100]}],
      xaxis: %{categories: ["Web", "App", "Parceiros", "Balcão", "Outros"]},
      plotOptions: %{
        bar: %{
          horizontal: true,
          barHeight: "55%",
          borderRadius: 4,
          borderRadiusApplication: "end",
          dataLabels: %{position: "end"}
        }
      },
      dataLabels: %{enabled: true},
      grid: %{show: false},
      legend: %{show: false}
    }
  end

  defp sparks do
    [
      {"Pedidos", "1.248", "+12% vs. mês anterior", @blue, [0, 4.3, 2.2, 13, 10.8, 21.7, 26]},
      {"Cancelamentos", "37", "−8% vs. mês anterior", @orange,
       [23.1, 17.3, 26, 14.4, 11.6, 5.8, 0]},
      {"Novos clientes", "214", "+19% vs. mês anterior", @green,
       [0, 2.4, 9.5, 7.1, 16.5, 18.9, 26]}
    ]
    |> Enum.map(fn {label, value, delta, color, data} ->
      %{
        label: label,
        value: value,
        delta: delta,
        options: %{
          chart: %{
            type: "line",
            height: 30,
            sparkline: %{enabled: true},
            animations: %{enabled: false}
          },
          colors: [color],
          series: [%{name: label, data: data}],
          stroke: %{curve: "smooth", width: 2, lineCap: "round"},
          tooltip: %{enabled: false}
        }
      }
    end)
  end

  defp today do
    hoje =
      Enum.map(0..23, fn h -> if h <= 15, do: round(cumulative(h) * 3337 / cumulative(15)) end)

    ontem = Enum.map(0..23, fn h -> round(cumulative(h) * 3062 / cumulative(15)) end)

    %{
      chart: Map.merge(%{type: "area", height: 190}, @pt),
      colors: [@blue, "#a8a8a8"],
      series: [
        %{name: "Hoje", data: hoje},
        %{name: "Ontem", data: ontem}
      ],
      xaxis: %{
        categories: Enum.map(0..23, &"#{String.pad_leading(Integer.to_string(&1), 2, "0")}:00"),
        tickAmount: 4
      },
      yaxis: %{min: 0, max: 6000, tickAmount: 3},
      stroke: %{curve: "smooth", width: [2, 1.5], dashArray: [0, 4]},
      fill: %{
        type: "gradient",
        gradient: %{shadeIntensity: 1, opacityFrom: [0.49, 0], opacityTo: 0, stops: [0, 100]}
      },
      dataLabels: %{enabled: false},
      grid: %{strokeDashArray: 3},
      legend: %{show: false}
    }
  end

  # A day of sales as an S curve: little at night, most between 08h and 20h.
  defp cumulative(hour), do: 1.0 / (1.0 + :math.exp(-(hour - 13) / 2.6))

  defp legend do
    %{
      chart: %{type: "donut", height: 330, defaultLocale: "pt-BR"},
      colors: [@blue, @orange, @green],
      labels: ["Site", "Balcão", "WhatsApp"],
      series: [664, 359, 261],
      dataLabels: %{enabled: false},
      stroke: %{width: 0},
      legend: %{
        position: "bottom",
        fontSize: "13px",
        markers: %{size: 8, shape: "square"},
        showValue: true,
        showPercent: true,
        value: %{formatter: "number_br"}
      },
      plotOptions: %{
        pie: %{
          donut: %{
            size: "72%",
            labels: %{show: true, total: %{show: true, label: "pedidos", formatter: "total"}}
          }
        }
      }
    }
  end

  defp stacked do
    %{
      chart: Map.merge(%{type: "bar", height: 226, stacked: true}, @pt),
      colors: [@blue, @orange, @green],
      series: [
        %{name: "Produtos", data: [17_200, 19_200, 21_200, 20_200, 25_000, 27_200]},
        %{name: "Serviços", data: [7_200, 8_200, 6_200, 9_200, 11_000, 11_200]},
        %{name: "Assinaturas", data: [4_000, 5_000, 5_500, 6_000, 8_000, 9_000]}
      ],
      xaxis: %{categories: Enum.take(@months, 6)},
      yaxis: %{min: 0, max: 50_000, tickAmount: 5},
      plotOptions: %{bar: %{columnWidth: "46%", borderRadius: 4}},
      tooltip: %{shared: true, intersect: false},
      dataLabels: %{enabled: false},
      grid: %{strokeDashArray: 3},
      legend: @legend
    }
  end

  defp lines do
    %{
      chart: Map.merge(%{type: "line", height: 198}, @pt),
      colors: [@blue, @orange, @green],
      series: [
        %{name: "Site", data: [3.1, 3.4, 3.2, 3.9, 4.4, 4.2, 5.0]},
        %{name: "App", data: [2.2, 2.6, 3.0, 2.8, 3.3, 3.6, 3.9]},
        %{name: "Balcão", data: [4.0, 3.8, 4.1, 3.7, 3.9, 3.6, 3.8]}
      ],
      xaxis: %{categories: ~w(Seg Ter Qua Qui Sex Sáb Dom)},
      yaxis: %{min: 0, max: 6, tickAmount: 3},
      stroke: %{curve: "smooth", width: 2},
      markers: %{size: 3.5},
      dataLabels: %{enabled: false},
      grid: %{strokeDashArray: 3},
      legend: @legend
    }
  end
end
