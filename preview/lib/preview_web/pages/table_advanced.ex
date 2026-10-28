defmodule PreviewWeb.Pages.TableAdvanced do
  use PreviewWeb.Page,
    title: "Table Advanced",
    category: :components,
    lineone: "components-table-advanced"

  @users [
    {"John Doe", 24, "443-893-2318", "Superadmin", 3, false},
    {"Sabina Mores", 26, "563-516-8941", "Author", 4, false},
    {"Tom Robert", 29, "897-154-7469", "Admin", 20, true},
    {"Nolan Doe", 22, "443-893-2318", "Author", 2, false},
    {"Raul Bradley", 31, "335-412-7721", "Author", 5, true},
    {"Katrina West", 27, "662-901-3345", "Admin", 6, false},
    {"Henry Curtis", 35, "787-221-6650", "Author", 7, false},
    {"Corey Evans", 23, "214-662-7045", "Superadmin", 8, true},
    {"Lance Tucker", 28, "520-332-1498", "Author", 9, false},
    {"Anthony Jensen", 33, "903-114-2278", "Admin", 10, false},
    {"Alfredo Elliott", 25, "614-508-3394", "Author", 11, true},
    {"Derrick Simmons", 30, "781-245-9081", "Author", 12, false}
  ]

  @developers [
    {"John Doe", "443-893-2316", "Level 1", 3, [{"Tailwind", "info"}, {"Alpine", "success"}]},
    {"Sabina Mores", "684-4161-8911", "Level 2", 8, [{"React", "warning"}, {"Remix", "info"}]},
    {"Tom Robert", "179-911-3218", "Level 3", 4,
     [{"Bootstrap", "error"}, {"Tailwind", "secondary"}]},
    {"Nolan Doe", "766-9746-1462", "Level 4", 14, [{"Tailwind", "info"}, {"Alpine", "success"}]},
    {"Katrina West", "662-901-3345", "Level 2", 6, [{"Vue", "success"}, {"Nuxt", "info"}]},
    {"Henry Curtis", "787-221-6650", "Level 3", 7, [{"Svelte", "error"}, {"Kit", "warning"}]},
    {"Corey Evans", "214-662-7045", "Level 1", 5, [{"React", "warning"}, {"Next", "info"}]},
    {"Lance Tucker", "520-332-1498", "Level 4", 9, [{"Laravel", "error"}, {"Alpine", "success"}]}
  ]

  @projects [
    {"Web Application", "John Doe", 42, "progress", "03 Sep"},
    {"Android App", "Sabina Mores", 77, "progress", "16 Sep"},
    {"Android App", "Bailie Coulman", 100, "cancelled", "N/A"},
    {"Desktop App", "Richardo Aldren", 100, "completed", "25 Aug"},
    {"CRM App", "Nolan Doe", 8, "pending", "3 Oct"},
    {"Landing Page", "Katrina West", 58, "progress", "12 Oct"},
    {"iOS App", "Henry Curtis", 100, "completed", "02 Aug"},
    {"Admin Dashboard", "Corey Evans", 25, "pending", "21 Oct"},
    {"E-commerce", "Lance Tucker", 100, "cancelled", "N/A"},
    {"Chat App", "Anthony Jensen", 91, "progress", "30 Sep"}
  ]

  @statuses %{
    "progress" =>
      {"In Progress", "text-primary dark:text-accent-light", "bg-primary dark:bg-accent"},
    "cancelled" => {"Cancelled", "text-error", "bg-error"},
    "completed" => {"Completed", "text-success", "bg-success"},
    "pending" => {"Pending", "text-secondary dark:text-secondary-light", "bg-secondary"}
  }

  def mount(socket) do
    assign(socket,
      users: %{search: "", page: 1, page_size: 4},
      developers: %{search: "", page: 1, page_size: 4},
      projects: %{
        search: "",
        page: 1,
        page_size: 5,
        employer: "",
        project: "",
        statuses: ~w(progress pending completed cancelled)
      }
    )
  end

  def handle_event("search", %{"table" => table, "search" => search}, socket),
    do: {:noreply, update_table(socket, table, &%{&1 | search: search, page: 1})}

  def handle_event("page", %{"table" => table, "page" => page}, socket),
    do: {:noreply, update_table(socket, table, &%{&1 | page: String.to_integer(page)})}

  def handle_event("page_size", %{"page_size" => size}, socket),
    do:
      {:noreply,
       update_table(socket, "users", &%{&1 | page_size: String.to_integer(size), page: 1})}

  def handle_event("filter", params, socket) do
    {:noreply,
     update_table(
       socket,
       "projects",
       &%{
         &1
         | employer: params["employer"],
           project: params["project"],
           statuses: Map.get(params, "statuses", []),
           page: 1
       }
     )}
  end

  defp update_table(socket, "users", fun), do: update(socket, :users, fun)
  defp update_table(socket, "developers", fun), do: update(socket, :developers, fun)
  defp update_table(socket, "projects", fun), do: update(socket, :projects, fun)

  def render(assigns) do
    users = filter(users(), :name, assigns.users.search)
    developers = filter(developers(), :name, assigns.developers.search)
    projects = projects(assigns.projects)

    assigns =
      assign(assigns,
        user_rows: page(users, assigns.users),
        user_total: length(users),
        developer_rows: page(developers, assigns.developers),
        developer_total: length(developers),
        project_rows: page(projects, assigns.projects),
        project_total: length(projects)
      )

    ~H"""
    <.data_table
      id="users-table"
      rows={@user_rows}
      search={@users.search}
      on_search={JS.push("search", value: %{table: "users"})}
      page={@users.page}
      page_size={@users.page_size}
      page_sizes={[4, 8, 12]}
      total={@user_total}
      on_page={JS.push("page", value: %{table: "users"})}
      on_page_size="page_size"
    >
      <:title>Users Table</:title>
      <:actions><.more_button vertical /></:actions>
      <:col :let={user} label="#">{user.id}</:col>
      <:col :let={user} label="Avatar">
        <div class="avatar flex size-10">
          <img class="mask is-squircle" src={avatar_src(user.avatar)} alt="avatar" />
        </div>
      </:col>
      <:col
        :let={user}
        label="Name"
        class="px-3 font-medium text-slate-700 dark:text-navy-100 lg:px-5"
      >
        {user.name}
      </:col>
      <:col :let={user} label="Age">{user.age}</:col>
      <:col :let={user} label="Phone">{user.phone}</:col>
      <:col :let={user} label="Role">
        <div class={["badge rounded-full", role_class(user.role)]}>{user.role}</div>
      </:col>
      <:col :let={user} label="Status">
        <label class="inline-flex items-center">
          <input
            class="form-switch h-5 w-10 rounded-full bg-slate-300 before:rounded-full before:bg-slate-50 checked:bg-primary checked:before:bg-white dark:bg-navy-900 dark:before:bg-navy-300 dark:checked:bg-accent dark:checked:before:bg-white"
            type="checkbox"
            checked={user.active}
            aria-label="Active"
          />
        </label>
      </:col>
      <:col label="Action"><.more_button /></:col>
    </.data_table>

    <.data_table
      id="collapsible-table"
      rows={@developer_rows}
      search={@developers.search}
      on_search={JS.push("search", value: %{table: "developers"})}
      page={@developers.page}
      page_size={@developers.page_size}
      total={@developer_total}
      on_page={JS.push("page", value: %{table: "developers"})}
      pager="pill"
      expand_label="More"
    >
      <:title>Collapsible Table</:title>
      <:actions><.more_button vertical /></:actions>
      <:col :let={dev} label="#">{dev.id}</:col>
      <:col :let={dev} label="Avatar">
        <div class="avatar flex">
          <img class="rounded-full" src={avatar_src(dev.avatar)} alt="avatar" />
        </div>
      </:col>
      <:col :let={dev} label="Name" class="font-medium text-slate-700 dark:text-navy-100">
        {dev.name}
      </:col>
      <:col :let={dev} label="Phone">{dev.phone}</:col>
      <:col :let={dev} label="Level">{dev.level}</:col>
      <:col :let={dev} label="Stack">
        <div class="flex space-x-2">
          <div
            :for={{name, color} <- dev.stack}
            class={["badge rounded-full border", stack_class(color)]}
          >
            {name}
          </div>
        </div>
      </:col>
      <:expand :let={detail}>
        <p>Lorem ipsum dolor, sit amet consectetur adipisicing elit. Aut amet sunt repudiandae!</p>
        <.table id={"inner-#{detail.row.id}"} rows={inner_rows()} hoverable>
          <:col :let={row} label="#">{row.id}</:col>
          <:col :let={row} label="Name">{row.name}</:col>
          <:col :let={row} label="Job">{row.job}</:col>
          <:col :let={row} label="Favorite Color">{row.color}</:col>
        </.table>
        <div class="text-right">
          <.button
            color="primary"
            variant="flat"
            size="sm"
            class="mt-2 rounded-sm px-3"
            phx-click={detail.toggle}
          >
            Hide
          </.button>
        </div>
      </:expand>
    </.data_table>

    <.data_table
      id="filter-table"
      rows={@project_rows}
      search={@projects.search}
      on_search={JS.push("search", value: %{table: "projects"})}
      page={@projects.page}
      page_size={@projects.page_size}
      total={@project_total}
      on_page={JS.push("page", value: %{table: "projects"})}
      pager="circle"
    >
      <:title>Table With Filter</:title>
      <:filters :let={toggle}>
        <form id="project-filters" phx-change="filter" phx-submit="filter">
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 lg:gap-6">
            <.filter_input
              name="employer"
              label="Employer name:"
              value={@projects.employer}
              placeholder="Enter Employer Name"
              icon="user"
            />
            <.filter_input
              name="project"
              label="Project name:"
              value={@projects.project}
              placeholder="Enter Project Name"
              icon="cog"
            />
            <.filter_input
              name="from"
              label="From:"
              value=""
              placeholder="Choose start date..."
              icon="calendar"
            />
            <.filter_input
              name="to"
              label="To:"
              value=""
              placeholder="Choose start date..."
              icon="calendar"
            />
            <div class="sm:col-span-2">
              <span>Project Status:</span>
              <div class="mt-2 grid grid-cols-1 gap-4 sm:grid-cols-4 sm:gap-5 lg:gap-6">
                <label
                  :for={{value, label, class} <- status_options()}
                  class="inline-flex items-center space-x-2"
                >
                  <input
                    class={["form-checkbox is-basic size-5 rounded-sm border-slate-400/70", class]}
                    type="checkbox"
                    name="statuses[]"
                    value={value}
                    checked={value in @projects.statuses}
                  />
                  <span>{label}</span>
                </label>
              </div>
            </div>
          </div>
          <div class="mt-4 space-x-1 text-right">
            <.button variant="flat" phx-click={toggle}>Cancel</.button>
            <.button color="primary" phx-click={toggle}>Apply</.button>
          </div>
        </form>
      </:filters>
      <:col :let={project} label="#">{project.id}</:col>
      <:col :let={project} label="Project Name" class="font-medium text-slate-700 dark:text-navy-100">
        {project.name}
      </:col>
      <:col :let={project} label="Employer Name">{project.employer}</:col>
      <:col :let={project} label="Progress">
        <div class="progress h-2 bg-slate-150 dark:bg-navy-500" title={project.tooltip}>
          <div class={["rounded-full", project.bar]} style={"width: #{project.progress}%"}></div>
        </div>
      </:col>
      <:col :let={project} label="Status">
        <div class={["badge space-x-2.5 px-0", project.text]}>
          <div class="size-2 rounded-full bg-current"></div>
          <span>{project.status}</span>
        </div>
      </:col>
      <:col :let={project} label="Deadline">{project.deadline}</:col>
    </.data_table>

    <div class="mt-8 space-y-6">
      <h3 class="text-base font-medium text-slate-700 dark:text-navy-100">
        Columns that leave by priority
      </h3>
      <div :for={width <- [820, 560, 380]} class="max-w-full" style={"width: #{width}px"}>
        <p class="mb-2 text-xs text-slate-400">{width}px box</p>
        <.card class="p-3">
          <.table id={"priority-#{width}"} rows={inner_rows()} hoverable>
            <:col :let={row} label="Name">
              <div class="flex items-center gap-2">
                <img
                  class="table-narrow-hide size-7 rounded-full"
                  src={avatar_src(row.id)}
                  alt=""
                />
                {row.name}
              </div>
            </:col>
            <:col :let={row} label="Job" priority={3}>{row.job}</:col>
            <:col :let={row} label="Owner" priority={2}>{row.color}</:col>
            <:col :let={row} label="Status" priority={1}>Active</:col>
            <:col :let={row} label="Id" align="right">{row.id}</:col>
          </.table>
        </.card>
      </div>
    </div>
    """
  end

  attr :vertical, :boolean, default: false

  defp more_button(assigns) do
    ~H"""
    <.button variant="flat" icon shape="pill" size="sm" class="size-8" aria-label="More">
      <svg
        :if={@vertical}
        xmlns="http://www.w3.org/2000/svg"
        class="size-4.5"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"
        />
      </svg>
      <svg
        :if={!@vertical}
        xmlns="http://www.w3.org/2000/svg"
        class="size-5"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="2"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z"
        />
      </svg>
    </.button>
    """
  end

  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :placeholder, :string, required: true
  attr :icon, :string, required: true

  defp filter_input(assigns) do
    ~H"""
    <label class="block">
      <span>{@label}</span>
      <div class="relative mt-1.5 flex">
        <input
          class="form-input peer w-full rounded-lg border border-slate-300 bg-transparent px-3 py-2 pl-9 placeholder:text-slate-400/70 hover:border-slate-400 focus:border-primary dark:border-navy-450 dark:hover:border-navy-400 dark:focus:border-accent"
          placeholder={@placeholder}
          type="text"
          name={@name}
          value={@value}
          phx-debounce="300"
        />
        <span class="pointer-events-none absolute flex h-full w-10 items-center justify-center text-slate-400 peer-focus:text-primary dark:text-navy-300 dark:peer-focus:text-accent">
          <.filter_icon icon={@icon} />
        </span>
      </div>
    </label>
    """
  end

  defp filter_icon(%{icon: "user"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="size-4.5 transition-colors duration-200"
      fill="none"
      viewBox="0 0 24 24"
    >
      <path
        stroke="currentColor"
        stroke-width="1.5"
        d="M5 19.111c0-2.413 1.697-4.468 4.004-4.848l.208-.035a17.134 17.134 0 015.576 0l.208.035c2.307.38 4.004 2.435 4.004 4.848C19 20.154 18.181 21 17.172 21H6.828C5.818 21 5 20.154 5 19.111zM16.083 6.938c0 2.174-1.828 3.937-4.083 3.937S7.917 9.112 7.917 6.937C7.917 4.764 9.745 3 12 3s4.083 1.763 4.083 3.938z"
      />
    </svg>
    """
  end

  defp filter_icon(%{icon: "cog"} = assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="size-4.5 transition-colors duration-200"
      fill="none"
      viewBox="0 0 24 24"
    >
      <path
        stroke="currentColor"
        stroke-width="1.5"
        d="M3.082 13.944c-.529-.95-.793-1.425-.793-1.944 0-.519.264-.994.793-1.944L4.43 7.63l1.426-2.381c.559-.933.838-1.4 1.287-1.66.45-.259.993-.267 2.08-.285L12 3.26l2.775.044c1.088.018 1.631.026 2.08.286.45.26.73.726 1.288 1.659L19.57 7.63l1.35 2.426c.528.95.792 1.425.792 1.944 0 .519-.264.994-.793 1.944L19.57 16.37l-1.426 2.381c-.559.933-.838 1.4-1.287 1.66-.45.259-.993.267-2.08.285L12 20.74l-2.775-.044c-1.088-.018-1.631-.026-2.08-.286-.45-.26-.73-.726-1.288-1.659L4.43 16.37l-1.35-2.426z"
      />
      <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="1.5" />
    </svg>
    """
  end

  defp filter_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="size-5 transition-colors duration-200"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="1.5"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
      />
    </svg>
    """
  end

  defp users do
    @users
    |> Enum.with_index(1)
    |> Enum.map(fn {{name, age, phone, role, avatar, active}, id} ->
      %{id: id, name: name, age: age, phone: phone, role: role, avatar: avatar, active: active}
    end)
  end

  defp developers do
    @developers
    |> Enum.with_index(1)
    |> Enum.map(fn {{name, phone, level, avatar, stack}, id} ->
      %{id: id, name: name, phone: phone, level: level, avatar: avatar, stack: stack}
    end)
  end

  defp projects(state) do
    @projects
    |> Enum.with_index(1)
    |> Enum.map(fn {{name, employer, progress, status, deadline}, id} ->
      {label, text, bar} = @statuses[status]

      %{
        id: id,
        name: name,
        employer: employer,
        progress: progress,
        key: status,
        status: label,
        text: text,
        bar: bar,
        tooltip: tooltip(status, progress, label),
        deadline: deadline
      }
    end)
    |> filter(:name, state.search)
    |> filter(:employer, state.employer)
    |> filter(:name, state.project)
    |> Enum.filter(&(&1.key in state.statuses))
  end

  defp tooltip("progress", progress, _label), do: "#{progress}% Completed"
  defp tooltip(_status, _progress, label), do: label

  defp filter(rows, _field, ""), do: rows

  defp filter(rows, field, query) do
    query = String.downcase(query)
    Enum.filter(rows, &(&1 |> Map.fetch!(field) |> String.downcase() |> String.contains?(query)))
  end

  defp page(rows, %{page: page, page_size: size}),
    do: Enum.slice(rows, (page - 1) * size, size)

  defp inner_rows do
    [
      %{id: 1, name: "Cy Ganderton", job: "Quality Control Specialist", color: "Blue"},
      %{id: 2, name: "Hart Hagerty", job: "Desktop Support Technician", color: "Purple"},
      %{id: 3, name: "Brice Swyre", job: "Tax Accountant", color: "Red"},
      %{id: 4, name: "Marjy Ferencz", job: "Office Assistant I", color: "Crimson"}
    ]
  end

  defp status_options do
    [
      {"pending", "Upcoming",
       "checked:border-secondary checked:bg-secondary hover:border-secondary focus:border-secondary dark:border-navy-400 dark:checked:border-secondary-light dark:checked:bg-secondary-light dark:hover:border-secondary-light dark:focus:border-secondary-light"},
      {"progress", "In Progress",
       "checked:border-primary checked:bg-primary hover:border-primary focus:border-primary dark:border-navy-400 dark:checked:border-accent dark:checked:bg-accent dark:hover:border-accent dark:focus:border-accent"},
      {"completed", "Complete",
       "checked:!border-success checked:bg-success hover:!border-success focus:!border-success dark:border-navy-400"},
      {"cancelled", "Cancelled",
       "checked:!border-error checked:bg-error hover:!border-error focus:!border-error dark:border-navy-400"}
    ]
  end

  defp avatar_src(n), do: "/lineone/images/avatar/avatar-#{n}.jpg"

  defp role_class("Author"), do: "bg-info/10 text-info dark:bg-info/15"

  defp role_class(_role),
    do: "bg-secondary/10 text-secondary dark:bg-secondary-light/15 dark:text-secondary-light"

  defp stack_class("info"), do: "border-info text-info"
  defp stack_class("success"), do: "border-success text-success"
  defp stack_class("warning"), do: "border-warning text-warning"
  defp stack_class("error"), do: "border-error text-error"

  defp stack_class("secondary"),
    do: "border-secondary text-secondary dark:border-secondary-light dark:text-secondary-light"
end
