defmodule PreviewWeb.Pages.Apexcharts do
  use PreviewWeb.Page,
    title: "Apexcharts",
    category: :components,
    lineone: "components-apexcharts"

  @no_toolbar %{show: false}
  @grid_lines %{xaxis: %{lines: %{show: true}}, yaxis: %{lines: %{show: true}}}

  @candles [
    {1_538_778_600_000, [6629.81, 6650.5, 6623.04, 6633.33]},
    {1_538_780_400_000, [6632.01, 6643.59, 6620, 6630.11]},
    {1_538_782_200_000, [6630.71, 6648.95, 6623.34, 6635.65]},
    {1_538_784_000_000, [6635.65, 6651, 6629.67, 6638.24]},
    {1_538_785_800_000, [6638.24, 6640, 6620, 6624.47]},
    {1_538_787_600_000, [6624.53, 6636.03, 6621.68, 6624.31]},
    {1_538_789_400_000, [6624.61, 6632.2, 6617, 6626.02]},
    {1_538_791_200_000, [6627, 6627.62, 6584.22, 6603.02]},
    {1_538_793_000_000, [6605, 6608.03, 6598.95, 6604.01]},
    {1_538_794_800_000, [6604.5, 6614.4, 6602.26, 6608.02]},
    {1_538_796_600_000, [6608.02, 6610.68, 6601.99, 6608.91]},
    {1_538_798_400_000, [6608.91, 6618.99, 6608.01, 6612]},
    {1_538_800_200_000, [6612, 6615.13, 6605.09, 6612]},
    {1_538_802_000_000, [6612, 6624.12, 6608.43, 6622.95]},
    {1_538_803_800_000, [6623.91, 6623.91, 6615, 6615.67]},
    {1_538_805_600_000, [6618.69, 6618.74, 6610, 6610.4]},
    {1_538_807_400_000, [6611, 6622.78, 6610.4, 6614.9]},
    {1_538_809_200_000, [6614.9, 6626.2, 6613.33, 6623.45]},
    {1_538_811_000_000, [6623.48, 6627, 6618.38, 6620.35]},
    {1_538_812_800_000, [6619.43, 6620.35, 6610.05, 6615.53]},
    {1_538_814_600_000, [6615.53, 6617.93, 6610, 6615.19]},
    {1_538_816_400_000, [6615.19, 6621.6, 6608.2, 6620]},
    {1_538_818_200_000, [6619.54, 6625.17, 6614.15, 6620]},
    {1_538_820_000_000, [6620.33, 6634.15, 6617.24, 6624.61]},
    {1_538_821_800_000, [6625.95, 6626, 6611.66, 6617.58]},
    {1_538_823_600_000, [6619, 6625.97, 6595.27, 6598.86]}
  ]

  def render(assigns) do
    assigns =
      assign(assigns,
        left: [
          {"Area Chart", area()},
          {"Bar Chart", gradient_area()},
          {"Candlestick", horizontal_bar()},
          {"Bubble Chart", gradient_line()},
          {"Radar Chart", candlestick()}
        ],
        right: [
          {"Area Chart", stacked_bar()},
          {"Line Chart", scatter()},
          {"Column Chart", radial_bar()},
          {"Radialbar Chart", radar()},
          {"Polar Area Chart", polar_area()}
        ]
      )

    ~H"""
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 lg:gap-6">
      <div class="space-y-4 sm:space-y-5 lg:space-y-6">
        <.chart_card
          :for={{{title, options}, index} <- Enum.with_index(@left, 1)}
          title={title}
          id={"chart-#{index}"}
          options={options}
        />
      </div>
      <div class="space-y-4 sm:space-y-5 lg:space-y-6">
        <.chart_card
          :for={{{title, options}, index} <- Enum.with_index(@right, 6)}
          title={title}
          id={"chart-#{index}"}
          options={options}
        />
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :id, :string, required: true
  attr :options, :map, required: true

  defp chart_card(assigns) do
    ~H"""
    <.example title={@title} class="max-w-xl">
      <p>
        <a
          href="https://github.com/apexcharts/apexcharts.js"
          class="font-normal text-primary transition-colors hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
        >
          Apexcharts
        </a>
        a modern JavaScript charting library that allows you to build interactive data visualizations with simple API and many samples. Check out code for detail of usage.
      </p>
      <div class="mt-5">
        <.chart id={@id} options={@options} />
      </div>
    </.example>
    """
  end

  defp area do
    %{
      colors: ["#34d399", "#ffba1a"],
      series: [
        %{name: "Series1", data: [31, 40, 28, 51, 42, 109, 100]},
        %{name: "Series2", data: [11, 32, 45, 32, 34, 52, 41]}
      ],
      chart: %{height: 350, type: "area", toolbar: @no_toolbar},
      dataLabels: %{enabled: false},
      stroke: %{curve: "smooth"},
      xaxis: %{
        type: "datetime",
        categories:
          Enum.map(~w(00:00 01:30 02:30 03:30 04:30 05:30 06:30), &"2018-09-19T#{&1}:00.000Z")
      },
      tooltip: %{x: %{format: "dd/MM/yy HH:mm"}},
      legend: %{position: "top", horizontalAlign: "left", fontSize: "14px"}
    }
  end

  defp gradient_area do
    %{
      colors: ["#6366f1", "#ffba1a"],
      series: [
        %{name: "PRODUCT B", data: [45, 75, 50, 70, 85, 90, 70, 62]},
        %{name: "PRODUCT A", data: [30, 16, 27, 30, 55, 60, 48, 43]}
      ],
      chart: %{type: "area", stacked: false, height: 350, toolbar: @no_toolbar},
      dataLabels: %{enabled: false},
      markers: %{size: 0},
      fill: %{
        type: "gradient",
        gradient: %{
          shadeIntensity: 1,
          inverseColors: false,
          opacityFrom: 0.35,
          opacityTo: 0.05,
          stops: [20, 100, 100, 100]
        }
      },
      tooltip: %{shared: true},
      legend: %{position: "top", horizontalAlign: "right", offsetX: -10},
      grid: @grid_lines
    }
  end

  defp horizontal_bar do
    %{
      colors: ["#ff9800", "#6366f1"],
      series: [
        %{name: "Net Profit", data: [44, 55, 57, 56, 61, 58, 63]},
        %{name: "Revenue", data: [76, 85, 101, 98, 87, 105, 91]}
      ],
      chart: %{type: "bar", height: 350, toolbar: @no_toolbar},
      plotOptions: %{bar: %{horizontal: true, columnWidth: "55%", borderRadius: 5}},
      dataLabels: %{enabled: false},
      stroke: %{show: true, width: 2, colors: ["transparent"]},
      xaxis: %{categories: ~w(Feb Mar Apr May Jun Jul Aug)},
      fill: %{opacity: 1},
      legend: %{
        position: "top",
        horizontalAlign: "right",
        fontSize: "14px",
        markers: %{radius: 12}
      }
    }
  end

  defp gradient_line do
    %{
      colors: ["#a855f7"],
      series: [%{name: "Sales", data: [14, 13, 10, 9, 19, 22, 25]}],
      chart: %{
        height: 350,
        type: "line",
        dropShadow: %{enabled: true, color: "#1E202C", top: 18, left: 6, blur: 8, opacity: 0.1}
      },
      stroke: %{width: 8, curve: "smooth"},
      xaxis: %{
        type: "datetime",
        categories: Enum.map(1..7, &"#{&1}/11/2000"),
        tickAmount: 10
      },
      fill: %{
        type: "gradient",
        gradient: %{
          shade: "dark",
          gradientToColors: ["#86efac"],
          shadeIntensity: 1,
          type: "horizontal",
          opacityFrom: 1,
          opacityTo: 0.95,
          stops: [0, 100, 0, 100]
        }
      },
      yaxis: %{min: -10, max: 40}
    }
  end

  defp candlestick do
    %{
      series: [%{name: "candle", data: Enum.map(@candles, fn {x, y} -> %{x: x, y: y} end)}],
      chart: %{height: 350, type: "candlestick", toolbar: @no_toolbar},
      grid: @grid_lines,
      tooltip: %{enabled: true},
      xaxis: %{type: "category"},
      yaxis: %{tooltip: %{enabled: true}}
    }
  end

  defp stacked_bar do
    %{
      series: [
        %{name: "PRODUCT A", data: [44, 55, 41, 67, 22, 43, 21, 49]},
        %{name: "PRODUCT B", data: [13, 23, 20, 8, 13, 27, 33, 12]},
        %{name: "PRODUCT C", data: [11, 17, 15, 15, 21, 14, 15, 13]}
      ],
      chart: %{type: "bar", height: 350, stacked: true, stackType: "100%", toolbar: @no_toolbar},
      plotOptions: %{bar: %{borderRadius: 15}},
      xaxis: %{categories: for(year <- [2011, 2012], q <- 1..4, do: "#{year} Q#{q}")},
      fill: %{opacity: 1},
      legend: %{
        position: "top",
        horizontalAlign: "left",
        fontSize: "14px",
        markers: %{radius: 12}
      }
    }
  end

  defp scatter do
    %{
      series: [
        %{
          name: "SAMPLE A",
          data: [
            [16.4, 5.4],
            [21.7, 2],
            [27.1, 2.3],
            [16.4, 0],
            [13.6, 3.7],
            [10.9, 5.2],
            [16.4, 6.5],
            [10.9, 0],
            [24.5, 7.1],
            [10.9, 0],
            [8.1, 4.7]
          ]
        },
        %{
          name: "SAMPLE B",
          data: [
            [36.4, 13.4],
            [1.6, 10],
            [9.9, 2],
            [7.1, 15],
            [1.4, 0],
            [3.6, 13.7],
            [1.9, 15.2],
            [6.4, 16.5],
            [0.9, 10],
            [4.5, 17.1],
            [10.9, 10]
          ]
        },
        %{
          name: "SAMPLE C",
          data: [
            [21.7, 3],
            [32.6, 3],
            [27.1, 4],
            [29.6, 6],
            [31.6, 8],
            [21.6, 5],
            [20.9, 4],
            [22.4, 0],
            [32.6, 10.3],
            [29.7, 20.8],
            [24.5, 0.8]
          ]
        }
      ],
      chart: %{
        height: 350,
        type: "scatter",
        zoom: %{enabled: true, type: "xy"},
        toolbar: @no_toolbar
      },
      xaxis: %{tickAmount: 10},
      yaxis: %{tickAmount: 7},
      legend: %{position: "bottom", horizontalAlign: "left", fontSize: "14px"}
    }
  end

  defp radial_bar do
    %{
      colors: ["#4ade80", "#f43f5e", "#a855f7"],
      series: [44, 55, 67],
      chart: %{height: 350, type: "radialBar"},
      plotOptions: %{
        radialBar: %{
          hollow: %{margin: 15, size: "35%"},
          track: %{margin: 15},
          dataLabels: %{
            name: %{fontSize: "22px"},
            value: %{fontSize: "16px"},
            total: %{show: true, label: "Total"}
          }
        }
      },
      stroke: %{lineCap: "round"},
      labels: ~w(Apples Oranges Bananas)
    }
  end

  defp radar do
    %{
      series: [
        %{name: "Series 1", data: [80, 50, 30, 40, 100, 20]},
        %{name: "Series 2", data: [20, 30, 40, 80, 20, 80]},
        %{name: "Series 3", data: [44, 76, 78, 13, 43, 10]}
      ],
      chart: %{
        height: 350,
        type: "radar",
        dropShadow: %{enabled: true, blur: 1, left: 1, top: 1}
      },
      grid: %{xaxis: %{lines: %{show: false}}, yaxis: %{lines: %{show: false}}},
      stroke: %{width: 2},
      fill: %{opacity: 0.1},
      markers: %{size: 0},
      xaxis: %{categories: ~w(2011 2012 2013 2014 2015 2016)}
    }
  end

  defp polar_area do
    %{
      series: [42, 47, 52, 58, 65],
      chart: %{width: 380, type: "polarArea", animations: %{enabled: false}},
      labels: ["Rose A", "Rose B", "Rose C", "Rose D", "Rose E"],
      fill: %{opacity: 1},
      stroke: %{width: 1},
      yaxis: %{show: false},
      legend: %{position: "bottom", horizontalAlign: "center"},
      plotOptions: %{polarArea: %{rings: %{strokeWidth: 0}, spokes: %{strokeWidth: 0}}},
      theme: %{
        monochrome: %{color: "#F000B9", enabled: true, shadeTo: "light", shadeIntensity: 0.6}
      }
    }
  end
end
