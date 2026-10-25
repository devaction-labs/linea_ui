defmodule LineaShowcaseWeb.Templates.Dashboards.Travel do
  @moduledoc """
  LineOne's Travel dashboard: the travels history (totals, a trips table the server searches and
  pages), analytics and expense charts, and the top hotels, which can be saved to favorites.
  """

  use LineaShowcaseWeb.Template,
    title: "Travel",
    section: :dashboards,
    lineone: "dashboards-travel"

  import LineaShowcaseWeb.Templates.Dashboards.Parts

  alias LineaShowcaseWeb.Templates.Dashboards.Travel.Data

  @page_size 5

  @impl true
  def mount(socket), do: assign(socket, search: "", page: 1, favorites: MapSet.new())

  @impl true
  def handle_event("search", %{"search" => search}, socket),
    do: {:noreply, assign(socket, search: search, page: 1)}

  def handle_event("paginate", %{"page" => page}, socket),
    do: {:noreply, assign(socket, page: String.to_integer(page))}

  def handle_event("report", %{"label" => label}, socket),
    do: {:noreply, send_toast(socket, "#{label} report is being prepared", color: "success")}

  def handle_event("favorite", %{"id" => id}, socket) do
    id = String.to_integer(id)
    favorites = socket.assigns.favorites

    {:noreply,
     assign(socket,
       favorites:
         (MapSet.member?(favorites, id) && MapSet.delete(favorites, id)) ||
           MapSet.put(favorites, id)
     )}
  end

  def handle_event("menu_action", params, socket), do: menu_toast(socket, params)

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  defp visible(search, page) do
    query = search |> String.trim() |> String.downcase()

    trips =
      Enum.filter(Data.trips(), fn trip ->
        query == "" or
          Enum.any?([trip.name, trip.country], &String.contains?(String.downcase(&1), query))
      end)

    total = length(trips)

    %{
      rows: trips |> Enum.drop((page - 1) * @page_size) |> Enum.take(@page_size),
      total: total,
      pages: max(div(total + @page_size - 1, @page_size), 1),
      first: min((page - 1) * @page_size + 1, total),
      last: min(page * @page_size, total)
    }
  end

  defp analytics_options do
    %{
      colors: ["#4ade80", "#f43f5e", "#a855f7"],
      series: [44, 55, 67],
      chart: %{height: 250, type: "radialBar"},
      plotOptions: %{
        radialBar: %{
          hollow: %{margin: 10, size: "35%"},
          track: %{margin: 10},
          dataLabels: %{
            name: %{fontSize: "22px"},
            value: %{fontSize: "16px"},
            total: %{show: true, label: "Total", formatter: "total"}
          }
        }
      },
      grid: %{padding: %{top: -20, bottom: -20, right: 0, left: 0}},
      stroke: %{lineCap: "round"},
      labels: ["Booked", "Cancelled", "Unconfirmed"]
    }
  end

  defp expense_options do
    %{
      colors: ["#0EA5E9"],
      series: [%{name: "Expense", data: [82, 25, 60, 30, 50, 20]}],
      chart: %{
        type: "area",
        stacked: false,
        height: 180,
        parentHeightOffset: 0,
        toolbar: %{show: false}
      },
      dataLabels: %{enabled: false},
      grid: %{padding: %{left: 0, right: 0, top: -20, bottom: -8}},
      fill: %{
        type: "gradient",
        gradient: %{
          shadeIntensity: 1,
          inverseColors: false,
          opacityFrom: 0.45,
          opacityTo: 0.1,
          stops: [20, 100, 100, 100]
        }
      },
      stroke: %{width: 2},
      tooltip: %{shared: true},
      legend: %{show: false},
      yaxis: %{show: false},
      xaxis: %{labels: %{show: false}, axisTicks: %{show: false}, axisBorder: %{show: false}}
    }
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :trips, visible(assigns.search, assigns.page))

    ~H"""
    <div id="travel-dashboard" class="-mx-[var(--margin-x)]">
      <div class="mt-4 grid grid-cols-12 gap-4 px-[var(--margin-x)] transition-all duration-[.25s] sm:mt-5 sm:gap-5 lg:mt-6 lg:gap-6">
        <.travels_history trips={@trips} page={@page} search={@search} />
        <div class="col-span-12 grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 lg:col-span-4 lg:grid-cols-1 lg:gap-6 xl:col-span-3">
          <.card padded={false} class="pb-5">
            <.card_title title="Analytics" menu="analytics-menu" />
            <div>
              <.chart id="analytics-chart" options={analytics_options()} />
            </div>
            <div class="mx-auto mt-3 max-w-xs px-4 text-center text-xs-plus sm:px-5">
              <p>Travel analytics calculated based on travels count</p>
            </div>
          </.card>
          <.card padded={false}>
            <div class="mt-3 flex items-center justify-between px-4 sm:px-5">
              <h2 class="font-medium tracking-wide text-slate-700 dark:text-navy-100">Expense</h2>
              <.card_menu id="expense-menu" button_class="-mr-2 size-7" />
            </div>
            <p class="grow px-4 text-xl font-semibold text-slate-700 dark:text-navy-100 sm:px-5">
              $34.6k
            </p>
            <div class="ax-transparent-gridline">
              <.chart id="expense-chart" options={expense_options()} />
            </div>
          </.card>
        </div>
      </div>
      <.top_hotels hotels={Data.hotels()} favorites={@favorites} />
    </div>
    """
  end

  attr :trips, :map, required: true
  attr :page, :integer, required: true
  attr :search, :string, required: true

  defp travels_history(assigns) do
    ~H"""
    <.card padded={false} class="col-span-12 lg:col-span-8 xl:col-span-9">
      <div class="mt-3 flex items-center justify-between px-4 sm:px-5">
        <h2 class="text-base font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100">
          Travels History
        </h2>
        <div class="flex">
          <.title_search id="travels-search" value={@search} />
          <.card_menu id="travels-history-menu" icon="huge-more-vertical" button_class="-mr-1.5" />
        </div>
      </div>
      <div class="mt-5 grid grid-cols-1 gap-4 px-4 sm:grid-cols-3 sm:px-5">
        <div
          :for={total <- Data.totals()}
          class={["relative flex flex-col overflow-hidden rounded-lg p-3.5", total.background]}
        >
          <p class={["text-xs uppercase", total.text]}>{total.label}</p>
          <div class="flex items-end justify-between space-x-2">
            <p class="mt-4 text-2xl font-medium text-white">{total.value}</p>
            <.text_link
              href="#"
              class={[
                "border-b border-dotted border-current pb-0.5 text-xs font-medium no-underline outline-hidden transition-colors duration-300 line-clamp-1 hover:text-white focus:text-white",
                total.text
              ]}
              phx-click="report"
              phx-value-label={total.label}
            >
              Get Report
            </.text_link>
          </div>
          <.mask shape={total.shape} class="absolute top-0 right-0 -m-3 size-16 bg-white/20" />
        </div>
      </div>
      <.table
        id="travels"
        rows={@trips.rows}
        row_id={&"trip-#{&1.id}"}
        variant="hoverable"
        rounded="none"
        wrapper_class="scrollbar-sm mt-5 min-w-full overflow-x-auto"
      >
        <:col :let={trip} head_class="hidden">
          <div class="flex items-center space-x-4">
            <div class="size-12">
              <img class="h-full w-full rounded-lg" src={trip.image} alt={trip.name} />
            </div>
            <div>
              <p class="font-medium text-slate-600 dark:text-navy-100">{trip.name}</p>
              <p class="mt-1 text-xs text-slate-400 dark:text-navy-300">{trip.country}</p>
            </div>
          </div>
        </:col>
        <:col :let={trip} head_class="hidden">{trip.nights} Night</:col>
        <:col :let={trip} head_class="hidden">
          <.icon name="huge-airplane-take-off-01" class="size-4" /> &hairsp; <span>{trip.from}</span>
        </:col>
        <:col :let={trip} head_class="hidden">
          <.icon name="huge-airplane-landing-01" class="size-4" /> &hairsp; <span>{trip.to}</span>
        </:col>
        <:col :let={trip} head_class="hidden">{trip.adults} Adult</:col>
        <:col :let={trip} head_class="hidden">
          <p class="font-medium text-slate-700 dark:text-navy-100">${trip.price}</p>
        </:col>
        <:empty>No trip matches.</:empty>
      </.table>
      <div class="flex flex-col justify-between space-y-4 px-4 py-4 sm:flex-row sm:items-center sm:space-y-0 sm:px-5">
        <div class="text-xs-plus">{@trips.first} - {@trips.last} of {@trips.total} entries</div>
        <.pagination page={@page} total_pages={@trips.pages} on_change="paginate" shape="pill" />
      </div>
    </.card>
    """
  end

  attr :hotels, :list, required: true
  attr :favorites, :any, required: true

  defp top_hotels(assigns) do
    ~H"""
    <div class="mt-4 pl-[var(--margin-x)] transition-all duration-[.25s] sm:mt-5 lg:mt-6">
      <div class="rounded-l-lg bg-slate-150 pt-4 pb-1 dark:bg-navy-800">
        <h2 class="px-4 text-base font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100 sm:px-5 lg:text-lg">
          Top Hotels
        </h2>
        <div class="scrollbar-sm mt-4 flex space-x-4 overflow-x-auto px-4 pb-4 sm:px-5">
          <div :for={hotel <- @hotels} class="flex w-72 shrink-0 flex-col">
            <img
              class="h-48 w-full rounded-2xl object-cover object-center"
              src={hotel.image}
              alt={hotel.name}
            />
            <.card padded={false} class="mx-2 -mt-8 grow rounded-2xl p-3.5">
              <div class="flex space-x-2">
                <.badge color={Data.kind_color(hotel.kind)} shape="pill" class="py-1 uppercase">
                  {hotel.kind}
                </.badge>
                <div class="flex flex-wrap items-center font-inter text-xs uppercase">
                  <p>{hotel.beds} beds</p>
                  <div class="mx-2 my-1 w-px self-stretch bg-slate-200 dark:bg-navy-500"></div>
                  <p>{hotel.adults} Adult</p>
                </div>
              </div>
              <div class="mt-2">
                <a
                  href="#"
                  class="text-sm-plus font-medium text-slate-700 line-clamp-1 hover:text-primary focus:text-primary dark:text-navy-100 dark:hover:text-accent-light dark:focus:text-accent-light"
                >
                  {hotel.name}
                </a>
              </div>
              <div class="flex items-end justify-between">
                <p class="mt-2">
                  <span class="text-base font-medium text-slate-700 dark:text-navy-100">${hotel.price}</span>
                  <span class="text-xs text-slate-400 dark:text-navy-300">/day</span>
                </p>
                <.favorite hotel={hotel} active={MapSet.member?(@favorites, hotel.id)} />
              </div>
            </.card>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :hotel, :map, required: true
  attr :active, :boolean, required: true

  defp favorite(assigns) do
    ~H"""
    <button
      type="button"
      class="flex shrink-0 items-center space-x-1"
      aria-pressed={to_string(@active)}
      aria-label={"Save #{@hotel.name}"}
      phx-click="favorite"
      phx-value-id={@hotel.id}
    >
      <.icon
        name="huge-star"
        class={["size-3.5", (@active && "text-warning") || "text-slate-400 dark:text-navy-300"]}
      />
      <span>{@hotel.rating}</span>
    </button>
    """
  end
end
