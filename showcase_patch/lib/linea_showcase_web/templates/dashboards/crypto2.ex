defmodule LineaShowcaseWeb.Templates.Dashboards.Crypto2 do
  @moduledoc "LineOne's second crypto dashboard: the candlestick statistics, mining rigs, wallets and the exchange."

  use LineaShowcaseWeb.Template,
    title: "Cryptocurrency v2",
    section: :dashboards,
    lineone: "dashboards-crypto-2",
    slug: "crypto-2"

  import LineaShowcaseWeb.Templates.Dashboards.Parts
  import LineaShowcaseWeb.Templates.Dashboards.Parts.Exchange, only: [exchange_panel: 1]

  alias __MODULE__.Data
  alias LineaShowcaseWeb.Templates.Dashboards.Parts.Exchange

  @wallet_tiles %{
    primary:
      {"bg-primary hover:shadow-primary/50 dark:bg-accent dark:shadow-accent/50 dark:hover:shadow-accent/50",
       "text-primary dark:text-accent", "text-indigo-100"},
    warning: {"bg-warning hover:shadow-warning/50", "text-warning", "text-amber-50"},
    info: {"bg-info hover:shadow-info/50", "text-info", "text-sky-100"},
    secondary: {"bg-secondary hover:shadow-secondary/50", "text-secondary", "text-pink-100"}
  }

  @impl LineaShowcaseWeb.Template
  def mount(socket) do
    socket
    |> assign(
      ranges: Data.ranges(),
      stats: Data.stats(),
      rigs: Data.rigs(),
      wallets: Data.wallets()
    )
    |> Exchange.init()
    |> select_range("12hr")
  end

  @impl LineaShowcaseWeb.Template
  def handle_event("range", %{"range" => range}, socket),
    do: {:noreply, select_range(socket, range)}

  def handle_event("range", %{"value" => range}, socket),
    do: {:noreply, select_range(socket, range)}

  def handle_event("rigs", %{"rig" => states}, socket) do
    rigs = Enum.map(socket.assigns.rigs, &%{&1 | on: states[&1.id] == "true"})
    {:noreply, assign(socket, rigs: rigs)}
  end

  def handle_event("rigs_all", %{"on" => on}, socket) do
    {:noreply, assign(socket, rigs: Enum.map(socket.assigns.rigs, &%{&1 | on: on == "true"}))}
  end

  def handle_event("wallet", %{"coin" => coin}, socket),
    do: {:noreply, Exchange.set_from(socket, coin)}

  def handle_event("exchange_" <> _ = event, params, socket),
    do: Exchange.handle_event(event, params, socket)

  def handle_event("menu", %{"action" => action}, socket),
    do: {:noreply, send_toast(socket, action, color: "info")}

  defp select_range(socket, range) do
    assign(socket,
      range: range,
      candles: %{
        series: [%{name: "candle", data: Data.candles(range)}],
        chart: %{height: 364, type: "candlestick", parentHeightOffset: 0, toolbar: %{show: false}},
        grid: %{
          xaxis: %{lines: %{show: true}},
          yaxis: %{lines: %{show: true}},
          padding: %{left: -12, right: -12, top: -6, bottom: 0}
        },
        tooltip: %{enabled: true},
        xaxis: %{type: "category", tickAmount: 10, labels: %{rotate: 0}},
        yaxis: %{tooltip: %{enabled: true}, labels: %{offsetX: -14}},
        responsive: [%{breakpoint: 640, options: %{xaxis: %{tickAmount: 6}}}]
      }
    )
  end

  @impl LineaShowcaseWeb.Template
  def render(assigns) do
    ~H"""
    <div class="mt-4 grid grid-cols-12 gap-4 sm:mt-5 sm:gap-5 lg:mt-6 lg:gap-6">
      <div class="col-span-12 lg:col-span-8">
        <div class="grid grid-cols-1 gap-4 sm:gap-5 lg:gap-6">
          <.card padded={false} class="px-5 pb-3">
            <div class="flex items-center justify-between py-3">
              <h3 class="text-base font-medium text-slate-800 dark:text-navy-50">Statistics</h3>
              <div class="flex items-center space-x-4 font-inter text-slate-700 dark:text-navy-100">
                <.tabs
                  id="statistics-tab"
                  selected={@range}
                  on_change="range"
                  class="hidden sm:flex"
                  list_class="space-x-4 font-inter"
                >
                  <:tab
                    :for={{key, label} <- @ranges}
                    name={key}
                    class="h-auto rounded-none border-b-0 p-0 tracking-wide aria-selected:text-primary"
                  >
                    {label}
                  </:tab>
                </.tabs>
                <.dots_menu id="statistics-menu" class="sm:-mr-1.5">
                  <.dropdown_item
                    :for={{key, label} <- @ranges}
                    phx-click="range"
                    phx-value-range={key}
                  >
                    {label}
                  </.dropdown_item>
                </.dots_menu>
              </div>
            </div>
            <.chart
              id="candlestick-chart"
              options={@candles}
              formatters={%{"yaxis.labels.formatter" => "thousands"}}
            />
          </.card>
          <div class="grid grid-cols-2 gap-4 sm:order-first sm:grid-cols-4 sm:gap-5 lg:gap-6">
            <div
              :for={stat <- @stats}
              class="rounded-lg border border-slate-150 p-3 dark:border-navy-700"
            >
              <div class="flex justify-between space-x-1">
                <p class="text-xl font-semibold text-slate-700 dark:text-navy-100">{stat.value}</p>
                <.stat_icon icon={stat.icon} />
              </div>
              <p class="mt-1 text-xs-plus line-clamp-1">{stat.label}</p>
            </div>
          </div>
          <.mining rigs={@rigs} />
        </div>
      </div>
      <div class="col-span-12 lg:col-span-4">
        <div class="grid grid-cols-2 gap-4 sm:grid-cols-4 sm:gap-5 lg:grid-cols-2 lg:gap-6">
          <.wallet :for={wallet <- @wallets} wallet={wallet} />
        </div>
        <.card padded={false} class="mt-4 px-4 pb-4 sm:mt-5 sm:px-5 lg:mt-6">
          <.exchange_panel
            form={@exchange}
            tab={@exchange_tab}
            received={@received}
            header_class="py-3"
          />
        </.card>
      </div>
    </div>
    """
  end

  attr :wallet, :map, required: true

  defp wallet(assigns) do
    assigns = assign(assigns, tile: @wallet_tiles[assigns.wallet.color])

    ~H"""
    <button
      type="button"
      phx-click="wallet"
      phx-value-coin={@wallet.coin}
      class={[
        "rounded-lg p-4 text-left transition-shadow duration-300 hover:shadow-lg",
        elem(@tile, 0)
      ]}
    >
      <div class="flex size-10 items-center justify-center rounded-lg bg-white/90">
        <.icon name={@wallet.icon} class={["size-5", elem(@tile, 1)]} />
      </div>
      <p class="mt-3 text-base font-medium text-white">{@wallet.name}</p>
      <div class="mt-8">
        <p class="mt-3 text-xl font-medium text-white">{@wallet.value}</p>
        <p class={["mt-1", elem(@tile, 2)]}>{@wallet.amount}</p>
      </div>
    </button>
    """
  end

  attr :rigs, :list, required: true

  defp mining(assigns) do
    ~H"""
    <.card padded={false} class="px-4 pb-4 sm:px-5">
      <div class="flex items-center justify-between py-3">
        <h2 class="font-medium tracking-wide text-slate-700 dark:text-navy-100">Mining Stats</h2>
        <.dots_menu id="mining-menu" class="-mr-1.5">
          <.dropdown_item phx-click="rigs_all" phx-value-on="true">Power On All</.dropdown_item>
          <.dropdown_item phx-click="rigs_all" phx-value-on="false">Power Off All</.dropdown_item>
        </.dots_menu>
      </div>
      <form id="mining-rigs" phx-change="rigs" class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div
          :for={rig <- @rigs}
          class="flex items-center justify-between space-x-2 rounded-lg border border-slate-200 p-3 dark:border-navy-600"
        >
          <div class="flex items-center space-x-3">
            <div class={[
              "flex size-10 shrink-0 items-center justify-center rounded-lg",
              rig_tile(rig)
            ]}>
              <.chip_icon />
            </div>
            <div>
              <p class="font-medium text-slate-700 dark:text-navy-100">ID: {rig.id}</p>
              <p class={["mt-0.5 text-xs line-clamp-1", rig_text(rig)]}>{rig_status(rig)}</p>
            </div>
          </div>
          <.switch
            id={"rig-#{rig.id}"}
            name={"rig[#{rig.id}]"}
            checked={rig.on}
            color="primary"
            shape="squircle"
            class="h-5 w-10"
          />
        </div>
      </form>
    </.card>
    """
  end

  defp rig_tile(%{on: true}), do: "bg-success text-white"
  defp rig_tile(%{down: true}), do: "bg-warning text-white"
  defp rig_tile(_off), do: "bg-slate-300 text-slate-700 dark:bg-navy-450 dark:text-navy-100"

  defp rig_text(%{on: true}), do: "text-success"
  defp rig_text(%{down: true}), do: "text-warning"
  defp rig_text(_off), do: nil

  defp rig_status(%{on: true, uptime: nil}), do: "Up for a few seconds"
  defp rig_status(%{on: true, uptime: uptime}), do: "Up for #{uptime}"
  defp rig_status(%{down: true, uptime: uptime}), do: "Down for #{uptime}"
  defp rig_status(_off), do: "Power Off"

  attr :icon, :atom, required: true

  defp stat_icon(%{icon: :chip} = assigns) do
    ~H"""
    <.icon name="huge-cpu" class="size-5 shrink-0 text-primary dark:text-accent" />
    """
  end

  defp stat_icon(%{icon: :chart} = assigns) do
    ~H"""
    <.icon name="huge-chart-column" class="size-5 shrink-0 text-success" />
    """
  end

  defp stat_icon(%{icon: :dollar} = assigns) do
    ~H"""
    <.icon name="huge-dollar-circle" class="size-5 text-warning" />
    """
  end

  defp stat_icon(%{icon: :refresh} = assigns) do
    ~H"""
    <.icon name="huge-refresh" class="size-5 text-info" />
    """
  end

  defp chip_icon(assigns) do
    ~H"""
    <.icon name="huge-cpu" class="size-6" />
    """
  end
end
