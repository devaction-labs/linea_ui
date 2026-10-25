defmodule LineaShowcaseWeb.Templates.Dashboards.Personal do
  @moduledoc """
  LineOne's Personal dashboard: earnings and counters, ongoing projects, contact list (an
  accordion with call/video/chat/mail actions), recent payments, client messages that are
  marked read on click, income, a calendar whose month and day are kept by the server, and the
  tweets carousel.
  """

  use LineaShowcaseWeb.Template,
    title: "Personal",
    section: :dashboards,
    lineone: "dashboards-personal"

  import LineaShowcaseWeb.Templates.Dashboards.Parts

  alias LineaShowcaseWeb.Templates.Dashboards.Personal.Data

  @impl true
  def mount(socket) do
    today = Data.today()

    assign(socket,
      month: Date.beginning_of_month(today),
      day: nil,
      messages: Data.messages()
    )
  end

  @impl true

  def handle_event("calendar_" <> _ = event, params, socket),
    do: calendar_event(event, params, socket)

  def handle_event("read", %{"id" => id}, socket) do
    id = String.to_integer(id)
    message = Enum.find(socket.assigns.messages, &(&1.id == id))

    {:noreply,
     socket
     |> update(:messages, &Enum.map(&1, fn m -> read(m, id) end))
     |> send_toast("Conversation with #{message.name} opened", color: "primary")}
  end

  def handle_event("contact", %{"name" => name, "via" => via}, socket),
    do: {:noreply, send_toast(socket, "#{via} #{name}", color: "primary")}

  def handle_event("payment", %{"name" => name, "amount" => amount}, socket),
    do: {:noreply, send_toast(socket, "#{amount} from #{name}", color: "success")}

  def handle_event("menu_action", params, socket), do: menu_toast(socket, params)

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  defp read(%{id: id} = message, id), do: %{message | unread: 0}
  defp read(message, _id), do: message

  defp earning_options do
    %{
      colors: ["#fff"],
      series: [%{name: "Earning", data: [0, 20, 50, 10]}],
      chart: %{
        type: "line",
        stacked: false,
        height: 60,
        parentHeightOffset: 0,
        toolbar: %{show: false}
      },
      dataLabels: %{enabled: false},
      grid: %{padding: %{left: 0, right: 0, top: -28}},
      stroke: %{width: 3, curve: "smooth"},
      tooltip: %{shared: true},
      legend: %{show: false},
      yaxis: %{show: false},
      xaxis: %{labels: %{show: false}, axisTicks: %{show: false}, axisBorder: %{show: false}}
    }
  end

  defp income_options do
    {months, data} = Data.income()

    %{
      series: [%{name: "Income", data: data}],
      colors: ["#4467EF"],
      chart: %{height: 250, type: "bar", parentHeightOffset: 0, toolbar: %{show: false}},
      plotOptions: %{bar: %{borderRadius: 10, columnWidth: "55%", dataLabels: %{position: "top"}}},
      dataLabels: %{enabled: true, formatter: "thousands_fixed", offsetY: -20},
      xaxis: %{
        categories: months,
        position: "top",
        axisBorder: %{show: false},
        axisTicks: %{show: false},
        tooltip: %{enabled: false}
      },
      yaxis: %{axisBorder: %{show: false}, axisTicks: %{show: false}, labels: %{show: false}}
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="personal-dashboard"
      class="mt-4 grid grid-cols-12 gap-4 sm:mt-5 sm:gap-5 lg:mt-6 lg:gap-6"
    >
      <div class="col-span-12 space-y-4 sm:space-y-5 lg:col-span-8 lg:space-y-6">
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-3 sm:gap-5 lg:gap-6">
          <.earnings />
          <div class="grid grid-cols-1 gap-4 sm:col-span-2 sm:grid-cols-2 sm:gap-5 lg:gap-6">
            <.stat :for={stat <- Data.stats()} stat={stat} />
          </div>
        </div>
        <.ongoing_projects projects={Data.projects()} />
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 lg:gap-6">
          <.contact_list contacts={Data.contacts()} />
          <.recent_payments payments={Data.payments()} />
        </div>
      </div>
      <div class="col-span-12 lg:col-span-4">
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 lg:grid-cols-1 lg:gap-6">
          <.client_messages messages={@messages} />
          <.card padded={false}>
            <.card_title
              title="Income"
              menu="income-menu"
              class="mt-3 flex h-8 items-center justify-between px-4 sm:px-5"
            />
            <div class="ax-transparent-gridline pr-2">
              <.chart id="income-chart" options={income_options()} />
            </div>
          </.card>
          <.month_calendar month={@month} day={@day} today={Data.today()} />
          <.tweets tweets={Data.tweets()} />
        </div>
      </div>
    </div>
    """
  end

  defp earnings(assigns) do
    assigns = assign(assigns, :options, earning_options())

    ~H"""
    <.card padded={false} class="bg-gradient-to-r from-blue-500 to-indigo-600 px-5 pb-5">
      <div>
        <div class="ax-transparent-gridline mt-5 w-1/2">
          <.chart id="earning-chart" options={@options} />
        </div>
        <p class="mt-3 text-base font-medium tracking-wide text-indigo-100">Earnings</p>
        <p class="mt-4 font-inter text-2xl font-semibold">
          <span class="text-indigo-100">$</span>
          <span class="text-white">31.313</span>
        </p>
        <.badge shape="pill" class="mt-2 bg-black/20 text-indigo-50">13 Members</.badge>
      </div>
      <div class="absolute bottom-0 right-0 overflow-hidden rounded-lg">
        <img
          class="w-24 translate-x-1/4 translate-y-1/4 opacity-50"
          src="/images/illustrations/the-dollar.svg"
          alt=""
        />
      </div>
    </.card>
    """
  end

  attr :stat, :map, required: true

  defp stat(assigns) do
    ~H"""
    <.card padded={false} class="justify-center p-4.5">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-base font-semibold text-slate-700 dark:text-navy-100">{@stat.value}</p>
          <p class="text-xs-plus line-clamp-1">{@stat.label}</p>
        </div>
        <.mask shape="star" class={["flex size-10 shrink-0 items-center justify-center", @stat.color]}>
          <.icon name={@stat.icon} class="size-5 text-white" />
        </.mask>
      </div>
      <div>
        <.badge
          color={(@stat.up && "success") || "error"}
          variant="soft"
          class="mt-2 space-x-1 py-1 px-1.5"
        >
          <span>{@stat.trend}</span>
          <.icon name="huge-chart-increase" class="size-3.5" />
        </.badge>
      </div>
    </.card>
    """
  end

  attr :projects, :list, required: true

  defp ongoing_projects(assigns) do
    ~H"""
    <div>
      <.card_title
        title="Ongoing Projects"
        menu="ongoing-projects-menu"
        class="flex items-center justify-between"
        title_class="text-sm-plus font-medium tracking-wide text-slate-700 dark:text-navy-100"
      />
      <div class="mt-3 space-y-3.5">
        <.card :for={project <- @projects} padded={false} class="p-3">
          <div class="flex items-center space-x-3">
            <img
              class="size-10 rounded-lg object-cover object-center"
              src={"/images/illustrations/#{project.image}"}
              alt={project.name}
            />
            <div class="flex-1">
              <div class="flex justify-between">
                <p class="font-medium text-slate-700 dark:text-navy-100">{project.name}</p>
              </div>
              <div class="mt-0.5 flex text-xs text-slate-400 dark:text-navy-300">
                <p>{project.updated}</p>
                <div class="mx-2 my-1 hidden w-px bg-slate-200 dark:bg-navy-500 sm:flex"></div>
                <p class="hidden sm:flex">Deadline: {project.deadline}</p>
              </div>
            </div>
          </div>
          <p class={["-mt-3 text-right text-xs font-medium", percent_color(project.color)]}>
            {project.progress}%
          </p>
          <.progress
            value={project.progress}
            color={project.color}
            variant={(project.color == "primary" && "solid") || "soft"}
            active={project.color == "primary"}
            label={project.name}
            class={["mt-2 h-1.5", project.color == "primary" && "bg-slate-150 dark:bg-navy-500"]}
          />
        </.card>
      </div>
    </div>
    """
  end

  defp percent_color("primary"), do: "text-primary dark:text-accent-light"
  defp percent_color("secondary"), do: "text-secondary dark:text-secondary-light"
  defp percent_color("warning"), do: "text-warning"
  defp percent_color("info"), do: "text-info"

  attr :contacts, :list, required: true

  defp contact_list(assigns) do
    ~H"""
    <.card padded={false} class="px-4 pb-4 sm:px-5">
      <.card_title
        title="Contact List"
        menu="contact-list-menu"
        class="my-3 flex h-8 items-center justify-between"
      />
      <.contact_accordion id="contacts-accordion" contacts={@contacts} />
    </.card>
    """
  end

  attr :payments, :list, required: true

  defp recent_payments(assigns) do
    ~H"""
    <.card padded={false} class="px-4 pb-4 sm:px-5">
      <div class="my-3 flex h-8 items-center justify-between">
        <h2 class="font-medium tracking-wide text-slate-700 dark:text-navy-100">Recent Payments</h2>
        <.text_link
          href="#"
          class="border-b border-dotted border-current pb-0.5 text-xs-plus font-medium text-primary no-underline outline-hidden transition-colors duration-300 hover:text-primary/70 focus:text-primary/70 dark:text-accent-light dark:hover:text-accent-light/70 dark:focus:text-accent-light/70"
        >
          View All
        </.text_link>
      </div>
      <div class="space-y-3.5">
        <div
          :for={payment <- @payments}
          class="flex cursor-pointer items-center justify-between"
          phx-click="payment"
          phx-value-name={payment.name}
          phx-value-amount={payment.amount}
        >
          <div class="flex items-center space-x-3.5">
            <.avatar src={"/images/avatar/#{payment.avatar}.jpg"} alt={payment.name} />
            <div>
              <p class="font-medium text-slate-700 dark:text-navy-100">{payment.name}</p>
              <p class="text-xs text-slate-400 line-clamp-1 dark:text-navy-300">{payment.at}</p>
            </div>
          </div>
          <p class="font-medium text-slate-600 dark:text-navy-100">{payment.amount}</p>
        </div>
      </div>
    </.card>
    """
  end

  attr :messages, :list, required: true

  defp client_messages(assigns) do
    ~H"""
    <.card padded={false} class="px-4 pb-4 sm:px-5">
      <.card_title
        title="Client Messages"
        menu="client-messages-menu"
        class="my-3 flex h-8 items-center justify-between"
      />
      <div class="space-y-4">
        <div
          :for={message <- @messages}
          class="flex cursor-pointer items-center justify-between space-x-2"
          phx-click="read"
          phx-value-id={message.id}
        >
          <div class="flex items-center space-x-3">
            <.avatar src={"/images/avatar/#{message.avatar}.jpg"} alt={message.name} />
            <div>
              <div class="flex items-center space-x-2">
                <p class="font-medium text-slate-700 dark:text-navy-100">{message.name}</p>
                <.badge
                  :if={message.unread > 0}
                  shape="pill"
                  class="h-4.5 min-w-[1.125rem] justify-center bg-slate-200 px-1.5 text-tiny-plus leading-none text-slate-800 dark:bg-navy-450 dark:text-white"
                >
                  {message.unread}
                </.badge>
              </div>
              <p class="text-xs text-slate-400 line-clamp-1 dark:text-navy-300">{message.text}</p>
            </div>
          </div>
          <span class="hover:text-primary dark:hover:text-accent-light">
            <.icon name="huge-arrow-right-01" class="size-5" />
          </span>
        </div>
      </div>
    </.card>
    """
  end

  attr :tweets, :list, required: true

  defp tweets(assigns) do
    ~H"""
    <.card padded={false}>
      <.carousel id="messages-carousel" pagination="bullets">
        <.carousel_slide :for={tweet <- @tweets} class="p-4 sm:p-5">
          <div class="flex items-center justify-between">
            <a
              href="#"
              class="font-inter font-medium tracking-wide transition-colors hover:text-slate-800 focus:text-slate-800 dark:hover:text-navy-100 dark:focus:text-navy-100"
            >
              {tweet.account}
            </a>
            <.icon name="huge-twitter" class="size-4" />
          </div>
          <p class="mt-3 text-xs-plus">{tweet.text}</p>
          <div class="mt-2 pb-5 text-xs">
            <a
              :for={tag <- tweet.tags}
              href="#"
              class="text-xs-plus text-primary hover:text-primary-focus dark:text-accent-light dark:hover:text-accent"
            >
              {tag}
            </a>
          </div>
        </.carousel_slide>
      </.carousel>
    </.card>
    """
  end
end
