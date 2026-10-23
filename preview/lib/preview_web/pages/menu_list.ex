defmodule PreviewWeb.Pages.MenuList do
  use PreviewWeb.Page, title: "Menu List", category: :components, lineone: "components-menu-list"

  @long ["Getting start", "Shipping", "Payments", "Returns", "My Account", "Copyright & Legal"] ++
          ["Mobile App", "Security"]

  @columns [
    [{1, "link", "primary", false, 8}, {2, "link", "primary", true, 8}],
    [{3, "solid", "primary", false, 6}, {4, "solid", "primary", true, 6}],
    [{5, "pill", "primary", false, 6}, {6, "pill", "primary", true, 6}],
    [{7, "solid", "neutral", false, 6}, {8, "solid", "neutral", true, 6}],
    [{9, "gradient", "primary", false, 6}, {10, "gradient", "primary", true, 6}],
    [{11, "bordered", "primary", false, 6}, {12, "bordered", "primary", true, 6}]
  ]

  def mount(socket), do: assign(socket, active: %{})

  def handle_event("pick", %{"value" => value}, socket) do
    [list, item] = String.split(value, ":")
    {:noreply, update(socket, :active, &Map.put(&1, list, item))}
  end

  def render(assigns) do
    assigns = assign(assigns, columns: @columns, labels: @long)

    ~H"""
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 lg:grid-cols-3 lg:gap-6">
      <div :for={column <- @columns} class="space-y-4 sm:space-y-5 lg:space-y-6">
        <div :for={{n, variant, color, icons, count} <- column} class="card">
          <div class="border-b border-slate-200 p-4 dark:border-navy-500 sm:px-5">
            <h2 class="font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100 lg:text-base">
              Menu List Example {n}
            </h2>
          </div>
          <div class="p-4 sm:px-5">
            <.menu_list id={"menu-#{n}"} variant={variant} color={color} on_select="pick">
              <:item
                :for={label <- Enum.take(@labels, count)}
                value={"#{n}:#{label}"}
                active={Map.get(@active, "#{n}", "Getting start") == label}
              >
                <.icon :if={icons} name={label} />
                <span>{label}</span>
              </:item>
            </.menu_list>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @paths %{
    "Getting start" => ["M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"],
    "Shipping" => [
      "M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10a1 1 0 001 1h1m8-1a1 1 0 01-1 1H9m4-1V8a1 1 0 011-1h2.586a1 1 0 01.707.293l3.414 3.414a1 1 0 01.293.707V16a1 1 0 01-1 1h-1m-6-1a1 1 0 001 1h1M5 17a2 2 0 104 0m-4 0a2 2 0 114 0m6 0a2 2 0 104 0m-4 0a2 2 0 114 0"
    ],
    "Payments" => [
      "M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"
    ],
    "Returns" => [
      "M16 15v-1a4 4 0 00-4-4H8m0 0l3 3m-3-3l3-3m9 14V5a2 2 0 00-2-2H6a2 2 0 00-2 2v16l4-2 4 2 4-2 4 2z"
    ],
    "My Account" => ["M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"],
    "Mobile App" => [
      "M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"
    ],
    "Security" => [
      "M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
    ]
  }

  attr :name, :string, required: true

  defp icon(%{name: "Copyright & Legal"} = assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.5" />
      <path
        d="M12.0449 15.8486C12.625 15.8486 13.1318 15.6729 13.5654 15.3213C13.999 14.9697 14.2393 14.5303 14.2861 14.0029H15.8242C15.7949 14.5479 15.6074 15.0664 15.2617 15.5586C14.916 16.0508 14.4531 16.4434 13.873 16.7363C13.2988 17.0293 12.6895 17.1758 12.0449 17.1758C10.75 17.1758 9.71875 16.7451 8.95117 15.8838C8.18945 15.0166 7.80859 13.833 7.80859 12.333V12.0605C7.80859 11.1348 7.97852 10.3115 8.31836 9.59082C8.6582 8.87012 9.14453 8.31055 9.77734 7.91211C10.416 7.51367 11.1689 7.31445 12.0361 7.31445C13.1025 7.31445 13.9873 7.63379 14.6904 8.27246C15.3994 8.91113 15.7773 9.74023 15.8242 10.7598H14.2861C14.2393 10.1445 14.0049 9.64062 13.583 9.24805C13.167 8.84961 12.6514 8.65039 12.0361 8.65039C11.21 8.65039 10.5684 8.94922 10.1113 9.54688C9.66016 10.1387 9.43457 10.9971 9.43457 12.1221V12.4297C9.43457 13.5254 9.66016 14.3691 10.1113 14.9609C10.5625 15.5527 11.207 15.8486 12.0449 15.8486Z"
        fill="currentColor"
      />
    </svg>
    """
  end

  defp icon(assigns) do
    assigns = assign(assigns, :paths, Map.fetch!(@paths, assigns.name))

    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path
        :if={@name == "Shipping"}
        d="M9 17a2 2 0 11-4 0 2 2 0 014 0zM19 17a2 2 0 11-4 0 2 2 0 014 0z"
      />
      <path
        :for={d <- @paths}
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="1.5"
        d={d}
      />
    </svg>
    """
  end
end
