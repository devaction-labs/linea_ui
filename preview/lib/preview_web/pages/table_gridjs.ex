defmodule PreviewWeb.Pages.TableGridjs do
  use PreviewWeb.Page,
    title: "Grid Table",
    category: :components,
    lineone: "components-table-gridjs"

  @people [
    %{id: "ID 1", name: "Cy Ganderton", job: "Quality Control Specialist", color: "Blue"},
    %{id: "ID 2", name: "Hart Hagerty", job: "Desktop Support Technician", color: "Purple"},
    %{id: "ID 3", name: "Brice Swyre", job: "Tax Accountant", color: "Red"},
    %{id: "ID 4", name: "Marjy Ferencz", job: "Office Assistant I", color: "Crimson"}
  ]

  @products [
    %{
      id: 59,
      title: "Spring and summershoes",
      price: 20,
      quantity: 3,
      total: 60,
      discount_percentage: "8.71",
      discounted_price: 55
    },
    %{
      id: 88,
      title: "TC Reusable Silicone Magic",
      price: 29,
      quantity: 2,
      total: 58,
      discount_percentage: "3.19",
      discounted_price: 56
    },
    %{
      id: 18,
      title: "Oil Free Moisturizer 100ml",
      price: 40,
      quantity: 2,
      total: 80,
      discount_percentage: "13.1",
      discounted_price: 70
    },
    %{
      id: 95,
      title: "Wholesale cargo lashing Belt",
      price: 930,
      quantity: 1,
      total: 930,
      discount_percentage: "17.67",
      discounted_price: 766
    },
    %{
      id: 39,
      title: "Women Sweaters Wool",
      price: 600,
      quantity: 2,
      total: 1200,
      discount_percentage: "17.2",
      discounted_price: 994
    },
    %{
      id: 96,
      title: "lighting ceiling kitchen",
      price: 30,
      quantity: 2,
      total: 60,
      discount_percentage: "14.89",
      discounted_price: 51
    },
    %{
      id: 91,
      title: "Black Motorbike",
      price: 569,
      quantity: 3,
      total: 1707,
      discount_percentage: "13.63",
      discounted_price: 1474
    },
    %{
      id: 9,
      title: "Infinix INBOOK",
      price: 1099,
      quantity: 1,
      total: 1099,
      discount_percentage: "11.83",
      discounted_price: 969
    },
    %{
      id: 16,
      title: "Hyaluronic Acid Serum",
      price: 19,
      quantity: 1,
      total: 19,
      discount_percentage: "13.31",
      discounted_price: 16
    },
    %{
      id: 54,
      title: "Pubg Printed Graphic T-Shirt",
      price: 46,
      quantity: 3,
      total: 138,
      discount_percentage: "16.44",
      discounted_price: 115
    }
  ]

  @films [
    %{title: "A New Hope", director: "George Lucas", producer: "Gary Kurtz, Rick McCallum"},
    %{
      title: "The Empire Strikes Back",
      director: "Irvin Kershner",
      producer: "Gary Kurtz, Rick McCallum"
    },
    %{
      title: "Return of the Jedi",
      director: "Richard Marquand",
      producer: "Howard G. Kazanjian, George Lucas, Rick McCallum"
    },
    %{title: "The Phantom Menace", director: "George Lucas", producer: "Rick McCallum"},
    %{title: "Attack of the Clones", director: "George Lucas", producer: "Rick McCallum"},
    %{title: "Revenge of the Sith", director: "George Lucas", producer: "Rick McCallum"},
    %{
      title: "The Force Awakens",
      director: "J. J. Abrams",
      producer: "Kathleen Kennedy, J. J. Abrams, Bryan Burk"
    }
  ]

  @contacts [
    {"John", "john@example.com", "(01) 22 888 4444", 2},
    {"Doe", "thedoe@example.com", "(33) 22 888 4444", 19},
    {"Nancy", "nancy@example.com", "(21) 33 888 4444", 14},
    {"Clarke", "clarke@example.com", "(44) 33 888 4444", 20},
    {"Robert", "robert@example.com", "(27) 63 688 6444", 14},
    {"Tom", "thetom@example.com", "(57) 63 688 6444", 4},
    {"Nolan", "Nolan@example.com", "(27) 63 688 6444", 3},
    {"Adam", "Adam@example.com", "(12) 22 888 4444", 2},
    {"Glen", "Glen@example.com", "(74) 22 888 4444", 18},
    {"Edna", "Edna@example.com", "(52) 33 888 4444", 13},
    {"Dianne", "dianne@example.com", "(78) 33 888 4444", 2},
    {"Wilson", "wilson@example.com", "(54) 63 688 6444", 1},
    {"Ross", "rose@example.com", "(98) 63 688 6444", 4},
    {"Henry", "henry@example.com", "(87) 63 688 6444", 3},
    {"Kerry", "kerry@example.com", "(55) 63 688 6444", 3}
  ]

  @tables ~w(people products films contacts)

  def mount(socket) do
    assign(socket,
      grids: Map.new(@tables, &{&1, %{search: "", sort_by: nil, sort_dir: "asc", page: 1}}),
      selected: []
    )
  end

  def handle_event("search", %{"grid" => grid, "search" => search}, socket) when grid in @tables,
    do: {:noreply, update_grid(socket, grid, &%{&1 | search: search, page: 1})}

  def handle_event("sort", %{"grid" => grid, "column" => column, "direction" => dir}, socket)
      when grid in @tables,
      do: {:noreply, update_grid(socket, grid, &%{&1 | sort_by: column, sort_dir: dir})}

  def handle_event("page", %{"grid" => grid, "page" => page}, socket) when grid in @tables,
    do: {:noreply, update_grid(socket, grid, &%{&1 | page: String.to_integer(page)})}

  def handle_event("select", %{"id" => id, "selected" => "true"}, socket),
    do: {:noreply, update(socket, :selected, &Enum.uniq([id | &1]))}

  def handle_event("select", %{"id" => id, "selected" => "false"}, socket),
    do: {:noreply, update(socket, :selected, &List.delete(&1, id))}

  def handle_event("select_all", %{"selected" => "true"}, socket),
    do: {:noreply, assign(socket, :selected, contacts() |> Enum.take(5) |> Enum.map(& &1.id))}

  def handle_event("select_all", %{"selected" => "false"}, socket),
    do: {:noreply, assign(socket, :selected, [])}

  defp update_grid(socket, grid, fun),
    do: update(socket, :grids, &Map.update!(&1, grid, fun))

  def render(assigns) do
    people = query(@people, assigns.grids["people"], ~w(id name job color))
    products = query(@products, assigns.grids["products"], ~w(id title))
    films = query(@films, assigns.grids["films"], ~w(title director producer))
    contacts = query(contacts(), assigns.grids["contacts"], ~w(id name email phone))

    assigns =
      assign(assigns,
        people: people,
        products: products,
        films: films,
        film_rows: page(films, assigns.grids["films"], 10),
        contacts: contacts,
        contact_rows: page(contacts, assigns.grids["contacts"], 10)
      )

    ~H"""
    <.grid_card title="From HTML Table">
      <.data_table
        id="grid-html"
        variant="grid"
        rows={@people}
        {grid_events("people", @grids["people"])}
      >
        <:col :let={row} label="#" sort_key="id">{row.id}</:col>
        <:col :let={row} label="Name" sort_key="name">{row.name}</:col>
        <:col :let={row} label="Job" sort_key="job">{row.job}</:col>
        <:col :let={row} label="Favorite Color" sort_key="color">{row.color}</:col>
      </.data_table>
    </.grid_card>

    <.grid_card title="Simple Exapmle">
      <.data_table
        id="grid-simple"
        variant="grid"
        rows={@products}
        {grid_events("products", @grids["products"])}
      >
        <:col :let={row} label="id" sort_key="id">{row.id}</:col>
        <:col :let={row} label="title" sort_key="title">{row.title}</:col>
        <:col :let={row} label="price" sort_key="price">{row.price}</:col>
        <:col :let={row} label="quantity" sort_key="quantity">{row.quantity}</:col>
        <:col :let={row} label="total" sort_key="total">{row.total}</:col>
        <:col :let={row} label="discountPercentage" sort_key="discount_percentage">
          {row.discount_percentage}
        </:col>
        <:col :let={row} label="discountedPrice" sort_key="discounted_price">
          {row.discounted_price}
        </:col>
      </.data_table>
    </.grid_card>

    <.grid_card title="GridJS Async Table">
      <.data_table
        id="grid-async"
        variant="grid"
        rows={@film_rows}
        total={length(@films)}
        page={@grids["films"].page}
        on_page={JS.push("page", value: %{grid: "films"})}
        {grid_events("films", @grids["films"])}
      >
        <:col :let={row} label="Title" sort_key="title">{row.title}</:col>
        <:col :let={row} label="Director" sort_key="director">{row.director}</:col>
        <:col :let={row} label="Producer" sort_key="producer">{row.producer}</:col>
      </.data_table>
    </.grid_card>

    <.grid_card title="GridJS Advanced Table">
      <.data_table
        id="grid-advanced"
        variant="grid"
        rows={@contact_rows}
        total={length(@contacts)}
        page={@grids["contacts"].page}
        on_page={JS.push("page", value: %{grid: "contacts"})}
        {grid_events("contacts", @grids["contacts"])}
      >
        <:col :let={row} label="ID" sort_key="id"><span class="mx-2">{row.id}</span></:col>
        <:col :let={row} label="Name" sort_key="name">
          <span class="font-medium text-slate-700 dark:text-navy-100">{row.name}</span>
        </:col>
        <:col :let={row} label="Avatar">
          <div class="avatar flex"><img class="rounded-full" src={row.avatar} alt="avatar" /></div>
        </:col>
        <:col :let={row} label="Email" sort_key="email">{row.email}</:col>
        <:col :let={row} label="Phone Number" sort_key="phone">{row.phone}</:col>
        <:col label="Actions">
          <div class="flex justify-center space-x-2">
            <.button color="info" variant="flat" icon class="size-8" aria-label="Edit">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="size-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                />
              </svg>
            </.button>
            <.button color="error" variant="flat" icon class="size-8" aria-label="Delete">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="size-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
            </.button>
          </div>
        </:col>
      </.data_table>
    </.grid_card>

    <.grid_card title="Row Selection">
      <.data_table
        id="grid-selection"
        variant="grid"
        rows={Enum.take(contacts(), 5)}
        row_key={& &1.id}
        selected={@selected}
        on_select="select"
        on_select_all="select_all"
      >
        <:col :let={row} label="ID"><span class="mx-2">{row.id}</span></:col>
        <:col :let={row} label="Name">
          <span class="font-medium text-slate-700 dark:text-navy-100">{row.name}</span>
        </:col>
        <:col :let={row} label="Email">{row.email}</:col>
        <:col :let={row} label="Phone Number">{row.phone}</:col>
      </.data_table>
      <p class="px-4 pt-4 sm:px-5">Selected: {Enum.join(Enum.reverse(@selected), ", ")}</p>
    </.grid_card>
    """
  end

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp grid_card(assigns) do
    ~H"""
    <div class="card pb-4">
      <div class="my-3 flex h-8 items-center justify-between px-4 sm:px-5">
        <h2 class="font-medium tracking-wide text-slate-700 line-clamp-1 dark:text-navy-100 lg:text-base">
          {@title}
        </h2>
        <.button variant="flat" icon shape="pill" size="sm" class="size-8" aria-label="More">
          <svg
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
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp grid_events(grid, state) do
    %{
      search: state.search,
      on_search: JS.push("search", value: %{grid: grid}),
      sort_by: state.sort_by,
      sort_dir: state.sort_dir,
      on_sort: JS.push("sort", value: %{grid: grid})
    }
  end

  defp contacts do
    @contacts
    |> Enum.with_index(1)
    |> Enum.map(fn {{name, email, phone, avatar}, id} ->
      %{
        id: Integer.to_string(id),
        name: name,
        email: email,
        phone: phone,
        avatar: "/lineone/images/avatar/avatar-#{avatar}.jpg"
      }
    end)
  end

  defp query(rows, state, fields) do
    rows
    |> search(state.search, fields)
    |> sort(state.sort_by, state.sort_dir)
  end

  defp search(rows, "", _fields), do: rows

  defp search(rows, query, fields) do
    query = String.downcase(query)

    Enum.filter(rows, fn row ->
      Enum.any?(fields, &(row |> field(&1) |> to_string() |> String.downcase() =~ query))
    end)
  end

  defp sort(rows, nil, _dir), do: rows
  defp sort(rows, column, "asc"), do: Enum.sort_by(rows, &field(&1, column), :asc)
  defp sort(rows, column, "desc"), do: Enum.sort_by(rows, &field(&1, column), :desc)

  defp field(row, column),
    do: Enum.find_value(row, fn {key, value} -> Atom.to_string(key) == column && value end)

  defp page(rows, %{page: page}, size), do: Enum.slice(rows, (page - 1) * size, size)
end
